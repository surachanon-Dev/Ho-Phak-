const reviewService = require('../services/reviewService');

async function create(req, res) {
    const id = await reviewService.create(req.params.id, req.user.id, req.body);
    res.status(201).json({ message: 'ส่งรีวิวแล้ว รอตรวจสอบก่อนแสดง', id });
}

async function update(req, res) {
    await reviewService.update(req.params.id, req.user.id, req.body);
    res.json({ message: 'แก้ไขรีวิวแล้ว รอตรวจสอบอีกครั้ง' });
}

async function remove(req, res) {
    await reviewService.remove(req.params.id, req.user.id);
    res.json({ message: 'ลบรีวิวแล้ว' });
}

module.exports = { create, update, remove };
