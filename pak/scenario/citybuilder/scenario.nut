
map.file = "citybuilder02.sve"

scenario.short_description = "City Builder"
scenario.author = "Dwachs"
scenario.version = "0.1"

local goal_citizens = 10000

local claimed_city = null

// name, city size, prod start, prod max
// set production to (city.size - size) * factor + start
local factorygoals = [
	{ name = "CHEMIST", good = "Medicine",  city_size = 1002, start = 70, factor = 0.05, target = 0.5 },
	{ name = "Materialswholesale", good = "Bretter", city_size = 1115, start = 200, factor = 0.05, target = 0.75 },
	{ name = "CHEMIST", good = "Chemicals", city_size = 1334, start = 50, factor = 0.09, target = 0.5, use_exist = true },
	{ name = "Buchgrosshandel", good = "Buecher", city_size = 1772, start = 100, factor = 0.05, target = 0.75 },
	{ name = "Materialswholesale", good = "Concrete", city_size = 2515, start = 300, factor = 0.05, target = 0.75, use_exist = true },
	{ name = "TANKE", good = "Gasoline", city_size = 3155, start = 500, factor = 0.05, target = 0.75 },
	{ name = "Autohaus", good = "Autos", city_size = 3715, start = 200, factor = 0.05, target = 0.75 },
	{ name = "TANKE", good = "Gasoline", city_size = 3957, start = 800, factor = 0.05, target = 0.75 },
	{ name = "CHEMIST", good = "Medicine",  city_size = 5312, start = 400, factor = 0.05, target = 0.5 },
	{ name = "Materialswholesale", good = "Stahl", city_size = 7915, start = 300, factor = 0.05, target = 0.75, use_exist = true },
	null
]


function get_rule_text(pl)
{
	return ttext("Do what you want. But do it now.")
}

function get_goal_text(pl)
{
	local text = ttext("Grow {city} up to {target} citizens.")
	text.city = claimed_city ? claimed_city.name : " a city of your choice"
	text.target = goal_citizens
	return text
}

function get_info_text(pl)
{
	return ttext("You have to develop a small city into a booming metropolis.")
}

function get_result_text(pl)
{
	local text = ttext("Your headquarter is next to {city}: {x},{y}. <br><br>")

	text.city = claimed_city ? claimed_city.name : "nothing";
	text.x = claimed_city ? claimed_city.pos.x : -1;
	text.y = claimed_city ? claimed_city.pos.y : -1;

	if (!claimed_city) {
		return text
	}

	local text2 = ttext("City is {not} allowed to grow. <br><br>")
	text2.not = claimed_city.get_citygrowth_enabled() ? "" : "<em>not</em>"

	local res = text.tostring() + text2.tostring()

	foreach(entry in persistent.factories) {
		text2 = ttext("{factory} needs {target} {goods}. You supplied {est}.<br><br>")
		text2.factory = translate( factorygoals[entry.index].name )
		text2.target = entry.target
		text2.goods = translate( factorygoals[entry.index].good )
		text2.est = entry.est

		res = res + text2.tostring()
	}
	return res

}

function is_scenario_completed(pl)
{
	if (claimed_city) {
		return (100*claimed_city.citizens[0]) / goal_citizens
	}
	return  0
}


function start()
{
	persistent.claimed <- null
	persistent.stage   <- 0
	persistent.factories <- []
}

function resume_game()
{
	if (claimed_city) {
		claimed_city = city_x(persistent.claimed.x, persistent.claimed.y)
	}
}

function calc_base_production(citizens, goal, maximum)
{
	return min(max( (citizens - goal.city_size) * goal.factor, 0) + goal.start, maximum).tointeger();
}


function step()
{
	if (! (claimed_city) ) {
		local pos = player_x(0).headquarter_pos
		if (pos.x >= 0) {
			persistent.claimed = { x= pos.x, y = pos.y}
			claimed_city = city_x(pos.x, pos.y)
		}
		else {
			return
		}
	}
	local citizens = claimed_city.citizens[0]
	// build factories
	while( factorygoals[ persistent.stage ]  &&  citizens > factorygoals[ persistent.stage ].city_size ) {
		local goal = factorygoals[ persistent.stage ]

		local build = true
		local pos = null;
		// see whether this factory was already built here but with different good requirement
		if ("use_exist" in goal) {
			if (goal.use_exist) {
				for(local i = persistent.factories.len()-1; i>=0; i--) {
					local entry = persistent.factories[i]
					local other_goal    = factorygoals[entry.index]
					if (other_goal.name == goal.name  &&  other_goal.good != goal.good) {
						build = false
						pos = entry.pos
						break
					}
				}
			}
		}

		if (build) {
			pos = build_city_factory(goal.name, claimed_city.pos)
		}

		if (pos.x > -1) {

			local factory = factory_x(pos.x, pos.y)
			local prod = calc_base_production(citizens, factorygoals[ persistent.stage ], factory.base_production);

			local max_consumption = factory.get_base_consumption( good_desc_x( goal.good ))

			factory.set_base_production(prod)
			local consumption = factory.get_base_consumption( good_desc_x( goal.good ))
			local target = (factorygoals[ persistent.stage ].target * consumption).tointeger()

			persistent.factories.append( { pos=pos, index = persistent.stage, est = 0, target = target, max = max_consumption} )
		}
		persistent.stage++
	}

	// adjust factory production goals and city growth
	local ticks_info = world.get_ticks()
	local ticks_last_month = ticks_info.next_month_ticks - ticks_info.ticks
	local ticks_this_month = ticks_info.ticks_per_month - ticks_last_month

	local city_grow_allowed = true;

	foreach(entry in persistent.factories) {
		local factory = factory_x(entry.pos.x, entry.pos.y)
		local goal    = factorygoals[entry.index]
		local consum  = factory.input.rawget( goal.good).consumed

		if (consum[1] > 0) {
			// weighted average
			entry.est = (consum[0]*ticks_this_month + consum[1]*ticks_last_month) / ticks_info.ticks_per_month
		}
		else {
			entry.est = consum[0]
		}

		if (entry.est < entry.target) {
			// prevent city growth
			city_grow_allowed = false;
		}

		local prod = calc_base_production(citizens, goal, entry.max);
		if ( prod > factory.base_production + 10) {
			factory.set_base_production(prod)

			local consumption = factory.get_base_consumption( good_desc_x( goal.good ))
			entry.target = (goal.target * consumption ).tointeger()
		}
	}

	claimed_city.set_citygrowth_enabled(city_grow_allowed)
}



function is_work_allowed_here(pl, tool_id, pos)
{
	// headquarter only on governors island
	if (tool_id == tool_headquarter) {
		local next_town = city_x(pos.x, pos.y)

		if (next_town) {
			if (claimed_city) {
				if (claimed_city.pos.x == next_town.pos.x && claimed_city.pos.y == next_town.pos.y) {
					return null // ok
				}
				local err = ttext("You are only allowed to build your headquarter next to {city} {x1},{y1} // {x2},{y2}!")
				err.city = claimed_city.get_name()
				return err
			}
			if (next_town) {
				if (next_town.citizens[0] > 1000) {
					return ttext("Build your headquarter near a smaller city!")
				}
				return null // ok
			}
		}
		return ttext("Build your headquarter near a city!")
	}
	return null // null is equivalent to 'allowed'
}
