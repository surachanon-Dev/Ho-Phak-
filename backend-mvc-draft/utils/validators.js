// ตรวจค่าที่ส่งมาจาก client ก่อนส่งต่อให้ service
const { fail } = require('./AppError');

const ZONES = ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'];
const BILLING_TYPES = ['per_unit', 'per_person_month', 'per_room_month'];

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
    const noRate = rate === undefined || rate === null;
    const noType = billingType === undefined || billingType === null;
    if (noRate && noType) {
        return { rate: null, billingType: null };
    }
    if (noRate || noType) {
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

module.exports = {
    ZONES, BILLING_TYPES, toInt, normalizePhone, checkPassword, optionalText, parseRate, parseDormitory,
};
