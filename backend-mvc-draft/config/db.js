const mysql = require('mysql2');

// pool ใช้ได้ทั้ง query ปกติและ transaction
// ค่าการเชื่อมต่อ MySQL อ่านจาก .env (DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME)
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '123456',
    database: process.env.DB_NAME || 'hophak',
    waitForConnections: true,
    connectionLimit: 10,
}).promise();

module.exports = pool;
