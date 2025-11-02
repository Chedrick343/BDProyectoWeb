# API Banco Damena

## Descripción
API REST desarrollada para exclusivamente el Banco Damena que permite la gestión de usuarios, cuentas, tarjetas, transferencias y autenticación segura.  
Desarrollada con **Node.js**, **Express.js** y **PostgreSQL**.
---

## Tecnologías Utilizadas
- **Backend:** Node.js, Express.js  
- **Base de datos:** PostgreSQL  
- **Autenticación:** JWT, BCrypt  
- **Seguridad:** CORS, Helmet  
- **Variables de entorno:** Dotenv  

---

## Dependencias

### Production
```json
{
  "express": "^4.18.2",
  "pg": "^8.11.3",
  "bcrypt": "^5.1.1",
  "jsonwebtoken": "^9.0.2",
  "cors": "^2.8.5",
  "dotenv": "^16.3.1"
}
```

### Development
```json
{
  "nodemon": "^3.0.1"
}
```

---

## Configuración del Entorno

### Variables de Entorno (`.env`)
```env
# Base de Datos PostgreSQL
PGHOST=134.199.141.222
PGUSER=user_damena
PGPASSWORD=xD2@3qLz9M
PGDATABASE=fecr_damena
PGPORT=15431

# Seguridad API
API_KEY=apiBanco_damena22*
JWT_SECRET=asecreta_muy_segura_que_cambies
JWT_EXPIRES_IN=1h

# Servidor
PORT=3000
```

---

## Instalación y Ejecución

### Prerrequisitos
- Node.js (v16 o superior)  
- PostgreSQL  
- Git  

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <url-del-repositorio>
   cd BDProyectoWeb
   ```

2. **Instalar dependencias**
   ```bash
   cd API
   npm install
   ```

3. **Configurar variables de entorno**
   ```bash
   # Crear archivo .env en la carpeta API/
   # y agregar las variables listadas arriba
   ```

4. **Ejecutar la aplicación**
   ```bash
   # Desarrollo (con nodemon)
   npm run dev

   # Producción
   npm start
   ```

5. **Verificar funcionamiento**
   ```bash
   # El servidor estará disponible en:
   http://localhost:3000
   ```

---

## Endpoints Principales

### Autenticación
- **POST** `/api/v1/auth/login` – Iniciar sesión  
- **POST** `/api/v1/auth/forgot-password` – Recuperar contraseña  
- **POST** `/api/v1/auth/verify-otp` – Verificar OTP  
- **POST** `/api/v1/auth/reset-password` – Restablecer contraseña  

### Usuarios
- **POST** `/api/v1/users` – Crear usuario  
- **GET** `/api/v1/users/:identification` – Obtener usuario  
- **PUT** `/api/v1/users/:id` – Actualizar usuario  
- **DELETE** `/api/v1/users/:id` – Eliminar usuario  

### Cuentas
- **POST** `/api/v1/accounts` – Crear cuenta  
- **GET** `/api/v1/accounts` – Listar cuentas  
- **GET** `/api/v1/accounts/:accountId` – Detalles de cuenta  
- **POST** `/api/v1/accounts/:accountId/status` – Cambiar estado  

### Tarjetas
- **POST** `/api/v1/cards` – Crear tarjeta  
- **GET** `/api/v1/cards` – Listar tarjetas  
- **GET** `/api/v1/cards/:cardId` – Detalles de tarjeta  
- **GET** `/api/v1/cards/:cardId/movements` – Movimientos de tarjeta  
- **POST** `/api/v1/cards/:cardId/movements` – Agregar movimiento  

### Transferencias
- **POST** `/api/v1/transfers/internal` – Transferencia interna  
- **POST** `/api/v1/transfers/validate-account` – Validar cuenta  
- **GET** `/api/v1/transfers/history/:accountId` – Historial  

### Datos Sensibles (PIN/CVV)
- **POST** `/api/v1/cards/:cardId/otp` – Generar OTP  
- **POST** `/api/v1/cards/:cardId/view-details` – Ver detalles con OTP  

## Estructura del Proyecto
```text
API/
├── src/
│   ├── controllers/     # Lógica de endpoints
│   ├── routes/          # Definición de rutas
│   ├── middlewares/     # Autenticación y validaciones
│   ├── config/          # Configuración BD
│   └── server.js        # Servidor principal
├── .env                 # Variables de entorno
├── package.json
└── README.md
```

---

## Seguridad
- Tokens JWT con expiración configurable  
- API Keys para endpoints públicos  
- Encriptación con **BCrypt**  
- Validación de roles (admin/cliente)  
- **CORS** configurado  
- **OTP** para operaciones sensibles  

---

## Pruebas

### Colección Postman
Incluye una colección con:
- Todos los endpoints configurados  
- Ejemplos de requests/responses  
- Variables de entorno para testing  
- Headers preconfigurados  
