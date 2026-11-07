// controller รับ request แล้วส่งต่อให้ service และตอบ response
const authService = require('../services/authService');

async function login(req, res) {
    const { username, password } = req.body || {};
    const token = await authService.login(username, password);
    res.json({ message: 'Login success', token });
}

async function register(req, res) {
    const { username, password } = req.body || {};
    const id = await authService.register(username, password);
    res.status(201).json({ message: 'สมัครสมาชิกสำเร็จ', id });
}

// token ถูกตรวจแล้วโดย requireAuth ฝั่ง client ต้องลบ token เอง
function logout(req, res) {
    res.status(200).json({ message: 'ออกจากระบบสำเร็จ' });
}

module.exports = { login, register, logout };
