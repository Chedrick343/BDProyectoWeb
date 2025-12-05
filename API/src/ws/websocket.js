import { io } from "socket.io-client";

export const socket = io("http://137.184.36.3:6000", {
    transports: ["websocket"],
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 5000,
    reconnectionAttempts: 5,
    auth: {
        bankId: "B06",           
        bankName: "Damena",
        token: "BANK-CENTRAL-IC8057-2025"
    }
});

// CONEXIÓN
socket.on("connect", () => {
    console.log("☑ Conectado al Banco Central");
    console.log("📡 Socket ID:", socket.id);
    console.log("✅ Listo para recibir eventos");
});

// AUTENTICACIÓN
socket.on("auth_success", (data) => {
    console.log("🔐 Autenticación exitosa:", data);
});

socket.on("auth_error", (err) => {
    console.error("❌ Error de autenticación:", err);
});

// ERROR DE CONEXIÓN
socket.on("connect_error", (err) => {
    console.error("❌ Error de conexión:", err.message);
    console.error("📋 Detalles:", err);
});

// DESCONEXIÓN
socket.on("disconnect", (reason) => {
    console.warn("⚠️ Desconectado del Banco Central:", reason);
});
