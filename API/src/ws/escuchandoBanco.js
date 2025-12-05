import { pool } from '../config/db.js';
import { socket } from "../ws/websocket.js";

socket.onAny((event, ...args) => {
    console.log("📡 EVENTO CAPTURADO:", event, args);
});

socket.on("event", async (msg) => {
    const { type, data } = msg;

    console.log("📥 Evento recibido:", type, data);

    switch (type) {

        case "transfer.reserve":
            const okReserve = await validarValoresCuenta(data.id);
            socket.emit("event", {
                type: "transfer.reserve.result",
                data: {
                    id: data.id,
                    ok: okReserve,
                    reason: okReserve ? undefined : "NO_FUNDS"
                }
            });
            break;

        case "transfer.debit":
            const okDebit = await debitarCuenta(data.id);
            socket.emit("event", {
                type: "transfer.debit.result",
                data: {
                    id: data.id,
                    ok: okDebit,
                    reason: okDebit ? undefined : "DEBIT_FAILED"
                }
            });
            break;

        // --------------------
        // BANCO DESTINO
        // --------------------
        case "transfer.init":
            console.log("Iniciando transferencia en banco destino:", data);
            await registrarInit(data);
            break;


        case "transfer.credit":
            const okCredit = await acreditarTemporalmente(data);
            socket.emit("event", {
                type: "transfer.credit.result",
                data: {
                    id: data.id,
                    ok: okCredit,
                    reason: okCredit ? undefined : "CREDIT_FAILED"
                }
            });
            break;

        case "transfer.rollback":
            await revertirCreditos(data);
            break;

        // --------------------
        // RESULTADO FINAL
        // --------------------
        case "transfer.commit":
            await finalizarTransaccion(data);

            // Resolver promesa hacia el frontend
            if (pendingTransfers[data.id]) {
                pendingTransfers[data.id].resolve({
                    status: "success", ...data
                });
            }
            break;

        case "transfer.reject":
            await marcarFallida(data.id);

            if (pendingTransfers[data.id]) {
                pendingTransfers[data.id].resolve({
                    status: "error",
                    reason: data.reason
                });
            }
            break;
    }
});

async function validarValoresCuenta(idTransferencia) {
    let client;

    try {
        client = await pool.connect();

        // 1. Obtener valores desde el SP
        const sql = `SELECT * FROM sp_obtener_datos_transferencia_para_debito($1)`;
        const result = await client.query(sql, [idTransferencia]);

        if (result.rows.length === 0) {
            console.error("⚠️ Transferencia no encontrada:", idTransferencia);
            return false;
        }

        const {
            monto_transferencia,
            saldo_cuenta,
            saldo_reservado,
            saldo_disponible
        } = result.rows[0];

        console.log("🔍 Datos obtenidos:", {
            monto_transferencia,
            saldo_cuenta,
            saldo_reservado,
            saldo_disponible
        });

        // 2. Validaciones
        if (saldo_cuenta < monto_transferencia) {
            console.log("❌ Saldo TOTAL insuficiente.");
            return false;
        }

        if (saldo_disponible < monto_transferencia) {
            console.log("❌ Saldo DISPONIBLE insuficiente.");
            return false;
        }
        return true;

    } catch (err) {
        console.error("❌ Error al validar valores de cuenta:", err);
        return false;
    } finally {
        if (client) client.release();
    }
}


async function debitarCuenta(id) { 
    try {
        const sql = `SELECT sp_debitar_transferencia($1) AS ok`;
        const values = [id];
        const result = await pool.query(sql, values);
        return result.rows[0].ok;
    } catch (error) {
        console.error("Error en débito:", error);
        return false;
    }
}

async function marcarFallida(idTransferencia) {
    try {
        const sql = `
            UPDATE transferencia
            SET estado = 'FAILED',
                fecha_actualizacion = NOW()
            WHERE id_transferencia = $1
        `;

        await pool.query(sql, [idTransferencia]);

        console.log(`❌ Transferencia ${idTransferencia} marcada como FAILED.`);
        return true;

    } catch (err) {
        console.error("❌ Error al marcar transferencia como fallida:", err);
        return false;
    }
}

/**------------------------------------ */
async function acreditarTemporalmente(data) {
    let client;

    try {
        client = await pool.connect();

        console.log(`💰 Acreditando temporalmente transferencia ${data.id} en cuenta destino ${data.to}`);

        const sqlGetCuenta = `
            SELECT id
            FROM cuenta
            WHERE iban = $1
        `;
        const queryCuenta = await client.query(sqlGetCuenta, [data.to]);

        if (queryCuenta.rows.length === 0) {
            console.error("❌ Cuenta destino NO encontrada:", data.to);
            return false;
        }

        const cuentaDestinoId = queryCuenta.rows[0].id;

        const sqlAcreditar = `
            UPDATE cuenta
            SET saldo = saldo + $1,
                fecha_actualizacion = NOW()
            WHERE id = $2
        `;

        await client.query(sqlAcreditar, [data.amount, cuentaDestinoId]);

        console.log(`✅ Acreditación temporal completada: +${data.amount} a cuenta ${data.to}`);

        return true;

    } catch (error) {
        console.error("❌ Error en crédito temporal:", error);
        return false;

    } finally {
        if (client) client.release();
    }
}

async function revertirCreditos(data) {
    let client;

    try {
        client = await pool.connect();

        console.log(`↩️ Revirtiendo crédito de transferencia ${data.id} en cuenta destino ${data.to}`);

        const sqlGetCuenta = `
            SELECT id
            FROM cuenta
            WHERE iban = $1
        `;
        const queryCuenta = await client.query(sqlGetCuenta, [data.to]);

        if (queryCuenta.rows.length === 0) {
            console.error("❌ Cuenta destino NO encontrada para reversión:", data.to);
            return false;
        }

        const cuentaDestinoId = queryCuenta.rows[0].id;

        const sqlRevertir = `
            UPDATE cuenta
            SET saldo = saldo - $1,
                fecha_actualizacion = NOW()
            WHERE id = $2
        `;

        await client.query(sqlRevertir, [data.amount, cuentaDestinoId]);

        console.log(`✅ Reversión de crédito completada: -${data.amount} a cuenta ${data.to}`);

        return true;

    } catch (error) {
        console.error("❌ Error al revertir crédito:", error);
        return false;

    } finally {
        if (client) client.release();
    }
}

async function finalizarTransaccion(data) {
    let client;

    try {
        client = await pool.connect();

        console.log(`🏁 Finalizando transferencia ${data.id}`);

        const sql = `
            UPDATE transferencia
            SET estado = 'COMPLETED',
                fecha_transferencia = NOW()
            WHERE id = $1
        `;

        const result = await client.query(sql, [data.id]);

        if (result.rowCount === 0) {
            console.error("❌ No se encontró la transferencia:", data.id);
            return false;
        }

        console.log(`✅ Transferencia ${data.id} marcada como COMPLETED`);
        return true;

    } catch (error) {
        console.error("❌ Error en finalizarTransaccion:", error);
        return false;

    } finally {
        if (client) client.release();
    }
}
