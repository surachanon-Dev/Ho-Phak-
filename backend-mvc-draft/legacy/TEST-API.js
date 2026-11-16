const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');

// อ่าน key จาก .env และหยุดทำงานถ้ายังไม่ได้ตั้งค่า
const JWT_KEY = process.env.JWT_KEY;
if (!JWT_KEY) {
    throw new Error('ยังไม่ได้ตั้งค่า JWT_KEY ใน .env');
}

// pool ใช้ได้ทั้ง query ปกติและ transaction
const db = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'hopak',
    waitForConnections: true,
    connectionLimit: 10,
}).promise();

const app = express();
app.use(cors());
app.use(express.json());

// ================================ ค่าคงที่และ helper ==================================
const ZONES = ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'];
const BILLING_TYPES = ['per_unit', 'per_person_month', 'per_room_month'];
const DORM_COLUMNS = [
    'name', 'zone', 'latitude', 'longitude', 'price_per_month', 'total_rooms', 'available_rooms',
    'water_rate', 'water_billing_type', 'electricity_rate', 'electricity_billing_type',
    'description', 'address', 'contact_phone',
];
const DORM_SET_CLAUSE = DORM_COLUMNS.map((c) => `${c} = ?`).join(', ');

// โยน error พร้อม status code ให้ errorHandler ตอบกลับ
function fail(status, message) {
    throw Object.assign(new Error(message), { status });
}

// แปลงค่าที่ส่งมาเป็นจำนวนเต็ม ถ้าไม่ได้ให้คืน null
function toInt(value) {
    if (value === undefined || value === null || value === '') return null;
    const n = Number(value);
    return Number.isInteger(n) ? n : null;
}

// เบอร์มือถือไทย 10 หลัก เก็บในรูปแบบ 0xxxxxxxxx
function normalizePhone(value) {
    let phone = String(value ?? '').replace(/[\s-]/g, '');
    if (phone.startsWith('+66')) {
        phone = '0' + phone.slice(3);
    }
    if (!/^0\d{9}$/.test(phone)) {
        fail(400, 'เบอร์โทรไม่ถูกต้อง ต้องเป็นเบอร์มือถือ 10 หลัก');
    }
    return phone;
}

function checkPassword(password, confirmPassword) {
    if (typeof password !== 'string' || password.length < 8) {
        fail(400, 'password ต้องยาวอย่างน้อย 8 ตัว');
    }
    if (confirmPassword !== undefined && confirmPassword !== password) {
        fail(400, 'password ยืนยันไม่ตรงกัน');
    }
}

// ข้อความที่เป็นตัวเลือก ถ้าว่างให้เก็บเป็น NULL
function optionalText(value, max) {
    if (value === undefined || value === null) return null;
    const text = String(value).trim();
    if (text.length > max) {
        fail(400, `ข้อความยาวเกิน ${max} ตัวอักษร`);
    }
    return text || null;
}

// ราคาน้ำหรือไฟต้องระบุทั้งจำนวนและหน่วยคิดพร้อมกัน หรือไม่ระบุทั้งคู่
function parseRate(rate, billingType, label) {
    if ((rate === undefined || rate === null) && (billingType === undefined || billingType === null)) {
        return { rate: null, billingType: null };
    }
    if (rate === undefined || rate === null || billingType === undefined || billingType === null) {
        fail(400, `ค่า${label}ต้องระบุทั้งราคาและหน่วยคิดพร้อมกัน`);
    }
    const n = Number(rate);
    if (!Number.isFinite(n) || n < 0 || Number(n.toFixed(2)) !== n) {
        fail(400, `ค่า${label}ต้องไม่ติดลบและมีทศนิยมไม่เกิน 2 ตำแหน่ง`);
    }
    if (!BILLING_TYPES.includes(billingType)) {
        fail(400, `หน่วยคิด${label}ไม่ถูกต้อง`);
    }
    return { rate: n, billingType };
}

// ตรวจข้อมูลหอพักทั้ง POST และ PUT แล้วคืนค่าที่พร้อมบันทึก
function parseDormitory(body) {
    const b = body || {};
    const name = typeof b.name === 'string' ? b.name.trim() : '';
    if (!name || name.length > 100) {
        fail(400, 'ชื่อหอพักต้องมี 1–100 ตัวอักษร');
    }
    if (!ZONES.includes(b.zone)) {
        fail(400, 'zone ไม่ถูกต้อง');
    }
    const latitude = Number(b.latitude);
    const longitude = Number(b.longitude);
    if (b.latitude == null || b.longitude == null || !Number.isFinite(latitude) || !Number.isFinite(longitude)
        || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        fail(400, 'พิกัดไม่ถูกต้อง');
    }
    const price = b.price_per_month;
    if (!Number.isInteger(price) || price < 1 || price > 1000000) {
        fail(400, 'ราคาต่อเดือนต้องเป็นจำนวนเต็ม 1–1,000,000 บาท');
    }
    const total = b.total_rooms;
    const available = b.available_rooms;
    if (!Number.isInteger(total) || total < 0) {
        fail(400, 'จำนวนห้องทั้งหมดต้องเป็นจำนวนเต็มไม่ติดลบ');
    }
    if (!Number.isInteger(available) || available < 0 || available > total) {
        fail(400, 'ห้องว่างต้องไม่ติดลบและไม่เกินห้องทั้งหมด');
    }
    const water = parseRate(b.water_rate, b.water_billing_type, 'น้ำ');
    const electricity = parseRate(b.electricity_rate, b.electricity_billing_type, 'ไฟ');
    const amenityIds = Array.isArray(b.amenity_ids) ? b.amenity_ids.map(toInt) : [];
    if (amenityIds.some((id) => id === null)) {
        fail(400, 'amenity_ids ต้องเป็นตัวเลข');
    }
    return {
        name,
        zone: b.zone,
        latitude,
        longitude,
        price_per_month: price,
        total_rooms: total,
        available_rooms: available,
        water_rate: water.rate,
        water_billing_type: water.billingType,
        electricity_rate: electricity.rate,
        electricity_billing_type: electricity.billingType,
        description: optionalText(b.description, 2000),
        address: optionalText(b.address, 1000),
        contact_phone: b.contact_phone ? normalizePhone(b.contact_phone) : null,
        amenity_ids: [...new Set(amenityIds)],
    };
}

