/**
 * Script to add achievements in-game. Player who reaches first XX points wins.
 */

/// specify the savegame to load
map.file = "<attach>" // achiever_map.sve"

/// short description to be shown in finance window
/// and in standard implementation of get_about_text
scenario.short_description = "Fight for achievements"

scenario.author = "dwachs"
scenario.version = "0.1"

const save_version = 1

// waytype handling
all_waytypes <- [wt_road, wt_rail, wt_water, wt_monorail, wt_maglev, wt_tram, wt_narrowgauge, wt_air]
max_waytypes <- all_waytypes.reduce(max) +1
vehicle_names <- array(max_waytypes)
vehicle_names[wt_road] = "buses and trucks"
vehicle_names[wt_rail] = "trains"
vehicle_names[wt_water] = "ships"
vehicle_names[wt_monorail] = "monorail trains"
vehicle_names[wt_maglev] = "futuristic maglevs"
vehicle_names[wt_tram] = "trams"
vehicle_names[wt_narrowgauge] = "narrow gauge trains"
vehicle_names[wt_air] = "planes"

// helper function
function save_coord(p)
{
	return "{x="+p.x+",y="+p.y+",z="+p.z+"}";
}

// current standing - calculated
current_standing_text <- ""

function get_info_text(pl)
{
	return "This game is a fight for achievements. <br><br> These are the current standings:<br><br>" + current_standing_text;
}
function get_rule_text(pl)
{
	return @"You can do everything you want. Even looking out of the window."
}

// results for active players - calculated
result_text <- array(16)

function get_result_text(pl)
{
	return result_text[pl]
}
function get_goal_text(pl)
{
	return "Outperform your competitors! Collect achievement points. All of them. Watch out for the less serious points. Have !!FUN!!"
}

//
class goal_base {
	points = 0

	/// performs checks, returns nothing
	function check(po) {  }

	/// return true if goal is completed
	function completed() { return true; }

	/// returns null if nothing still achieved
	function get_text(po) { return null; }

	function get_points(po) { return points; }
}

// deepest/highest station
// largest station
// longest bridge
// most construction cost
// transport per month / year / company lifetime ?
// made me smile: staion name contains :)
// boring / interesting station
// random yearly challenges: points awarded to winning player

class level_goal_base extends goal_base {
	level    = 100
	maxlevel = 1
	factor   = 1
	pincrease= 1
	reached_level=0

	constructor(l,f,pi,sav_)
	{
		level = l;
		factor = f;
		maxlevel = 0x7fffffff / factor;
		pincrease = pi;
		points = 0;
	}

	// overload this
	function get_number(po) { return 1; }

	function check(po) {
		local res = get_number(po)
		while (res >= level  &&  level < maxlevel) {
			reached_level = level
			level  *= factor
			points += pincrease
		}
	}

	// only completes on overflow
	function completed() { return level>=maxlevel; }
}

