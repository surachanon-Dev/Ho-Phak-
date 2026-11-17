// service ของฟีเจอร์เจ้าของที่แอปเรียกผ่าน ApiOwnerExtras:
// ค่าน้ำ/ค่าไฟ, ลบหอ, รายการ report รีวิว
const dormitoryModel = require('../models/dormitoryModel');
const reportModel = require('../models/reportModel');
const { fail } = require('../utils/AppError');
const { toInt } = require('../utils/validators');

// ใช้ชื่อเดียวกับ enum UtilityMode ในแอป (UtilityMode.name): setPrice | included | notSpecified
const MODES = ['setPrice', 'included', 'notSpecified'];

async function ownedDormOrFail(rawId, ownerId) {
    const id = toInt(rawId);
    if (id === null) fail(404, 'ไม่พบหอพัก');
    const dorm = await dormitoryModel.findOwned(id, ownerId);
    if (!dorm) fail(404, 'ไม่พบหอพัก');
    return dorm;
}

// มีอัตราจริงในระบบ → set_price เสมอ ไม่มีอัตรา → ใช้โหมดที่เจ้าของเลือกไว้
// เก็บใน DB เป็น set_price / included / not_specified และส่งออกเป็นชื่อ enum ของแอป
function modeOf(rate, storedMode) {
    if (rate !== null && rate !== undefined) return 'setPrice';
    return storedMode === 'included' ? 'included' : 'notSpecified';
}

function toDbMode(appMode) {
    return appMode === 'setPrice' ? 'set_price' : appMode === 'notSpecified' ? 'not_specified' : appMode;
}

async function getUtilities(rawDormId, ownerId) {
    const dorm = await ownedDormOrFail(rawDormId, ownerId);
    return {
        water: modeOf(dorm.water_rate, dorm.water_utility_mode),
        electricity: modeOf(dorm.electricity_rate, dorm.electricity_utility_mode),
    };
}

function checkMode(value, label) {
    if (!MODES.includes(value)) fail(400, `วิธีระบุค่า${label}ไม่ถูกต้อง`);
    return value;
}

// set_price ต้องมีอัตราและหน่วยคิดที่ตั้งไว้ในฟอร์มหอแล้ว (แก้ราคาที่ฟอร์มหอ)
// included / not_specified ล้างอัตราและหน่วยคิดออก
function plan(mode, rate, billing, label) {
    if (mode === 'setPrice') {
        if (rate === null || rate === undefined || !billing) {
            fail(400, `ตั้งราคา${label}ในฟอร์มหอพักก่อน แล้วค่อยเลือก "ตั้งราคา"`);
        }
        return { mode: toDbMode(mode), rate, billing };
    }
    return { mode: toDbMode(mode), rate: null, billing: null };
}

async function updateUtilities(rawDormId, ownerId, body) {
    const dorm = await ownedDormOrFail(rawDormId, ownerId);
    const water = checkMode(body.water, 'น้ำ');
    const electricity = checkMode(body.electricity, 'ไฟ');
    const w = plan(water, dorm.water_rate, dorm.water_billing_type, 'น้ำ');
    const e = plan(electricity, dorm.electricity_rate, dorm.electricity_billing_type, 'ไฟ');

    await dormitoryModel.updateUtilities(dorm.id, {
        waterMode: w.mode, waterRate: w.rate, waterBilling: w.billing,
        electricityMode: e.mode, electricityRate: e.rate, electricityBilling: e.billing,
    });
    return { water, electricity };
}

async function deleteDormitory(rawDormId, ownerId) {
    const dorm = await ownedDormOrFail(rawDormId, ownerId);
    await dormitoryModel.deleteById(dorm.id);
}

async function listReviewReports(ownerId) {
    return reportModel.listByOwner(ownerId);
}

async function reportReview(rawReviewId, ownerId, body) {
    const reviewId = toInt(rawReviewId);
    if (reviewId === null || !(await reportModel.findOwnedReview(reviewId, ownerId))) {
        fail(404, 'ไม่พบรีวิวในหอของคุณ');
    }
    const reason = typeof body.reason === 'string' ? body.reason.trim() : '';
    if (reason.length === 0 || reason.length > 500) fail(400, 'เหตุผลต้องมี 1–500 ตัวอักษร');
    const created = await reportModel.insert(reviewId, ownerId, reason);
    if (!created) fail(409, 'รายงานรีวิวนี้ไปแล้ว');
}

module.exports = { getUtilities, updateUtilities, deleteDormitory, listReviewReports, reportReview };
