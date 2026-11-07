const mysql = require('mysql2');

// การเชื่อมต่อ MySQL ของ XAMPP ใช้ร่วมกันทั้ง backend
const con = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'hopak'
});

module.exports = con;
