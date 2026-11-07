// แชทระหว่างนักศึกษากับเจ้าของหอ (mount ที่ /api/conversations)
const express = require('express');
const { studentOnly, chatOnly } = require('../middleware/auth');
const chatController = require('../controllers/chatController');

const router = express.Router();

router.post('/', studentOnly, chatController.open);
router.get('/', chatOnly, chatController.list);
router.get('/:id/messages', chatOnly, chatController.messages);
router.post('/:id/messages', chatOnly, chatController.send);
router.delete('/:id', chatOnly, chatController.remove);

module.exports = router;
