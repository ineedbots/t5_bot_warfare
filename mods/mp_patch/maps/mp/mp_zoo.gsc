#include maps\mp\_utility;
main()
{
	//needs to be first for create fx
	maps\mp\mp_zoo_fx::main();
	
	precachemodel("collision_wall_256x256x10");
	precachemodel("collision_geo_32x32x128");
	precachemodel("collision_geo_128x128x10");
	precachemodel("collision_geo_64x64x64");

	maps\mp\_load::main();

	maps\mp\mp_zoo_amb::main();

//	maps\mp\_compass::setupMiniMap("compass_map_mp_zoo"); 
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_zoo_wager");
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_zoo");
	}	
	

	// If the team nationalites change in this file, you must also update the level's csc file,
	// the level's csv file, and the share/raw/mp/mapsTable.csv
	maps\mp\gametypes\_teamset_urbanspecops::level_init();

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

	// enable new spawning system
	maps\mp\gametypes\_spawning::level_use_unified_spawning(true);

	//spawn gates to explain rogue physics collision brush
	
	gate1 = Spawn("script_model", (1040, 1495, 56) );
	if ( IsDefined(gate1) )
	{
		gate1.angles = (0, 270, 0);
		gate1 SetModel("p_zoo_bend_gate_mid");
	}
	gate2 = Spawn("script_model", (1104, 1495, 56) );
	if ( IsDefined(gate2) )
	{
		gate2.angles = (0, 270, 0);
		gate2 SetModel("p_zoo_bend_gate_mid");
	}
	
	// spawn collision for bit of collision above a light in B3
	spawncollision("collision_wall_256x256x10","collider",(876, 2034, 169), (0, 90, 0));
	
	// spawn collision to stop players from hiding inside the may-pole.
	spawncollision("collision_geo_32x32x128","collider",(49, 832, 66), (0, 0, 0));
	spawncollision("collision_geo_32x32x128","collider",(49, 832, 194), (0, 0, 0));
	
		// spawn collision to stop players from hiding inside the may-pole base.
	spawncollision("collision_geo_64x64x64","collider",(47, 833, -16), (0, 0, 0));
	spawncollision("collision_geo_64x64x64","collider",(47, 833, -16), (0, 315, 0));
	
	// spawn collision to stop players from standing on collision in aviary.
	spawncollision("collision_geo_128x128x10","collider",(934, 205, 74), (28.2, 340.6, -38.4));

	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 || isPregame() )
	{
		spawncollision("collision_wall_256x256x10","collider",(-5, 821, 72), (0, 297, 0));
  }

}
