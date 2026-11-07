const express = require('express');
const argon2 = require('@node-rs/argon2');
const { requireAuth } = require('../middleware/auth');
const authController = require('../controllers/authController');

const router = express.Router();

router.post('/login', authController.login);
router.post('/auth/register', authController.register);
router.post('/auth/logout', requireAuth, authController.logout);

// TODO: ลบก่อนส่งงาน route นี้ให้ใครก็ hash รหัสผ่านเองได้
router.get('/password/:raw', (req, res) => {
    res.send(argon2.hashSync(req.params.raw));
});

module.exports = router;
