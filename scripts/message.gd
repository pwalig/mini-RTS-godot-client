class_name Message extends Script

enum Type{
	NAME,
	JOIN,
	GAME_JOINED,
	QUIT,
	INVALID,
	QUEUED,
	YES,
	NO,
	BOARD_STATE
}

const _header_byte_map = {
	Type.NAME: "n",
	Type.JOIN: "j",
	Type.QUIT: "q",
}

const _byte_header_map = {
	"i": Type.INVALID,
	"g": Type.GAME_JOINED,
	"q": Type.QUEUED,
	"y": Type.YES,
	"n": Type.NO,
	"p": Type.BOARD_STATE
}

static func encode(type: Type, value = null) -> PackedByteArray:
	var msg_str: String = _header_byte_map[type]
	if value != null:
		msg_str += " " + value + '\n'
	return msg_str.to_utf8_buffer()

static func decode(data: PackedByteArray) -> Array:
	var msg_str: String = data.get_string_from_utf8()
	
	if msg_str[0] in _byte_header_map:
		var type: Type = _byte_header_map[msg_str[0]]
		if msg_str.length() == 1: # one byte message
			return [type, ""]
		return [type, msg_str.substr(1)]
	
	return [null, msg_str]
