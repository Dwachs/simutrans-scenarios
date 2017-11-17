class ship_connector_t extends manager_t
{
	// input data
	fsrc = null
	fdest = null
	freight = null
	planned_way = null
	planned_station = null
	planned_depot = null
	planned_convoy = null

	// step-by-step construct the connection
	phase = 0
	// generated data
	c_start = null
	c_end   = null
	c_depot = null
	c_sched = null
	c_line  = null
	c_cnv   = null

	constructor()
	{
		base.constructor("ship_connector_t")
		debug = true
	}

	function work()
	{
		// TODO check if child does the right thing
		local pl = our_player
		local tic = get_ops_total();

		switch(phase) {
			case 0: // find empty water tiles
				// oilrigs ?
				// decide whether harbour is needed ...
				c_start = find_anchorage(fsrc)
				c_end   = find_anchorage(fdest)

				if (c_start.len()>0  &&  c_end.len()>0) {
					phase ++
				}
				else {
					print("No station places found")
					error_handler()
					return r_t(RT_TOTAL_FAIL)
				}

			case 1: // find path between both factories
				{
					local err = find_route()
					if (err) {
						print("No way from " + coord_to_string(c_start)+ " to " + coord_to_string(c_end))
						error_handler()
						return r_t(RT_TOTAL_FAIL)
					}
					phase ++
				}
			case 2: // build station
				{ /*
					local err = command_x.build_station(pl, c_start, planned_station )
					if (err) {
						print("Failed to build station at " + coord_to_string(c_start))
						error_handler()
						return r_t(RT_TOTAL_FAIL)
					}
					local err = command_x.build_station(pl, c_end, planned_station )
					if (err) {
						print("Failed to build station at " + coord_to_string(c_end))
						error_handler()
						return r_t(RT_TOTAL_FAIL)
					}
					{
						// store place of unload station for future use
						local fs = ::station_manager.access_freight_station(fdest)
						if (fs.ship_unload == null) {
							fs.ship_unload = c_end

							print( recursive_save({unload = c_end}, "\t\t\t", []) )
						}
					} */
					phase ++
				}
			case 3: // find depot place
				{
					phase ++
				}
			case 4: // build way to depot
				{
					phase ++
				}
			case 5: // build depot
				{
					// depot already existing ?
					if (c_depot.find_object(mo_depot_water) == null) {
						// no: build
						local err = command_x.build_depot(pl, c_depot, planned_depot )
						if (err) {
							print("Failed to build depot at " + coord_to_string(c_depot))
							error_handler()
							return r_t(RT_TOTAL_FAIL)
						}
						{
							// store depot location
							local fs = ::station_manager.access_freight_station(fsrc)
							if (fs.ship_depot == null) {
								fs.ship_depot = c_depot
							}
						}
					}
					phase ++
				}
			case 6: // create schedule
				{
					local sched = schedule_x(wt_water, [])
					sched.entries.append( schedule_entry_x(c_start, 100, 0) );
					sched.entries.append( schedule_entry_x(c_end, 0, 0) );
					c_sched = sched
					phase ++
				}

			case 7: // create line and set schedule
				{
					pl.create_line(wt_water)

					// find the line - it is a line without schedule and convoys
					local list = pl.get_line_list()
					foreach(line in list) {
						if (line.get_waytype() == wt_water  &&  line.get_schedule().entries.len()==0) {
							// right type, no schedule -> take this.
							c_line = line
							break
						}
					}
					// set schedule
					c_line.change_schedule(pl, c_sched);
					phase ++
				}
			case 8: // append vehicle_constructor
				{
					local c = vehicle_constructor_t()
					c.p_depot  = depot_x(c_depot.x, c_depot.y, c_depot.z)
					c.p_line   = c_line
					c.p_convoy = planned_convoy
					c.p_count  = min(planned_convoy.nr_convoys, 3)
					append_child(c)

					local toc = get_ops_total();
					print("ship_connector wasted " + (toc-tic) + " ops")

					phase ++
					return r_t(RT_PARTIAL_SUCCESS)
				}
			case 9: // build station extension

		}

		industry_manager.set_link_state(fsrc, fdest, freight, industry_link_t.st_built)
		industry_manager.access_link(fsrc, fdest, freight).append_line(c_line)

		return r_t(RT_TOTAL_SUCCESS)
	}

	function error_handler()
	{
		industry_manager.set_link_state(fsrc, fdest, freight, industry_link_t.st_failed);
		// add fallback to plan road/amphibic connection
	}

	static function find_anchorage(factory)
	{
		// try to find tiles already covered by some harbours
		local tile_list = ::finder.find_water_places( ::finder.get_tiles_near_factory(factory) )
		local halt_list = factory.get_halt_list()
		local anch = []

		if (tile_list.len()>0  &&  halt_list.len()>0) {
			foreach(tile in tile_list) {

				local h = schedule_entry_x(tile,0,0).get_halt(our_player)
				if (h) {
					foreach(halt in halt_list) {
						if ( (h <=> halt) == 0) {
							anch.append(tile)
						}
					}
				}
			}
		}
		if (anch.len()>0) {
			return anch
		}
		// find places to build harbour
		if (tile_list.len()>0) {
			foreach(tile in tile_list) {
				for(local d = 1; d<16; d*=2) {
					local to = from.get_neighbour(wt_all, tile)
					if (to  &&  to->is_empty()) {
						anch.append(tile)
						break
					}
				}
			}
		}
		return anch
	}

	function find_route()
	{
		local as = route_finder_water()

		local res = as.search_route(c_start, c_end)

		if ("err" in res) {
			return res.err
		}
		c_start = res.start
		c_end   = res.end

		local asd = route_finder_water_depot()
		res = asd.search_route(as.route)

		if ("err" in res) {
			return res.err
		}
		local d = res.depot
		c_depot = tile_x(d.x, d.y, d.z)
	}
}


