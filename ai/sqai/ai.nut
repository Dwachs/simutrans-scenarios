// account for changes in scenario_base
factory_production_x.scaling <- 0

// TODO obey construction speed setting
// TODO check allowed transport types

// some meta data
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
persistent.our_player_nr <- -1

our_player_nr <- -1
our_player    <- null // player_x instance


tree <- {}

factorysearcher <- null
industry_manager <- null

possible_names <- ["Petersil Cars", "Teumer Alp Dream Trucks", "Runk & Strunk Transports", "A. Nach B. Transports", "Interflug Fourwheelers",
	"Pfarnest International", "Suboptimal Transports", "Conveyor Belts & Braces", "Bucket Brigade Inc.",
	"Maggikraut AG", "Bugs & Eggs Unlimited", "S. Claus & R. Deer Worldwide", "Leiterwagn & Sons"
			]
// 2.. 14 = 13 names

function start(pl_nr)
{
	our_player_nr = pl_nr

	if (our_player_nr > 1  &&  our_player_nr-2 < possible_names.len()) {
		player_x(our_player_nr).set_name( possible_names[our_player_nr-2]);
	}
	our_player = player_x(our_player_nr)

	info_text  +="Act as player no " + our_player_nr + " under the name " + our_player.get_name() + ". <br>"
	print("Act as player no " + our_player_nr + " under the name " + our_player.get_name())

	factorysearcher = factorysearcher_t()
	industry_manager = industry_manager_t()

	tree = factorysearcher

}

station_buildings <- {}


info_text <- ""
_step <- 0
_next_construction_step <- 0

function step()
{
	tree.step()
	_step++


	if (_step > _next_construction_step) {
		local r = factorysearcher.get_report()
		if (r   &&  r.action) {
			print("New report: expected construction cost: " + (r.cost_fix / 100.0))
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

function is_cash_available(cost /* in 1/100 cr */)
{
	return 2*cost + 2*our_player.get_current_maintenance() < our_player.get_current_net_wealth()
}
