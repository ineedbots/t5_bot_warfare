#include maps\mp\_utility;
#include common_scripts\utility; 
#include maps\mp\_events;

main()
{
	precachemodel("tag_origin");

	level.onSpawnIntermission = ::cosmodrome_intermission;

	/#
		level thread devgui_cosmodrome();
		execdevgui( "devgui_mp_cosmodrome" );
	#/
	
	//needs to be first for create fx
	maps\mp\mp_cosmodrome_fx::main();

	precachemodel("collision_wall_128x128x10");
	precachemodel("collision_geo_128x128x128");
	precachemodel("collision_wall_512x512x10");
  precachemodel("collision_geo_mc_8x560x190");
  precachemodel("collision_geo_mc_4x52x190");
  precachemodel("collision_geo_mc_4x156x190");

	maps\mp\_load::main();
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_cosmodrome_wager"); 
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_cosmodrome"); 
	}
	maps\mp\mp_cosmodrome_amb::main();

	// If the team nationalites change in this file,
	// you must update the team nationality in the level's csc file as well!
	maps\mp\gametypes\_teamset_urbanspecops::level_init();
	
	level thread rocket_arm_think();
	level thread rocket_think();
	level thread radar_dish_think();
	level thread distant_rockets_think();

	// spawn collision to prevent players from sneaking under a small area by the rocket
	spawncollision("collision_wall_128x128x10","collider",(1558, -179, -362), (0, 225, 0));

	// spawn collision to prevent players from sneaking inside 2 vents
	spawncollision("collision_wall_128x128x10","collider",(-699, 1457, -60), (0, 270, 0));
	spawncollision("collision_wall_128x128x10","collider",(-699, 1329, -60), (0, 270, 0));

	// spawn collision to prevent players from strafe jumping onto pipes.
	spawncollision("collision_geo_128x128x128","collider",(1408.5, 863, -126.5), (0, 0, 0));
	spawncollision("collision_geo_128x128x128","collider",(1536.5, 863, -126.5), (0, 0, 0));

	// spawn collision to prevent players from jumping up onto walls by the rocket
	spawncollision("collision_wall_512x512x10","collider",(1224, -160, 240), (0, 0, 0));
	spawncollision("collision_wall_512x512x10","collider",(1348, -160, 240), (0, 0, 0));

	// Spawn collision to keep players from walking onto a small ledge of collision on the green girders.
	spawncollision("collision_wall_128x128x10","collider",(1911, 1018, -82), (0, 270, 0));
	
	// not sure if this is the best way to determine that the map has been trimmed down
	if ( isSmallMapVersion() )
	{
	  //spawning missile clip collision to catch grenades, rockets and crossbow bolts on the wager match boundary
	  spawncollision("collision_geo_mc_8x560x190","collider",(-393, 396.5, -72), (0, 270, 0));
	  spawncollision("collision_geo_mc_4x52x190","collider",(-358, 676.5, -74), (0, 0, 0));
	  spawncollision("collision_geo_mc_4x156x190","collider",(-328.5, 758, -74), (0, 270, 0));
	}
	
	// enable new spawning system
	maps\mp\gametypes\_spawning::level_use_unified_spawning(true);
	
	SetDvar( "scr_spawn_enemy_influencer_radius", 1700 );
	SetDvar( "scr_spawn_dead_friend_influencer_radius", 1300 );
	SetDvar( "scr_spawn_dead_friend_influencer_timeout_seconds", 10 );
	SetDvar( "scr_spawn_dead_friend_influencer_count", 7 );
}

isSmallMapVersion()
{
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		return true;
	}
	
	gametype = getDvar( #"g_gametype" );
	if (  gametype == "oic" )
		return true;
		
	if (  gametype == "hlnd" )
		return true;
		
	if (  gametype == "shrp" )
		return true;
		
	if (  gametype == "gun" )
		return true;
		
	return false;
}

