// service ของการสมัครและเข้าสู่ระบบ
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const { JWT_KEY } = require('../config/env');
const userModel = require('../models/userModel');
const { fail } = require('../utils/AppError');
const { normalizePhone, checkPassword, optionalText } = require('../utils/validators');

// role บังคับเป็น student เสมอ ไม่รับจาก client
async function register({ phone, password, confirmPassword, username }) {
    const normalized = normalizePhone(phone);
    checkPassword(password, confirmPassword);

    if (await userModel.findByPhone(normalized)) {
        fail(409, 'เบอร์นี้ถูกใช้แล้ว');
    }
    return userModel.insertStudent({
        username: optionalText(username, 50),
        phone: normalized,
        passwordHash: argon2.hashSync(password),
    });
}

async function login({ phone, password }) {
    const normalized = normalizePhone(phone);
    if (typeof password !== 'string' || password === '') {
        fail(400, 'กรุณากรอก password');
    }

    const user = await userModel.findByPhone(normalized);
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
    return { token, user: { id: user.id, role: user.role, is_verified: user.is_verified } };
}

module.exports = { register, login };
