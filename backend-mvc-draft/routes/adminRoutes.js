// เส้นทางของ admin (mount ที่ /api/admin) ทุก route ผ่าน adminOnly
const express = require('express');
const { adminOnly } = require('../middleware/auth');
const adminController = require('../controllers/adminController');

const router = express.Router();

router.use(adminOnly);

router.get('/queue', adminController.queue);
router.get('/logs', adminController.logs);
router.get('/dormitories', adminController.listDormitories);
router.get('/users', adminController.listUsers);

router.post('/dormitories/:id/approve', adminController.approveDormitory);
router.post('/dormitories/:id/reject', adminController.rejectDormitory);
router.post('/dormitories/:id/suspend', adminController.suspendDormitory);
router.post('/dormitories/:id/restore', adminController.restoreDormitory);

router.post('/verifications/:id/approve', adminController.approveVerification);
router.post('/verifications/:id/reject', adminController.rejectVerification);

router.post('/users/:id/suspend', adminController.suspendUser);
router.post('/users/:id/restore', adminController.restoreUser);

router.get('/reviews', adminController.listReviews);
router.post('/reviews/:id/publish', adminController.publishReview);
router.post('/reviews/:id/hide', adminController.hideReview);

module.exports = router;
