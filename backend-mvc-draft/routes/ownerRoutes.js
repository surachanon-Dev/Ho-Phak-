// เส้นทางของเจ้าของหอ (mount ที่ /api/owner)
const express = require('express');
const { ownerOnly, requireAuth, requireRole } = require('../middleware/auth');
const dormitoryController = require('../controllers/dormitoryController');
const verificationController = require('../controllers/verificationController');

const router = express.Router();

// หอพัก: ต้องเป็น owner ที่ยืนยันตัวตนแล้ว
router.get('/dormitories', ownerOnly, dormitoryController.listForOwner);
router.post('/dormitories', ownerOnly, dormitoryController.createForOwner);
router.get('/dormitories/:id', ownerOnly, dormitoryController.detailForOwner);
router.put('/dormitories/:id', ownerOnly, dormitoryController.updateForOwner);
router.patch('/dormitories/:id/visibility', ownerOnly, dormitoryController.toggleVisibility);
router.get('/dormitories/:id/reviews', ownerOnly, dormitoryController.reviewsForOwner);

// ยืนยันตัวตน: ยังไม่ต้องยืนยันก่อนจึงไม่ใช้ requireVerifiedOwner
router.get('/verification', [requireAuth, requireRole('owner')], verificationController.getMine);
router.post('/verification', [requireAuth, requireRole('owner')], verificationController.submit);

module.exports = router;
