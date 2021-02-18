#include maps\mp\_utility;
main()
{
	//needs to be first for create fx
	maps\mp\mp_crisis_fx::main();
	
	precachemodel("collision_geo_128x128x10");
	
	maps\mp\_load::main();

	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_crisis_wager");
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_crisis");
	}

	//maps\mp\mp_crisis_amb::main();


	// If the team nationalites change in this file,
	// you must update the team nationality in the level's csc file as well!
	maps\mp\gametypes\_teamset_cubans::level_init();

	//setdvar("compassmaxrange","2100");


	// spawn collision to prevent players from seeing through the LVT
	spawncollision("collision_geo_128x128x10","collider",(2891, 1282.5, 72.5), (3.6, 36.48, -1.65));

	// enable new spawning system
	maps\mp\gametypes\_spawning::level_use_unified_spawning(true);
}
