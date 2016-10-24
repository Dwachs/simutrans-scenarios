class astar_node extends coord3d
{
	previous = null // previous node
	cost     = -1   // cost to reach this node
	weight   = -1   // heuristic cost to reach target
	dist     = -1   // distance to target
	constructor(c, p, co, w, d)
	{
		x = c.x
		y = c.y
		z = c.z
		previous = p
		cost     = co
		weight   = w
		dist     = d
	}
}

function abs(x) { return x>0 ? x : -x }

class astar
{
	closed_list = null // table
	nodes       = null // array of astar_node
	heap        = null // binary heap
	targets     = null // array of coord3d's

	boundingbox = null // box containing all the targets

	route       = null // route, reversed: target to start

	constructor()
	{
		closed_list = {}
		heap        = simple_heap_x()
		targets     = []

	}

	function prepare_search()
	{
		closed_list = {}
		nodes       = []
		route       = []
		heap.clear()
		targets     = []
	}

	function add_to_close(c)
	{
		closed_list[ coord3d_to_key(c) ] <- 1
	}

	function test_and_close(c)
	{
		local key = coord3d_to_key(c)
		if (key in closed_list) {
			return false
		}
		else {
			closed_list[ key ] <- 1
			return true
		}
	}

	function is_closed(c)
	{
		local key = coord3d_to_key(c)
		return (key in closed_list)
	}

	function add_to_open(c, weight)
	{
		local i = nodes.len()
		nodes.append(c)
		heap.insert(weight, i)
	}

	function search()
	{
		// compute bounding box of targets
		compute_bounding_box()

		local current_node = null
		while (!heap.is_empty()) {

			local wi = heap.pop()
			current_node = nodes[wi.value]
			local dist = current_node.dist

			// target reached
			if (dist == 0) break;
			// already visited previously
			if (!test_and_close(current_node)) continue;
			// investigate neighbours and put them into open list
			process_node(current_node)

			current_node = null
		}

		route = []
		if (current_node) {
			// found route
			route.append(current_node)

			while (current_node.previous) {
				current_node = current_node.previous
				route.append(current_node)
			}
		}
	}

	function compute_bounding_box()
	{
		if (targets.len()>0) {
			local first = targets[0]
			boundingbox = { xmin = first.x, xmax = first.x, ymin = first.y, ymax = first.y }

			for(local i=1; i < targets.len(); i++) {
				local t = targets[i]
				if (boundingbox.xmin > t.x) boundingbox.xmin = t.x;
				if (boundingbox.xmax < t.x) boundingbox.xmax = t.x;
				if (boundingbox.ymin > t.y) boundingbox.ymin = t.y;
				if (boundingbox.ymax < t.y) boundingbox.ymax = t.y;
			}
		}
	}

	function estimate_distance(c)
	{
		local d = 0

		local t
		t = boundingbox.xmin - c.x; if (t>0) d += t;
		t = c.x - boundingbox.xmax; if (t>0) d += t;
		t = boundingbox.ymin - c.y; if (t>0) d += t;
		t = c.y - boundingbox.ymax; if (t>0) d += t;

		if (d==0) {
			// inside bounding box
			for(local i=1; i < targets.len(); i++) {
				local t = targets[i]
				d = max(d, abs(t.x-c.x) + abs(t.y-c.y) )
			}
		}
		return d
	}

	function coord3d_to_key(c)
	{
		return c.x + ":" + c.y + ":" + c.z;
	}
}

class ab_node extends ::astar_node
{
	dir = 0 // direction to reach this node
	constructor(c, p, co, w, d, di)
	{
		base.constructor(c, p, co, w, d)
		dir = di
	}
}


class astar_builder extends astar
{
	builder = null
	way     = null



	function process_node(cnode)
	{
		local from = tile_x(cnode.x, cnode.y, cnode.z)
		for(local d = 1; d<16; d*=2) {
			local to = from.get_neighbour(wt_all, d)
			if (to  &&  builder.is_allowed_step(from, to)  &&  !is_closed(to)) {
				// estimate moving cost
				local move = ((dir.double(d) & cnode.dir) != 0) ? /* straight */ 14 : /* curve */ 10
				local dist   = 10*estimate_distance(to)
				// is there already a road?
				if (!to.has_way(wt_road)) {
					move += 8
				}

				local cost   = cnode.cost + move
				local weight = cost + dist
				local node = ab_node(to, cnode, cost, weight, dist, d)

				add_to_open(node, weight)
			}
		}
	}

	function search_route(start, end)
	{
		prepare_search()
		targets.append(end)
		compute_bounding_box()

		local dist   = estimate_distance(start)
		add_to_open(ab_node(start, null, 1, dist+1, dist, 0), dist+1)

		search()

		if (route.len() > 0) {
			local w = command_x(tool_build_way);
			w.set_flags(2)

			for (local i = 1; i<route.len(); i++) {
				local err = w.work(our_player, route[i-1], route[i], way.get_name() )
				if (err) {
					label_x.create(node, our_player, "<" + err + ">")
				}
			}
		}
	}
}

