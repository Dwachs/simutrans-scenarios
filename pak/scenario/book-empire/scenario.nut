
map.file = "book-empire.sve"

scenario.short_description = "Supply book shop"
scenario.author = "prissi (scripting by Dwachs)"
scenario.version = "0.1"

function get_rule_text(pl)
{
	return "No rules. Only pressure to win."
}

function get_goal_text(pl)
{
	return @"Supply the book shop at (20,50). <br><br>
	The scenario is won if book shop starts selling."
}

function get_info_text(pl)
{
	return @"Your transport company is engaged to help the people of Leipzig to get something to read in dark winter nights."
}

function get_result_text(pl)
{
	local con = get_book_consumption()

	local text = "The bookshop sold " + con + " books."
	if ( con > 0 )
		text = "<it>Congratulation!</it><br> <br> You won the scenario!"
	else
		text = "Leipzig people are still bored of your transportation service."

	return text
}

// accessor to the book statistics
local book_slot = null

function start()
{
	book_slot = factory_x(20, 50).input.Buecher
}

function get_book_consumption()
{
	return book_slot.consumed.reduce( max )
}

function is_scenario_completed(pl)
{
	// make the book shop sell something
	return  get_book_consumption() > 0 ? 100 : 0;
}
