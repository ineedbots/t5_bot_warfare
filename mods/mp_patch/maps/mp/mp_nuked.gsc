#include maps\mp\_utility;
#include common_scripts\utility;

main()
{	
	//needs to be first for create fx
	maps\mp\mp_nuked_fx::main();

	precachemodel("collision_wall_128x128x10");

  // move a dom spawn that is sharing space with one of the mannequins
	move_spawn_point( "mp_dom_spawn", (791, 449, -20), ( 779, 445, -20 ) );

	maps\mp\_load::main();

	maps\mp\mp_nuked_amb::main();
	maps\mp\_compass::setupMiniMap("compass_map_mp_nuked"); 

	level.onSpawnIntermission = ::nuked_intermission;

	/#
		level thread devgui_nuked();
		execdevgui( "devgui_mp_nuked" );
	#/

	// If the team nationalites change in this file,
	// you must update the team nationality in the level's csc file as well!
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
	SetDvar( "scr_spawn_enemy_influencer_radius", 1600 );
	SetDvar( "scr_spawn_dead_friend_influencer_radius", 1300 );
	SetDvar( "scr_spawn_dead_friend_influencer_timeout_seconds", 8 );
	SetDvar( "scr_spawn_dead_friend_influencer_count", 7 );

	//spawn collision in yellow house to prevent players from jump-crouching into a door.
	spawncollision("collision_wall_128x128x10","collider",(769.2, 329.3, 143), (0, 290.6, 0));
	spawncollision("collision_wall_128x128x10","collider",(769.2, 329.3, 271), (0, 290.6, 0));
	
	level.const_fx_exploder_end_game_glass_shatter = 5001;
	level.disableOutroVisionSet = true;

	level thread nuked_mannequin_init();
	nuked_doomsday_clock_init();
	level thread maps\mp\mp_nuked_platform::main();
	
	level thread nuked_population_sign_think();
	level thread nuked_bomb_drop_think();

	/#
		level thread nuked_bomb_drop_dev();
	#/
	
}

move_spawn_point( targetname, start_point, new_point )
{
                spawn_points = getentarray( targetname, "classname" );
                
                for ( i = 0; i < spawn_points.size; i++ )
                {
                                if ( distancesquared( spawn_points[i].origin, start_point ) < 1 )
                                {
                                                spawn_points[i].origin = new_point;
                                                return;
                                }
                }
}

nuked_mannequin_init()
{
	keep_count = 28;
	level.mannequin_count = 0;

	destructibles = GetEntArray( "destructible", "targetname" );
	mannequins = nuked_mannequin_filter( destructibles );

	if ( mannequins.size <= 0 )
	{
		return;
	}

	remove_count = mannequins.size - keep_count;
	remove_count = clamp( remove_count, 0, remove_count );

	mannequins = array_randomize( mannequins );

	for ( i = 0; i < remove_count; i++ )
	{
		assert( IsDefined( mannequins[i].target ) );

		collision = GetEnt( mannequins[i].target, "targetname" );
		assert( IsDefined( collision ) );

		collision delete();
		mannequins[i] delete();
		level.mannequin_count--;
	}

	level waittill( "prematch_over" );
	level.mannequin_time = GetTime();
}

nuked_mannequin_filter( destructibles )
{
	mannequins = [];

	for ( i = 0; i < destructibles.size; i++ )
	{
		destructible = destructibles[i];

		if ( IsSubStr( destructible.destructibledef, "male" ) )
		{
			mannequins[ mannequins.size ] = destructible;
			level.mannequin_count++;
		}
	}

	return mannequins;
}

nuked_intermission()
{
	maps\mp\gametypes\_globallogic_defaults::default_onSpawnIntermission();
	
	if ( wasLastRound() )
	{
		level notify( "bomb_drop" );
	}
}

nuked_bomb_drop_think()
{	
	cameraStart = GetStruct( "endgame_camera_start", "targetname" );
	cameraEnd = GetStruct( cameraStart.target, "targetname" );

	bomb = GetEnt( "nuked_bomb", "targetname" );

	for ( ;; )
	{
		camera = Spawn( "script_model", cameraStart.origin );
		camera.angles = cameraStart.angles;
		camera SetModel( "tag_origin" );

		level waittill( "bomb_drop" );
		
		if( level.finalkillcam && IsDefined(level.lastKillCam ) )
		{
			wait( 0.1 );
			while( level.inFinalKillcam )
			{
				wait( 0.1 );
			}
		}

		for ( i = 0; i < get_players().size; i++ )
		{
			player = get_players()[i];
			player CameraSetPosition( camera );
			player CameraSetLookAt();
			player CameraActivate( true );	
		}

		cam_move_time = set_dvar_float_if_unset( "scr_cam_move_time", "2.5" );
		bomb_explode_delay = set_dvar_float_if_unset( "scr_bomb_explode_delay", "1.5" );
		glass_break_delay = set_dvar_float_if_unset( "scr_glass_break_delay", "0.5" );
		//white_out_delay = set_dvar_float_if_unset( "scr_white_out_delay", "1.0" );

		camera MoveTo( cameraEnd.origin, cam_move_time, 0, 0 );
		camera RotateTo( cameraEnd.angles, cam_move_time, 0, 0 );
		
		bomb playSound ("amb_end_nuke");

		dest = ( bomb.origin[0], bomb.origin[1], bomb.origin[2] - 3700 );

		time = set_dvar_float_if_unset( "scr_bomb_time", "1.5" );
		accel_time = set_dvar_float_if_unset( "scr_bomb_accel_time", ".75" );

		bomb MoveTo( dest, time, accel_time, 0 );
		
		wait( bomb_explode_delay );
		playfx ( level._effect["fx_mp_nuked_nuclear_explosion"], bomb.origin);
		wait( glass_break_delay );
		level thread waitForGlassBreak();
		cameraForward = anglestoforward( cameraEnd.angles );
		explodePoint = cameraEnd.origin + 20*cameraForward;
		//black = ( 0.2, 0.2, 0.2 );	
		//debugstar(explodePoint, 2 * 1000, black);
		physicsExplosionSphere( explodePoint, 128, 128, 1 );
		RadiusDamage( explodePoint, 128, 128, 128 ); 
		//wait( white_out_delay );

		camera thread vibrate();

		//PrintLn( "SND NUKE play" );
		//VisionSetNaked( "flash_grenade", .4 );

		/#
			//bomb waittill( "movedone" );

			wait( 3.5 - glass_break_delay );
			level notify( "bomb_reset" );
			camera delete();
		#/
	}
}

