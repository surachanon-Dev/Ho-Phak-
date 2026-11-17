// service ของสิ่งอำนวยความสะดวก (ใช้ตอนเจ้าของเลือก amenities ให้หอ)
const amenityModel = require('../models/amenityModel');

async function list() {
    return amenityModel.listAll();
}

module.exports = { list };
