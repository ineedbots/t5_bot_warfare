init()
{
	level.bot_builtins["printconsole"] = ::do_printconsole;
	level.bot_builtins["botmovementoverride"] = ::do_botmovementoverride;
	level.bot_builtins["botclearmovementoverride"] = ::do_botclearmovementoverride;
	level.bot_builtins["botclearbuttonoverride"] = ::do_botclearbuttonoverride;
	level.bot_builtins["botbuttonoverride"] = ::do_botbuttonoverride;
	level.bot_builtins["botclearoverrides"] = ::do_botclearoverrides;
	level.bot_builtins["botmantleoverride"] = ::do_botmantleoverride;
	level.bot_builtins["botclearmantleoverride"] = ::do_botclearmantleoverride;
	level.bot_builtins["botclearweaponoverride"] = ::do_botclearweaponoverride;
	level.bot_builtins["botweaponoverride"] = ::do_botweaponoverride;
	level.bot_builtins["botclearbuttonoverrides"] = ::do_botclearbuttonoverrides;
	level.bot_builtins["botaimoverride"] = ::do_botaimoverride;
	level.bot_builtins["botclearaimoverride"] = ::do_botclearaimoverride;
	level.bot_builtins["botmeleeparams"] = ::do_botmeleeparams;
}

do_printconsole( s )
{
	PrintLn( s );
}

do_botmovementoverride( a, b )
{
	self botMovementOverride( a, b );
}

do_botclearmovementoverride()
{
	self botClearMovementOverride();
}

do_botclearbuttonoverride( a )
{
	self botClearButtonOverride( a );
}

do_botbuttonoverride( a, b )
{
	self botButtonOverride( a, b );
}

do_botclearoverrides( a )
{
	self botClearOverrides( a );
}

do_botmantleoverride()
{
	self botMantleOverride();
}

do_botclearmantleoverride()
{
	self botClearMantleOverride();
}

do_botclearweaponoverride()
{
	self botClearWeaponOverride();
}

do_botweaponoverride( a )
{
	self botWeaponOverride( a );
}

do_botclearbuttonoverrides()
{
	self botClearButtonOverrides();
}

do_botaimoverride()
{
	self botAimOverride();
}

do_botclearaimoverride()
{
	self botClearAimOverride();
}

do_botmeleeparams( yaw, dist )
{
	// self botMeleeParams( yaw, dist );
}