class route_finder_water extends astar
{
	function process_node(cnode)
	{
		local from = tile_x(cnode.x, cnode.y, cnode.z)
		local back = dir.backward(cnode.dir)

		for(local d = 1; d<16; d*=2) {
			// do not go backwards
			if (d == back) {
				continue
			}

			local to = from.get_neighbour(wt_all, d)
			if (to) {
				if (::finder._tile_water(to)  &&  !is_closed(to)) {
					// estimate moving cost
					local move = ((dir.double(d) & cnode.dir) != 0) ? /* straight */ 14 : /* curve */ 10
					local dist   = 10*estimate_distance(to)

					local cost   = cnode.cost + move
					local weight = cost + dist
					local node = ab_node(to, cnode, cost, weight, dist, d)

					add_to_open(node, weight)
				}
			}
		}
	}

	function search_route(start, end)
	{
		prepare_search()
		foreach (e in end) {
			targets.append(e);
		}
		compute_bounding_box()

		foreach (s in start)
		{
			local dist = estimate_distance(s)
			add_to_open(ab_node(s, null, 1, dist+1, dist, 0), dist+1)
		}

		search()

		if (route.len() == 0) {
			print("No water route found")
			return { err =  "No route" }
		}

		local res = { start = route[ route.len()-1], end = route[0] }

		// now find route to some depot place

		if (route.len() > 0) {
			return { start = route[ route.len()-1], end = route[0] }
		}

		print("No water deport route found")
		return { err =  "No route" }
	}
}

class route_finder_water_depot extends route_finder_water
{
	function estimate_distance(c)
	{
		// take first empty tile
		return 0
	}

	function search_route(watertiles)
	{
		prepare_search()

		// do not place depot on route between harbours
		foreach(w in watertiles) {
			add_to_close(w)
		}
		// add neighboring tiles of route to open list
		for(local i=0; i<watertiles.len(); i++)
		{
			local dist = (watertiles.len() - i)*10;
			process_node(ab_node(watertiles[i], null, 1, dist+1, dist, 0))
		}

		search()

		if (route.len() > 0) {
			return { depot = route[0] }
		}
		print("No route found")
		return { err =  "No route" }
	}
}

