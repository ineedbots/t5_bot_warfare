init()
{
	level.bot_builtins[ "printconsole" ] = ::do_printconsole;
	level.bot_builtins[ "botmovementoverride" ] = ::do_botmovementoverride;
	level.bot_builtins[ "botclearmovementoverride" ] = ::do_botclearmovementoverride;
	level.bot_builtins[ "botclearbuttonoverride" ] = ::do_botclearbuttonoverride;
	level.bot_builtins[ "botbuttonoverride" ] = ::do_botbuttonoverride;
	level.bot_builtins[ "botclearoverrides" ] = ::do_botclearoverrides;
	level.bot_builtins[ "botmantleoverride" ] = ::do_botmantleoverride;
	level.bot_builtins[ "botclearmantleoverride" ] = ::do_botclearmantleoverride;
	level.bot_builtins[ "botclearweaponoverride" ] = ::do_botclearweaponoverride;
	level.bot_builtins[ "botweaponoverride" ] = ::do_botweaponoverride;
	level.bot_builtins[ "botclearbuttonoverrides" ] = ::do_botclearbuttonoverrides;
	level.bot_builtins[ "botaimoverride" ] = ::do_botaimoverride;
	level.bot_builtins[ "botclearaimoverride" ] = ::do_botclearaimoverride;
	level.bot_builtins[ "botmeleeparams" ] = ::do_botmeleeparams;
	level.bot_builtins[ "clearbotmeleeparams" ] = ::do_clearbotmeleeparams;
}

do_printconsole( s )
{
	println( s );
}

do_botmovementoverride( a, b )
{
	self botmovementoverride( a, b );
}

do_botclearmovementoverride()
{
	self botclearmovementoverride();
}

do_botclearbuttonoverride( a )
{
	self botclearbuttonoverride( a );
}

do_botbuttonoverride( a, b )
{
	self botbuttonoverride( a, b );
}

do_botclearoverrides( a )
{
	self botclearoverrides( a );
}

do_botmantleoverride()
{
	self botmantleoverride();
}

do_botclearmantleoverride()
{
	self botclearmantleoverride();
}

do_botclearweaponoverride()
{
	self botclearweaponoverride();
}

do_botweaponoverride( a )
{
	self botweaponoverride( a );
}

do_botclearbuttonoverrides()
{
	self botclearbuttonoverrides();
}

do_botaimoverride()
{
	self botaimoverride();
}

do_botclearaimoverride()
{
	self botclearaimoverride();
}

do_botmeleeparams( yaw, dist )
{
	self botmeleeparams( yaw, dist );
}

do_clearbotmeleeparams()
{
	self botclearmeleeparams();
}
