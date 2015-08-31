
map.file = "borderline.sve"

scenario.short_description = "Borderline - International Transport"
scenario.author = "Dwachs"
scenario.version = "0.1"


local port_styx = null
local port_cern = null
local border_x = 180

function get_rule_text(pl)
{
	local text = ttextfile("rule.txt")
	text.cmp0 = player_x(0).get_name()
	text.cmp2 = player_x(2).get_name()
	text.styx = port_styx.get_name()
	text.cern = port_cern.get_name()

	return text
}

function get_goal_text(pl)
{
	return @"Transport a lot of stuff"
}

function get_info_text(pl)
{
	return "Respect the borders"
}

function get_result_text(pl)
{
	return "Nothing to see"
}

function start()
{
	port_styx = square_x(97,27).get_halt()
	port_cern = square_x(274,51).get_halt()

	local index = scenario.forbidden_tools.find( tool_switch_player )
	if (index != null) {
		scenario.forbidden_tools.remove(index)
	}
}

function is_scenario_completed(pl)
{
	return 1
}

function is_schedule_allowed(pl, schedule)
{
	local east = false
	local west = false
	local noni = false // one halt is not one of the international ports

	foreach(entry in schedule.entries) {
		local halt = entry.get_halt(player_x(pl))

		if (pl == 0  &&  entry.x > border_x  &&  (halt == null  ||  halt.id != port_cern.id)) {
			local text = ttext( "Only {cmp2} can transport here!" )
			text.cmp2 = player_x(2).get_name()
			return text
		}
		if (pl == 2  &&  entry.x < border_x  &&  (halt == null  ||  halt.id != port_styx.id)) {
			local text = ttext( "Only {cmp0} can transport here!" )
			text.cmp0 = player_x(0).get_name()
			return text
		}

		east = east || entry.x > border_x
		west = west || entry.x < border_x
		noni = noni || ( (halt.id != port_cern.id)  &&  (halt.id != port_styx.id) )
	}

	return null
}