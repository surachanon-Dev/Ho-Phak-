const express = require('express');
const { requireAuth, requireOwner, requireVerifiedOwner } = require('../middleware/auth');
const ownerController = require('../controllers/ownerController');

const router = express.Router();

// ทุก route ของ owner ผ่านด่านเดียวกัน: token → role → การยืนยันตัวตน
const ownerOnly = [requireAuth, requireOwner, requireVerifiedOwner];

router.get('/middleware', ownerOnly, ownerController.checkOwner);
router.post('/dormitories', ownerOnly, ownerController.createDormitory);
router.get('/dormitories', ownerOnly, ownerController.listDormitories);
router.get('/dormitories/:id', ownerOnly, ownerController.getDormitory);
router.put('/dormitories/:id', ownerOnly, ownerController.updateDormitory);
router.delete('/dormitories/:id', ownerOnly, ownerController.deleteDormitory);

module.exports = router;