function dormValues(data) {
    return DORM_COLUMNS.map((c) => data[c]);
}

async function checkAmenities(ids) {
    if (ids.length === 0) return;
    const [[row]] = await db.query('SELECT COUNT(*) AS n FROM amenities WHERE id IN (?)', [ids]);
    if (row.n !== ids.length) {
        fail(400, 'สิ่งอำนวยความสะดวกบางรายการไม่มีในระบบ');
    }
}

// รันงานในทรานแซกชันเดียว ถ้าพังจะ rollback ทั้งหมด
async function withTransaction(work) {
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();
        const result = await work(conn);
        await conn.commit();
        return result;
    } catch (err) {
        await conn.rollback();
        throw err;
    } finally {
        conn.release();
    }
}

async function writeAmenities(conn, dormitoryId, ids) {
    await conn.query('DELETE FROM dormitory_amenities WHERE dormitory_id = ?', [dormitoryId]);
    if (ids.length > 0) {
        await conn.query('INSERT INTO dormitory_amenities (dormitory_id, amenity_id) VALUES ?',
            [ids.map((id) => [dormitoryId, id])]);
    }
}

async function applyDormitory(conn, dormitoryId, data) {
    await conn.query(`UPDATE dormitories SET ${DORM_SET_CLAUSE} WHERE id = ?`, [...dormValues(data), dormitoryId]);
    await writeAmenities(conn, dormitoryId, data.amenity_ids);
}

async function loadAmenities(dormitoryId) {
    const [rows] = await db.query(
        `SELECT a.id, a.name FROM dormitory_amenities da
         JOIN amenities a ON a.id = da.amenity_id WHERE da.dormitory_id = ? ORDER BY a.id`, [dormitoryId]);
    return rows;
}

async function loadImages(dormitoryId) {
    const [rows] = await db.query(
        'SELECT id, file_path, sort_order FROM dormitory_images WHERE dormitory_id = ? ORDER BY sort_order, id', [dormitoryId]);
    return rows;
}

// หอของ owner คนนี้เท่านั้น ถ้าไม่ใช่ตอบ 404 เหมือนไม่มีหอนี้
async function findOwnedDormitory(id, ownerId) {
    const dormitoryId = toInt(id);
    if (dormitoryId === null) fail(404, 'ไม่พบหอพัก');
    const [rows] = await db.query('SELECT * FROM dormitories WHERE id = ? AND owner_id = ?', [dormitoryId, ownerId]);
    if (rows.length === 0) fail(404, 'ไม่พบหอพัก');
    return rows[0];
}

// ดึงหอที่นักศึกษาเห็นได้เท่านั้น คือเผยแพร่แล้วและเจ้าของยังใช้งานได้
async function findPublicDormitory(id) {
    const dormitoryId = toInt(id);
    if (dormitoryId === null) fail(404, 'ไม่พบหอพัก');
    const [rows] = await db.query(
        `SELECT d.* FROM dormitories d JOIN users u ON u.id = d.owner_id
         WHERE d.id = ? AND d.status = 'published' AND u.status = 'active'`, [dormitoryId]);
    if (rows.length === 0) fail(404, 'ไม่พบหอพัก');
    return rows[0];
}

async function ratingSummary(dormitoryId) {
    const [[row]] = await db.query(
        `SELECT COUNT(*) AS review_count, ROUND(AVG(rating), 2) AS rating_avg
         FROM reviews WHERE dormitory_id = ? AND status = 'published'`, [dormitoryId]);
    return row;
}

async function logAdmin(conn, admin, action, targetType, targetId, details) {
    await conn.query(
        'INSERT INTO admin_logs (admin_id, admin_name, action, target_type, target_id, details) VALUES (?, ?, ?, ?, ?, ?)',
        [admin.id, admin.username, action, targetType, targetId, details ? JSON.stringify(details) : null]);
}

async function notify(conn, userId, type, title, body, relatedType, relatedId) {
    await conn.query(
        'INSERT INTO notifications (user_id, type, title, body, related_type, related_id) VALUES (?, ?, ?, ?, ?, ?)',
        [userId, type, title, body, relatedType, relatedId]);
}

// ================================ Middleware ==================================
// ด่านที่ 1: ตรวจ token และโหลดสถานะล่าสุดจาก DB ทุกครั้ง
async function requireAuth(req, res, next) {
    const header = req.headers['authorization'];
    if (!header) fail(401, 'ม่ายมี header นะ');
    if (!header.startsWith('Bearer ')) fail(401, 'ต้องขึ้นต้นด้วย Bearer');

    let payload;
    try {
        payload = jwt.verify(header.split(' ')[1], JWT_KEY);
    } catch (err) {
        fail(401, err.name === 'TokenExpiredError' ? 'token หมดอายุแล้ว' : 'token ไม่ถูกต้อง');
    }

    const [rows] = await db.query(
        'SELECT id, username, role, status, is_verified FROM users WHERE id = ?', [payload.id]);
    if (rows.length === 0) fail(401, 'ไม่พบผู้ใช้งาน');
    if (rows[0].status !== 'active') fail(403, 'บัญชีนี้ถูกระงับ');

    req.user = rows[0];
    next();
}

// ด่านที่ 2: ตรวจ role ของผู้ใช้
function requireRole(...roles) {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) fail(403, 'ไม่มีสิทธิ์เข้าถึง');
        next();
    };
}

// ด่านที่ 3: owner ต้องยืนยันตัวตนแล้ว
function requireVerifiedOwner(req, res, next) {
    if (!req.user.is_verified) fail(403, 'ผู้ใช้งานยังไม่ได้ยืนยันตัวตน');
    next();
}

const ownerOnly = [requireAuth, requireRole('owner'), requireVerifiedOwner];
const studentOnly = [requireAuth, requireRole('student')];
const adminOnly = [requireAuth, requireRole('admin')];
const chatOnly = [requireAuth, requireRole('student', 'owner')];

