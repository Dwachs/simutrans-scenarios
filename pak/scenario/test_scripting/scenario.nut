
//map.file = "<attach>" //"test.sve"
map.file = "test.sve"

scenario.short_description = "Test-Ground"
scenario.author = "dwachs"
scenario.version = "0.815"
//scenario.api = "120.2"


local localinglobal = 1

function blab(blub)
{
	print("BLA " + blub)
}

function resume_game()
{
}


function start()
{
	debug_text = ""
	test_is_valid()
	test_building()
	test_map_objects()
	test_tiles()
	test_transformer()
	gui.open_info_win_at("debug")
}


debug_text <- ""

function get_debug_text(pl)
{
	return debug_text == "" ? "All tests passed." : debug_text
}

function get_rule_text(pl)
{
	// 	sleep()
	local c = coord(21,44)
	return ttext("Do what you want. But do it now.<a href='info'>Rules here!</a> <a href =  \"(21,44)\"'>Leipzig</a> " + c.href("Leipzig2") )

}

function get_goal_text(pl)
{
	local c = coord3d(0,0,0)
	return ttext(@" <it>Here is an example</it>.

			<a href='script:blab(99)'>HERE</a>

			Do not build anything at <i>the position</i> <a href='(47,11)'>near Cologne</a>.
			The mayor of <a href='(8,15)'>Berlin</a> seems to frustrated with your airport building capabilities.

			Your results can be found in <a href='result'>results</a> tab.
			Transport at least 500 passengers per month. <a href='rules'>Rules here!</a>"  + c.href("here"))
}

function get_info_text(pl)
{

	local start = settings.get_start_time()
	local text = ttext("Starting from {month} of {year}, your duty is to build up a passenger network that is capable of transporting 500 passengers per month.")
	text.month = start.month
	text.year = start.year
	return text + "<a href='result'>Rules here!</a>"
}

function get_result_text(pl)
{
	return "Go away"
}

local open_dbg = true

function is_scenario_completed(pl)
{
	if (open_dbg) gui.open_info_win_at("debug")
	open_dbg = false
	return  1
}



function is_schedule_allowed(pl, schedule)
{
	print("Howdy!")
	if (schedule.waytype == wt_road) return "Njet"
	return null
}

function is_convoy_allowed(pl, cnv, depot)
{
	return null
}

function is_work_allowed_here(pl, tool, pos)
{
	return null
}

function new_month()
{
	print("Happy new month " + get_month_name(world.get_time().month) )
}
function new_year()
{
	print("Happy new year " + world.get_time().year )
}

function is_tool_allowed(pl, tool_id, wt)
{
	if (tool_id == 0x4000) return false
	if (tool_id == 0x401c) return false
	return true
}

function TEST(res, valid)
{
	return
}

function testprint(string, res, valid)
{
	print(string + (res == valid ? "ok" : "FAIL") )
	if (res != valid) {
		debug_text += string + "FAIL<br>\n"
	}
}

function test_is_valid()
{
	testprint("test_is_valid city "   , city_x(21,44).is_valid(), true)
	testprint("test_is_valid convoy " , convoy_x(21).is_valid(), false)
	testprint("test_is_valid factory " , factory_x(21,51).is_valid(), true)
	local f = factory_x(21,51)
	f.x = 55
	testprint("test_is_valid factory " , f.is_valid(), false)
	testprint("test_is_valid halt " , halt_x(21).is_valid(), false)
	testprint("test_is_valid line " , line_x(21).is_valid(), false)
	testprint("test_is_valid tile1 " , tile_x(25,45,23).is_valid(), true)
	local t = tile_x(25,45,4)
	testprint("test_is_valid tile2 " , t.is_valid(), true)
	local r = t.find_object(mo_way)
	testprint("test_is_valid road1 " , r.is_valid(), true)
	r.x += 1
	testprint("test_is_valid road2 " , r.is_valid(), false)

	testprint("test_is_valid desc1 " , sign_desc_x("NoEntry").is_valid(), true)
	testprint("test_is_valid desc2 " , sign_desc_x("NoEntryklgsdhk").is_valid(), false)
	testprint("test_is_valid player1 " , player_x(1).is_valid(), true)
	testprint("test_is_valid player2 " , player_x(12).is_valid(), false)
}

function test_building()
{
	local bookshop1 = building_x(21,50,4)
	local bookshop2 = building_x(21,51,4)
	local townhall = building_x(21,44,4)

	testprint("test same_building1 ", bookshop1.is_same_building(bookshop2), true)
	testprint("test same_building2 ", bookshop1.is_same_building(townhall), false)
}

function test_map_objects()
{
	{
		local rs = sign_x(23, 48, 4)
		testprint("test roadsign_passable1 ", rs.can_pass(player_x(0)), true)
		testprint("test roadsign_passable1 ", rs.can_pass(player_x(2)), true)
		testprint("test roadsign_passable1 ", rs.can_pass(player_x(3)), false)
	}
}

function test_tiles()
{
	local tile = square_x(21,50).get_ground_tile();

	testprint("test get_ground_tile ", tile.z, 4);
	testprint("test is_marked1 ", tile.is_marked(), tile.is_marked())
	tile.mark()
	testprint("test is_marked2 ", tile.is_marked(), true)
	tile.unmark()
}

function test_transformer()
{
	// transformer at 47,99,3; 72,103,4; 65,47,2
	// factories at   45,99,2; 73,101,4; 65,45
	// factory without at 33,54

	{
		local tr1 = transformer_x(47,99,3);
		local fac1 = factory_x(45,99);
		local fac2 = tr1.get_factory();
		testprint("test transformer_x::get_factory ", (fac1.x==fac2.x)  &&  (fac1.y==fac2.y), true);

		local tr2 = fac2.get_transformer()
		testprint("test factory_x::get_transformer 1 ", (tr1.x==tr2.x)  &&  (tr1.y==tr2.y) &&  (tr1.z==tr2.z), true);
		testprint("test factory_x::is_transformer_connected 1 ", fac2.is_transformer_connected(), true);
	}
	{
		local tr1 = transformer_x(72,103,4);
		local fac1 = factory_x(73,101);
		local fac2 = tr1.get_factory();
		testprint("test transformer_x::get_factory ", (fac1.x==fac2.x)  &&  (fac1.y==fac2.y), true);
	}
	{
		local fac2 = factory_x(33,54)
		testprint("test factory_x::get_transformer 2 ", fac2.get_transformer(), null);
		testprint("test factory_x::is_transformer_connected 2 ", fac2.is_transformer_connected(), false);
	}
	{
		local tr1 = transformer_x(47,99,3);
		local tr2 = transformer_x(72,103,4);
		local tr3 = transformer_x(65,47,2);
		local lt  = powerline_x(48,99,3);
		testprint("test powerline_x::is_connected 1 ", tr1.is_connected(tr2), true);
		testprint("test powerline_x::is_connected 2 ", tr1.is_connected(tr3), false);
		testprint("test powerline_x::is_connected 3 ", lt.is_connected(tr2), true);
		testprint("test powerline_x::is_connected 4 ", lt.is_connected(tr3), false);

	}
}
