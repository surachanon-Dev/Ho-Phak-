// สร้าง (หรือรีเซ็ต) บัญชีทดสอบ 3 role ในฐานข้อมูลที่ backend ใช้อยู่
// ใช้ค่าเชื่อมต่อ DB เดียวกับ backend (config/db.js + .env)
//
// รัน (ในโฟลเดอร์ backend-mvc-draft):
//   node --env-file=.env scripts/seed-test-users.js
//
// รันซ้ำได้: ถ้ามีเบอร์นี้อยู่แล้วจะรีเซ็ตรหัสผ่าน role และสถานะให้ตามรายการด้านล่าง
// ใช้เบอร์ 08990000xx เพื่อไม่ไปทับบัญชีทดสอบที่เพื่อนสร้างไว้ (0800000001, 08x1111111 ฯลฯ)
const argon2 = require('@node-rs/argon2');
const db = require('../config/db');

const PASSWORD = 'Test@1234';

const ACCOUNTS = [
    { role: 'student', phone: '0899000001', username: 'qa_student', first: 'ทดสอบ', last: 'นักศึกษา', verified: 0 },
    { role: 'owner',   phone: '0899000002', username: 'qa_owner',     first: 'ทดสอบ', last: 'เจ้าของหอ', verified: 1 },
    { role: 'admin',   phone: '0899000003', username: 'qa_admin',     first: 'ทดสอบ', last: 'แอดมิน',   verified: 1 },
];

async function upsert(a, hash) {
    const [rows] = await db.query('SELECT id FROM users WHERE phone = ?', [a.phone]);
    if (rows.length > 0) {
        await db.query(
            `UPDATE users SET username = ?, first_name = ?, surname = ?, password = ?, role = ?, is_verified = ?,
                    status = 'active', suspension_reason = NULL, suspended_at = NULL, suspended_by = NULL
             WHERE id = ?`,
            [a.username, a.first, a.last, hash, a.role, a.verified, rows[0].id]);
        return { id: rows[0].id, action: 'รีเซ็ต' };
    }
    const [result] = await db.query(
        `INSERT INTO users (username, first_name, surname, phone, password, role, is_verified)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [a.username, a.first, a.last, a.phone, hash, a.role, a.verified]);
    return { id: result.insertId, action: 'สร้างใหม่' };
}

(async () => {
    const hash = argon2.hashSync(PASSWORD);
    for (const a of ACCOUNTS) {
        const { id, action } = await upsert(a, hash);
        console.log(`${action}: ${a.role.padEnd(7)} id=${id}  เบอร์ ${a.phone}  ชื่อผู้ใช้ ${a.username}`);
    }
    console.log(`\nรหัสผ่านทุกบัญชี: ${PASSWORD}`);
    await db.end();
})().catch(async (err) => {
    console.error('สร้างบัญชีไม่สำเร็จ:', err.message);
    try { await db.end(); } catch (_) { /* ignore */ }
    process.exit(1);
});
