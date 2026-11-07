// model ของตาราง reviews
const db = require('../config/db');

async function findOwn(id, userId) {
    const [rows] = await db.query('SELECT * FROM reviews WHERE id = ? AND user_id = ?', [id, userId]);
    return rows[0];
}

// ถ้านักศึกษาเคยรีวิวหอนี้แล้ว จะเกิด ER_DUP_ENTRY ให้ service แปลงเป็น 409
async function insert(dormitoryId, userId, rating, body) {
    const [result] = await db.query(
        "INSERT INTO reviews (dormitory_id, user_id, rating, body, status) VALUES (?, ?, ?, ?, 'pending')",
        [dormitoryId, userId, rating, body]);
    return result.insertId;
}

// แก้ไขแล้วต้องรอตรวจใหม่และล้างข้อมูลการตรวจเดิม
async function updateOwn(id, rating, body) {
    await db.query(
        `UPDATE reviews SET rating = ?, body = ?, status = 'pending', moderation_reason = NULL,
         moderated_by = NULL, moderated_at = NULL WHERE id = ?`, [rating, body, id]);
}

async function deleteOwn(id, userId) {
    const [result] = await db.query('DELETE FROM reviews WHERE id = ? AND user_id = ?', [id, userId]);
    return result.affectedRows;
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

async function listByStatus(status) {
    const [rows] = await db.query(
        `SELECT r.id, r.dormitory_id, r.user_id, r.rating, r.body, r.status, r.created_at, d.name AS dormitory_name
         FROM reviews r JOIN dormitories d ON d.id = r.dormitory_id WHERE r.status = ? ORDER BY r.id`, [status]);
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
    findOwn, insert, updateOwn, deleteOwn, listPublishedForDormitory, summary, listByStatus, findForUpdate, setModeration,
};
