const authService = require('../services/authService');

async function register(req, res) {
    const id = await authService.register(req.body || {});
    res.status(201).json({ message: 'สมัครสมาชิกสำเร็จ', id });
}

async function login(req, res) {
    const { token, user } = await authService.login(req.body || {});
    res.json({ message: 'Login success', token, user });
}

// token ถูกตรวจแล้วโดย requireAuth ฝั่ง client ต้องลบ token เอง
function logout(req, res) {
    res.json({ message: 'ออกจากระบบสำเร็จ' });
}

function me(req, res) {
    res.json({ user: req.user });
}

module.exports = { register, login, logout, me };
