const favoriteService = require('../services/favoriteService');

async function list(req, res) {
    const favorites = await favoriteService.list(req.user.id);
    res.json({ favorites });
}

async function add(req, res) {
    await favoriteService.add(req.user.id, req.params.dormitoryId);
    res.status(201).json({ message: 'เพิ่มในรายการโปรดแล้ว' });
}

async function remove(req, res) {
    await favoriteService.remove(req.user.id, req.params.dormitoryId);
    res.json({ message: 'ลบออกจากรายการโปรดแล้ว' });
}

module.exports = { list, add, remove };
