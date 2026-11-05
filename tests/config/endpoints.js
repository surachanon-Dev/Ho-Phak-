/**
 * Every API path lives here.
 * If the Backend team (P3, P5) uses different paths, change only this file.
 * :id is replaced by the real id at runtime.
 */
module.exports = {
  auth: {
    register: 'POST /api/auth/register',
    login: 'POST /api/auth/login',
    logout: 'POST /api/auth/logout',
    me: 'GET /api/auth/me',
  },
  owner: {
    listDorms: 'GET /api/owner/dormitories',
    createDorm: 'POST /api/owner/dormitories',
    updateDorm: 'PUT /api/owner/dormitories/:id',
    deleteDorm: 'DELETE /api/owner/dormitories/:id',
    submitVerification: 'POST /api/owner/verifications',
    myVerification: 'GET /api/owner/verifications',
  },
  student: {
    listDorms: 'GET /api/dormitories', // ?zone=&lat=&lng=&radius=
    dormDetail: 'GET /api/dormitories/:id',
  },
  admin: {
    listVerifications: 'GET /api/admin/verifications', // ?status=pending
    updateVerification: 'PATCH /api/admin/verifications/:id', // body { status }
  },

  // Field names in requests and responses
  fields: {
    // multipart field names for file uploads
    dormImage: 'cover_image',
    verificationDoc: 'document',
    // where to find values in a response (the first path that has a value wins)
    tokenPaths: ['token', 'accessToken', 'data.token'],
    idPaths: ['id', 'insertId', 'data.id', 'dormitory.id', 'verification.id'],
    listPaths: ['', 'data', 'dormitories', 'verifications', 'items'],
    distancePaths: ['distance', 'distance_km'],
  },

  zones: ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'],
};
