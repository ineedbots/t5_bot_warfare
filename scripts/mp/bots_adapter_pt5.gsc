main()
{
	level.bot_builtins[ "printconsole" ] = ::do_printconsole;
	level.bot_builtins[ "botmovementoverride" ] = ::do_botmovementoverride;
	level.bot_builtins[ "botbuttonoverride" ] = ::do_botbuttonoverride;
	level.bot_builtins[ "botclearoverride" ] = ::do_botclearoverride;
	level.bot_builtins[ "botmantleoverride" ] = ::do_botmantleoverride;
	level.bot_builtins[ "botweaponoverride" ] = ::do_botweaponoverride;
	level.bot_builtins[ "botaimoverride" ] = ::do_botaimoverride;
	level.bot_builtins[ "botmeleeparamsoverride" ] = ::do_botmeleeparamsoverride;
	level.bot_builtins[ "replacefunc" ] = ::do_replacefunc;
	level.bot_builtins[ "getfunction" ] = ::do_getfunction;
	level.bot_builtins[ "disabledetouronce" ] = ::do_disabledetouronce;
	maps\mp\gametypes\_bot::main();
}

do_replacefunc( a, b )
{
	return replacefunc( a, b );
}

do_getfunction( a, b )
{
	return getfunction( a, b );
}

do_printconsole( s )
{
	printf( s );
}

do_disabledetouronce( s )
{
	disabledetouronce( s );
}

do_botmovementoverride( a, b )
{
	self botmovementoverride( a, b );
}

do_botclearoverride( a )
{
	self botclearoverride( a );
}

do_botbuttonoverride( a )
{
	self botbuttonoverride( a );
}

do_botmantleoverride( a )
{
	self botmantleoverride( a );
}

do_botweaponoverride( a )
{
	self botweaponoverride( a );
}

do_botaimoverride( a )
{
	self botaimoverride( a );
}

do_botmeleeparamsoverride( yaw, dist )
{
	self botmeleeparamsoverride( yaw, dist );
}
