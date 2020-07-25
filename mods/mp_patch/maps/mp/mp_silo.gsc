#include maps\mp\_utility;
#include common_scripts\utility; 


//========================================================
//					main
//========================================================
main()
{
	//needs to be first for create fx
	maps\mp\mp_silo_fx::main();
	maps\mp\createart\mp_silo_art::main();
	
	precachemodel("collision_wall_256x256x10");
	
	maps\mp\_load::main();
	
	//	maps\mp\_compass::setupMiniMap("compass_map_mp_silo"); 
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_silo_wager");
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_silo");
	}	
	
	/#
		execdevgui( "devgui_mp_silo" );
	#/

	maps\mp\mp_silo_amb::main();
	
	// If the team nationalites change in this file, you must also update the level's csc file,
	// the level's csv file, and the share/raw/mp/mapsTable.csv
	maps\mp\gametypes\_teamset_urbanspecops::level_init();

	// Set up the default range of the compass
	setdvar( "compassmaxrange","2100" );

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
	maps\mp\gametypes\_spawning::level_use_unified_spawning( true );
	
	level thread crane_container();

	//spawning collision in wager match so players can't hide in the spawned plates
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 || isPregame() )
	{
		spawncollision("collision_wall_256x256x10","collider",(1527, 71, 16), (0, 337, 0));
	}

}


//========================================================
//					cargo_container
//========================================================
crane_container()
{		
	crane_container = GetEnt( "crane_container", "targetname" );
	
	if( !IsDefined( crane_container ) )
	{
		return;
	}

	crane_container thread rotate_crane_container();  
}


//========================================================
//					rotate_crane_container
//========================================================
rotate_crane_container()
{
	rotate_time = 8;
	rotate_angle = 30;
	
	self RotateYaw( rotate_angle / 2, rotate_time / 2 );
	self waittill( "rotatedone" );
		
	while( true )
	{
		rotate_angle = rotate_angle * -1;
		
		self RotateYaw( rotate_angle, rotate_time, rotate_time / 2, rotate_time / 2 );
		self waittill( "rotatedone" );
	}

}