cosmodrome_intermission()
{
	maps\mp\gametypes\_globallogic_defaults::default_onSpawnIntermission();

	rocket_base = GetEnt( "cosmodrome_rocket_base", "script_noteworthy" );

	if ( !IsDefined( rocket_base ) )
	{
		return;
	}

	if ( IsDefined( level.rocket_camera ) && level.rocket_camera == true )
	{
		lookat = Spawn( "script_model", rocket_base.origin + ( 0, 0, 1024 ) );
		lookat SetModel( "tag_origin" );
		lookat LinkTo( rocket_base );
		
		self CameraSetPosition( self.origin );
		self CameraSetLookAt( lookat );
		self CameraActivate( true );	
	}
}

rocket_arm_think()
{
	start_pitch = set_dvar_int_if_unset( "scr_rocket_arm_pitch", "90" );
	rotate_time = set_dvar_int_if_unset( "scr_rocket_arm_rotate_secs", "30" );
	wait_time = set_dvar_int_if_unset( "scr_rocket_arm_wait_secs", "5" );
	
	arm_base = GetEnt( "cosmodrome_rocket_arm_base", "targetname" );
	AssertEx( IsDefined( arm_base ), "Unable to find entity with targetname: 'cosmodrome_rocket_arm_base'" );
	
	arm = GetEntArray( "cosmodrome_rocket_arm", "targetname" );
	AssertEx( IsDefined( arm ), "Unable to find entity with targetname: 'cosmodrome_rocket_arm'" );

	for ( i = 0; i < arm.size; i++ )
	{
		arm[i] LinkTo( arm_base );
	}

	if ( !IsDefined( arm_base.angles_target ) )
	{
		arm_base.angles_target = arm_base.angles;
	}
	
	arm_base.angles = ( start_pitch, arm_base.angles[1], arm_base.angles[2] );
	//IPrintLnBold ("rocket is MOVING?"); 
	
	wait ( wait_time );
	
	//IPrintLnBold ("start arm sound"); 
	arm_base playloopsound("evt_rocket_lp",.2);
	arm_base PlaySound ("evt_rocket_start");
	arm_base RotateTo( arm_base.angles_target, rotate_time );
	
	
	wait(rotate_time);
	arm_base stoploopsound(.3);
	arm_base PlaySound ("evt_rocket_end");
	//	IPrintLnBold (rotate_time); 
	// stop loppsound with fade
	// play oneshot attach
	// stop loop sound
}

rocket_prelaunch( rocket_base )
{
	//this will play vo for countdown and delay the launch by 10 seconds
	snd_countdown ();

	// move the claw arms away from the rocket
	claw_r = GetEntArray("claw_r", "targetname");
	claw_l = GetEntArray("claw_l", "targetname");
	claw_arm_r = GetEntArray("claw_arm_r", "targetname");
	claw_arm_l = GetEntArray("claw_arm_l", "targetname");
	mover_r = GetEnt("claw_r_mover", "targetname");
	mover_l = GetEnt("claw_l_mover", "targetname");
	move_here_r = GetEnt("claw_r_move_here", "targetname");
	move_here_l = GetEnt("claw_l_move_here", "targetname");

	for(i = 0 ; i < claw_r.size; i++)
	{
		claw_r[i] LinkTo(mover_r);
	}
	for(i = 0 ; i < claw_l.size; i++)
	{
		claw_l[i] LinkTo(mover_l);
	}
	mover_r MoveTo(move_here_r.origin, 3.0);
	mover_l MoveTo(move_here_l.origin, 3.0);
	
	// play sound on the arms  
	thread snd_rocket_gantry ( mover_r, mover_l);
	
	wait(4.0);
	for(i = 0; i < claw_r.size; i++)
	{
		claw_r[i] Unlink();
		claw_r[i] LinkTo(move_here_r);
	}
	for(i = 0; i < claw_l.size; i++)
	{
		claw_l[i] Unlink();
		claw_l[i] LinkTo(move_here_l);
	}

	for(i = 0; i < claw_arm_r.size; i++)
	{
		claw_arm_r[i] LinkTo(move_here_r);
	}
	for(i = 0; i < claw_arm_l.size; i++)
	{
		claw_arm_l[i] LinkTo(move_here_l);
	}
	move_here_r RotateYaw(75, 3.0);
	move_here_l RotateYaw(-75, 3.0);

	// wait to launch
	rocket_base playsound ("evt_cosmo_launch");	
	playsoundatposition("evt_cosmo_air_distf",(0,0,0));
	playsoundatposition("evt_cosmo_air_distr",(0,0,0));	
	
	wait(5);
}

