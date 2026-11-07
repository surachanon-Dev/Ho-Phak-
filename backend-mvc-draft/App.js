const express = require('express');
const cors = require('cors');

// โหลด .env ก่อนทุกอย่าง ถ้าไม่มี JWT_KEY จะหยุดทำงานตรงนี้
require('./config/env');

const { errorHandler, notFound } = require('./middleware/errorHandler');
const authRoutes = require('./routes/authRoutes');
const dormitoryRoutes = require('./routes/dormitoryRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const ownerRoutes = require('./routes/ownerRoutes');
const favoriteRoutes = require('./routes/favoriteRoutes');
const chatRoutes = require('./routes/chatRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api', authRoutes);
app.use('/api/dormitories', dormitoryRoutes);
app.use('/api', reviewRoutes);
app.use('/api/owner', ownerRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/conversations', chatRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);

// ต้องอยู่หลัง route ทั้งหมด
app.use(notFound);
app.use(errorHandler);

app.listen(3000, () => {
    console.log('server running at http://localhost:3000');
});