class transported_passengers_month extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(100, 10, 1, _saved_table); }

	function get_number(po) { return po.get_transported_pax().reduce( max ); }

	function get_text(po) { return points > 0 ? "Transported " + integer_to_string(reached_level) + " passengers in one month." : null; }

	function _save() { return "transported_passengers_month()"; }
}
class transported_mail_month extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(50, 8, 2, _saved_table); }

	function get_number(po) { return po.get_transported_mail().reduce( max ); }

	function get_text(po) { return points > 0 ? "Transported " + integer_to_string(reached_level) + " bags of mail in one month." : null; }

	function _save() { return "transported_mail_month()"; }
}
class deliver_power_month extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(400, 5, 1, _saved_table) }

	function get_number(po) { return po.get_powerline().reduce( max ); }

	function get_text(po) { return points > 0 ? "Delivered " + integer_to_string(reached_level) + "MW of power to various industries." : null; }

	function _save() { return "deliver_power_month()"; }
}
class burn_money_month extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(100000, 10, 1, _saved_table) }

	function get_number(po) { return -po.get_construction().reduce( min ); }

	function get_text(po) { return points > 0 ? "Burnt " + money_to_string(reached_level) + " for constructions in one month." : null; }

	function _save() { return "burn_money_month()"; }
}
class hoard_money_month extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(1000000, 10, 1, _saved_table) }

	function get_number(po) { return po.get_cash().reduce( max ); }

	function get_text(po) { return points > 0 ? "Hoarded " + money_to_string(reached_level) + " at the bank." : null; }

	function _save() { return "hoard_money_month()"; }
}
class profite_month extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(10000, 10, 1, _saved_table) }

	function get_number(po) { return po.get_profit().reduce( max ); }

	function get_text(po) { return points > 0 ? "Earned " + money_to_string(reached_level) + " in one month." : null; }

	function _save() { return "profite_month()"; }
}
class toll_plus_month extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(1000, 10, 1, _saved_table) }

	function get_number(po) { return po.get_profit().reduce( max ); }

	function get_text(po) { return points > 0 ? "Robbed others for " + money_to_string(reached_level) + " in tolls for one month." : null; }

	function _save() { return "toll_plus_month()"; }
}
class deliver_goods_month extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(1000, 10, 1, _saved_table) }

	function get_number(po) { return po.get_transported_goods().reduce( max ); }

	function get_text(po) { return points > 0 ? "Delivered " + integer_to_string(reached_level) + " units of cargo in one month." : null; }

	function _save() { return "deliver_goods_month()"; }
}


class convoy_profitable extends level_goal_base {
	wt = 0

	constructor(wt_ = wt_invalid, _saved_table = null) { wt = wt_; base.constructor(1, 10, 1, _saved_table) }

	function get_number(po) { return company_goal_info[po.nr].cnv_profitable[wt]; }

	function _save() { return "convoy_profitable(" + wt + ")"; }

	function get_text(po)
	{
		return points > 0 ? "Has " + reached_level + " " + vehicle_names[wt] + " running with profit." : null
	}
}

class convoy_distance extends level_goal_base {

	constructor(_saved_table = null) { base.constructor(100, 10, 1, _saved_table) }

	function get_number(po) { return company_goal_info[po.nr].max_dist; }

	function _save() { return "convoy_distance()"; }

	function get_text(po)
	{
		return points > 0 ? "Has a convoy running more than " + integer_to_string(reached_level) + " kilometres." : null
	}
}


class headquarter extends goal_base {

	function check(po) { points = po.get_headquarter_level(); }

	function get_text(po) { points > 0 ? "Built an adequate headquarter.": null; }

	function _save() { return "headquarter()"; }
}

// simulate static data for longest_bridge goal - persistent
longest_bridge_info <- {
	player_nr = -1 /// player who receives points
	max_length = -1
}

class longest_bridge extends goal_base {

	info = longest_bridge_info

	// points = length of longest bridge
	function get_points(po) { return info.player_nr == po.nr  &&  info.max_length > 0 ? info.max_length /2 : 0; }

	// completed - only check after bridge building

	function get_text(po) { return info.player_nr == po.nr  &&  info.max_length > 0 ? "Built longest bridge ever." : null; }

	function _save() { return "longest_bridge()"; }
}

class save_historic_building extends goal_base {

	pos  = null
	desc = null

	constructor(p,d)
	{
		pos = clone p;
		if (typeof(d)=="string") {
			desc = building_desc_x(d)
		}
		else {
			desc = d;
		}
		points = 5;
	}

	// check whether building is still there
	function check(po)
	{
		local t = tile_x(pos.x,pos.y,pos.z)
		if (t) {
			local d = t.find_object(mo_building)
			if (d) {
				if (desc.is_equal(  d.get_desc() ))
				{
					// everything ok
					return
				}
			}
		}
		// fail - building has vanished
		desc = null
		points = -10
	}

	function completed() { return points <= 0; }

	function get_text(po)
	{
		if (points > 0) {
			return "Saved a historic building from being demolished."
		}
		else if (points < 0) {
			return "Demolished an exceptionally important historic building."
		}
		return null;
	}

	function get_points(po) { return points; }

