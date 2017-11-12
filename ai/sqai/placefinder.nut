/**
 * Helper static functions to find places for stations, depots, etc.
 */

class finder {

	static function get_tiles_near_factory(factory)
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

	static function find_empty_place(area, target)
	{
		// find place closest to target
		local tx = target.x
		local ty = target.y

		local best = null
		local dist = 10000
		// check for flat and empty ground
		for(local i = 0; i<area.len(); i++) {

			local h = area[i]
			if (i>0  &&  h == area[i-1]) continue;

			local x = h >> 16
			local y = h & 0xffff

			if (world.is_coord_valid({x=x,y=y})) {
				local tile = square_x(x, y).get_ground_tile()

				if (tile.is_empty()  &&  tile.get_slope()==0) {
					local d = abs(x - tx) + abs(y - ty)
					if (d < dist) {
						dist = d
						best = tile
					}
				}
			}
		}
		return best
	}


	static function _find_places(area, test /* function */)
	{
		local list = []
		// check for flat and empty ground
		for(local i = 0; i<area.len(); i++) {

			local h = area[i]
			if (i>0  &&  h == area[i-1]) continue;

			local x = h >> 16
			local y = h & 0xffff

			if (world.is_coord_valid({x=x,y=y})) {
				local tile = square_x(x, y).get_ground_tile()

				if (test(tile)) {
					list.append(tile)
				}
			}
		}
		return list.len() > 0 ?  list : []
	}

	static function find_empty_places(area)
	{
		return _find_places(area, _tile_empty)
	}

	static function _tile_empty(tile)
	{
		return tile.is_empty()  &&  tile.get_slope()==0
	}

	static function find_station_place(factory, target, unload = false)
	{
		if (unload) {
			// try unload station from station manager
			local res = ::station_manager.access_freight_station(factory).road_unload
			if (res) {
				return [res]
			}
		}
		local area = get_tiles_near_factory(factory)

		return find_empty_places(area)
	}

	static function find_depot_place(start, target)
	{
		{
			// try depot location from station manager
			local res = ::station_manager.access_freight_station(fsrc).depot
			if (res) {
				return res
			}
		}

		local cov = 5
		local area = []

		local t = tile_x(start.x, start.y, start.z)

		// follow the road up to the next crossing
		// check whether depot can be built next to road
		local d = t.get_way_dirs(wt_road)
		if (!dir.is_single(d)) {
			d = d	& dir.southeast // only s or e
		}
		for(local i=0; i<4; i++) {
			local nt = t.get_neighbour(wt_road, d)
			if (nt == null) break
			// should have a road
			local rd = nt.get_way_dirs(wt_road)
			// find direction to proceed: not going back, where we were coming from
			local nd = rd & (~(dir.backward(d)))
			// loop through neighbor tiles not on the road
			foreach(d1 in dir.nsew) {
				if (d1 & rd ) continue
				// test this spot
				local dp = nt.get_neighbour(wt_all, d1)
				if (dp  &&  dp.is_empty()  &&  dp.get_slope()==0) {
					return dp
				}
			}
			if (!dir.is_single(nd)  ||  nd==0) break
			// proceed
			t = nt
			d = nd
		}

		t = tile_x(start.x, start.y, start.z)
		// now go into direction perpendicular
		// to the road in the station
		local dirs = dir.double( t.get_way_dirs(wt_road) ) ^ dir.all

		// try to find depot spot next to the station
		for(local i = 1;  i < 16; i=i<<1)
		{
			if (i & dirs) {
				local n = t.get_neighbour(wt_all, i)
				if (n  &&  n.is_empty()  &&  n.get_slope()==0) {
					return n
				}
			}
		}

		// generate a list of tiles near the station
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