Rocket_Think()
{		
	level.const_fx_exploder_rocket_coolant = 2;
	
	level.rocket_camera = false;
	flag_init( "rocket_launch_grenade_detonate" );
	
	rocket = GetEntArray( "cosmodrome_rocket", "targetname" );
	AssertEx( IsDefined( rocket ), "Unable to find entity with targetname: 'cosmodrome_rocket'" );
	array_thread( rocket, ::rocket_sticky_grenade_think );

	rocket_base = GetEnt( "cosmodrome_rocket_base", "script_noteworthy" );
	AssertEx( IsDefined( rocket_base ), "Unable to find entity with script_noteworthy: 'cosmodrome_rocket_base'" );
	level.rocket_base = rocket_base;
	
	rocket_damage_triggers = GetEntArray( "cosmodrome_rocket_damage_trigger", "targetname" );
	rocket_collision = GetEntArray( "rocket_collision", "targetname" );
	
	killCamEnt = spawn( "script_model", rocket_base.origin );
	rocket_base.killCamEnt = killCamEnt;
	killCamEnt.startTime = gettime();
	killCamEnt linkTo( rocket_base, "tag_origin", (50,0,-1000), ( 0,0,0 ) );


	rocket_timer_init();

	wait( 3 );
	exploder( level.const_fx_exploder_rocket_coolant );

	event = level waittill_any_return( "rocket_launch", "rocket_launch_skip_prelaunch" );

	if ( event == "rocket_launch" )
	{
		rocket_prelaunch( rocket_base );
	}

	level.rocket_camera = true;

	// pre-launch fx 
	earthquake_origin = rocket_base GetTagOrigin( "tag_engine" );
	earthquake( .25, 4, earthquake_origin, 4096 );

	//play 3d launch aounds on rocket_base, and 2 st 2d sounds

	
	wait( 3.5 );
	flag_set( "rocket_launch_grenade_detonate" );

	// launch fx
	earthquake( .35, 15, earthquake_origin, 4096 );
	array_thread( rocket_damage_triggers, ::rocket_damage_think );
	array_thread( rocket_damage_triggers, ::destroy_greandes_in_trigger );
	rocket_base SetClientFlag( level.const_flag_rocket_fx );
	exploder_stop( level.const_fx_exploder_rocket_coolant );

	// move pieces
	array_thread( rocket, ::rocket_move );

	// stop damage
	wait( 6 );
	level notify( "rocket_damage_stop" );

	wait( 2 );
	level.rocket_camera = false;

	for ( i = 0; i < rocket_damage_triggers.size; i++ )
	{
		rocket_damage_triggers[i] delete();
	}

	for ( i = 0; i < rocket_collision.size; i++ )
	{
		rocket_collision[i] delete();
	}
}

snd_rocket_gantry ( orignr, originl)
{
	orignr playsound ("evt_gantry_disengage");
	orignr playsound ("evt_rocket_start");
//	originl playsound ("evt_rocket_start");
}	
snd_countdown()
{
 	//wait 2;
 	countdownl = spawn("script_origin", (480, -1256, 224));
 	countdownr = spawn("script_origin", (152, 1488, 224));				
 	
 	clientnotify ( "snd_rocket_launch" );
 		
 	
	 if( IsDefined(countdownl)&& IsDefined(countdownr) )
	 	{	
	 		countdownl playsound( "vox_mp_com_1a_rua1" );
	 		wait .112;
			countdownr playsound( "vox_mp_com_1a_rua1" );
	 		wait 16.5;
	 		
	 		thread snd_launch ();
	 		

		}
}
snd_launch ()
{
 		countdownl = spawn("script_origin", (480, -1256, 224));
 		countdownr = spawn("script_origin", (152, 1488, 224));	
 		wait 2;
 		countdownl playsound( "vox_mp_com_2a_rua1" );
 		wait .112;
 		countdownr playsound( "vox_mp_com_2a_rua1" );
	
}
rocket_sticky_grenade_think()
{
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "grenade_stuck", grenade_ent );
		grenade_ent thread sticky_grenade_think();
	}
}

