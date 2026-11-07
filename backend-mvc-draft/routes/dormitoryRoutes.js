// หอพักสาธารณะ ไม่ต้อง login
const express = require('express');
const dormitoryController = require('../controllers/dormitoryController');

const router = express.Router();

router.get('/', dormitoryController.search);
router.get('/:id', dormitoryController.detail);
router.get('/:id/reviews', dormitoryController.publicReviews);

module.exports = router;
