const express = require('express');
const cors = require('cors');

// โหลด .env ก่อนทุกอย่าง ถ้าไม่มี JWT_KEY จะหยุดทำงานตรงนี้
require('./config/env');

const authRoutes = require('./routes/auth');
const ownerRoutes = require('./routes/owner');
const errorHandler = require('./middleware/errorHandler');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api', authRoutes);
app.use('/api/owner', ownerRoutes);

// ต้องอยู่หลัง route ทั้งหมด
app.use(errorHandler);

app.listen(3000, () => {
    console.log('server running at http://localhost:3000');
});
