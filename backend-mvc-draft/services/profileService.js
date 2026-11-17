// service ของโปรไฟล์และรหัสผ่านของผู้ใช้ที่ล็อกอินอยู่ (ทุก role)
// หมายเหตุ: ยังไม่รองรับรูปโปรไฟล์ และการเปลี่ยนเบอร์ยังไม่ต้องรอแอดมินอนุมัติ (pending_phone เป็น null เสมอ)
const argon2 = require('@node-rs/argon2');
const profileModel = require('../models/profileModel');
const { fail } = require('../utils/AppError');
const { normalizePhone, checkPassword } = require('../utils/validators');

function toProfile(user) {
    return {
        first_name: user.first_name ?? '',
        surname: user.surname ?? '',
        phone: user.phone,
        pending_phone: null,
        photo: null,
    };
}

function requiredName(value, label) {
    const text = typeof value === 'string' ? value.trim() : '';
    if (text.length === 0 || text.length > 50) {
        fail(400, `${label}ต้องมี 1–50 ตัวอักษร`);
    }
    return text;
}

function verifyPassword(hash, password) {
    if (typeof password !== 'string' || password === '') return false;
    try {
        return argon2.verifySync(hash, password);
    } catch (err) {
        return false;
    }
}

async function getProfile(userId) {
    const user = await profileModel.findFullById(userId);
    if (!user) fail(404, 'ไม่พบผู้ใช้งาน');
    return toProfile(user);
}

// เปลี่ยนเบอร์ต้องยืนยันด้วย password ปัจจุบันก่อน
async function updateProfile(userId, body) {
    const user = await profileModel.findFullById(userId);
    if (!user) fail(404, 'ไม่พบผู้ใช้งาน');

    const firstName = requiredName(body.first_name, 'ชื่อ');
    const surname = requiredName(body.surname, 'นามสกุล');
    const phone = normalizePhone(body.phone);

    if (phone !== user.phone) {
        if (!verifyPassword(user.password, body.password)) {
            fail(403, 'ต้องใส่ password ปัจจุบันให้ถูกต้องเพื่อเปลี่ยนเบอร์');
        }
        if (await profileModel.findOtherIdByPhone(phone, userId)) {
            fail(409, 'เบอร์นี้ถูกใช้แล้ว');
        }
    }

    await profileModel.updateProfile(userId, { firstName, surname, phone });
    return getProfile(userId);
}

async function changePassword(userId, { current_password: current, new_password: next }) {
    const user = await profileModel.findFullById(userId);
    if (!user) fail(404, 'ไม่พบผู้ใช้งาน');
    if (!verifyPassword(user.password, current)) fail(403, 'password ปัจจุบันไม่ถูกต้อง');
    checkPassword(next);
    await profileModel.updatePasswordHash(userId, argon2.hashSync(next));
}

module.exports = { getProfile, updateProfile, changePassword };
