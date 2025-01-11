class_name CONFIG
extends Script

# client specific config
const tilesize: Vector2 = Vector2(256,256)
const LOD_tresh: float = 0.2
const anim_duration: float = 0.2

# copied server default config
static var millis: int = 3000
static var maxPlayers: int = 2
static var boardXY: Vector2i = Vector2i(256,256)
static var unitsToWin: int = 50
static var startResources: int = 25
static var resourceHp: int = 100
static var unitHp: int = 100
static var unitDamage: int = 10
static var allowedNameCharacters: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_"
# why not regex :(

# network config
const end_msg: String = "\n"
const end_section: String = ";"
const end_subsection: String = ","
const end_param: String = " "

static func apply(params: Array) -> void:
	millis = params[0]
	maxPlayers = params[1]
	boardXY = Vector2i(params[2],params[3])
	unitsToWin = params[4]
	startResources = params[5]
	resourceHp = params[6]
	unitHp = params[7]
	unitDamage = params[8]
	allowedNameCharacters = params[9]
	