sticky_grenade_think()
{
	self endon( "death" );
	level endon( "rocket_damage_stop" );
	
	flag_wait( "rocket_launch_grenade_detonate" );
	wait( 0.05 );

	self Detonate();
}

//Self is the trigger. This loops to make sure any grenade or claymore that's touching the damage trigger explodes.
destroy_greandes_in_trigger()
{
	self endon( "death" );
	level endon( "rocket_damage_stop" );
	
	flag_wait( "rocket_launch_grenade_detonate" );
	
	for( ;; )
	{
		grenades = GetEntArray( "grenade", "classname" );
		
		for ( i = 0; i < grenades.size; i++ )
		{
			if( grenades[i] IsTouching( self ))
			{
				grenades[i] Detonate();
			}
			
		}
	
		wait 1;
	}
}

rocket_timer_init()
{
	level waittill( "prematch_over" );

	event = set_dvar_if_unset( "scr_rocket_event", "end" );
	trigger1 = set_dvar_int_if_unset( "scr_rocket_event_trigger1", "0" );
	trigger2 = set_dvar_int_if_unset( "scr_rocket_event_trigger2", "0" );

	if ( rocket_launch_abort() )
	{
		return;
	}

	switch ( event )
	{
		case "end":
			add_timed_event( 0, "rocket_launch" );
			add_score_event( level.scorelimit, "rocket_launch" );
			// AE 11-2-09: putting in the distant rocket timing
			add_score_event( int(level.scorelimit * 0.5), "distant_rocket_launch" );
			break;

		case "time":
			assert( trigger1 >= 0 );
			add_timed_event( trigger1, "rocket_launch" );
			// AE 11-2-09: putting in the distant rocket timing
			add_timed_event( int(trigger1 * 0.5), "distant_rocket_launch" );
			break;
			
		case "percent":
			assert( trigger1 >= 0 );
			assert( trigger1 <= 100 );

			minutes = ( trigger1 * 0.01 ) * level.timelimit;
			add_timed_event( minutes * 60, "rocket_launch" );
			// AE 11-2-09: putting in the distant rocket timing
			add_timed_event( int(minutes * 60 * 0.5), "distant_rocket_launch" );

			score = ( trigger1 * 0.01 ) * level.scorelimit;
			add_score_event( score, "rocket_launch" );
			// AE 11-2-09: putting in the distant rocket timing
			add_score_event( int(score * 0.5), "distant_rocket_launch" );
			break;

		case "random_time":
			assert( trigger1 >= 0 );
			assert( trigger2 >= 0 );
			assert( trigger1 < trigger2 );

			time = RandomIntRange( trigger1, trigger2 + 1 );
			add_timed_event( trigger1, "rocket_launch" );
			// AE 11-2-09: putting in the distant rocket timing
			add_timed_event( int(trigger1 * 0.5), "distant_rocket_launch" );
			break;

		case "random_percent":
			assert( trigger1 >= 0 );
			assert( trigger1 <= 100 );
			assert( trigger2 >= 0 );
			assert( trigger2 <= 100 );
			assert( trigger1 < trigger2 );

			percent = RandomIntRange( trigger1, trigger2 + 1 );
			minutes = ( percent * 0.01 ) * level.timelimit;
			add_timed_event( minutes * 60, "rocket_launch" );
			// AE 11-2-09: putting in the distant rocket timing
			add_timed_event( int(minutes * 60 * 0.5), "distant_rocket_launch" );

			percent = RandomIntRange( trigger1, trigger2 + 1 );
			score = ( percent * 0.01 ) * level.scorelimit;
			add_score_event( score, "rocket_launch" );
			// AE 11-2-09: putting in the distant rocket timing
			add_score_event( int(score * 0.5), "distant_rocket_launch" );
			break;

		default:
			error( "Unknown event type: '" + event + "' used in dvar 'scr_rocket_event'" );
			break;
	}
}

rocket_launch_abort()
{
	launch_abort = set_dvar_int_if_unset( "scr_rocket_event_off", "0" );
	assert( launch_abort >= 0 );
	assert( launch_abort <= 100 );

	if ( RandomInt( 101 ) < launch_abort )
	{
		return true;
	}

	return false;
}

