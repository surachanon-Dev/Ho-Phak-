// รีวิวของนักศึกษา (mount ที่ /api)
const express = require('express');
const { studentOnly } = require('../middleware/auth');
const reviewController = require('../controllers/reviewController');

const router = express.Router();

router.get('/reviews/me', studentOnly, reviewController.listMine);
router.post('/dormitories/:id/reviews', studentOnly, reviewController.create);
router.put('/reviews/:id', studentOnly, reviewController.update);
router.delete('/reviews/:id', studentOnly, reviewController.remove);

module.exports = router;
