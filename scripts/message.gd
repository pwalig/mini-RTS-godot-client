class_name Message extends Script

enum Type{
	NAME,
	JOIN,
	QUIT,
	INVALID,
	ACCEPTED,
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
	"a": Type.ACCEPTED,
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
	var splitted: PackedStringArray = msg_str.split('\n', false)
	
	if splitted[0] in _byte_header_map:
		var type: Type = _byte_header_map[splitted[0]]
		if splitted.is_empty(): # one byte message
			return [type]
		return [type, splitted.slice(1)]
	
	return [null, splitted]
