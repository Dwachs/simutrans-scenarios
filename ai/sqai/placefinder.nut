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
}
