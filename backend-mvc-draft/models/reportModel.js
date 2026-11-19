// model ของตาราง review_reports (เจ้าของ report รีวิวในหอของตัวเองให้แอดมินตัดสิน)
const db = require('../config/db');

// รีวิวที่อยู่ในหอของเจ้าของคนนี้เท่านั้น
async function findOwnedReview(reviewId, ownerId) {
    const [rows] = await db.query(
        `SELECT r.id FROM reviews r JOIN dormitories d ON d.id = r.dormitory_id
         WHERE r.id = ? AND d.owner_id = ?`, [reviewId, ownerId]);
    return rows[0];
}

async function listByOwner(ownerId) {
    const [rows] = await db.query(
        'SELECT review_id, reason FROM review_reports WHERE owner_id = ? ORDER BY created_at, id', [ownerId]);
    return rows;
}

// คืนค่า false ถ้าเคย report รีวิวนี้แล้ว
async function insert(reviewId, ownerId, reason) {
    try {
        await db.query('INSERT INTO review_reports (review_id, owner_id, reason) VALUES (?, ?, ?)',
            [reviewId, ownerId, reason]);
        return true;
    } catch (err) {
        if (err.code === 'ER_DUP_ENTRY') return false;
        throw err;
    }
}

// admin ตัดสินแล้ว (Keep หรือ Hide) → ปิดรายงานที่ยังเปิดอยู่ของรีวิวนี้
async function resolveForReview(reviewId, conn = db) {
    await conn.query("UPDATE review_reports SET status = 'resolved' WHERE review_id = ? AND status = 'open'", [reviewId]);
}

module.exports = { findOwnedReview, listByOwner, insert, resolveForReview };
