import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import authRoutes from './routes/authRoutes.js';
import userRoutes from './routes/userRoutes.js';
import accountRoutes from './routes/accountsRoutes.js';
import transferRoutes from './routes/transfersRoutes.js';
import cardsRoutes from './routes/cardsRoutes.js';
import bankRoutes from './routes/bankRoutes.js';
dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());


app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/accounts', accountRoutes);
app.use('/api/v1/transfers', transferRoutes);
app.use('/api/v1/cards', cardsRoutes);
app.use('/api/v1/bank', bankRoutes);

app.listen(process.env.PORT || 3000, () => {
  console.log(`Servidor escuchando en http://localhost:${process.env.PORT || 3000}`);
});
