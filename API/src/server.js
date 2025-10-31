import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import authRoutes from './routes/authRoutes.js';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

// ✅ Versionado de la API
app.use('/api/v1', authRoutes);

app.listen(process.env.PORT || 3000, () => {
  console.log(`Servidor escuchando en http://localhost:${process.env.PORT || 3000}`);
});
