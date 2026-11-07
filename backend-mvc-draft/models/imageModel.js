// model ของตาราง dormitory_images
const db = require('../config/db');

async function forDormitory(dormitoryId) {
    const [rows] = await db.query(
        'SELECT id, file_path, sort_order FROM dormitory_images WHERE dormitory_id = ? ORDER BY sort_order, id',
        [dormitoryId]);
    return rows;
}

module.exports = { forDormitory };