vibrate()
{
	self endon( "death" );
	
	pitchVibrateAmplitude = 1;
	
	vibrateAmplitude = 2;
	vibrateTime = 0.05;
	
	originalAngles = self.angles;
	
	angles0 = ( originalAngles[0], originalAngles[1], originalAngles[2] - vibrateAmplitude );
	angles1 = ( originalAngles[0], originalAngles[1], originalAngles[2] + vibrateAmplitude );
	
	for(;;)
	{
		angles0 = ( originalAngles[0] - pitchVibrateAmplitude , originalAngles[1], originalAngles[2] - vibrateAmplitude );
		angles1 = ( originalAngles[0] + pitchVibrateAmplitude, originalAngles[1], originalAngles[2] + vibrateAmplitude );
		
		self RotateTo(angles0, vibrateTime );
		self waittill( "rotatedone" );
		self RotateTo(angles1, vibrateTime );
		self waittill( "rotatedone" );
		
		if ( vibrateAmplitude > 0 )
			vibrateAmplitude -= 0.25;
		pitchVibrateAmplitude = 0 - pitchVibrateAmplitude;
		pitchVibrateAmplitude *= 0.66;
	}
}
	
waitForGlassBreak()
{
	level endon( "bomb_reset" );
	level waittill( "glass_smash", origin );

	exploder( level.const_fx_exploder_end_game_glass_shatter );	
}

nuked_population_sign_think()
{
	tens_model = GetEnt( "counter_tens", "targetname" );
	ones_model = GetEnt( "counter_ones", "targetname" );

	step = ( 360 / 10 ); // 10 digits (0-9) on the dial

	// put the dials at 0
	ones = 0;
	tens = 0;

	tens_model RotateRoll( step, 0.05 );
	ones_model RotateRoll( step, 0.05 );

	for ( ;; )
	{
		wait( 1 );

		for ( ;; )
		{
			num_players = get_players().size;
			
			dial = ones + ( tens * 10 );

			if ( num_players < dial )
			{
				ones--;
				time = set_dvar_float_if_unset( "scr_dial_rotate_time", "0.5" );

				if ( ones < 0 )
				{
					ones = 9;
					tens_model RotateRoll( 0 - step, time );
					tens--;
				}

				ones_model RotateRoll( 0 - step, time );
				ones_model waittill( "rotatedone" );
			}
			else if ( num_players > dial )
			{
				ones++;
				time = set_dvar_float_if_unset( "scr_dial_rotate_time", "0.5" );

				if ( ones > 9 )
				{
					ones = 0;
					tens_model RotateRoll( step, time );
					tens++;
				}

				ones_model RotateRoll( step, time );
				ones_model waittill( "rotatedone" );
			}
			else
			{
				break;
			}
		}
	}
}

nuked_doomsday_clock_init()
{
	min_hand_model = GetEnt( "clock_min_hand", "targetname" );
	sec_hand_model = GetEnt( "clock_sec_hand", "targetname" );

	start_angle = 318;

	min_hand_model RotatePitch( start_angle, 0.05 );
	min_hand_model waittill( "rotatedone" );

	if ( level.timelimit > 0 )
	{
		min_hand_model RotatePitch( 360 - start_angle, level.timelimit * 60 );
		sec_hand_model RotatePitch( 360 * level.timelimit, level.timelimit * 60 );
	}
	else 
	{
		sec_hand_model thread nuked_doomsday_clock_seconds_think();
	}
}

nuked_doomsday_clock_seconds_think()
{
	for ( ;; )
	{
		self RotatePitch( 360, 60 );
		self waittill( "rotatedone" );
	}
}

/#
nuked_bomb_drop_dev()
{
	bomb = GetEnt( "nuked_bomb", "targetname" );
	bomb_origin = bomb.origin;

	for ( ;; )
	{
		level waittill( "bomb_reset" );
		bomb.origin = bomb_origin;

		player = getHostPlayer();
		player CameraActivate( false );
		VisionSetNaked( "mp_nuked", 0 );
	}
}

devgui_nuked( cmd )
{
	for ( ;; )
	{
		wait( 0.5 );

		devgui_string = GetDvar( #"devgui_notify" );

		switch( devgui_string )
		{
			case "":
			break;

			case "warp_to_bomb":
				player = getHostPlayer();
				AddDebugCommand( "noclip" );
				player SetOrigin( ( 3969, 8094, 1052 ) );
				player SetPlayerAngles( ( -19, 94, 0 ) );
			break;

			default:
				level notify( devgui_string );
			break;
		}

		SetDvar( "devgui_notify", "" );
	}
}
#/