	function _save() { return "save_historic_building("+save_coord(pos)+", \""+desc.get_name()+"\")"; }
}

class underground_station extends goal_base {

	constructor() { points = 1 }

	function get_text(po) { return "Built an underground station." }

	function _save() { return "underground_station()" }
}

class aboveground_station extends goal_base {

	constructor() { points = 1 }

	function get_text(po) { return "Built a station above our heads." }

	function _save() { return "aboveground_station()" }
}


// goals to check - persistent
pending_goals <- array(16)

// index of next goal to check - calculated
pending_index <- array(16,0)
// name/total points of players - calculated
active_players <- array(16)

// results of removed/bankrupt players - persistent
inactive_players <- []

active_players_default <- { name = "", points = 0, is_active = 1}

// static info per company - persistent
company_goal_info <- array(16)

// default value for static info
function get_company_goal_info_default()
{
	local t = {}
	t.historic <- 0
	t.underground_station <- 0
	t.aboveground_station <- 0
	t.cnv_profitable <- array(max_waytypes,0)
	t.max_dist <- 0
	return t;
}

// tiles to check for strange things - persistent
pending_tile_checks <- []

// generator to do the convoy checks
// perform_convoy_checks will suspend itself
generator_cnv_checks <- null

function is_scenario_completed(pl)
{
	if (pl == 1) {
		// public player does not compete - time for special checks
		switch(pending_index[pl]) {
			case 1:
				check_activity()
				break
			case 2:
				perform_tilechecks()
				break
			case 3:
				// call the routine, which just returns the generator
				if (generator_cnv_checks==null) {
					generator_cnv_checks = perform_convoy_checks();
				}
				// actually do the checks, routine may suspend itself
				if ( !(resume generator_cnv_checks) ) {
					generator_cnv_checks = null
				}
				break
			default:
				pending_index[pl] = 0
		}
		pending_index[pl]++
		return 1;
	}
	// fill goal array if necessary
	if (!pending_goals[pl]) {
		pending_goals[pl]     = generate_pending_goals()
		company_goal_info[pl] = get_company_goal_info_default()
	}
	if (!active_players[pl]) {
		active_players[pl]    = clone active_players_default
	}
	local our_goals = pending_goals[pl]

	// check index, on overflow do maintenance work
	if (pending_index[pl] >= our_goals.len()) {
		pending_index[pl] = 0;
		compile_result_text(pl)
		//print("Result : " + pl + " / " + pending_index[pl])

		if (pl == 0) {
			compile_current_standing();
		}
		return 1;
	}

	// check next goal
	local po = player_x(pl)
	if (po  &&  po.is_active()) {
		local goal = our_goals[ pending_index[pl] ]
		if (!goal.completed()) {
			goal.check(po)
		}
	}
	pending_index[pl]++

	return 1
}

function perform_tilechecks()
{
	// first filter out old checks
	pending_tile_checks = pending_tile_checks.filter(tile_check_base.filter);
	// .. now iterate
	foreach(tc in pending_tile_checks) {
		tc.check()
		tc.tries --
	}
	persistent.pending_tile_checks = pending_tile_checks;
}

function compile_result_text(pl)
{
	local res = null
	local total = 0
	local po = player_x(pl)
	foreach(goal in pending_goals[pl]) {
		local text = goal.get_text(po)
		local points = goal.get_points(po)
		if (text) {
			if (res) res += "<br>"; else res = ""

			res += "(" + (points>0?"+":"") + points + ") " + text
			total += points
		}
		//if (points) print(text)
	}
	if (res) {
		res += "<br><br>" + total + " points total achieved."
	}
	else {
		res = "<br>No points achieved."
	}

	result_text[pl]  = res
	active_players[pl].points = total
	active_players[pl].name   = po.get_name()
}

