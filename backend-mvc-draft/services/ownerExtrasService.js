// service ของฟีเจอร์เจ้าของที่แอปเรียกผ่าน ApiOwnerExtras:
// ค่าน้ำ/ค่าไฟ, ลบหอ, รายการ report รีวิว
const fs = require('fs');
const path = require('path');
const dormitoryModel = require('../models/dormitoryModel');
const revisionModel = require('../models/revisionModel');
const imageModel = require('../models/imageModel');
const dormitoryDocumentModel = require('../models/dormitoryDocumentModel');
const reportModel = require('../models/reportModel');
const { ROOT } = require('../config/upload');
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

// ค่าที่เจ้าของเพิ่งกรอกในฟอร์มหอ: หอที่เผยแพร่แล้วเก็บเป็นฉบับรอตรวจ แถวจริงยังไม่มีอัตราใหม่
// จึงใช้อัตราจากฉบับรอตรวจก่อน ถ้าไม่มีฉบับรอตรวจค่อยใช้แถวจริง
async function currentRates(dorm) {
    const pending = await revisionModel.findPending(dorm.id);
    if (pending) {
        try {
            const p = typeof pending.payload === 'string' ? JSON.parse(pending.payload) : pending.payload;
            if (p && typeof p === 'object') {
                return {
                    waterRate: p.water_rate, waterBilling: p.water_billing_type,
                    electricityRate: p.electricity_rate, electricityBilling: p.electricity_billing_type,
                };
            }
        } catch {
            // payload เสีย: ใช้ค่าในแถวจริงแทน
        }
    }
    return {
        waterRate: dorm.water_rate, waterBilling: dorm.water_billing_type,
        electricityRate: dorm.electricity_rate, electricityBilling: dorm.electricity_billing_type,
    };
}

async function updateUtilities(rawDormId, ownerId, body) {
    const dorm = await ownedDormOrFail(rawDormId, ownerId);
    const water = checkMode(body.water, 'น้ำ');
    const electricity = checkMode(body.electricity, 'ไฟ');
    const rates = await currentRates(dorm);
    const w = plan(water, rates.waterRate, rates.waterBilling, 'น้ำ');
    const e = plan(electricity, rates.electricityRate, rates.electricityBilling, 'ไฟ');

    await dormitoryModel.updateUtilities(dorm.id, {
        waterMode: w.mode, waterRate: w.rate, waterBilling: w.billing,
        electricityMode: e.mode, electricityRate: e.rate, electricityBilling: e.billing,
    });
    return { water, electricity };
}

async function deleteDormitory(rawDormId, ownerId) {
    const dorm = await ownedDormOrFail(rawDormId, ownerId);
    // เก็บที่อยู่ไฟล์ไว้ก่อนลบแถว (FK cascade ลบรายการรูป/เอกสารไปด้วย) แล้วค่อยลบไฟล์หลังลบสำเร็จ
    const images = await imageModel.forDormitory(dorm.id);
    const documentPaths = await dormitoryDocumentModel.listPaths(dorm.id);
    await dormitoryModel.deleteById(dorm.id);
    for (const rel of [...images.map((i) => i.file_path), ...documentPaths]) {
        // path ใน DB ขึ้นต้นด้วย /uploads/ หรือ private_uploads/ ตัด / นำหน้าให้ join ภายใต้ ROOT เท่านั้น
        const full = path.resolve(ROOT, String(rel).replace(/^\/+/, ''));
        if (full.startsWith(ROOT + path.sep)) fs.unlink(full, () => {});
    }
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
