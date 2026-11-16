const mysql = require('mysql2');

// pool ใช้ได้ทั้ง query ปกติและ transaction
const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '123456',
    database: 'hophak',
    waitForConnections: true,
    connectionLimit: 10,
}).promise();

module.exports = pool;