rocket_move()
{
	self MoveTo( self.origin + ( 0, 0, 50000 ), 50, 45 );

	self waittill( "movedone" );
	self delete();
}

rocket_damage_think()
{
	level endon( "rocket_damage_stop" );
	damage_interval_secs = 1;

	assert( self.classname == "trigger_radius" );

/#
	if ( set_dvar_int_if_unset( "scr_rocket_debug", "0" ) != 0 )
	{
		drawcylinder( self.origin, self.radius, self.height, undefined, "rocket_damage_stop" );
	}
#/

	for( ;; )
	{
		self waittill( "trigger", ent );
		
		if(IsPlayer(ent))
		{
			player = ent;
			
			if ( player.sessionstate != "playing" )
			{
				continue;
			}
	
			if ( !IsDefined( player.rocket_damage_time ) ) 
			{
				player.rocket_damage_time = GetTime();
			}
	
			if ( player.rocket_damage_time > GetTime() )
			{
				continue;
			}
	
			player shellshock( "tabun_gas_mp", damage_interval_secs );
			player.rocket_damage_time = GetTime() + ( damage_interval_secs * 1000 );
			player DoDamage( RandomIntRange( 40, 60 ), self.origin, self, level.rocket_base, 0, "MOD_SUICIDE" );
		}
		//This kill dogs in the radius trigger
		else if ( IsAI( ent ))
		{
			ent DoDamage( ent.health * 2, ent.origin);
		}
		//This kills RC bombs in the radius trigger
		else if(IsDefined( ent.targetname ) && ent.targetname == "rcbomb" )
		{		
			//Destroy RC bomb
			ent maps\mp\_rcbomb::rcbomb_force_explode();
		}		
	}
}

radar_dish_think()
{
	radar_dish = GetEnt( "cosmodrome_radar_dish", "targetname" );
	AssertEx( IsDefined( radar_dish ), "Unable to find entity with targetname: 'cosmodrome_radar_dish'" );

	for ( ;; )
	{
		rotate_time = set_dvar_int_if_unset( "scr_radar_dish_rotate_secs", "30" );

		if ( rotate_time <= 0 )
		{
			return;
		}

		radar_dish RotateYaw( 360, rotate_time );
		radar_dish waittill( "rotatedone" );
	}

}

