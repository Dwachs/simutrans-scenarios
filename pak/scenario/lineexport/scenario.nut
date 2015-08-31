map.file = "<attach>"

function start()
{
	local player = player_x(0)
	local list = player.get_line_list()
	foreach(line in list) {
		local schedule = line.get_schedule()
		foreach(entry in schedule.entries) {
			local halt = entry.get_halt(player)
			if (halt) {
				print("Line [" + line.get_name() + "] stops at " + halt.get_name() )
			}
		}
		print("----------")
	}
}