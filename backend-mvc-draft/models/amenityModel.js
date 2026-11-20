// model ของตาราง amenities และ dormitory_amenities
const db = require('../config/db');

async function forDormitory(dormitoryId) {
    const [rows] = await db.query(
        `SELECT a.id, a.name FROM dormitory_amenities da
         JOIN amenities a ON a.id = da.amenity_id WHERE da.dormitory_id = ? ORDER BY a.id`, [dormitoryId]);
    return rows;
}

async function countExisting(ids) {
    if (ids.length === 0) return 0;
    const [[row]] = await db.query('SELECT COUNT(*) AS n FROM amenities WHERE id IN (?)', [ids]);
    return row.n;
}

// แทนที่รายการสิ่งอำนวยความสะดวกทั้งหมดของหอ
async function replaceForDormitory(dormitoryId, ids, conn = db) {
    await conn.query('DELETE FROM dormitory_amenities WHERE dormitory_id = ?', [dormitoryId]);
    if (ids.length > 0) {
        await conn.query('INSERT INTO dormitory_amenities (dormitory_id, amenity_id) VALUES ?',
            [ids.map((id) => [dormitoryId, id])]);
    }
}

async function listAll() {
    const [rows] = await db.query("SELECT id, name FROM amenities ORDER BY id");
    return rows;
}

async function findById(id) {
    const [rows] = await db.query('SELECT id, name FROM amenities WHERE id = ?', [id]);
    return rows[0];
}

async function insert(name, conn = db) {
    const [result] = await conn.query('INSERT INTO amenities (name) VALUES (?)', [name]);
    return result.insertId;
}

async function rename(id, name, conn = db) {
    const [result] = await conn.query('UPDATE amenities SET name = ? WHERE id = ?', [name, id]);
    return result.affectedRows;
}

async function remove(id, conn = db) {
    const [result] = await conn.query('DELETE FROM amenities WHERE id = ?', [id]);
    return result.affectedRows;
}

// เจ้าของหอที่ใช้สิ่งอำนวยความสะดวกนี้อยู่ (ใช้แจ้งเตือนเมื่อ admin เปลี่ยนหรือลบ)
async function ownerIdsUsing(amenityId, conn = db) {
    const [rows] = await conn.query(
        `SELECT DISTINCT d.owner_id FROM dormitory_amenities da
         JOIN dormitories d ON d.id = da.dormitory_id WHERE da.amenity_id = ?`, [amenityId]);
    return rows.map((r) => r.owner_id);
}

module.exports = {
    forDormitory, countExisting, replaceForDormitory, listAll, findById, insert, rename, remove, ownerIdsUsing,
};
