class_name AiDifficulty
extends RefCounted

# How capable a bot fugitive is. The level is chosen in the lobby and stored
# on the bot's player data; the profile it maps to is what the brain and the
# body actually read. Every number here is a whole tuning knob, so the levels
# differ in kind and not only in degree: an easy bot wanders, dawdles, notices
# little and cannot keep a cop out of its route, a hard bot beelines at full
# speed and treats every cop it has seen as a no-go area.
#
# The values below are the Medium profile. Easy and Hard override only what
# differs.

enum Level { EASY, MEDIUM, HARD }
const DEFAULT := Level.MEDIUM

# Fraction of a human's walk, crouch and sprint speeds
var speed_scale := 0.9
# Seconds between decisions
var think_interval := 0.2
# How far away a cop on foot can be noticed, given a line of sight
var see_distance := 25.0
# A cop inside this range sends the bot into cover
var caution_distance := 20.0
# A cop inside this range while the bot is lit makes it run
var panic_distance := 9.0
# A cop inside this range makes a hiding bot crouch
var crouch_distance := 14.0
# How long a cop that ducks out of view is assumed to still be about
var threat_memory := 5.0
# How far away a frozen teammate can be and still be worth going to, zero
# for a bot that never turns back for anyone
var rescue_distance := 35.0
# From this close the bot goes straight into the safe zone, cop or no cop
var safe_zone_dash_distance := 20.0
# Cells sampled when picking a hiding, fleeing or detour spot: more is choosier
var spot_candidates := 40
# Chance, each time a route is replanned on the way in, of wandering off to
# a random spot within detour_radius before carrying on
var detour_chance := 0.2
var detour_radius := 10.0
# Whether routes bend around cops the bot has seen
var keeps_clear_of_cops := true
# Whether the bot spends stamina sprinting once the cops are out, whether to
# get away from one or to cover the last stretch into the safe zone
var sprints_after_headstart := true


static func label(level: int) -> String:
	match level:
		Level.EASY:
			return "Easy"
		Level.HARD:
			return "Hard"
		_:
			return "Medium"


static func is_valid(level) -> bool:
	return level is int and level in Level.values()


# The profile for a level; anything that is not a known level gets Medium
static func profile(level: int) -> AiDifficulty:
	var p := AiDifficulty.new()
	match level:
		Level.EASY:
			p.speed_scale = 0.75
			p.think_interval = 0.4
			p.see_distance = 15.0
			p.caution_distance = 12.0
			p.panic_distance = 7.0
			p.crouch_distance = 6.0
			p.threat_memory = 2.0
			p.rescue_distance = 0.0
			p.safe_zone_dash_distance = 12.0
			p.spot_candidates = 8
			p.detour_chance = 0.5
			p.detour_radius = 14.0
			p.keeps_clear_of_cops = false
			p.sprints_after_headstart = false
		Level.HARD:
			p.speed_scale = 1.0
			p.think_interval = 0.15
			p.see_distance = 32.0
			p.caution_distance = 24.0
			p.panic_distance = 10.0
			p.crouch_distance = 20.0
			p.threat_memory = 8.0
			p.rescue_distance = 50.0
			p.safe_zone_dash_distance = 25.0
			p.spot_candidates = 60
			p.detour_chance = 0.0
			p.detour_radius = 0.0
	return p