function compile_current_standing()
{
	local st = []
	for(local pl = 0; pl < 15; pl ++) {
		if (pl != 1  &&  active_players[pl]) {
			st.append( clone active_players[pl] )
		}
	}
	st.extend(inactive_players)
	st.sort( @(sa,sb) ( sb.points<=>sa.points ))

	current_standing_text = ""
	foreach(idx,sa in st) {
		local ia = sa.is_active
		current_standing_text += ia ? "<em>" : ""
		current_standing_text += "[" + (idx+1) + "] " + sa.name + " (" + sa.points + " points)"
		current_standing_text += ia ? "</em>" : ""
		current_standing_text += "<br>\n"
	}
	//print(current_standing_text)
}

function check_activity()
{
	for(local pl = 0; pl < 15; pl ++) {
		if (pl == 1) continue
		local player = player_x(pl)
		if (pending_goals[pl]  &&  !player.is_active())
		{
			local inact = clone active_players[pl]
			inact.is_active = 0
			inactive_players.append(inact)
			pending_goals[pl] = null
		}
	}
}

function generate_pending_goals()
{
	local a = [
		transported_passengers_month(),
		transported_mail_month(),
		deliver_goods_month(),
		deliver_power_month(),
		hoard_money_month(),
		burn_money_month(),
		profite_month(),
		longest_bridge(),
		convoy_distance(),
 		];
	foreach(wt in all_waytypes) {
		a.append(convoy_profitable(wt))
	}
	return a
}


function is_work_allowed_here(pl, tool_id, pos)
{
	// catch bridge building here ...
	if (tool_id == tool_build_bridge) {
		// store bridge position ...
		print("Caught bridge at (" + pos.x + ", " +pos.y + ", " +pos.z +")")
		pending_tile_checks.append( checkforbridge(pos, pl) )
	}
	// buy historic building
	if (tool_id == tool_buy_house  &&  company_goal_info[pl].historic == 0) {
		print("Caught buy-house at (" + pos.x + ", " +pos.y + ", " +pos.z +")")
		pending_tile_checks.append( checkhistoric(pos, pl) )
	}
	// catch station building here ...
	if (tool_id == tool_build_station) {
		local tile = tile_x(pos.x, pos.y, pos.z)
		if (!tile.is_ground()) {
			pending_tile_checks.append( checkstation(pos, pl) )
		}
	}
	return null
}

//
class tile_check_base {
	tries = 5
	pos   = null
	pl    = -1

	constructor(p, pl_, t_ = 5) { tries = t_; pos = clone p; pl = pl_;}

	function check() {}

	static function filter(idx, val) { return val.tries>0; }
}

class checkforbridge extends tile_check_base {
	function check()
	{
		local start = tile_x(pos.x,pos.y,pos.z)
		if (!start.is_bridge()  ||  !start.is_ground()) return;

		// first way on bridge - now find bridge direction
		local way = start.find_object(mo_way);
		if (!way) return;

		local wt = way.get_waytype();
		local max_length = 0
		foreach(r in dir.nsew) {
			local length = 1
			local tile = start.get_neighbour(wt,r)
			while (tile  &&  tile.is_bridge()  &&  !tile.is_ground()) {
				tile = tile.get_neighbour(wt,r)
				length ++
			}

			if (tile  &&  tile.is_bridge()) length ++;

			if (length > max_length) max_length = length;
		}

		// do not check again
		tries = 0

		if (max_length > longest_bridge_info.max_length) {
			longest_bridge_info.max_length = max_length
			// get owner of bridge
			local bridge = start.find_object(mo_bridge);
			longest_bridge_info.player_nr = bridge ? bridge.get_owner().nr : -1;
		}

		print("Check for bridge at (" + pos.x + ", " +pos.y + ", " +pos.z +") ==> " + max_length)
	}

	function _save() { return "checkforbridge("+save_coord(pos)+","+pl+","+tries+")"; }
}

class checkhistoric extends tile_check_base {
	function check()
	{
		if (company_goal_info[pl].historic != 0) return

		local t = tile_x(pos.x,pos.y,pos.z)
		if (t) {
			local d = t.find_object(mo_building)
			if (d) {
				if (d.get_owner().nr == pl)
				{
					if (d.get_desc().is_retired( world.get_time() ) ){
						// this is an old building
						pending_goals[pl].append(save_historic_building(pos, d.get_desc()))
						company_goal_info[pl].historic = 1
					}
					// do not check again
					tries = 0
				}
			}
		}
	}
	function _save() { return "checkhistoric("+save_coord(pos)+","+pl+","+tries+")"; }
}

