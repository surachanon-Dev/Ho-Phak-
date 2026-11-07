// service ของหอพัก ทั้งฝั่งสาธารณะ (นักศึกษา) และฝั่งเจ้าของ
const dormitoryModel = require('../models/dormitoryModel');
const revisionModel = require('../models/revisionModel');
const amenityModel = require('../models/amenityModel');
const imageModel = require('../models/imageModel');
const reviewModel = require('../models/reviewModel');
const { withTransaction } = require('../utils/transaction');
const { fail } = require('../utils/AppError');
const { ZONES, toInt, parseDormitory } = require('../utils/validators');

const SORTS = {
    price_asc: 'd.price_per_month ASC',
    price_desc: 'd.price_per_month DESC',
    newest: 'd.id DESC',
};

// หอที่นักศึกษาเห็นได้ ถ้าไม่ใช่ตอบ 404
async function getPublicOrFail(rawId) {
    const id = toInt(rawId);
    if (id === null) fail(404, 'ไม่พบหอพัก');
    const dorm = await dormitoryModel.findPublic(id);
    if (!dorm) fail(404, 'ไม่พบหอพัก');
    return dorm;
}

// หอของ owner คนนี้เท่านั้น ถ้าไม่ใช่ตอบ 404 เหมือนไม่มีหอนี้
async function getOwnedOrFail(rawId, ownerId) {
    const id = toInt(rawId);
    if (id === null) fail(404, 'ไม่พบหอพัก');
    const dorm = await dormitoryModel.findOwned(id, ownerId);
    if (!dorm) fail(404, 'ไม่พบหอพัก');
    return dorm;
}

async function checkAmenities(ids) {
    const count = await amenityModel.countExisting(ids);
    if (count !== ids.length) {
        fail(400, 'สิ่งอำนวยความสะดวกบางรายการไม่มีในระบบ');
    }
}

// ---- สาธารณะ ----
async function search({ zone, minPrice, maxPrice, hasRooms, sort, q }) {
    if (zone !== undefined && !ZONES.includes(zone)) fail(400, 'zone ไม่ถูกต้อง');
    const min = minPrice === undefined ? undefined : toInt(minPrice);
    if (minPrice !== undefined && min === null) fail(400, 'minPrice ต้องเป็นตัวเลข');
    const max = maxPrice === undefined ? undefined : toInt(maxPrice);
    if (maxPrice !== undefined && max === null) fail(400, 'maxPrice ต้องเป็นตัวเลข');

    const orderBy = Object.hasOwn(SORTS, sort) ? SORTS[sort] : SORTS.newest;
    const keyword = q ? String(q).trim() : '';
    return dormitoryModel.searchPublic({
        zone,
        minPrice: min,
        maxPrice: max,
        hasRooms: hasRooms === '1',
        q: keyword || undefined,
        orderBy,
    });
}

async function publicDetail(rawId) {
    const dorm = await getPublicOrFail(rawId);
    return {
        ...dorm,
        amenities: await amenityModel.forDormitory(dorm.id),
        images: await imageModel.forDormitory(dorm.id),
        ...(await reviewModel.summary(dorm.id)),
    };
}

async function publicReviews(rawId) {
    const dorm = await getPublicOrFail(rawId);
    return {
        reviews: await reviewModel.listPublishedForDormitory(dorm.id),
        summary: await reviewModel.summary(dorm.id),
    };
}

// ---- เจ้าของ ----
async function listForOwner(ownerId) {
    return dormitoryModel.listByOwner(ownerId);
}

// หอใหม่ต้องให้ admin อนุมัติก่อนแสดงให้นักศึกษาเห็น
async function createForOwner(ownerId, body) {
    const data = parseDormitory(body);
    await checkAmenities(data.amenity_ids);
    return withTransaction(async (conn) => {
        const id = await dormitoryModel.insertDormitory(ownerId, data, conn);
        await amenityModel.replaceForDormitory(id, data.amenity_ids, conn);
        return id;
    });
}

async function detailForOwner(rawId, ownerId) {
    const dorm = await getOwnedOrFail(rawId, ownerId);
    const amenities = await amenityModel.forDormitory(dorm.id);
    const images = await imageModel.forDormitory(dorm.id);
    const latestRevision = await revisionModel.findLatest(dorm.id);
    return {
        dormitory: { ...dorm, amenity_ids: amenities.map((a) => a.id), amenities, images },
        latest_revision: latestRevision || null,
    };
}

// แก้ไขหอ: ยังไม่เคยเผยแพร่ให้แก้ตรงแล้วส่งตรวจใหม่ / เผยแพร่แล้วให้เก็บเป็นฉบับรอตรวจ
async function updateForOwner(rawId, ownerId, body) {
    const dorm = await getOwnedOrFail(rawId, ownerId);
    if (dorm.status === 'suspended') fail(403, 'หอพักถูกระงับ แก้ไขไม่ได้');
    const data = parseDormitory(body);
    await checkAmenities(data.amenity_ids);

    if (dorm.status === 'pending' || dorm.status === 'rejected') {
        await withTransaction(async (conn) => {
            await dormitoryModel.updateFields(dorm.id, data, conn);
            await amenityModel.replaceForDormitory(dorm.id, data.amenity_ids, conn);
            await dormitoryModel.updateStatus(dorm.id, { status: 'pending', rejectionReason: null }, conn);
        });
        return 'ส่งหอพักให้ admin ตรวจอีกครั้งแล้ว';
    }

    const payload = JSON.stringify(data);
    const pending = await revisionModel.findPending(dorm.id);
    if (pending) {
        await revisionModel.updatePayload(pending.id, payload);
    } else {
        await revisionModel.insert(dorm.id, ownerId, payload);
    }
    if (dorm.status === 'published') {
        await dormitoryModel.updateStatus(dorm.id, { status: 'changes_pending' });
    }
    return 'ส่งการแก้ไขให้ admin ตรวจแล้ว นักศึกษายังเห็นฉบับเดิมจนกว่าจะอนุมัติ';
}

// ซ่อน/แสดงหอสำหรับนักศึกษา เฉพาะหอที่เผยแพร่หรือซ่อนอยู่
async function toggleVisibility(rawId, ownerId) {
    const dorm = await getOwnedOrFail(rawId, ownerId);
    if (dorm.status === 'suspended') fail(403, 'หอพักถูกระงับ เปลี่ยนการแสดงผลไม่ได้');
    let next;
    if (dorm.status === 'published') next = 'hidden';
    else if (dorm.status === 'hidden') next = 'published';
    else fail(409, 'หอพักนี้ยังเปลี่ยนการแสดงผลไม่ได้');
    await dormitoryModel.updateStatus(dorm.id, { status: next });
    return next;
}

async function reviewsForOwner(rawId, ownerId) {
    const dorm = await getOwnedOrFail(rawId, ownerId);
    return {
        reviews: await reviewModel.listPublishedForDormitory(dorm.id),
        summary: await reviewModel.summary(dorm.id),
    };
}

module.exports = {
    getPublicOrFail, getOwnedOrFail, search, publicDetail, publicReviews,
    listForOwner, createForOwner, detailForOwner, updateForOwner, toggleVisibility, reviewsForOwner,
};
