// controller ของฟีเจอร์เจ้าของที่แอปเรียกผ่าน ApiOwnerExtras (mount ที่ /api/owner)
const ownerExtrasService = require('../services/ownerExtrasService');

async function getUtilities(req, res) {
    res.json(await ownerExtrasService.getUtilities(req.params.id, req.user.id));
}

async function updateUtilities(req, res) {
    res.json(await ownerExtrasService.updateUtilities(req.params.id, req.user.id, req.body || {}));
}

async function deleteDormitory(req, res) {
    await ownerExtrasService.deleteDormitory(req.params.id, req.user.id);
    res.json({ message: 'ลบหอพักแล้ว' });
}

async function listReviewReports(req, res) {
    res.json({ reports: await ownerExtrasService.listReviewReports(req.user.id) });
}

async function reportReview(req, res) {
    await ownerExtrasService.reportReview(req.params.id, req.user.id, req.body || {});
    res.status(201).json({ message: 'ส่งรายงานรีวิวแล้ว' });
}

module.exports = { getUtilities, updateUtilities, deleteDormitory, listReviewReports, reportReview };
