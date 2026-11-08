// model ของตาราง dormitory_images
const db = require('../config/db');

async function forDormitory(dormitoryId) {
    const [rows] = await db.query(
        'SELECT id, file_path, sort_order FROM dormitory_images WHERE dormitory_id = ? ORDER BY sort_order, id',
        [dormitoryId]);
    return rows;
}

async function countForDormitory(dormitoryId) {
    const [[row]] = await db.query('SELECT COUNT(*) AS n FROM dormitory_images WHERE dormitory_id = ?', [dormitoryId]);
    return row.n;
}

// rows เป็นอาเรย์ของ [dormitory_id, file_path, sort_order]
async function insertMany(rows, conn = db) {
    await conn.query('INSERT INTO dormitory_images (dormitory_id, file_path, sort_order) VALUES ?', [rows]);
}

// หารูปที่อยู่ในหอของเจ้าของคนนี้เท่านั้น
async function findOwnedImage(imageId, dormitoryId, ownerId) {
    const [rows] = await db.query(
        `SELECT di.id, di.file_path FROM dormitory_images di
         JOIN dormitories d ON d.id = di.dormitory_id
         WHERE di.id = ? AND di.dormitory_id = ? AND d.owner_id = ?`,
        [imageId, dormitoryId, ownerId]);
    return rows[0];
}

async function deleteById(id) {
    await db.query('DELETE FROM dormitory_images WHERE id = ?', [id]);
}

module.exports = { forDormitory, countForDormitory, insertMany, findOwnedImage, deleteById };
