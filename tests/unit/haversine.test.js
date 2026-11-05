/**
 * Unit Test: the reference distance formula
 * The backend's distance function (P5) should give the same results as this file.
 */
const { haversineKm } = require('../helpers/geo');

test('UNIT-01 the same point is 0 km', () => {
  expect(haversineKm(16.47, 102.82, 16.47, 102.82)).toBe(0);
});

test('UNIT-02 1 degree of latitude is about 111.2 km', () => {
  expect(haversineKm(0, 0, 1, 0)).toBeCloseTo(111.19, 1);
});

test('UNIT-03 Bangkok to Khon Kaen is about 400 km in a straight line', () => {
  const d = haversineKm(13.7563, 100.5018, 16.4419, 102.8360);
  expect(d).toBeGreaterThan(370);
  expect(d).toBeLessThan(400);
});

test('UNIT-04 swapping the start and end points gives the same result', () => {
  const a = haversineKm(16.44, 102.81, 16.47, 102.82);
  const b = haversineKm(16.47, 102.82, 16.44, 102.81);
  expect(a).toBeCloseTo(b, 10);
});
