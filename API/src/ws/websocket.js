import { io } from "socket.io-client";

export const socket = io("http://137.184.36.3:6000", {
    transports: ["websocket"],
    auth: {
        bankId: "B08",           
        bankName: "Damena",
        token: "BANK-CENTRAL-IC8057-2025"
    }
});

// CONEXIÓN
socket.on("connect", () => {
    console.log("☑ Conectado al Banco Central");
});

// ERROR
socket.on("connect_error", (err) => {
    console.error("❌ Error de conexión:", err.message);
});
