class industry_link_t
{
	f_src   = null // factory_x
	f_dest  = null // factory_x
	freight = null // string

	state = 0

	static st_free    = 0 /// not registered
	static st_planned = 1 /// link is planned
	static st_failed  = 2 /// construction failed, do not try again
	static st_built   = 3 /// connection successfully built

	constructor(s,d,f)
	{
		f_src = s
		f_dest = d
		freight = f
	}
}



class industry_manager_t extends manager_t
{
	link_list = null

	constructor()
	{
		link_list = {}
	}

	/// Generate unique key from link data
	static function key(src, des, fre)
	{
		return translate(fre) + "-from-" + src.get_name() + coord_to_string(src)
		                      + "-to-" + des.get_name() + coord_to_string(des)
	}

	function set_link_state(src, des, fre, state)
	{
		local k = key(src, des, fre)

		try {
			link_list.rawget(k).state = state
		}
		catch(ev) {
			// not existing - create entry
			local l = industry_link_t(src, des, fre)
			l.state = state
			link_list.rawset(k, l)
		}
		if (state == industry_link_t.st_built) {
			local text = ""
			text = "Transport " + translate(fre) + " from "
			text += coord(src.x, src.y).href(src.get_name()) + " to "
			text += coord(des.x, des.y).href(des.get_name()) + "<br>"

			info_text += text
		}
	}

	function get_link_state(src, des, fre)
	{
		local k = key(src, des, fre)

		local res
		try {
			res = link_list.rawget(k).state
		}
		catch(ev) {
			res = industry_link_t.st_free
		}
		local toc = get_ops_total()
		return res
	}
}
