// ข้อมูลส่วนตัวของผู้ใช้ที่ล็อกอิน (mount ที่ /api/me) ทุก role ใช้ได้
const express = require('express');
const { requireAuth } = require('../middleware/auth');
const meController = require('../controllers/meController');

const router = express.Router();

router.get('/profile', requireAuth, meController.getProfile);
router.put('/profile', requireAuth, meController.updateProfile);
router.put('/password', requireAuth, meController.changePassword);
router.post('/become-owner', requireAuth, meController.becomeOwner);
router.get('/notification-settings', requireAuth, meController.getNotificationSettings);
router.put('/notification-settings', requireAuth, meController.updateNotificationSettings);

module.exports = router;
