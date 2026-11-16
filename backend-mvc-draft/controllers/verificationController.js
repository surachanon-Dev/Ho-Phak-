const verificationService = require('../services/verificationService');

async function getMine(req, res) {
    const verification = await verificationService.getMine(req.user.id);
    res.json({ verification });
}

async function submit(req, res) {
    await verificationService.submit(req.user.id, req.file);
    res.status(201).json({ message: 'ส่งเอกสารให้ admin ตรวจแล้ว' });
}

module.exports = { getMine, submit };