// ================================ Auth ========================================
app.post('/api/auth/register', async (req, res) => {
    const { phone, password, confirmPassword, username } = req.body || {};
    const normalized = normalizePhone(phone);
    checkPassword(password, confirmPassword);

    const [dup] = await db.query('SELECT id FROM users WHERE phone = ?', [normalized]);
    if (dup.length > 0) fail(409, 'เบอร์นี้ถูกใช้แล้ว');

    const hash = argon2.hashSync(password);
    // role บังคับเป็น student เสมอ ไม่รับจาก client
    const [result] = await db.query(
        "INSERT INTO users (username, phone, password, role, is_verified) VALUES (?, ?, ?, 'student', 0)",
        [optionalText(username, 50), normalized, hash]);
    res.status(201).json({ message: 'สมัครสมาชิกสำเร็จ', id: result.insertId });
});

app.post('/api/login', async (req, res) => {
    const { phone, password } = req.body || {};
    const normalized = normalizePhone(phone);
    if (typeof password !== 'string' || password === '') fail(400, 'กรุณากรอก password');

    const [rows] = await db.query('SELECT * FROM users WHERE phone = ?', [normalized]);
    const user = rows[0];
    let valid = false;
    if (user) {
        try {
            valid = argon2.verifySync(user.password, password);
        } catch (err) {
            valid = false;
        }
    }
    // ไม่บอกว่าเบอร์หรือรหัสผ่านไหนผิด เพื่อไม่ให้เดาบัญชีได้
    if (!valid) fail(401, 'เบอร์หรือ password ไม่ถูกต้อง');
    if (user.status !== 'active') fail(403, 'บัญชีนี้ถูกระงับ');

    const token = jwt.sign({ id: user.id }, JWT_KEY, { expiresIn: '1d' });
    res.json({ message: 'Login success', token, user: { id: user.id, role: user.role, is_verified: user.is_verified } });
});

app.post('/api/auth/logout', requireAuth, (req, res) => {
    // token ถูกตรวจแล้ว ฝั่ง client ต้องลบ token เอง
    res.json({ message: 'ออกจากระบบสำเร็จ' });
});

app.get('/api/me', requireAuth, (req, res) => {
    res.json({ user: req.user });
});

// ================================ Owner: หอพัก ================================
app.get('/api/owner/dormitories', ownerOnly, async (req, res) => {
    const [rows] = await db.query('SELECT * FROM dormitories WHERE owner_id = ? ORDER BY id DESC', [req.user.id]);
    res.json({ dormitories: rows });
});

// หอใหม่ต้องให้ admin อนุมัติก่อนแสดงให้นักศึกษาเห็น
app.post('/api/owner/dormitories', ownerOnly, async (req, res) => {
    const data = parseDormitory(req.body);
    await checkAmenities(data.amenity_ids);

    const id = await withTransaction(async (conn) => {
        const [result] = await conn.query(
            `INSERT INTO dormitories (owner_id, ${DORM_COLUMNS.join(', ')}, status)
             VALUES (?, ${DORM_COLUMNS.map(() => '?').join(', ')}, 'pending')`,
            [req.user.id, ...dormValues(data)]);
        await writeAmenities(conn, result.insertId, data.amenity_ids);
        return result.insertId;
    });
    res.status(201).json({ message: 'ส่งหอพักให้ admin ตรวจแล้ว', id });
});

app.get('/api/owner/dormitories/:id', ownerOnly, async (req, res) => {
    const dorm = await findOwnedDormitory(req.params.id, req.user.id);
    const amenities = await loadAmenities(dorm.id);
    const images = await loadImages(dorm.id);
    const [revisions] = await db.query(
        `SELECT id, payload, status, rejection_reason, submitted_at FROM dormitory_revisions
         WHERE dormitory_id = ? ORDER BY id DESC LIMIT 1`, [dorm.id]);
    res.json({
        dormitory: { ...dorm, amenity_ids: amenities.map((a) => a.id), amenities, images },
        latest_revision: revisions[0] || null,
    });
});

// แก้ไขหอ: ยังไม่เคยเผยแพร่ให้แก้ตรงแล้วส่งตรวจใหม่ / เผยแพร่แล้วให้เก็บเป็นฉบับรอตรวจ
app.put('/api/owner/dormitories/:id', ownerOnly, async (req, res) => {
    const dorm = await findOwnedDormitory(req.params.id, req.user.id);
    if (dorm.status === 'suspended') fail(403, 'หอพักถูกระงับ แก้ไขไม่ได้');
    const data = parseDormitory(req.body);
    await checkAmenities(data.amenity_ids);

    if (dorm.status === 'pending' || dorm.status === 'rejected') {
        await withTransaction(async (conn) => {
            await applyDormitory(conn, dorm.id, data);
            await conn.query("UPDATE dormitories SET status = 'pending', rejection_reason = NULL WHERE id = ?", [dorm.id]);
        });
        return res.json({ message: 'ส่งหอพักให้ admin ตรวจอีกครั้งแล้ว' });
    }

    const payload = JSON.stringify(data);
    const [pending] = await db.query(
        "SELECT id FROM dormitory_revisions WHERE dormitory_id = ? AND status = 'pending'", [dorm.id]);
    if (pending.length > 0) {
        await db.query('UPDATE dormitory_revisions SET payload = ?, submitted_at = NOW() WHERE id = ?', [payload, pending[0].id]);
    } else {
        await db.query('INSERT INTO dormitory_revisions (dormitory_id, owner_id, payload) VALUES (?, ?, ?)',
            [dorm.id, req.user.id, payload]);
    }
    if (dorm.status === 'published') {
        await db.query("UPDATE dormitories SET status = 'changes_pending' WHERE id = ?", [dorm.id]);
    }
    res.json({ message: 'ส่งการแก้ไขให้ admin ตรวจแล้ว นักศึกษายังเห็นฉบับเดิมจนกว่าจะอนุมัติ' });
});

// ซ่อน/แสดงหอสำหรับนักศึกษา เฉพาะหอที่เผยแพร่หรือซ่อนอยู่
app.patch('/api/owner/dormitories/:id/visibility', ownerOnly, async (req, res) => {
    const dorm = await findOwnedDormitory(req.params.id, req.user.id);
    if (dorm.status === 'suspended') fail(403, 'หอพักถูกระงับ เปลี่ยนการแสดงผลไม่ได้');
    let next;
    if (dorm.status === 'published') next = 'hidden';
    else if (dorm.status === 'hidden') next = 'published';
    else fail(409, 'หอพักนี้ยังเปลี่ยนการแสดงผลไม่ได้');
    await db.query('UPDATE dormitories SET status = ? WHERE id = ?', [next, dorm.id]);
    res.json({ message: 'เปลี่ยนการแสดงผลแล้ว', status: next });
});