class checkstation extends tile_check_base {
	function check()
	{
		local t = tile_x(pos.x,pos.y,pos.z)
		if (t  &&  !t.is_ground()) {
			local st = t.find_object(mo_building)
			if (st  &&  st.get_owner().nr == pl) {
				local b = st.get_desc()
				if (b.get_type() == building_desc_x.station) {
					if (t.is_tunnel()) {
						if (company_goal_info[pl].underground_station == 0) {
							company_goal_info[pl].underground_station = 1;
							pending_goals[pl].append(underground_station())
						}
					}
					else {
						if (company_goal_info[pl].aboveground_station == 0) {
							company_goal_info[pl].aboveground_station = 1;
							pending_goals[pl].append(aboveground_station())
						}
					}
				}
				// do not check again
				tries = 0
			}
		}
	}
	function _save() { return "checkstation("+save_coord(pos)+","+pl+","+tries+")"; }
}

function perform_convoy_checks()
{
	local iteration = 0;
	local cnv_counter = array(15)
	local max_dist    = array(15,0)
	for(local i=0; i<15; i++) {
		cnv_counter[i] = array(max_waytypes,0)
	}

	foreach(cnv in convoy_list_x()) {
		local pl = cnv.get_owner().nr
		local is_profitable = cnv.get_profit().reduce(max) > 0
		if (is_profitable) {
			cnv_counter[ pl ][ cnv.get_waytype() ] ++
		}
		local distance      = cnv.get_distance_traveled_total()
		if (distance > max_dist[pl]) {
			max_dist[pl] = distance
		}
		iteration++
		if (iteration % 100 == 0) {
			yield true
		}
	}
	for(local pl=0; pl<15; pl++) {
		foreach(wt in all_waytypes) {
			local c = cnv_counter[ pl ][ wt ]
			if (c>0) {
				company_goal_info[pl].cnv_profitable[wt] = max(company_goal_info[pl].cnv_profitable[wt], c);
			}
		}
		if (max_dist[pl]>0) {
			company_goal_info[pl].max_dist = max(company_goal_info[pl].max_dist, max_dist[pl])
		}
	}
	return null
}

persistent <- {
	pending_goals       = pending_goals
	company_goal_info   = company_goal_info
	pending_tile_checks = pending_tile_checks
	longest_bridge_info = longest_bridge_info
	inactive_players    = inactive_players
}

function start()
{
	persistent.save_version <- save_version
	init()
}


function resume_game()
{
	init()
	pending_goals       = persistent.pending_goals
	company_goal_info   = persistent.company_goal_info
	pending_tile_checks = persistent.pending_tile_checks
	inactive_players    = persistent.inactive_players

	// save game version
	if ( !("save_version" in persistent) ) {
		persistent.save_version <- 0
	}

	// copy it piece by piece otherwise the reference longest_bridge::info will be off
	foreach(key,value in persistent.longest_bridge_info)
	{
		longest_bridge_info.rawset(key,value)
	}
	persistent.longest_bridge_info = longest_bridge_info

	// refresh point calculations
	for(local pl = 0; pl < 15; pl++)
	{
		local po = player_x(pl)
		if (pl != 1  &&  po.is_active()) {
			// update
			switch(persistent.save_version) {
				case 0:
					pending_goals[pl].insert(2, deliver_goods_month())
					print("Ha" + pl)
			}
			// player info
			active_players[pl]    = clone active_players_default
			// check goals
			foreach(goal in pending_goals[pl]) {
				goal.check(po)
			}
			// .. and compile result
			compile_result_text(pl)
		}
	}
	compile_current_standing()
	// everything updated...
	persistent.save_version = save_version
}

function init()
{
	scenario.forbidden_tools = scenario.forbidden_tools.filter( @(index,val)( val != tool_switch_player) )
	for(local pl=0; pl<16; pl++)
		result_text[pl] = "Results are being calculated..."
}


