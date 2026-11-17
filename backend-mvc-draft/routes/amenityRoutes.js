// สิ่งอำนวยความสะดวกทั้งหมด (mount ที่ /api/amenities) ทุก role ที่ล็อกอินแล้วดูได้
const express = require('express');
const { requireAuth } = require('../middleware/auth');
const amenityService = require('../services/amenityService');

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
    const amenities = await amenityService.list();
    res.json({ amenities });
});

module.exports = router;
