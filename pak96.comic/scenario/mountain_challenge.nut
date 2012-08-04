/**
 # pak96.comic scenario *(Mountain Challenge) Passenger goal
 # April 1st 2012
 # Author: CheckSumDigit
 */

map.file = "MountainChallenge_a09.sve"

/// short description to be shown in finance window
/// and in standard implementation of get_about_text
scenario.short_description = "Mountain Challenge"

scenario.author = "CheckSumDigit"
scenario.version = "0.1"


function get_info_text(pl)
{
	return ttext("You are in charge of developing a comfortable and profitable passenger network.")
}
function get_rule_text(pl)
{
	return ttext("No rules.")
}
function get_result_text(pl)
{
	local text1 = ttext("You transported max {pax} passengers per month.");
	text1.pax = get_transported_pax(pl)
	return text1
}
function get_goal_text(pl)
{
	return ttext("Transport passengers. A lot of them. Per month.")
}


function start()
{
}


function get_transported_pax(pl)
{
	return player_x(pl).transported_pax.reduce( max )
}

function is_scenario_completed(pl)
{
	local pax = get_transported_pax(pl)
	return min(pax / 6500, 100)
}

function resume_game()
{
}

persistent = {}
