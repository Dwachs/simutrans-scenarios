// account for changes in scenario_base
factory_production_x.scaling <- 0


/// short description to be shown in finance window
/// and in standard implementation of get_about_text
ai <- {}
ai.short_description <- "Test AI player implementation"

ai.author <-"dwachs"
ai.version <- "0.1"



// includes
include("basic")
include("factorysearcher")
include("industry_connection_planner")
include("industry_manager")
include("prototyper")
include("road_connector")
include("vehicle_constructor")

// global variables
persistent.our_player <- -1

our_player <- persistent.our_player.weakref()

tree <- {}

factorysearcher <- null
industry_manager <- null

possible_names <- ["Petersil Cars", "Teumer Alp Dream Trucks", "Runk & Strunk Transports", "A. Nach B. Transports", "Interflug Fourwheelers",
	"Pfarnest International", "Suboptimal Transports", "Conveyor Belts & Braces", "Bucket Brigade Inc.",
	"Maggikraut AG", "Bugs & Eggs Unlimited", "S. Claus & R. Deer Worldwide", "Leiterwagn & Sons"
			]

function start(pl_nr = -1)
{
	print("player number " + pl_nr)
	if (pl_nr == -1) {
		for(local i = 14; i > 1; i--) {
			if (player_x(i).is_active()) {
				our_player = i
				print("Take over player " + i)
			}
		}
		if (our_player == -1) {
			our_player = 0
		}
	}
	else {
		our_player = pl_nr
	}
	info_text += "Playing as player " + our_player + "<br><br><br>"

	if (our_player > 0  &&  our_player-1 < possible_names.len()) {
		player_x(our_player).set_name( possible_names[our_player-1]);
	}

	print(info_text)
	init()

	factorysearcher = factorysearcher_t()
	industry_manager = industry_manager_t()

	tree = factorysearcher
}

station_buildings <- {}

// called from start and resume_game
function init()
{
	// filter station buildings
	local s = building_desc_x.get_building_list(building_desc_x.station)
	foreach(val in s) {
		if (val.get_type() == building_desc_x.station) {
			local wt = val.get_waytype()

			if (!(wt in station_buildings)) {
				station_buildings.rawset(wt, [])
			}
			station_buildings.rawget(wt).append(val)
		}
	}
}

info_text <- ""

function get_info_text(pl)
{
	return info_text
}

function get_goal_text(pl)
{
	return @"
	-- who checks timeline for stuff to be built? <br>
	-- hash for coordinates
	"
}


_step <- 0
_next_construction_step <- 0

function step()
{
	tree.step()
	_step++


	if (_step > _next_construction_step) {
		local r = factorysearcher.get_report()
		if (r   &&  r.action) {
			tree.append_child(r.action)
		}
		_next_construction_step += 1 + (_step % 3)
	}

	// ??
}


function compare_coord(c1, c2)
{
	local res = c1.x <=> c2.x
	if (res == 0) {
		res = c1.y <=> c2.y
	}
	return res
}