// เจ้าของดูรีวิวได้อย่างเดียว ตอบกลับไม่ได้
app.get('/api/owner/dormitories/:id/reviews', ownerOnly, async (req, res) => {
    const dorm = await findOwnedDormitory(req.params.id, req.user.id);
    const [reviews] = await db.query(
        `SELECT id, rating, body, created_at FROM reviews
         WHERE dormitory_id = ? AND status = 'published' ORDER BY created_at DESC`, [dorm.id]);
    res.json({ reviews, summary: await ratingSummary(dorm.id) });
});

// ================================ Owner: ยืนยันตัวตน ============================
app.get('/api/owner/verification', [requireAuth, requireRole('owner')], async (req, res) => {
    const [rows] = await db.query('SELECT * FROM verifications WHERE owner_id = ?', [req.user.id]);
    res.json({ verification: rows[0] || null });
});

// อัปโหลดไฟล์จริงยังไม่รองรับ ตอนนี้รับ URL ของเอกสารก่อน
app.post('/api/owner/verification', [requireAuth, requireRole('owner')], async (req, res) => {
    const documentUrl = optionalText(req.body?.document_url, 255);
    if (!documentUrl) fail(400, 'กรุณาระบุ document_url');

    const [rows] = await db.query('SELECT * FROM verifications WHERE owner_id = ?', [req.user.id]);
    const current = rows[0];
    if (current && current.status === 'pending') fail(409, 'มีคำขอที่รอตรวจอยู่แล้ว');
    if (current && current.status === 'approved') fail(409, 'ยืนยันตัวตนแล้ว');

    await withTransaction(async (conn) => {
        if (current) {
            await conn.query(
                `UPDATE verifications SET document_url = ?, status = 'pending', submitted_at = NOW(),
                 reviewed_at = NULL, reviewed_by = NULL, rejection_reason = NULL WHERE id = ?`,
                [documentUrl, current.id]);
        } else {
            await conn.query(
                "INSERT INTO verifications (owner_id, document_url, status, submitted_at) VALUES (?, ?, 'pending', NOW())",
                [req.user.id, documentUrl]);
        }
        await conn.query('UPDATE users SET is_verified = 0 WHERE id = ?', [req.user.id]);
    });
    res.status(201).json({ message: 'ส่งเอกสารให้ admin ตรวจแล้ว' });
});

// ================================ หอพักสาธารณะ (นักศึกษา) ======================
app.get('/api/dormitories', async (req, res) => {
    const { zone, minPrice, maxPrice, hasRooms, sort, q } = req.query;
    let sql = `SELECT d.id, d.name, d.zone, d.latitude, d.longitude, d.price_per_month,
                      d.total_rooms, d.available_rooms, d.water_rate, d.water_billing_type,
                      d.electricity_rate, d.electricity_billing_type,
                      (SELECT ROUND(AVG(r.rating), 2) FROM reviews r WHERE r.dormitory_id = d.id AND r.status = 'published') AS rating_avg,
                      (SELECT COUNT(*) FROM reviews r WHERE r.dormitory_id = d.id AND r.status = 'published') AS review_count
               FROM dormitories d JOIN users u ON u.id = d.owner_id
               WHERE d.status = 'published' AND u.status = 'active'`;
    const params = [];
    if (zone !== undefined) {
        if (!ZONES.includes(zone)) fail(400, 'zone ไม่ถูกต้อง');
        sql += ' AND d.zone = ?';
        params.push(zone);
    }
    if (minPrice !== undefined) {
        const v = toInt(minPrice);
        if (v === null) fail(400, 'minPrice ต้องเป็นตัวเลข');
        sql += ' AND d.price_per_month >= ?';
        params.push(v);
    }
    if (maxPrice !== undefined) {
        const v = toInt(maxPrice);
        if (v === null) fail(400, 'maxPrice ต้องเป็นตัวเลข');
        sql += ' AND d.price_per_month <= ?';
        params.push(v);
    }
    if (hasRooms === '1') sql += ' AND d.available_rooms > 0';
    if (q) {
        sql += ' AND d.name LIKE ?';
        params.push(`%${String(q).trim()}%`);
    }
    const sorts = { price_asc: 'd.price_per_month ASC', price_desc: 'd.price_per_month DESC', newest: 'd.id DESC' };
    const orderBy = Object.hasOwn(sorts, sort) ? sorts[sort] : sorts.newest;
    const [rows] = await db.query(`${sql} ORDER BY ${orderBy}`, params);
    res.json({ dormitories: rows });
});

app.get('/api/dormitories/:id', async (req, res) => {
    const dorm = await findPublicDormitory(req.params.id);
    res.json({
        dormitory: {
            ...dorm,
            amenities: await loadAmenities(dorm.id),
            images: await loadImages(dorm.id),
            ...(await ratingSummary(dorm.id)),
        },
    });
});

app.get('/api/dormitories/:id/reviews', async (req, res) => {
    const dorm = await findPublicDormitory(req.params.id);
    const [reviews] = await db.query(
        `SELECT id, rating, body, created_at FROM reviews
         WHERE dormitory_id = ? AND status = 'published' ORDER BY created_at DESC`, [dorm.id]);
    res.json({ reviews, summary: await ratingSummary(dorm.id) });
});

// ================================ รีวิว (นักศึกษา) ============================
app.post('/api/dormitories/:id/reviews', studentOnly, async (req, res) => {
    const dorm = await findPublicDormitory(req.params.id);
    const rating = toInt(req.body?.rating);
    if (rating === null || rating < 1 || rating > 5) fail(400, 'คะแนนต้องเป็นจำนวนเต็ม 1–5');
    const body = optionalText(req.body?.body, 1000);
    try {
        const [result] = await db.query(
            "INSERT INTO reviews (dormitory_id, user_id, rating, body, status) VALUES (?, ?, ?, ?, 'pending')",
            [dorm.id, req.user.id, rating, body]);
        res.status(201).json({ message: 'ส่งรีวิวแล้ว รอตรวจสอบก่อนแสดง', id: result.insertId });
    } catch (err) {
        if (err.code === 'ER_DUP_ENTRY') fail(409, 'คุณรีวิวหอนี้แล้ว แก้ไขรีวิวเดิมแทนได้');
        throw err;
    }
});

