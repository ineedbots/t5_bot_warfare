#include maps\mp\_utility;
main()
{
	//needs to be first for create fx
	maps\mp\mp_cairo_fx::main();

	precachemodel("collision_geo_10x10x512");
	precachemodel("collision_wall_128x128x10");
	
	maps\mp\_load::main();
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_cairo_wager");
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_cairo");
	}

	maps\mp\mp_cairo_amb::main();


	// If the team nationalites change in this file,
	// you must update the team nationality in the level's csc file as well!
	maps\mp\gametypes\_teamset_cubans::level_init();

	//setdvar("compassmaxrange","2100");

	// spawn collision to prevent players from standing inside telephone poles
	spawncollision("collision_geo_10x10x512","collider",(2264, -240, -61), (0, 0, 0));
	spawncollision("collision_geo_10x10x512","collider",(-1437, -529, -61), (0, 0, 0));

	// spawn collision to prevent players from standing on top of a doorway behind the cigar building
	spawncollision("collision_wall_128x128x10","collider",(716, 1181, 219), (0, 270, 0));



	// enable new spawning system
	maps\mp\gametypes\_spawning::level_use_unified_spawning(true);
}
