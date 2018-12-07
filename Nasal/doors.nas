# McDonnell Douglas DC-10
# Nasal door system
#########################

var Door =
{
	new: func(name, transit_time)
	{
		return aircraft.door.new("sim/model/door-positions/" ~ name, transit_time);
	}
};
var doors =
{
	pax_l1: Door.new("pax-l1", 3),
	cargo_fwd: Door.new("cargo-fwd", 3),
	waterdoors: Door.new("waterdoors", 0.5)
};