app.put('/api/reviews/:id', studentOnly, async (req, res) => {
    const reviewId = toInt(req.params.id);
    const [rows] = reviewId === null ? [[]] : await db.query(
        'SELECT * FROM reviews WHERE id = ? AND user_id = ?', [reviewId, req.user.id]);
    if (rows.length === 0) fail(404, 'ไม่พบรีวิว');
    const rating = toInt(req.body?.rating);
    if (rating === null || rating < 1 || rating > 5) fail(400, 'คะแนนต้องเป็นจำนวนเต็ม 1–5');
    const body = optionalText(req.body?.body, 1000);
    // แก้ไขแล้วต้องรอตรวจใหม่
    await db.query(
        `UPDATE reviews SET rating = ?, body = ?, status = 'pending', moderation_reason = NULL,
         moderated_by = NULL, moderated_at = NULL WHERE id = ?`, [rating, body, reviewId]);
    res.json({ message: 'แก้ไขรีวิวแล้ว รอตรวจสอบอีกครั้ง' });
});

app.delete('/api/reviews/:id', studentOnly, async (req, res) => {
    const reviewId = toInt(req.params.id);
    const [result] = reviewId === null ? [{ affectedRows: 0 }] : await db.query(
        'DELETE FROM reviews WHERE id = ? AND user_id = ?', [reviewId, req.user.id]);
    if (result.affectedRows === 0) fail(404, 'ไม่พบรีวิว');
    res.json({ message: 'ลบรีวิวแล้ว' });
});

// ================================ รายการโปรด (นักศึกษา) ========================
app.get('/api/favorites', studentOnly, async (req, res) => {
    // ส่งทุกสถานะกลับไป ให้หน้าแอปแสดง "Unavailable" กับหอที่ถูกซ่อนหรือระงับ
    const [rows] = await db.query(
        `SELECT d.id, d.name, d.zone, d.price_per_month, d.status, f.created_at AS saved_at
         FROM favorites f JOIN dormitories d ON d.id = f.dormitory_id
         WHERE f.user_id = ? ORDER BY f.created_at DESC`, [req.user.id]);
    res.json({ favorites: rows });
});

app.post('/api/favorites/:dormitoryId', studentOnly, async (req, res) => {
    const dorm = await findPublicDormitory(req.params.dormitoryId);
    await db.query('INSERT IGNORE INTO favorites (user_id, dormitory_id) VALUES (?, ?)', [req.user.id, dorm.id]);
    res.status(201).json({ message: 'เพิ่มในรายการโปรดแล้ว' });
});

app.delete('/api/favorites/:dormitoryId', studentOnly, async (req, res) => {
    const dormitoryId = toInt(req.params.dormitoryId);
    if (dormitoryId === null) fail(404, 'ไม่พบรายการโปรด');
    const [result] = await db.query('DELETE FROM favorites WHERE user_id = ? AND dormitory_id = ?', [req.user.id, dormitoryId]);
    if (result.affectedRows === 0) fail(404, 'ไม่พบรายการโปรด');
    res.json({ message: 'ลบออกจากรายการโปรดแล้ว' });
});

// ================================ แชท (นักศึกษาและเจ้าของ) ======================
// ดึงการสนทนาและตรวจว่าผู้ใช้เป็นคู่สนทนาเท่านั้น
async function loadConversation(id, user) {
    const conversationId = toInt(id);
    if (conversationId === null) fail(404, 'ไม่พบการสนทนา');
    const [rows] = await db.query(
        `SELECT c.*, d.status AS dormitory_status FROM conversations c
         LEFT JOIN dormitories d ON d.id = c.dormitory_id WHERE c.id = ?`, [conversationId]);
    const conversation = rows[0];
    if (!conversation || (conversation.tenant_id !== user.id && conversation.owner_id !== user.id)) {
        fail(404, 'ไม่พบการสนทนา');
    }
    return conversation;
}

app.post('/api/conversations', studentOnly, async (req, res) => {
    const dorm = await findPublicDormitory(req.body?.dormitory_id);
    const [existing] = await db.query(
        'SELECT id FROM conversations WHERE dormitory_id = ? AND tenant_id = ? AND owner_id = ?',
        [dorm.id, req.user.id, dorm.owner_id]);
    if (existing.length > 0) {
        // เปิดแชทเดิมอีกครั้งให้กลับมาแสดงในรายการของนักศึกษา
        await db.query('UPDATE conversations SET deleted_by_tenant_at = NULL WHERE id = ?', [existing[0].id]);
        return res.json({ id: existing[0].id, message: 'เปิดแชทเดิมแล้ว' });
    }
    // เจ้าของดึงจากฐานข้อมูล ไม่รับจาก client
    const [result] = await db.query(
        'INSERT INTO conversations (tenant_id, owner_id, dormitory_id) VALUES (?, ?, ?)',
        [req.user.id, dorm.owner_id, dorm.id]);
    res.status(201).json({ id: result.insertId, message: 'เปิดแชทแล้ว' });
});

app.get('/api/conversations', chatOnly, async (req, res) => {
    const isOwner = req.user.role === 'owner';
    // ชื่อคอลัมน์มาจากค่าคงที่ในโค้ดเท่านั้น ไม่รับจาก client
    const side = isOwner ? 'owner_id' : 'tenant_id';
    const deletedAt = isOwner ? 'deleted_by_owner_at' : 'deleted_by_tenant_at';
    const [rows] = await db.query(
        `SELECT c.id, c.dormitory_id, c.tenant_id, c.owner_id, d.name AS dormitory_name, d.status AS dormitory_status,
                (SELECT body FROM messages m WHERE m.conversation_id = c.id ORDER BY m.id DESC LIMIT 1) AS last_message,
                (SELECT MAX(sent_at) FROM messages m WHERE m.conversation_id = c.id) AS last_sent_at,
                (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id AND m.sender_id <> ? AND m.read_at IS NULL) AS unread_count
         FROM conversations c LEFT JOIN dormitories d ON d.id = c.dormitory_id
         WHERE c.${side} = ?
           AND (c.${deletedAt} IS NULL
                OR (SELECT MAX(sent_at) FROM messages m WHERE m.conversation_id = c.id) > c.${deletedAt})
         ORDER BY last_sent_at DESC`,
        [req.user.id, req.user.id]);
    res.json({ conversations: rows });
});

