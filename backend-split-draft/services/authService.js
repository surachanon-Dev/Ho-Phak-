// service เก็บกฎทางธุรกิจของการ login และ register
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const { JWT_KEY } = require('../config/env');
const userModel = require('../models/userModel');
const { AppError } = require('../utils/AppError');

async function login(username, password) {
    if (!username || !password) {
        throw new AppError(400, 'กรุณากรอก username และ password');
    }

    const user = await userModel.findByUsername(username);
    if (!user) {
        throw new AppError(401, 'User not found');
    }

    // ถ้า hash ในฐานข้อมูลอ่านไม่ได้ verifySync จะ throw ต้องดักไว้ไม่ให้ server ล่ม
    let same;
    try {
        same = argon2.verifySync(user.password, password);
    } catch (err) {
        console.error(err);
        throw new AppError(500, 'Password hash error');
    }
    if (!same) {
        throw new AppError(401, 'Password not match');
    }

    const payload = { id: user.id, username: user.username, role: user.role };
    return jwt.sign(payload, JWT_KEY, { expiresIn: '1d' });
}

// สมัครได้เฉพาะ owner และบัญชีใหม่ยังไม่ยืนยันตัวตน
async function register(username, password) {
    if (!username || !password) {
        throw new AppError(400, 'กรอกข้อมูลให้ครบจ้าว');
    }
    if (password.length < 8) {
        throw new AppError(400, 'password ต้องยาวอย่างน้อย 8 ตัว');
    }

    const hash = argon2.hashSync(password);
    try {
        return await userModel.insert({ username, password: hash, role: 'owner', isVerified: 0 });
    } catch (err) {
        if (err.code === 'ER_DUP_ENTRY') {
            throw new AppError(409, 'username นี้ถูกใช้แล้ว');
        }
        throw err;
    }
}

module.exports = { login, register };
