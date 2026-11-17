// controller ของข้อมูลส่วนตัวของผู้ใช้ที่ล็อกอินอยู่ (mount ที่ /api/me)
const profileService = require('../services/profileService');
const notificationPrefService = require('../services/notificationPrefService');

async function getProfile(req, res) {
    res.json({ profile: await profileService.getProfile(req.user.id) });
}

async function updateProfile(req, res) {
    res.json({ profile: await profileService.updateProfile(req.user.id, req.body || {}) });
}

async function changePassword(req, res) {
    await profileService.changePassword(req.user.id, req.body || {});
    res.json({ message: 'เปลี่ยนรหัสผ่านแล้ว' });
}

async function getNotificationSettings(req, res) {
    res.json(await notificationPrefService.get(req.user.id));
}

async function updateNotificationSettings(req, res) {
    res.json(await notificationPrefService.update(req.user.id, req.body || {}));
}

module.exports = {
    getProfile, updateProfile, changePassword, getNotificationSettings, updateNotificationSettings,
};