app.get('/api/conversations/:id/messages', chatOnly, async (req, res) => {
    const conversation = await loadConversation(req.params.id, req.user);
    const [messages] = await db.query(
        'SELECT id, sender_id, body, sent_at, read_at FROM messages WHERE conversation_id = ? ORDER BY id ASC',
        [conversation.id]);
    // ทำเครื่องหมายว่าอ่านแล้วเฉพาะข้อความของอีกฝ่าย
    await db.query(
        'UPDATE messages SET read_at = NOW() WHERE conversation_id = ? AND sender_id <> ? AND read_at IS NULL',
        [conversation.id, req.user.id]);
    const readOnly = conversation.dormitory_id === null || conversation.dormitory_status === 'suspended';
    res.json({ messages, read_only: readOnly });
});

app.post('/api/conversations/:id/messages', chatOnly, async (req, res) => {
    const conversation = await loadConversation(req.params.id, req.user);
    if (conversation.dormitory_id === null) fail(403, 'หอพักนี้ถูกลบแล้ว ส่งข้อความไม่ได้');
    if (conversation.dormitory_status === 'suspended') fail(403, 'หอพักถูกระงับ ส่งข้อความไม่ได้');
    const body = typeof req.body?.body === 'string' ? req.body.body.trim() : '';
    if (!body || body.length > 2000) fail(400, 'ข้อความต้องมี 1–2000 ตัวอักษร');
    const [result] = await db.query(
        'INSERT INTO messages (conversation_id, sender_id, body) VALUES (?, ?, ?)',
        [conversation.id, req.user.id, body]);
    res.status(201).json({ id: result.insertId });
});

// ลบแชทจากรายการของตัวเองเท่านั้น อีกฝ่ายยังเห็นอยู่
app.delete('/api/conversations/:id', chatOnly, async (req, res) => {
    const conversation = await loadConversation(req.params.id, req.user);
    const column = conversation.tenant_id === req.user.id ? 'deleted_by_tenant_at' : 'deleted_by_owner_at';
    await db.query(`UPDATE conversations SET ${column} = NOW() WHERE id = ?`, [conversation.id]);
    res.json({ message: 'ลบแชทจากรายการของคุณแล้ว' });
});

// ================================ การแจ้งเตือน ================================
app.get('/api/notifications', requireAuth, async (req, res) => {
    const [rows] = await db.query(
        `SELECT id, type, title, body, related_type, related_id, read_at, created_at
         FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 50`, [req.user.id]);
    res.json({ notifications: rows });
});

app.patch('/api/notifications/:id/read', requireAuth, async (req, res) => {
    const notificationId = toInt(req.params.id);
    const [rows] = notificationId === null ? [[]] : await db.query(
        'SELECT id FROM notifications WHERE id = ? AND user_id = ?', [notificationId, req.user.id]);
    if (rows.length === 0) fail(404, 'ไม่พบการแจ้งเตือน');
    await db.query('UPDATE notifications SET read_at = COALESCE(read_at, NOW()) WHERE id = ?', [notificationId]);
    res.json({ message: 'อ่านแล้ว' });
});

// ================================ Admin ======================================
// คิวรอตรวจทั้งหมด: หอใหม่, ฉบับแก้ไข และเอกสารยืนยันตัวตน
app.get('/api/admin/queue', adminOnly, async (req, res) => {
    const [dormitories] = await db.query(
        `SELECT d.id, d.name, d.zone, d.owner_id, u.username AS owner_username, d.created_at
         FROM dormitories d JOIN users u ON u.id = d.owner_id
         WHERE d.status = 'pending' ORDER BY d.id`);
    const [revisions] = await db.query(
        `SELECT r.id, r.dormitory_id, r.submitted_at, d.name AS dormitory_name, r.payload
         FROM dormitory_revisions r JOIN dormitories d ON d.id = r.dormitory_id
         WHERE r.status = 'pending' ORDER BY r.id`);
    const [verifications] = await db.query(
        `SELECT v.id, v.owner_id, v.document_url, v.submitted_at, u.phone AS owner_phone
         FROM verifications v JOIN users u ON u.id = v.owner_id WHERE v.status = 'pending' ORDER BY v.id`);
    res.json({ new_dormitories: dormitories, revisions, verifications });
});

app.post('/api/admin/dormitories/:id/approve', adminOnly, async (req, res) => {
    const dormitoryId = toInt(req.params.id);
    if (dormitoryId === null) fail(404, 'ไม่พบหอพัก');
    await withTransaction(async (conn) => {
        const [[dorm]] = await conn.query('SELECT * FROM dormitories WHERE id = ? FOR UPDATE', [dormitoryId]);
        if (!dorm) fail(404, 'ไม่พบหอพัก');

        if (dorm.status === 'pending') {
            await conn.query(
                `UPDATE dormitories SET status = 'published', rejection_reason = NULL,
                 status_changed_by = ?, status_changed_at = NOW() WHERE id = ?`, [req.user.id, dorm.id]);
        } else {
            const [[revision]] = await conn.query(
                "SELECT * FROM dormitory_revisions WHERE dormitory_id = ? AND status = 'pending' ORDER BY id DESC LIMIT 1 FOR UPDATE",
                [dorm.id]);
            if (!revision) fail(409, 'หอพักนี้ไม่มีรายการรอตรวจ');
            await applyDormitory(conn, dorm.id, JSON.parse(revision.payload));
            // หอที่เผยแพร่อยู่แล้วกลับไปเผยแพร่ ส่วนหอที่ซ่อนอยู่คงสถานะซ่อนไว้
            const nextStatus = dorm.status === 'changes_pending' ? 'published' : dorm.status;
            await conn.query('UPDATE dormitories SET status = ? WHERE id = ?', [nextStatus, dorm.id]);
            await conn.query(
                "UPDATE dormitory_revisions SET status = 'approved', reviewed_at = NOW(), reviewed_by = ? WHERE id = ?",
                [req.user.id, revision.id]);
        }
        await logAdmin(conn, req.user, 'dormitory.approve', 'dormitory', dorm.id, { from: dorm.status });
        await notify(conn, dorm.owner_id, 'dormitory_approved', 'หอพักได้รับการอนุมัติ', dorm.name, 'dormitory', dorm.id);
    });
    res.json({ message: 'อนุมัติหอพักแล้ว' });
});

