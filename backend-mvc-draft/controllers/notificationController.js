const notificationService = require('../services/notificationService');

async function list(req, res) {
    const notifications = await notificationService.list(req.user.id);
    res.json({ notifications });
}

async function markRead(req, res) {
    await notificationService.markRead(req.params.id, req.user.id);
    res.json({ message: 'อ่านแล้ว' });
}

module.exports = { list, markRead };
