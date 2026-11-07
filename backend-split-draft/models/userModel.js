// model ทำหน้าที่เดียวคือคุยกับตาราง users
const db = require('../config/db').promise();

async function findByUsername(username) {
    const [rows] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
    return rows[0];
}

async function findVerification(id) {
    const [rows] = await db.query('SELECT id, is_verified FROM users WHERE id = ?', [id]);
    return rows[0];
}

async function insert({ username, password, role, isVerified }) {
    const sql = 'INSERT INTO users (username, password, role, is_verified) VALUES (?, ?, ?, ?)';
    const [result] = await db.query(sql, [username, password, role, isVerified]);
    return result.insertId;
}

module.exports = { findByUsername, findVerification, insert };
