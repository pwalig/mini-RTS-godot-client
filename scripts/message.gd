class_name Message extends Script

enum Type{
	NAME,
	JOIN,
	QUIT,
	MOVE,
	ATTACK,
	DIG, # as 'm' is used by MOVE
	CONFIGURATION,
	LEFT,
	UNIT,
	FIELD_RESOURCE,
	TICK,
	QUEUED,
	YES,
	NO,
	LOST,
	WON,
	PLAYERS_STATE,
	RESOURCES_STATE
}

const _header_byte_map = {
	Type.NAME: "n",
	Type.JOIN: "j",
	Type.QUIT: "q",
	Type.MOVE: "m",
	Type.ATTACK: "a",
	Type.DIG: "d",
}

const _byte_header_map = {
	"c": Type.CONFIGURATION,
	"j": Type.JOIN,
	"l": Type.LEFT,
	"m": Type.MOVE,
	"a": Type.ATTACK,
	"d": Type.DIG,
	"u": Type.UNIT,
	"f": Type.FIELD_RESOURCE,
	"t": Type.TICK,
	"q": Type.QUEUED,
	"y": Type.YES,
	"n": Type.NO,
	"L": Type.LOST,
	"W": Type.WON,
	"p": Type.PLAYERS_STATE,
	"r": Type.RESOURCES_STATE,
}

static func encode(type: Type) -> PackedByteArray:
	var msg_str: String = _header_byte_map[type] + CONFIG.end_msg
	return msg_str.to_utf8_buffer()

static func encode_params(type: Type, params: Array) -> PackedByteArray:
	var msg_str: String = _header_byte_map[type]
	msg_str += CONFIG.end_param.join(params) + CONFIG.end_msg
	return msg_str.to_utf8_buffer()

static func encode_str(type: Type, val: String) -> PackedByteArray:
	var msg_str: String = _header_byte_map[type] + val + CONFIG.end_msg
	return msg_str.to_utf8_buffer()

static func decode(msg_str: String) -> Array:	
	if msg_str[0] in _byte_header_map:
		var type: Type = _byte_header_map[msg_str[0]]
		if msg_str.length() == 1: # one byte message
			return [type, ""]
		return [type, msg_str.substr(1)]
	
	return [null, msg_str]
