// model ของตาราง dormitory_documents
const db = require('../config/db');

async function insert(dormitoryId, documentUrl, originalName) {
    const [result] = await db.query(
        'INSERT INTO dormitory_documents (dormitory_id, document_url, original_name) VALUES (?, ?, ?)',
        [dormitoryId, documentUrl, originalName]);
    return result.insertId;
}

// เอกสารล่าสุดของหอ (เจ้าของส่งใหม่ได้ ฉบับล่าสุดเป็นฉบับที่ admin เห็น)
async function latestForDormitory(dormitoryId) {
    const [rows] = await db.query(
        'SELECT id, dormitory_id, document_url, original_name, uploaded_at FROM dormitory_documents WHERE dormitory_id = ? ORDER BY id DESC LIMIT 1',
        [dormitoryId]);
    return rows[0];
}

// ที่เก็บไฟล์เอกสารทุกฉบับของหอ ใช้ลบไฟล์เมื่อหอถูกลบ
async function listPaths(dormitoryId) {
    const [rows] = await db.query('SELECT document_url FROM dormitory_documents WHERE dormitory_id = ?', [dormitoryId]);
    return rows.map((r) => r.document_url);
}

module.exports = { insert, latestForDormitory, listPaths };