devgui_cosmodrome( cmd )
{
	for ( ;; )
	{
		wait( 0.5 );

		devgui_string = GetDvar( #"devgui_notify" );

		switch( devgui_string )
		{
			case "":
			break;

			case "rocket_arm":
				SetDvar( "scr_rocket_arm_wait_secs", "0" );
				level thread rocket_arm_think();
			break;

			default:
				level notify( devgui_string );
			break;
		}

		SetDvar( "devgui_notify", "" );
	}
}

distant_rockets_think()
{
	// have the rockets in the distance going off

	distant_rocket = GetEntArray( "distant_rocket", "targetname" );
	AssertEx( IsDefined( distant_rocket ), "Unable to find entity with targetname: 'distant_rocket'" );

	distant_rocket_gantry1 = GetEntArray("distant_rocket_gantry1", "targetname");
	AssertEx( IsDefined( distant_rocket_gantry1 ), "Unable to find entity with targetname: 'distant_rocket_gantry1'" );
	distant_rocket_gantry2 = GetEntArray("distant_rocket_gantry2", "targetname");
	AssertEx( IsDefined( distant_rocket_gantry2 ), "Unable to find entity with targetname: 'distant_rocket_gantry2'" );

	distant_rocket_arm1 = GetEntArray( "distant_rocket_arm1", "targetname" );
	AssertEx( IsDefined( distant_rocket_arm1 ), "Unable to find entity with targetname: 'distant_rocket_arm1'" );
	distant_rocket_arm2 = GetEntArray( "distant_rocket_arm2", "targetname" );
	AssertEx( IsDefined( distant_rocket_arm2 ), "Unable to find entity with targetname: 'distant_rocket_arm2'" );
	distant_rocket_arm3 = GetEntArray( "distant_rocket_arm3", "targetname" );
	AssertEx( IsDefined( distant_rocket_arm3 ), "Unable to find entity with targetname: 'distant_rocket_arm3'" );
	distant_rocket_arm4 = GetEntArray( "distant_rocket_arm4", "targetname" );
	AssertEx( IsDefined( distant_rocket_arm4 ), "Unable to find entity with targetname: 'distant_rocket_arm4'" );

	distant_rocket_engine = GetEnt( "distant_rocket_engine", "script_noteworthy" );
	AssertEx( IsDefined( distant_rocket_engine ), "Unable to find entity with script_noteworthy: 'distant_rocket_engine'" );
	distant_rocket_engine SetModel("tag_origin");
	distant_rocket_engine.angles = (-90, 0, 0);

	wait( 3 );

	level waittill( "distant_rocket_launch" );

	// splay sound on the gantry
	thread snd_distant_gantry (distant_rocket_engine, distant_rocket_engine);
		// play sound for arms
	thread snd_distant_rocket_arm (distant_rocket_engine);

	// move the gantry away from the rocket
	array_thread( distant_rocket_gantry1, ::distant_rocket_gantry1_move );
	array_thread( distant_rocket_gantry2, ::distant_rocket_gantry2_move );
	
	wait(10);

	// move the arms away from the rocket
	array_thread( distant_rocket_arm1, ::distant_rocket_arm1_move );
	array_thread( distant_rocket_arm2, ::distant_rocket_arm2_move );
	array_thread( distant_rocket_arm3, ::distant_rocket_arm3_move );
	array_thread( distant_rocket_arm4, ::distant_rocket_arm4_move );
	


	// wait to launch
	wait(8);

	// pre-launch fx 
	// TODO: small earthquakes??
	//earthquake_origin = rocket_base GetTagOrigin( "tag_engine" );
	//earthquake( .25, 4, earthquake_origin, 4096 );

	// play 3d launch aounds on distant_rocket_engine, and 2 st 2d sounds
	distant_rocket_engine playsound ("evt_dist_cosmo_launch");	
	//playsoundatposition("evt_dist_cosmo_air_distf",(0,0,0));
	distant_rocket_engine playsound ("evt_dist_cosmo_air_distf");
	wait( 3.5 );

	// launch fx
	//earthquake( .35, 15, earthquake_origin, 4096 );

	playfxontag( level._effect["rocket_blast_trail"], distant_rocket_engine, "tag_origin" );

	// move pieces
	array_thread( distant_rocket, ::rocket_move );

}

distant_rocket_gantry1_move() // self == distant_rocket_gantry
{
	self RotatePitch(-45, 10.0);
	self waittill("rotatedone");
}
distant_rocket_gantry2_move() // self == distant_rocket_gantry
{
	self RotatePitch(45, 10.0);
	self waittill("rotatedone");
}

distant_rocket_arm1_move() // self == distant_rocket_arm
{
	self RotatePitch(-45, 6.0);
	self waittill("rotatedone");
}
distant_rocket_arm2_move() // self == distant_rocket_arm
{
	self RotateRoll(-45, 6.0);
	self waittill("rotatedone");
}
distant_rocket_arm3_move() // self == distant_rocket_arm
{
	self RotatePitch(45, 6.0);
	self waittill("rotatedone");
}
distant_rocket_arm4_move() // self == distant_rocket_arm
{
	self RotateRoll(45, 6.0);
	self waittill("rotatedone");
}
snd_distant_rocket_arm ( distant_rocket_engine )
{
	
	//IPrintLnBold ("this is in the distant rocket arm section - snd_distant_rocket_arm");
	distant_rocket_engine playloopsound ("evt_dist_rocket_lp", .5);
	distant_rocket_engine PlaySound ("evt_dist_rocket_start");	
	//self waittill("rotatedone");
	wait (16);
	distant_rocket_engine stoploopsound(.3);
	distant_rocket_engine PlaySound ("evt_dist_rocket_end");

}	
snd_distant_gantry ( orignr, originl)
{
	//IPrintLnBold ("this is playing dist rocket start");
	orignr playsound ("evt_dist_gantry_disengage");
	orignr playsound ("evt_dist_rocket_start");
}	
