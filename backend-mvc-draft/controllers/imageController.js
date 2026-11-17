const imageService = require('../services/imageService');

// req.dormitory ถูกตั้งโดย requireOwnedDormitory และ req.files โดย multer
async function upload(req, res) {
    const count = await imageService.addImages(req.dormitory.id, req.files);
    res.status(201).json({ message: 'อัปโหลดรูปสำเร็จ', count });
}

async function remove(req, res) {
    await imageService.removeImage(req.params.id, req.params.imageId, req.user.id);
    res.json({ message: 'ลบรูปแล้ว' });
}

module.exports = { upload, remove };
