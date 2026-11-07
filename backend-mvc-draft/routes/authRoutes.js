const express = require('express');
const { requireAuth } = require('../middleware/auth');
const authController = require('../controllers/authController');

const router = express.Router();

router.post('/login', authController.login);
router.post('/auth/register', authController.register);
router.post('/auth/logout', requireAuth, authController.logout);
router.get('/me', requireAuth, authController.me);

module.exports = router;
