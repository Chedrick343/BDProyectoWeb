// src/config/db.js
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

// Creamos un pool de conexiones para ejecutar múltiples consultas simultáneamente
export const pool = new Pool({
  host: process.env.PGHOST,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  database: process.env.PGDATABASE,
  port: process.env.PGPORT,
});

// Verificamos la conexión
pool.connect()
  .then(client => {
    console.log('✅ Conexión exitosa a PostgreSQL');
    client.release();
  })
  .catch(err => {
    console.error('❌ Error al conectar con la base de datos:', err.message);
  });