app.post('/api/admin/dormitories/:id/reject', adminOnly, async (req, res) => {
    const dormitoryId = toInt(req.params.id);
    if (dormitoryId === null) fail(404, 'ไม่พบหอพัก');
    const reason = optionalText(req.body?.reason, 1000);
    if (!reason) fail(400, 'ต้องระบุเหตุผลการปฏิเสธ');
    await withTransaction(async (conn) => {
        const [[dorm]] = await conn.query('SELECT * FROM dormitories WHERE id = ? FOR UPDATE', [dormitoryId]);
        if (!dorm) fail(404, 'ไม่พบหอพัก');

        if (dorm.status === 'pending') {
            await conn.query(
                "UPDATE dormitories SET status = 'rejected', rejection_reason = ?, status_changed_by = ?, status_changed_at = NOW() WHERE id = ?",
                [reason, req.user.id, dorm.id]);
        } else {
            const [[revision]] = await conn.query(
                "SELECT id FROM dormitory_revisions WHERE dormitory_id = ? AND status = 'pending' ORDER BY id DESC LIMIT 1 FOR UPDATE",
                [dorm.id]);
            if (!revision) fail(409, 'หอพักนี้ไม่มีรายการรอตรวจ');
            await conn.query(
                "UPDATE dormitory_revisions SET status = 'rejected', rejection_reason = ?, reviewed_at = NOW(), reviewed_by = ? WHERE id = ?",
                [reason, req.user.id, revision.id]);
            if (dorm.status === 'changes_pending') {
                await conn.query("UPDATE dormitories SET status = 'published' WHERE id = ?", [dorm.id]);
            }
        }
        await logAdmin(conn, req.user, 'dormitory.reject', 'dormitory', dorm.id, { reason });
        await notify(conn, dorm.owner_id, 'dormitory_rejected', 'หอพักไม่ผ่านการตรวจ', reason, 'dormitory', dorm.id);
    });
    res.json({ message: 'ปฏิเสธรายการแล้ว' });
});

app.post('/api/admin/dormitories/:id/suspend', adminOnly, async (req, res) => {
    const dormitoryId = toInt(req.params.id);
    if (dormitoryId === null) fail(404, 'ไม่พบหอพัก');
    const reason = optionalText(req.body?.reason, 1000);
    if (!reason) fail(400, 'ต้องระบุเหตุผลการระงับ');
    await withTransaction(async (conn) => {
        const [[dorm]] = await conn.query('SELECT * FROM dormitories WHERE id = ? FOR UPDATE', [dormitoryId]);
        if (!dorm) fail(404, 'ไม่พบหอพัก');
        await conn.query(
            "UPDATE dormitories SET status = 'suspended', status_reason = ?, status_changed_by = ?, status_changed_at = NOW() WHERE id = ?",
            [reason, req.user.id, dorm.id]);
        await logAdmin(conn, req.user, 'dormitory.suspend', 'dormitory', dorm.id, { reason });
        await notify(conn, dorm.owner_id, 'dormitory_suspended', 'หอพักถูกระงับ', reason, 'dormitory', dorm.id);
    });
    res.json({ message: 'ระงับหอพักแล้ว' });
});

app.post('/api/admin/dormitories/:id/restore', adminOnly, async (req, res) => {
    const dormitoryId = toInt(req.params.id);
    if (dormitoryId === null) fail(404, 'ไม่พบหอพัก');
    await withTransaction(async (conn) => {
        const [[dorm]] = await conn.query('SELECT * FROM dormitories WHERE id = ? FOR UPDATE', [dormitoryId]);
        if (!dorm) fail(404, 'ไม่พบหอพัก');
        if (dorm.status !== 'suspended') fail(409, 'หอพักนี้ไม่ได้ถูกระงับ');
        await conn.query(
            "UPDATE dormitories SET status = 'published', status_reason = NULL, status_changed_by = ?, status_changed_at = NOW() WHERE id = ?",
            [req.user.id, dorm.id]);
        await logAdmin(conn, req.user, 'dormitory.restore', 'dormitory', dorm.id, null);
        await notify(conn, dorm.owner_id, 'dormitory_restored', 'หอพักกลับมาแสดงแล้ว', dorm.name, 'dormitory', dorm.id);
    });
    res.json({ message: 'คืนสถานะหอพักแล้ว' });
});

// ตรวจเอกสารยืนยันตัวตน: อนุมัติแล้วตั้ง is_verified = 1 ในทรานแซกชันเดียวกัน
app.post('/api/admin/verifications/:id/approve', adminOnly, async (req, res) => {
    const verificationId = toInt(req.params.id);
    if (verificationId === null) fail(404, 'ไม่พบคำขอ');
    await withTransaction(async (conn) => {
        const [[verification]] = await conn.query('SELECT * FROM verifications WHERE id = ? FOR UPDATE', [verificationId]);
        if (!verification) fail(404, 'ไม่พบคำขอ');
        if (verification.status !== 'pending') fail(409, 'คำขอนี้ตรวจไปแล้ว');
        await conn.query(
            "UPDATE verifications SET status = 'approved', reviewed_at = NOW(), reviewed_by = ?, rejection_reason = NULL WHERE id = ?",
            [req.user.id, verification.id]);
        await conn.query('UPDATE users SET is_verified = 1 WHERE id = ?', [verification.owner_id]);
        await logAdmin(conn, req.user, 'verification.approve', 'verification', verification.id, { owner_id: verification.owner_id });
        await notify(conn, verification.owner_id, 'verification_approved', 'ยืนยันตัวตนสำเร็จ', 'คุณสามารถเพิ่มหอพักได้แล้ว', 'verification', verification.id);
    });
    res.json({ message: 'อนุมัติการยืนยันตัวตนแล้ว' });
});

