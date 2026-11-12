num? asNum(dynamic v) => v == null ? null : (v is num ? v : num.tryParse(v.toString()));
int asInt(dynamic v, [int fallback = 0]) => asNum(v)?.toInt() ?? fallback;
double asDouble(dynamic v, [double fallback = 0]) => asNum(v)?.toDouble() ?? fallback;
DateTime? asDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
String asStr(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;
