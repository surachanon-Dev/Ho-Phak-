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

module.exports = { forDormitory, countExisting, replaceForDormitory };
