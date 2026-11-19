const dormitoryDocumentService = require('../services/dormitoryDocumentService');

// req.dormitory ถูกตั้งโดย requireOwnedDormitory
async function getMine(req, res) {
    const document = await dormitoryDocumentService.getMetadataForOwner(req.dormitory.id);
    res.json({ document });
}

// req.dormitory ถูกตั้งโดย requireOwnedDormitory และ req.file โดย multer
async function upload(req, res) {
    await dormitoryDocumentService.addForDormitory(req.dormitory.id, req.file);
    res.status(201).json({ message: 'ส่งเอกสารความเป็นเจ้าของหอให้ admin ตรวจแล้ว' });
}

module.exports = { getMine, upload };
