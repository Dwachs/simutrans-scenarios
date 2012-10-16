
map.file = "../book-empire/book-empire.sve"

scenario.short_description = "Millionaire"
scenario.author = "prissi (scripting by Dwachs)"
scenario.version = "0.1"

function get_rule_text(pl)
{
	return "No limits."
}

function get_goal_text(pl)
{
	return @"Become millionaire as fast as possible."
}

function get_info_text(pl)
{
	return @"You started a small transport company to become rich. Your grandparents did not have a glue, where all their money flows
		 into."
}

function get_result_text(pl)
{
	local cash = get_cash(pl)

	local text = "Your bank account is worth " + cash + ".<br> <br>"
	if ( cash >= 1000000 )
		text += "<it>Congratulation!</it><br> <br> You won the scenario!"
	else
		text += "You still have to work a little bit harder."

	return text
}

function get_cash(pl)
{
	return player_x(pl).cash[0]
}

function is_scenario_completed(pl)
{
	return  get_cash(pl) / 10000
}