app.post('/api/admin/verifications/:id/reject', adminOnly, async (req, res) => {
    const verificationId = toInt(req.params.id);
    if (verificationId === null) fail(404, 'ไม่พบคำขอ');
    const reason = optionalText(req.body?.reason, 1000);
    if (!reason) fail(400, 'ต้องระบุเหตุผลการปฏิเสธ');
    await withTransaction(async (conn) => {
        const [[verification]] = await conn.query('SELECT * FROM verifications WHERE id = ? FOR UPDATE', [verificationId]);
        if (!verification) fail(404, 'ไม่พบคำขอ');
        if (verification.status !== 'pending') fail(409, 'คำขอนี้ตรวจไปแล้ว');
        await conn.query(
            "UPDATE verifications SET status = 'rejected', reviewed_at = NOW(), reviewed_by = ?, rejection_reason = ? WHERE id = ?",
            [req.user.id, reason, verification.id]);
        await conn.query('UPDATE users SET is_verified = 0 WHERE id = ?', [verification.owner_id]);
        await logAdmin(conn, req.user, 'verification.reject', 'verification', verification.id, { reason });
        await notify(conn, verification.owner_id, 'verification_rejected', 'ยืนยันตัวตนไม่ผ่าน', reason, 'verification', verification.id);
    });
    res.json({ message: 'ปฏิเสธคำขอแล้ว' });
});

// ระงับบัญชีผู้ใช้ (ไม่ระงับบัญชี admin)
app.post('/api/admin/users/:id/suspend', adminOnly, async (req, res) => {
    const userId = toInt(req.params.id);
    if (userId === null) fail(404, 'ไม่พบผู้ใช้งาน');
    const reason = optionalText(req.body?.reason, 1000);
    if (!reason) fail(400, 'ต้องระบุเหตุผลการระงับ');
    await withTransaction(async (conn) => {
        const [[target]] = await conn.query('SELECT id, role FROM users WHERE id = ? FOR UPDATE', [userId]);
        if (!target) fail(404, 'ไม่พบผู้ใช้งาน');
        if (target.role === 'admin') fail(403, 'ระงับบัญชี admin ไม่ได้');
        await conn.query(
            "UPDATE users SET status = 'suspended', suspension_reason = ?, suspended_at = NOW(), suspended_by = ? WHERE id = ?",
            [reason, req.user.id, target.id]);
        await logAdmin(conn, req.user, 'user.suspend', 'user', target.id, { reason });
    });
    res.json({ message: 'ระงับบัญชีแล้ว' });
});

app.post('/api/admin/users/:id/restore', adminOnly, async (req, res) => {
    const userId = toInt(req.params.id);
    if (userId === null) fail(404, 'ไม่พบผู้ใช้งาน');
    await withTransaction(async (conn) => {
        const [[target]] = await conn.query('SELECT id, status FROM users WHERE id = ? FOR UPDATE', [userId]);
        if (!target) fail(404, 'ไม่พบผู้ใช้งาน');
        if (target.status !== 'suspended') fail(409, 'บัญชีนี้ไม่ได้ถูกระงับ');
        await conn.query(
            "UPDATE users SET status = 'active', suspension_reason = NULL, suspended_at = NULL, suspended_by = NULL WHERE id = ?",
            [target.id]);
        await logAdmin(conn, req.user, 'user.restore', 'user', target.id, null);
    });
    res.json({ message: 'คืนสถานะบัญชีแล้ว' });
});

// ตรวจรีวิว: รีวิวใหม่ต้องถูกเผยแพร่ก่อนแสดง
app.get('/api/admin/reviews', adminOnly, async (req, res) => {
    const status = ['pending', 'published', 'hidden'].includes(req.query.status) ? req.query.status : 'pending';
    const [rows] = await db.query(
        `SELECT r.id, r.dormitory_id, r.user_id, r.rating, r.body, r.status, r.created_at, d.name AS dormitory_name
         FROM reviews r JOIN dormitories d ON d.id = r.dormitory_id WHERE r.status = ? ORDER BY r.id`, [status]);
    res.json({ reviews: rows });
});

app.post('/api/admin/reviews/:id/publish', adminOnly, async (req, res) => {
    const reviewId = toInt(req.params.id);
    if (reviewId === null) fail(404, 'ไม่พบรีวิว');
    await withTransaction(async (conn) => {
        const [[review]] = await conn.query('SELECT id FROM reviews WHERE id = ? FOR UPDATE', [reviewId]);
        if (!review) fail(404, 'ไม่พบรีวิว');
        await conn.query(
            "UPDATE reviews SET status = 'published', moderation_reason = NULL, moderated_by = ?, moderated_at = NOW() WHERE id = ?",
            [req.user.id, reviewId]);
        await logAdmin(conn, req.user, 'review.publish', 'review', reviewId, null);
    });
    res.json({ message: 'เผยแพร่รีวิวแล้ว' });
});

app.post('/api/admin/reviews/:id/hide', adminOnly, async (req, res) => {
    const reviewId = toInt(req.params.id);
    if (reviewId === null) fail(404, 'ไม่พบรีวิว');
    const reason = optionalText(req.body?.reason, 1000);
    if (!reason) fail(400, 'ต้องระบุเหตุผลการซ่อนรีวิว');
    await withTransaction(async (conn) => {
        const [[review]] = await conn.query('SELECT id FROM reviews WHERE id = ? FOR UPDATE', [reviewId]);
        if (!review) fail(404, 'ไม่พบรีวิว');
        await conn.query(
            "UPDATE reviews SET status = 'hidden', moderation_reason = ?, moderated_by = ?, moderated_at = NOW() WHERE id = ?",
            [reason, req.user.id, reviewId]);
        await logAdmin(conn, req.user, 'review.hide', 'review', reviewId, { reason });
    });
    res.json({ message: 'ซ่อนรีวิวแล้ว' });
});

app.get('/api/admin/logs', adminOnly, async (req, res) => {
    const [rows] = await db.query('SELECT * FROM admin_logs ORDER BY id DESC LIMIT 100');
    res.json({ logs: rows });
});

// ================================ Error handler ===============================
// ไม่พบ route
app.use((req, res) => {
    res.status(404).json({ message: 'ไม่พบ API นี้' });
});

// จุดเดียวที่แปลง error เป็น response
app.use((err, req, res, next) => {
    if (err.type === 'entity.parse.failed') {
        return res.status(400).json({ message: 'รูปแบบ JSON ไม่ถูกต้อง' });
    }
    if (err.status) {
        return res.status(err.status).json({ message: err.message });
    }
    if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ message: 'ข้อมูลซ้ำกับที่มีอยู่แล้ว' });
    }
    console.error(err);
    res.status(500).json({ message: 'DB error' });
});

app.listen(3000, () => {
    console.log('server running at http://localhost:3000');
});
