const chatService = require('../services/chatService');

async function open(req, res) {
    const { id, created } = await chatService.open(req.user.id, req.body?.dormitory_id);
    if (created) {
        return res.status(201).json({ id, message: 'เปิดแชทแล้ว' });
    }
    res.json({ id, message: 'เปิดแชทเดิมแล้ว' });
}

async function list(req, res) {
    const conversations = await chatService.list(req.user);
    res.json({ conversations });
}

async function messages(req, res) {
    res.json(await chatService.messages(req.params.id, req.user));
}

async function send(req, res) {
    const id = await chatService.send(req.params.id, req.user, req.body);
    res.status(201).json({ id });
}

async function remove(req, res) {
    await chatService.remove(req.params.id, req.user);
    res.json({ message: 'ลบแชทจากรายการของคุณแล้ว' });
}

module.exports = { open, list, messages, send, remove };
