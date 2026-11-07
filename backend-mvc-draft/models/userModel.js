// model ทำหน้าที่คุยกับตาราง users เท่านั้น
// รับ conn ได้เพื่อให้ใช้ในทรานแซกชันเดียวกันได้ ถ้าไม่ส่งจะใช้ pool
const db = require('../config/db');

async function findAuthState(id) {
    const [rows] = await db.query(
        'SELECT id, username, role, status, is_verified FROM users WHERE id = ?', [id]);
    return rows[0];
}

async function findByPhone(phone) {
    const [rows] = await db.query('SELECT * FROM users WHERE phone = ?', [phone]);
    return rows[0];
}

async function insertStudent({ username, phone, passwordHash }) {
    const [result] = await db.query(
        "INSERT INTO users (username, phone, password, role, is_verified) VALUES (?, ?, ?, 'student', 0)",
        [username, phone, passwordHash]);
    return result.insertId;
}

async function findForUpdate(id, conn = db) {
    const [rows] = await conn.query('SELECT id, role, status FROM users WHERE id = ? FOR UPDATE', [id]);
    return rows[0];
}

async function setVerified(id, value, conn = db) {
    await conn.query('UPDATE users SET is_verified = ? WHERE id = ?', [value, id]);
}

async function suspend(id, reason, suspendedBy, conn = db) {
    await conn.query(
        "UPDATE users SET status = 'suspended', suspension_reason = ?, suspended_at = NOW(), suspended_by = ? WHERE id = ?",
        [reason, suspendedBy, id]);
}

async function restore(id, conn = db) {
    await conn.query(
        "UPDATE users SET status = 'active', suspension_reason = NULL, suspended_at = NULL, suspended_by = NULL WHERE id = ?",
        [id]);
}

// รายการผู้ใช้ทั้งหมดสำหรับ admin กรองด้วย role และ status ได้ (ค่าที่ service ตรวจแล้ว หรือ undefined)
// ไม่ส่งรหัสผ่านกลับไป
async function listForAdmin({ role, status } = {}) {
    const conditions = [];
    const params = [];
    if (role !== undefined) {
        conditions.push('role = ?');
        params.push(role);
    }
    if (status !== undefined) {
        conditions.push('status = ?');
        params.push(status);
    }
    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const [rows] = await db.query(
        `SELECT id, username, phone, role, status, is_verified, created_at FROM users
         ${where} ORDER BY id DESC`, params);
    return rows;
}

module.exports = { findAuthState, findByPhone, insertStudent, findForUpdate, setVerified, suspend, restore, listForAdmin };
