#include maps\mp\_utility;
main()
{
	//needs to be first for create fx
	maps\mp\mp_villa_fx::main();

	precachemodel("collision_geo_64x64x256");
	precachemodel("collision_geo_32x32x128");
	precachemodel("collision_geo_32x32x32");

	maps\mp\_load::main();

	maps\mp\mp_villa_amb::main();
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_villa_wager"); 
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_villa"); 
	}

	// If the team nationalites change in this file,
	// you must update the team nationality in the level's csc file as well!
	maps\mp\gametypes\_teamset_cubans::level_init();

	// Set up the default range of the compass
	setdvar("compassmaxrange","2100");

	// Set up some generic War Flag Names.
	// Example from COD5: CALLSIGN_SEELOW_A is the name of the 1st flag in Selow whose string is "Cottage" 
	// The string must have MPUI_CALLSIGN_ and _A. Replace Mapname with the name of your map/bsp and in the 
	// actual string enter a keyword that names the location (Roundhouse, Missle Silo, Launchpad, Guard Tower, etc)

	game["strings"]["war_callsign_a"] = &"MPUI_CALLSIGN_MAPNAME_A";
	game["strings"]["war_callsign_b"] = &"MPUI_CALLSIGN_MAPNAME_B";
	game["strings"]["war_callsign_c"] = &"MPUI_CALLSIGN_MAPNAME_C";
	game["strings"]["war_callsign_d"] = &"MPUI_CALLSIGN_MAPNAME_D";
	game["strings"]["war_callsign_e"] = &"MPUI_CALLSIGN_MAPNAME_E";

	game["strings_menu"]["war_callsign_a"] = "@MPUI_CALLSIGN_MAPNAME_A";
	game["strings_menu"]["war_callsign_b"] = "@MPUI_CALLSIGN_MAPNAME_B";
	game["strings_menu"]["war_callsign_c"] = "@MPUI_CALLSIGN_MAPNAME_C";
	game["strings_menu"]["war_callsign_d"] = "@MPUI_CALLSIGN_MAPNAME_D";
	game["strings_menu"]["war_callsign_e"] = "@MPUI_CALLSIGN_MAPNAME_E";

	// collision keeping players from poking their heads into rock
	spawncollision("collision_geo_64x64x256","collider",(4790, 1863, 388), (0, 30.8, 0));

	// collision keeping players from poking their heads into another rock near the allies spawn
	spawncollision("collision_geo_32x32x128","collider",(4329, 3735, 144), (0, 0, 0));

	// collision keeping players from poking their heads into another rock near D2.
	spawncollision("collision_geo_32x32x32","collider",(2512, 3818, 113), (0, 45, 0));


	// enable new spawning system
	maps\mp\gametypes\_spawning::level_use_unified_spawning(true);
	
	level thread startLightning();
}



startLightning()
{
	while(1)
	{
		self thread trigger_lightning_exploder();
		wait( 30 + randomfloat(40) );	
		//wait (4);

	}
}



trigger_lightning_exploder()
{	
	randomExploder = randomint( 4 );	
	//randomExploder = 3;		
	switch( randomExploder )
	{
		case 0:
		exploder(1001);
		playsoundatposition("amb_thunder_clap",( 259.2, -801, 1197 ));			
		//println ("sound exploder 1");
		break;
		case 1:
		exploder(1002);
		playsoundatposition("amb_thunder_clap",( 2523, -17012, 1174 ));				
		//println ("sound exploder 2");		
		break;
		case 2:
		exploder(1003);
		playsoundatposition("amb_thunder_clap",(6457, -611, 1145));		
		//println ("sound exploder 3");					
		break;
		case 3:
		exploder(1004);
		playsoundatposition("amb_thunder_clap",(4981, 1335, 890));		
		//println ("sound exploder 4");					
		break;
	}
}
