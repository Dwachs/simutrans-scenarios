
function abs(a) { return a >= 0 ? a : -a }


class industry_connection_planner_t extends node_t
{
	fsrc = null
	fdest = null
	freight = null

	// planned stuff
	planned_way = null
	planned_station = null
	planned_depot = null
	planned_convoy = null
	plan_report = null

	constructor(s,d,f) { base.constructor("industry_connection_planner"); fsrc = s; fdest = d; freight = f; }

	function step()
	{
		debug = true
		local tic = get_ops_total();

		dbgprint("Plan link for " + freight + " from " + fsrc.get_name() + " at " + fsrc.x + "," + fsrc.y + " to "+ fdest.get_name() + " at " + fdest.x + "," + fdest.y)

		// TODO check if factories are still existing
		// TODO check if connection is plannable

		// compute monthly production
		local prod = calc_production()
		dbgprint("production = " + prod);

		// plan convoy prototype
		local prototyper = prototyper_t(wt_road, freight)

		prototyper.max_vehicles = 4
		prototyper.min_speed = 1
		prototyper.max_length = 1

		local cnv_valuator = valuator_simple_t()
		cnv_valuator.wt = wt_road
		cnv_valuator.freight = freight
		cnv_valuator.volume = prod
		cnv_valuator.max_cnvs = 200
		cnv_valuator.distance = abs(fsrc.x-fdest.x) + abs(fsrc.y-fdest.y)

		local bound_valuator = valuator_simple_t.valuate_monthly_transport.bindenv(cnv_valuator)
		prototyper.valuate = bound_valuator

		if (planned_convoy == null) {
			if (prototyper.step().has_failed()) {
				return r_t(RT_ERROR)
			}

			planned_convoy = prototyper.best
		}

		// fill in report when best way is found
		local r = report_t()
		// plan way
		if (planned_way == null) {
			local way_list = way_desc_x.get_available_ways(wt_road, st_flat)
			local best_way = null
			local best = null

			foreach(way in way_list) {
				cnv_valuator.way_maintenance = way.get_maintenance()
				cnv_valuator.way_max_speed   = way.get_topspeed()

				local test = cnv_valuator.valuate_monthly_transport(planned_convoy)
				if (best == null  ||  test > best) {
					best = test
					best_way = way
				}
			}
			dbgprint("Best value = " + best + " way = " + best_way.get_name())

			// valuate again with best way
			cnv_valuator.way_maintenance = 0
			cnv_valuator.way_max_speed   = best_way.get_topspeed()

			r.gain_per_m  = cnv_valuator.valuate_monthly_transport(planned_convoy)
			r.nr_convoys = planned_convoy.nr_convoys

			planned_way = best_way
		}


		// plan station
		if (planned_station == null) {
			local station_list = building_desc_x.get_available_stations(building_desc_x.station, wt_road, good_desc_x(freight))

			if (station_list.len()) {
				planned_station = station_list[0]
			}
		}
		// plan depot
		if (planned_depot == null) {
			local depot_list = building_desc_x.get_available_stations(building_desc_x.depot, wt_road, good_desc_x(freight))

			if (depot_list.len()) {
				planned_depot = depot_list[0]
			}
		}

		if (planned_convoy == null  ||  planned_way == null || planned_station == null || planned_depot == null) {
			return r_t(RT_ERROR)
		}

		// successfull - complete report
		r.cost_fix     = cnv_valuator.distance * planned_way.get_cost() + 2*planned_station.get_cost() + planned_depot.get_cost()
		r.cost_monthly = cnv_valuator.distance * planned_way.get_maintenance() + 2*planned_station.get_maintenance() + planned_depot.get_maintenance()
		r.gain_per_m  -= r.cost_monthly

		// create action node
		local cn = road_connector_t()
		cn.fsrc = fsrc
		cn.fdest = fdest
		cn.freight = freight
		cn.planned_way = planned_way
		cn.planned_station = planned_station
		cn.planned_depot = planned_depot
		cn.planned_convoy = planned_convoy

		r.action = cn

		// that's the report
		plan_report = r

		dbgprint("Plan: way = " + planned_way.get_name() + ", station = " + planned_station.get_name() + ", depot = " + planned_depot.get_name());
		dbgprint("Report: gain_per_m  = " + r.gain_per_m + ", nr_convoys  = " + r.nr_convoys + ", cost_fix  = " + r.cost_fix + ", cost_monthly  = " + r.cost_monthly)

		// deliver it
		local r = r_t(RT_READY)
		r.report = plan_report

		local toc = get_ops_total();
		print("industry_connection_planner wasted " + (toc-tic) + " ops")
		return r
	}


	function calc_production()
	{
		local src_prod = fsrc.output.rawget(freight).get_base_production();
		local dest_con = fdest.input.rawget(freight).get_base_consumption();

		dbgprint("production = " + src_prod + " / " + dest_con);
		return min(src_prod,dest_con)
	}
}