// controller ของหอพัก ทั้งฝั่งสาธารณะและฝั่งเจ้าของ
const dormitoryService = require('../services/dormitoryService');

// ---- สาธารณะ ----
async function search(req, res) {
    const dormitories = await dormitoryService.search(req.query);
    res.json({ dormitories });
}

async function detail(req, res) {
    const dormitory = await dormitoryService.publicDetail(req.params.id);
    res.json({ dormitory });
}

async function publicReviews(req, res) {
    res.json(await dormitoryService.publicReviews(req.params.id));
}

// ---- เจ้าของ ----
async function listForOwner(req, res) {
    const dormitories = await dormitoryService.listForOwner(req.user.id);
    res.json({ dormitories });
}

async function createForOwner(req, res) {
    const id = await dormitoryService.createForOwner(req.user.id, req.body);
    res.status(201).json({ message: 'ส่งหอพักให้ admin ตรวจแล้ว', id });
}

async function detailForOwner(req, res) {
    res.json(await dormitoryService.detailForOwner(req.params.id, req.user.id));
}

async function updateForOwner(req, res) {
    const message = await dormitoryService.updateForOwner(req.params.id, req.user.id, req.body);
    res.json({ message });
}

async function toggleVisibility(req, res) {
    const status = await dormitoryService.toggleVisibility(req.params.id, req.user.id);
    res.json({ message: 'เปลี่ยนการแสดงผลแล้ว', status });
}

async function reviewsForOwner(req, res) {
    res.json(await dormitoryService.reviewsForOwner(req.params.id, req.user.id));
}

module.exports = {
    search, detail, publicReviews,
    listForOwner, createForOwner, detailForOwner, updateForOwner, toggleVisibility, reviewsForOwner,
};
