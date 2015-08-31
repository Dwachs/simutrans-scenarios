class factorysearcher_t extends manager_t
{
	fsrc = null
	fdest = null
	freight = null
	froot = null

	constructor()
	{
		base.constructor("factorysearcher")
		debug = false
	}

	// TODO cache forbidden etc connections
	function work()
	{
		if (fsrc) return r_t(RT_READY)

		// find factory with incomplete connected tree
		local min_mfc = 10000;
		local list = factory_list_x()
		foreach(fab in list) {
			if (fab.output.len() == 0) {

				local n = count_missing_factories(fab)
				dbgprint("Consumer " + fab.get_name() + " at " + fab.x + "," + fab.y + " has " + n + " missing links")

				if ((n > 0)  &&  (n < min_mfc)) {
					// TODO add some random here
					n = min_mfc
					froot = fab
				}
			}
		}

		// nothing found??
		if (froot==null) return r_t(RT_DONE_NOTHING);

		dbgprint("Connect  " + froot.get_name() + " at " + froot.x + "," + froot.y)

		// find link to connect
		if (find_missing_link(froot)) {
			dbgprint("Close link for " + freight + " from " + fsrc.get_name() + " at " + fsrc.x + "," + fsrc.y + " to "+ fdest.get_name() + " at " + fdest.x + "," + fdest.y)

			local icp = industry_connection_planner_t(fsrc, fdest, freight);
			append_child(icp)
		}
		return r_t(RT_PARTIAL_SUCCESS);
	}

	/**
	 * @returns -1 if factory tree is incomplete, otherwise number of missing connections
	 */
	// TODO cache the results per factory
	static function count_missing_factories(fab)
	{
		// source of raw material?
		if (fab.input.len() == 0) return 0;

		// build list of supplying factories
		local suppliers = [];
		foreach(c in fab.get_suppliers()) {
			suppliers.append( factory_x(c.x, c.y) );
		}

		local count = 0;
		// iterate all input goods and search for supply
		foreach(good, islot in fab.input) {
			// test for in-storage or in-transit goods
			local st = islot.get_storage()
			local it = islot.get_in_transit()
			if (st[0] + st[1] + it[0] + it[1] > 0) {
				// something stored/in-transit in last and current month
				// no need to search for more supply
				continue
			}

			local g_complete = false;
			// minimum of missing links for one input good
			local g_count    = 100000;
			foreach(s in suppliers) {
				if (good in s.output) {
					local n = count_missing_factories(s);
					if ( n<0) {
						// incomplete
					}
					else {
						// complete
						g_complete = true;
						if (n<g_count) {
							g_count = n;
						}
					}
				}
			}

			if (!g_complete) {
				// no suppliers for this good
				return -1
			}
			count += g_count+1
		}
		dbgprint("Factory " + fab.get_name() + " at " + fab.x + "," + fab.y + " has " + count + " missing links")
		return count
	}

	/**
	 * find link to connect in tree of factory @p fab.
	 * sets fsrc, fdest, lgood if true was returned
	 * @returns true if link is found
	 */
	function find_missing_link(fab)
	{
		dbgprint("Missing link for factory " + fab.get_name() + " at " + fab.x + "," + fab.y)
		// source of raw material?
		if (fab.input.len() == 0) return false;

		// build list of supplying factories
		local suppliers = [];
		foreach(c in fab.get_suppliers()) {
			suppliers.append( factory_x(c.x, c.y) );
		}

		local count = 0;
		// iterate all input goods and search for supply
		foreach(good, islot in fab.input) {
			// check for current supply
			if ( 4*(islot.get_storage()[0] + islot.get_in_transit()[0]) > islot.max_storage) {
				continue
			}
			// find suitable supplier
			foreach(s in suppliers) {
				local oslot = null
				try {
					oslot = s.output.rawget(good)
				}
				catch(ev) {
					// this good is not produced
					continue
				}

				dbgprint("Factory " + s.get_name() + " at " + s.x + "," + s.y + " supplies " + good)

				if (s.input.len()>0  &&  ( 8*oslot.get_storage()[0] < oslot.max_storage ) ) {
					// better try to complete this link
					if (find_missing_link(s)) return true;
				}
				// this is our link
				fsrc = s
				fdest = fab
				freight = good
				return true
			}
		}
		return false // all links are connected
	}
}
