#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	//needs to be first for create fx
	maps\mp\mp_array_fx::main();

	precachemodel("collision_geo_10x10x512");
	precachemodel("collision_geo_64x64x64");
	precachemodel("collision_wall_64x64x10");
	precachemodel("collision_wall_512x512x10");
	precachemodel("collision_geo_64x64x256");
	precachemodel("p_glo_concrete_barrier_damaged");

	maps\mp\_load::main();
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_array_wager");
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_array");
	}
	
	maps\mp\mp_array_amb::main();

	// If the team nationalites change in this file,
	// you must update the team nationality in the level's csc file as well!
	maps\mp\gametypes\_teamset_winterspecops::level_init();

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


	// collision keeping players from poking their heads into the tree near B3.
	spawncollision("collision_geo_10x10x512","collider",(1397, 1095, 346), (0, 0, 0));
	spawncollision("collision_geo_10x10x512","collider",(1387, 1095, 346), (0, 0, 0));

	// collision to prevent players from jumping behind electrical cabinets and getting stuck
	spawncollision("collision_geo_64x64x64","collider",(-399, 1615, 614), (0, 15, 0));
	spawncollision("collision_wall_64x64x10","collider",(-445, 1593, 642), (0, 150, 0));

	// collision that will keep player from jumping out of the map and landing in the rocks.
	spawncollision("collision_wall_512x512x10","collider",(-1682, 1046, 496), (0, 30, 0));

	// collision to stop players from getting stuck behind the steel girders.
	spawncollision("collision_geo_64x64x64","collider",(-387, 307, 346), (0, 360, 0));

	// spawn collision underneathe the corner of the center building. This is to keep players from calling the RCXD and pushing themselves outside of the map.
	spawncollision("collision_geo_64x64x256","collider",(-852, 852, 496), (0,15,90));
	spawncollision("collision_geo_64x64x256","collider",(-788, 652, 492), (0,15,90));

	// spawn a trigger to keep players from planting turrets into the large tanks.
	addNoTurretTrigger( (-692, 3292, 500), 180, 800 );
	addNoTurretTrigger( (-1236, 3292, 500), 180, 800 );

	// spawn a couple of K Rails to make sense of the collision spawned under the center building.
	kRail1 = Spawn("script_model", (-824, 672, 480) );
	if ( IsDefined(kRail1) )
	{
		kRail1.angles = (0, 105, 0);
		kRail1 SetModel("p_glo_concrete_barrier_damaged");
	}
	
	kRail2 = Spawn("script_model", (-804, 600, 468) );
	if ( IsDefined(kRail2) )
	{
		kRail2.angles = (15, 285, 0);
		kRail2 SetModel("p_glo_concrete_barrier_damaged");
	}
	
	// enable new spawning system
	maps\mp\gametypes\_spawning::level_use_unified_spawning(true);
	
	radar_move_init();
}

radar_move_init()
{
	level endon ("game_ended");
		
	dish_top = GetEnt( "dish_top", "targetname" );  
	dish_base = GetEnt( "dish_base", "targetname" ); 
	dish_inside = GetEnt( "dish_inside", "targetname" );
	dish_gears = GetEntArray( "dish_gear", "targetname");

	total_time_for_rotation_outside = 240;
	total_time_for_rotation_inside = 60;

	dish_top LinkTo(dish_base);
	dish_base thread rotate_dish_top(total_time_for_rotation_outside);
	dish_inside thread rotate_dish_top(total_time_for_rotation_inside);
	
	if(dish_gears.size > 0)
	{
		array_thread(dish_gears, ::rotate_dish_gears, total_time_for_rotation_inside);
	}
}

rotate_dish_top( time )
{
	self endon ("game_ended");

	while(1)
	{
		self RotateYaw( 360, time );
		self waittill( "rotatedone" );
	}
}

rotate_dish_gears( time )
{
	self endon ("game_ended");

	gear_ratio = 5.0 / 60.0;
	inverse_gear_ratio = 1.0 / gear_ratio;
	
	while(1)
	{
		self RotateYaw( 360 * inverse_gear_ratio, time );
		self waittill( "rotatedone" );
	}
}

addNoTurretTrigger( position, radius, height )
{
    while( !IsDefined( level.noTurretPlacementTriggers ) )
		wait( 0.1 );
                    
    trigger = Spawn( "trigger_radius", position, 0, radius, height );
    
    level.noTurretPlacementTriggers[level.noTurretPlacementTriggers.size] = trigger;
}

