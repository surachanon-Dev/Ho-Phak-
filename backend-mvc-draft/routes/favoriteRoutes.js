// รายการโปรดของนักศึกษา (mount ที่ /api/favorites)
const express = require('express');
const { studentOnly } = require('../middleware/auth');
const favoriteController = require('../controllers/favoriteController');

const router = express.Router();

router.get('/', studentOnly, favoriteController.list);
router.post('/:dormitoryId', studentOnly, favoriteController.add);
router.delete('/:dormitoryId', studentOnly, favoriteController.remove);

module.exports = router;
