// model ของตาราง reviews
const db = require('../config/db');

async function findOwn(id, userId) {
    const [rows] = await db.query('SELECT * FROM reviews WHERE id = ? AND user_id = ?', [id, userId]);
    return rows[0];
}

// ถ้านักศึกษาเคยรีวิวหอนี้แล้ว จะเกิด ER_DUP_ENTRY ให้ service แปลงเป็น 409
async function insert(dormitoryId, userId, rating, body) {
    const [result] = await db.query(
        "INSERT INTO reviews (dormitory_id, user_id, rating, body, status) VALUES (?, ?, ?, ?, 'published')",
        [dormitoryId, userId, rating, body]);
    return result.insertId;
}

// แก้ไขแล้วแสดงทันทีเหมือนเดิม — คง status เดิมไว้ (รีวิวที่ admin ซ่อนแล้วแก้เองไม่ทำให้กลับมาแสดง)
async function updateOwn(id, rating, body) {
    await db.query('UPDATE reviews SET rating = ?, body = ? WHERE id = ?', [rating, body, id]);
}

async function deleteOwn(id, userId) {
    const [result] = await db.query('DELETE FROM reviews WHERE id = ? AND user_id = ?', [id, userId]);
    return result.affectedRows;
}

// รีวิวทั้งหมดของนักศึกษาคนนี้ (ทุกสถานะ) พร้อมชื่อหอ ใช้ในหน้า "My reviews"
async function listByUser(userId) {
    const [rows] = await db.query(
        `SELECT r.id, r.dormitory_id, d.name AS dormitory_name, r.rating, r.body, r.status,
                r.moderation_reason, r.created_at
         FROM reviews r JOIN dormitories d ON d.id = r.dormitory_id
         WHERE r.user_id = ? ORDER BY r.created_at DESC, r.id DESC`, [userId]);
    return rows;
}

async function listPublishedForDormitory(dormitoryId) {
    const [rows] = await db.query(
        `SELECT id, rating, body, created_at FROM reviews
         WHERE dormitory_id = ? AND status = 'published' ORDER BY created_at DESC`, [dormitoryId]);
    return rows;
}

async function summary(dormitoryId) {
    const [[row]] = await db.query(
        `SELECT COUNT(*) AS review_count, ROUND(AVG(rating), 2) AS rating_avg
         FROM reviews WHERE dormitory_id = ? AND status = 'published'`, [dormitoryId]);
    return row;
}

// รายการให้ admin ตรวจ (เฉพาะรีวิวที่ owner รายงาน — รีวิวใหม่ขึ้นทันทีไม่ต้องรอตรวจ)
//  open   = แสดงอยู่ + มีรายงานที่ยังไม่ตัดสิน
//  kept   = แสดงอยู่ + admin ตัดสินให้คงไว้แล้ว
//  hidden = ถูกซ่อน
async function listByStatus(status) {
    const where = {
        open: "r.status = 'published' AND rr.status = 'open'",
        kept: "r.status = 'published' AND rr.status = 'resolved'",
        hidden: "r.status = 'hidden'",
    }[status];
    const [rows] = await db.query(
        `SELECT r.id, r.dormitory_id, r.user_id, r.rating, r.body, r.status, r.created_at,
                d.name AS dormitory_name,
                COALESCE(NULLIF(TRIM(CONCAT_WS(' ', u.first_name, u.surname)), ''), u.username, 'Anonymous') AS author,
                rr.reason AS report_reason,
                COALESCE(NULLIF(TRIM(CONCAT_WS(' ', rep.first_name, rep.surname)), ''), rep.username) AS reporter_name
         FROM reviews r
         JOIN dormitories d ON d.id = r.dormitory_id
         LEFT JOIN users u ON u.id = r.user_id
         LEFT JOIN review_reports rr ON rr.review_id = r.id
         LEFT JOIN users rep ON rep.id = rr.owner_id
         WHERE ${where}
         ORDER BY r.id DESC`);
    return rows;
}

async function findForUpdate(id, conn = db) {
    const [rows] = await conn.query('SELECT id FROM reviews WHERE id = ? FOR UPDATE', [id]);
    return rows[0];
}

// reason เป็น null เมื่อเผยแพร่ ใส่ข้อความเมื่อซ่อน
async function setModeration(id, { status, reason = null, reviewerId }, conn = db) {
    await conn.query(
        'UPDATE reviews SET status = ?, moderation_reason = ?, moderated_by = ?, moderated_at = NOW() WHERE id = ?',
        [status, reason, reviewerId, id]);
}

module.exports = {
    findOwn, insert, updateOwn, deleteOwn, listByUser, listPublishedForDormitory, summary, listByStatus, findForUpdate, setModeration,
};
