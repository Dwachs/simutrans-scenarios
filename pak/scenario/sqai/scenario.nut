// account for changes in scenario_base
factory_production_x.scaling <- 0


/// specify the savegame to load
map.file = "<attach>"

/// short description to be shown in finance window
/// and in standard implementation of get_about_text
scenario.short_description = "Test AI player implementation"

scenario.author = "dwachs"
scenario.version = "0.1"

// includes
include("basic")
include("factorysearcher")
include("industry_connection_planner")
include("prototyper")
include("road_connector")

// global variables
persistent.our_player <- -1

our_player <- persistent.our_player.weakref()

tree <- {}

function start()
{
	for(local i = 14; i > 1; i--) {
		if (player_x(i).is_active()) {
			our_player = i
			print("Take over player " + i)
		}
	}
	our_player = 0
	init()
	tree = factorysearcher_t()
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

function is_scenario_completed(pl)
{
	if (our_player > -1) {
		step()
	}
	return 99;
}

function get_info_text(pl)
{
	return "Playing as player " + our_player
}

function get_goal_text(pl)
{
	return @"
	-- who checks timeline for stuff to be built? <br>
	-- hash for coordinates
	"
}

function step()
{
	tree.step()
	local r = tree.get_report()
	if (r   &&  r.action) {
		tree.append_child(r.action)
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

