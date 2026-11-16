// model ทำหน้าที่คุยกับตาราง dormitories เท่านั้น
// ทุกคำสั่งที่ดึงหรือแก้ไขข้อมูลของเจ้าของต้องมี owner_id เป็นเงื่อนไข
const db = require('../config/db');

// คอลัมน์ของหอที่ owner แก้ไขได้ (ชื่อคอลัมน์มาจากค่าคงที่นี้เท่านั้น)
const DORM_COLUMNS = [
    'name', 'zone', 'latitude', 'longitude', 'price_per_month', 'total_rooms', 'available_rooms',
    'water_rate', 'water_billing_type', 'electricity_rate', 'electricity_billing_type',
    'description', 'address', 'contact_phone',
];
const DORM_SET_CLAUSE = DORM_COLUMNS.map((c) => `${c} = ?`).join(', ');

function dormValues(data) {
    return DORM_COLUMNS.map((c) => data[c]);
}

async function insertDormitory(ownerId, data, conn = db) {
    const [result] = await conn.query(
        `INSERT INTO dormitories (owner_id, ${DORM_COLUMNS.join(', ')}, status)
         VALUES (?, ${DORM_COLUMNS.map(() => '?').join(', ')}, 'pending')`,
        [ownerId, ...dormValues(data)]);
    return result.insertId;
}

async function updateFields(id, data, conn = db) {
    await conn.query(`UPDATE dormitories SET ${DORM_SET_CLAUSE} WHERE id = ?`, [...dormValues(data), id]);
}

// เปลี่ยนสถานะและฟิลด์ที่เกี่ยวข้องกับสถานะ เฉพาะ key ที่ส่งมาเท่านั้นที่จะถูกแก้
async function updateStatus(id, { status, rejectionReason, statusReason, changedBy }, conn = db) {
    const sets = ['status = ?'];
    const params = [status];
    if (rejectionReason !== undefined) {
        sets.push('rejection_reason = ?');
        params.push(rejectionReason);
    }
    if (statusReason !== undefined) {
        sets.push('status_reason = ?');
        params.push(statusReason);
    }
    if (changedBy !== undefined) {
        sets.push('status_changed_by = ?', 'status_changed_at = NOW()');
        params.push(changedBy);
    }
    params.push(id);
    await conn.query(`UPDATE dormitories SET ${sets.join(', ')} WHERE id = ?`, params);
}

async function findForUpdate(id, conn = db) {
    const [rows] = await conn.query('SELECT * FROM dormitories WHERE id = ? FOR UPDATE', [id]);
    return rows[0];
}

async function listByOwner(ownerId) {
    const [rows] = await db.query('SELECT * FROM dormitories WHERE owner_id = ? ORDER BY id DESC', [ownerId]);
    return rows;
}

async function findOwned(id, ownerId) {
    const [rows] = await db.query('SELECT * FROM dormitories WHERE id = ? AND owner_id = ?', [id, ownerId]);
    return rows[0];
}

// หอที่นักศึกษาเห็นได้ คือเผยแพร่แล้วและเจ้าของยังใช้งานได้
async function findPublic(id) {
    const [rows] = await db.query(
        `SELECT d.* FROM dormitories d JOIN users u ON u.id = d.owner_id
         WHERE d.id = ? AND d.status = 'published' AND u.status = 'active'`, [id]);
    return rows[0];
}

// ค้นหาหอที่เผยแพร่แล้ว orderBy ต้องมาจากค่าที่ service กำหนดเท่านั้น
async function searchPublic({ zone, minPrice, maxPrice, hasRooms, q, orderBy }) {
    let sql = `SELECT d.id, d.name, d.zone, d.latitude, d.longitude, d.price_per_month,
                      d.total_rooms, d.available_rooms, d.water_rate, d.water_billing_type,
                      d.electricity_rate, d.electricity_billing_type,
                      (SELECT ROUND(AVG(r.rating), 2) FROM reviews r WHERE r.dormitory_id = d.id AND r.status = 'published') AS rating_avg,
                      (SELECT COUNT(*) FROM reviews r WHERE r.dormitory_id = d.id AND r.status = 'published') AS review_count
               FROM dormitories d JOIN users u ON u.id = d.owner_id
               WHERE d.status = 'published' AND u.status = 'active'`;
    const params = [];
    if (zone !== undefined) {
        sql += ' AND d.zone = ?';
        params.push(zone);
    }
    if (minPrice !== undefined) {
        sql += ' AND d.price_per_month >= ?';
        params.push(minPrice);
    }
    if (maxPrice !== undefined) {
        sql += ' AND d.price_per_month <= ?';
        params.push(maxPrice);
    }
    if (hasRooms) sql += ' AND d.available_rooms > 0';
    if (q) {
        sql += ' AND d.name LIKE ?';
        params.push(`%${q}%`);
    }
    const [rows] = await db.query(`${sql} ORDER BY ${orderBy}`, params);
    return rows;
}

async function listPendingNew() {
    const [rows] = await db.query(
        `SELECT d.id, d.name, d.zone, d.owner_id, u.username AS owner_username, d.created_at
         FROM dormitories d JOIN users u ON u.id = d.owner_id
         WHERE d.status = 'pending' ORDER BY d.id`);
    return rows;
}

// รายการหอทั้งหมดสำหรับ admin กรองด้วยสถานะได้ (status เป็นค่าที่ service ตรวจแล้ว หรือ undefined)
async function listForAdmin(status) {
    const where = status === undefined ? '' : 'WHERE d.status = ?';
    const params = status === undefined ? [] : [status];
    const [rows] = await db.query(
        `SELECT d.id, d.name, d.zone, d.status, d.owner_id, u.username AS owner_username, d.created_at
         FROM dormitories d JOIN users u ON u.id = d.owner_id
         ${where} ORDER BY d.id DESC`, params);
    return rows;
}

module.exports = {
    DORM_COLUMNS, insertDormitory, updateFields, updateStatus, findForUpdate,
    listByOwner, findOwned, findPublic, searchPublic, listPendingNew, listForAdmin,
};
