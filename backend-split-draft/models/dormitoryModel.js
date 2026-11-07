// model ทำหน้าที่เดียวคือคุยกับตาราง dormitories
// ทุกคำสั่งที่แก้หรือดึงข้อมูลต้องมี owner_id เป็นเงื่อนไขเสมอ
const db = require('../config/db').promise();

async function insert(ownerId, data) {
    const sql = 'INSERT INTO dormitories (owner_id, name, zone, latitude, longitude, price_per_month) VALUES (?, ?, ?, ?, ?, ?)';
    const { name, zone, latitude, longitude, price_per_month } = data;
    const [result] = await db.query(sql, [ownerId, name, zone, latitude, longitude, price_per_month]);
    return result.insertId;
}

async function findByOwner(ownerId) {
    const [rows] = await db.query('SELECT * FROM dormitories WHERE owner_id = ?', [ownerId]);
    return rows;
}

async function findOneByOwner(id, ownerId) {
    const [rows] = await db.query('SELECT * FROM dormitories WHERE id = ? AND owner_id = ?', [id, ownerId]);
    return rows[0];
}

// คืนจำนวนแถวที่ถูกแก้ ถ้า 0 แปลว่าไม่ใช่หอของ owner คนนี้หรือไม่มีหอนี้
async function update(id, ownerId, data) {
    const sql = 'UPDATE dormitories SET name = ?, zone = ?, latitude = ?, longitude = ?, price_per_month = ? WHERE id = ? AND owner_id = ?';
    const { name, zone, latitude, longitude, price_per_month } = data;
    const [result] = await db.query(sql, [name, zone, latitude, longitude, price_per_month, id, ownerId]);
    return result.affectedRows;
}

async function remove(id, ownerId) {
    const [result] = await db.query('DELETE FROM dormitories WHERE id = ? AND owner_id = ?', [id, ownerId]);
    return result.affectedRows;
}

module.exports = { insert, findByOwner, findOneByOwner, update, remove };
