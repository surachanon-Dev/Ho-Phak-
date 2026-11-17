// model ของข้อมูลโปรไฟล์ในตาราง users (ชื่อ นามสกุล เบอร์ รหัสผ่าน)
const db = require('../config/db');

async function findFullById(id) {
    const [rows] = await db.query(
        'SELECT id, first_name, surname, phone, password FROM users WHERE id = ?', [id]);
    return rows[0];
}

// คืน id ของผู้ใช้อื่นที่ใช้เบอร์นี้อยู่ (ไม่รวมตัวเอง) หรือ undefined
async function findOtherIdByPhone(phone, selfId) {
    const [rows] = await db.query('SELECT id FROM users WHERE phone = ? AND id <> ?', [phone, selfId]);
    return rows[0]?.id;
}

async function updateProfile(id, { firstName, surname, phone }) {
    await db.query(
        'UPDATE users SET first_name = ?, surname = ?, phone = ? WHERE id = ?',
        [firstName, surname, phone, id]);
}

async function updatePasswordHash(id, passwordHash) {
    await db.query('UPDATE users SET password = ? WHERE id = ?', [passwordHash, id]);
}

module.exports = { findFullById, findOtherIdByPhone, updateProfile, updatePasswordHash };
