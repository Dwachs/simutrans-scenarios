class road_connector_t extends manager_t
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
		base.constructor("road_connector_t")
		debug = true
	}

	function work()
	{
		// TODO check if child does the right thing
		local pl = player_x(our_player)
		local tic = get_ops_total();

		switch(phase) {
			case 0: // find places for stations
				c_start = find_station_place(fsrc, fdest)
				if (c_start) {
					c_end   = find_station_place(fdest, c_start)
				}

				if (c_start  &&  c_end) {
					phase ++
				}
				else {
					return r_t(RT_TOTAL_FAIL)
				}
			case 1: // build way
				{
					local w = command_x(tool_build_way);
					local err = w.work(pl, c_start, c_end, planned_way.get_name() )
					if (err) {
						print("Failed to build way from " + coord_to_string(c_start)+ " to " + coord_to_string(c_end))
						error_handler()
						return r_t(RT_TOTAL_FAIL)
					}
					phase ++
				}
			case 2: // build station
				{
					local w = command_x(tool_build_station);
					local err = w.work(pl, c_start, planned_station.get_name() )
					if (err) {
						print("Failed to build station at " + coord_to_string(c_start))
						error_handler()
						return r_t(RT_TOTAL_FAIL)
					}
					local err = w.work(pl, c_end, planned_station.get_name() )
					if (err) {
						print("Failed to build station at " + coord_to_string(c_end))
						error_handler()
						return r_t(RT_TOTAL_FAIL)
					}
					phase ++
				}
			case 3: // find depot place
				c_depot = find_depot_place(c_start, c_start)
				if (c_depot) {
					phase ++
				}
				else  {
					return r_t(RT_TOTAL_FAIL)
				}
			case 4: // build way to depot
				{
					local w = command_x(tool_build_way);
					local err = w.work(pl, c_start, c_depot, planned_way.get_name() )
					if (err) {
						print("Failed to depot access from " + coord_to_string(c_start)+ " to " + coord_to_string(c_depot))
						error_handler()
						return r_t(RT_TOTAL_FAIL)
					}
					phase ++
				}
			case 5: // build depot
				{
					local w = command_x(tool_build_depot);
					local err = w.work(pl, c_depot, planned_depot.get_name() )
					if (err) {
						print("Failed to build depot at " + coord_to_string(c_depot))
						error_handler()
						return r_t(RT_TOTAL_FAIL)
					}
					phase ++
				}
			case 6: // create schedule
				{
					local sched = schedule_x(wt_road, [])
					sched.entries.append( schedule_entry_x(c_start, 100, 0) );
					sched.entries.append( schedule_entry_x(c_end, 0, 0) );
					c_sched = sched
					phase ++
				}

			case 7: // create line and set schedule
				{
					pl.create_line(wt_road)

					// find the line - it is a line without schedule and convoys
					local list = pl.get_line_list()
					foreach(line in list) {
						if (line.get_waytype() == wt_road  &&  line.get_schedule().entries.len()==0) {
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
					print("road_connector wasted " + (toc-tic) + " ops")

					phase ++
					return r_t(RT_PARTIAL_SUCCESS)
				}

		}

		industry_manager.set_link_state(fsrc, fdest, freight, industry_link_t.st_built);

		return r_t(RT_TOTAL_SUCCESS)
	}

	function error_handler()
	{
		industry_manager.set_link_state(fsrc, fdest, freight, industry_link_t.st_failed);
	}

	function get_tiles_near_factory(factory)
	{
		local cov = settings.get_station_coverage()
		local area = []

		// generate a list of tiles that will reach the factory
		local ftiles = factory.get_tile_list()
		foreach (c in ftiles) {
			for(local dx = -cov; dx <= cov; dx++) {
				for(local dy = -cov; dy <= cov; dy++) {
					if (dx==0 && dy==0) continue;

					local x = c.x+dx
					local y = c.y+dy

					if (x>=0 && y>=0) area.append( (x << 16) + y );
				}
			}
		}
		// sort
		sleep()
		area.sort(/*compare_coord*/)
		return area
	}

	function find_empty_place(area, target)
	{
		local candidates = []
		// check for flat and empty ground
		for(local i = 0; i<area.len(); i++) {

			local h = area[i]
			if (i>0  &&  h == area[i-1]) continue;

			local x = h >> 16
			local y = h & 0xffff

			if (world.is_coord_valid({x=x,y=y})) {
				local tile = square_x(x, y).get_ground_tile()

				if (tile.is_empty()  &&  tile.get_slope()==0) {
					candidates.append(tile)
				}
			}
		}

		if (candidates.len() == 0) {
			return null // no place found ??
		}

		// find place closest to target
		local tx = target.x
		local ty = target.y
		local nearest = candidates[0]
		local dist = abs(nearest.x - tx) + abs(nearest.y - ty)
		for (local i=1; i<candidates.len(); i++) {
			local c = candidates[i]
			local d = abs(c.x - tx) + abs(c.y - ty)
			if (d<dist) {
				dist = d
				nearest = c
			}
		}
		return nearest
	}

	function find_station_place(factory, target)
	{
		local area = get_tiles_near_factory(factory)

		return find_empty_place(area, target)
	}

	function find_depot_place(start, target)
	{
		local cov = 5
		local area = []

		// generate a list of tiles that will reach the factory
		for(local dx = -cov; dx <= cov; dx++) {
			for(local dy = -cov; dy <= cov; dy++) {
				if (dx==0 && dy==0) continue;

				local x = start.x+dx
				local y = start.y+dy

				if (x>=0 && y>=0) area.append( (x << 16) + y );
			}
		}
		return find_empty_place(area, target)
	}
}