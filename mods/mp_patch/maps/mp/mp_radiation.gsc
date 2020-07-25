#include maps\mp\_utility;
#include common_scripts\utility; 


main()
{
	precachemodel("tag_origin");
	
	/#
		level thread devgui_radiation();
		execdevgui("devgui_mp_radiation");
	#/
	
	//needs to be first for create fx
	maps\mp\mp_radiation_fx::main();

	precachemodel("collision_geo_64x64x256");
	precachemodel("collision_wall_128x128x10");
	precachemodel("collision_geo_256x256x10");


	maps\mp\_load::main();

	maps\mp\mp_radiation_amb::main();
	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_radiation_wager"); 
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_radiation"); 
	}
	
	
	//Increase sample size so as to resolve lighting issue
	SetDvar("sm_sunSampleSizeNear", ".5" );
	
	// If the team nationalites change in this file,
	// you must update the team nationality in the level's csc file as well!
	maps\mp\gametypes\_teamset_urbanspecops::level_init();

	// Set up the default range of the compass
	setdvar("compassmaxrange","2100");

	// COLLISION - to prevent players from placing turrets inside a large cylinder brush in the tank room
	spawncollision("collision_geo_64x64x256","collider",(1221, 41, 236), (0, 0, 0));

	// COLLISION - to prevent players from jumping onto a little ledge of collision
	spawncollision("collision_wall_128x128x10","collider",(1042, -309, 309), (0, 0, 0));
	spawncollision("collision_wall_128x128x10","collider",(1080, -309, 309), (0, 0, 0));
	
	// COLLISION - to prevent players from dropping turrets in the large grey tanks by the warehouse
  spawncollision("collision_geo_64x64x256","collider",(568, 219, 264), (0, 0, 0));
  spawncollision("collision_geo_64x64x256","collider",(567, -105, 264), (0, 0, 0));
  
  // COLLISION - to prevent players dropping off the catwalk onto ledge in warehouse
  spawncollision("collision_wall_128x128x10","collider",(1157, -345, 186), (0, 270, 0));
  spawncollision("collision_wall_128x128x10","collider",(1157, -345, 314), (0, 270, 0));
  spawncollision("collision_wall_128x128x10","collider",(1157, -345, 442), (0, 270, 0));
  
	//NOTURRET - spawns radius triggers to stop players from placing turrets in the large cylinders in the NE corner of the map
	addNoTurretTrigger((1440, -1116, 145), 230, 256);
	addNoTurretTrigger((1446, -1659, 145), 230, 256);



	// enable new spawning system
	maps\mp\gametypes\_spawning::level_use_unified_spawning(true);
	
	flag_init_func();
	
	level_objects_init();
	
}

flag_init_func()
{
	flag_init("kill_stuck_players");
}

level_objects_init()
{
	level._digger_fx = LoadFX( "maps/mp_maps/fx_mp_sand_digger_radiation" );
	waittillframeend;
	level._door_switch_trig1 = getent_and_assert("switch_trigger1");
	level._door_switch_trig2 = getent_and_assert("switch_trigger2");
	
	level._door1 = getent_and_assert("big_door1_clip");
	level._door2 = getent_and_assert("big_door2_clip");
	
	level.const_fx_exploder_switch_green_light = 2001;
	level.const_fx_exploder_switch_red_light = 2002;
	
	//Gets some diggers digging
	level thread digger_dig_init();
	
	//Gets diggers in the background moving
	moving_diggers_init();
	
	//Sets up the switchs players can flip to open the double doors
	level thread door_switch_func();
	
	if( !level.wagerMatch && !isPregame() )
	{
		//get my doors opening at the start of the match
		level thread double_doors_open_at_start();
	}
	
	//Get conveyer belt working
	level thread conveyer_belt_init();
}

turnSwitchPanelRed()
{
	exploder_stop( level.const_fx_exploder_switch_green_light );
	exploder( level.const_fx_exploder_switch_red_light );		
}

turnSwitchPanelGreen()
{
	exploder_stop( level.const_fx_exploder_switch_red_light );
	exploder( level.const_fx_exploder_switch_green_light );	
}	

//Sets it up so a player can flip a switch and open large double doors
door_switch_func()
{ 	
	//Set up the use trigger switches that activate my double doors
	level._door_switch_trig1 thread door_switch_setup(); 
	level._door_switch_trig2 thread door_switch_setup(); 
	
	//Cooldown switches inform the player that the door switch is on cooldown if they try to interact with it
	cooldown_switches = GetEntArray("off_trigger","targetname");
	AssertEx( cooldown_switches.size > 0, "Missing off_triggers");
	
	for( i = 0; i < cooldown_switches.size; i++)
	{
		cooldown_switches[i] UseTriggerRequireLookAt();
		cooldown_switches[i] SetCursorHint( "HINT_NOICON" );
		cooldown_switches[i] SetHintString( &"MP_HOLD_DOOR_SWITCH_UNAVAILABLE");
		cooldown_switches[i] trigger_off();
	}
	
	turnSwitchPanelRed();
	
	kill_trig1 = getent_and_assert("edge_death_trig1");
	kill_trig2 = getent_and_assert("edge_death_trig2");
	center_death_trig = getent_and_assert("center_death_trig");
	
	//Set up DVARS for tweaking door opening sequence
	d1_new_angle = set_dvar_int_if_unset("scr_d1_new_angle", "123");
	d2_new_angle = set_dvar_int_if_unset("scr_d2_new_angle", "-123");
	
	door_model1 = getent_and_assert("big_door1");
	door_model2 = getent_and_assert("big_door2");
	
	door_model1 LinkTo(level._door1);
	door_model2 LinkTo(level._door2);

	door_monster_clip = GetEnt("door_monster_clip","targetname");

	//door_monster_clip thread dog_kill();
	
	//snd_door_status tracks if the door is open or closed	
	snd_door_status = 0;
	
	light_structs = getstructarray("switch_struct","targetname");
	AssertEx( light_structs.size > 0, "Missing light structs");
	
	for( i = 0; i < light_structs.size; i++)
	{
		light_structs[i] thread switch_lights(i);
	}
	
	tunnel_structs = getstructarray("tunnel_light_spot","targetname");
	AssertEx(tunnel_structs.size > 0, "Missing light structs");
	
	for( i = 0; i < light_structs.size; i++)
	{
		tunnel_structs[i] thread tunnel_lights(i);
	}
		
	while(!level.wagermatch)
	{
		//This is a switch in the level on the catwalk
		waittill_any_ents(level._door_switch_trig1,"trigger",level._door_switch_trig2,"trigger");
		
		//Disables the switch temporarily
		level._door_switch_trig1 trigger_off();
		level._door_switch_trig2 trigger_off();
		
		for( i = 0; i < cooldown_switches.size; i++)
		{
			cooldown_switches[i] trigger_on();
		}
		
		//Set up DVARS for tweaking door opening sequence. Acceleration and decelation variation added for realistic offset.
		door_time = set_dvar_int_if_unset("scr_d1_time", "8");
		
		//The doors have specific accelleration and deceleration values so as give an organic-looking timing offset.
		//When the doors are opening, we want Door 2 to accelerate slightly faster so as to avoid clipping.
		if(snd_door_status == 0)
		{
			d1_accel = door_time * .6;
			d2_accel = door_time * .7;
			
			d1_decel = door_time * .4;
			d2_decel = door_time * .3;
			
			//Monster clip is placed and path nodes are severed to keep dogs from running on the doors 
			door_monster_clip trigger_on();
			door_monster_clip DisconnectPaths();
		}
		//When the doors are closing, we want Door 1 to accelerate slightly faster so as to avoid clipping.
		else
		{
			d1_accel = door_time * .7;
			d2_accel = door_time * .6;
			
			d1_decel = door_time * .3;
			d2_decel = door_time * .4;
		}
			
		door_cooldown = set_dvar_int_if_unset("scr_door_cooldown", "20");
		
		level._door1 RotateRoll(d1_new_angle, door_time, d1_accel, d1_decel);
		level._door2 RotateRoll(d2_new_angle, door_time, d2_accel, d2_decel);
		
		thread dropEverythingOnDoorsToGround();
		level thread destroyEquipment();
		
		// Play door opening sound
		level._door1 playloopsound ("evt_hydraulic_loop", .5);
		level._door1 playsound ("evt_hydraulic_start");
		level._door1 thread door_snd_alarm ( 5 );
		
		//This sets it so my doors move in reverse next time they're activated
		d1_new_angle = d1_new_angle * -1;
		d2_new_angle = d1_new_angle * -1;
		
		//Flag marks the period of time i'm checking for any player caught in moving collision
		flag_set("kill_stuck_players");
		
		//Give time for doors to move a moderate amount before starts kill trigger
		wait 4;

		//Only want to kill players if doors are closing
		if(snd_door_status == 1)
		{
			//These are three seperate trigger brushes I want to check for stuck players
			kill_trig1 thread kill_edge_players_func();
			kill_trig2 thread kill_edge_players_func();
			center_death_trig thread kill_edge_players_func();
		}
		level._door1 waittill("rotatedone");

		//snd_door_status tracks if the door is currently open or closed for seprate open and close audio	
		if (snd_door_status == 0)
		{
			//stops the move loop, plays endind sound, and set current door status
			level._door1 stoploopsound (1);
			center_death_trig playsound ("evt_hydraulic_open");
			snd_door_status = 1;
		}	
		else
		{
			//stops the move loop, plays endind sound, and set current door status
			level._door1 stoploopsound (1);
			center_death_trig playsound ("evt_hydraulic_close");

			//Clip is removed so dogs can path
			door_monster_clip ConnectPaths();
			door_monster_clip trigger_off();
			snd_door_status = 0;
		}

		flag_clear("kill_stuck_players");
		
		//Special notify to end my check for players caught on collision
		level notify ("edge_check");
	
		wait (door_cooldown);
		level notify ("no_cooldown");
		
		for( i = 0; i < cooldown_switches.size; i++)
		{
			cooldown_switches[i] trigger_off();
		}
		
		level._door_switch_trig1 trigger_on();
		level._door_switch_trig2 trigger_on();
	}
}
door_snd_alarm ( alarmTimes )
{
	
	for (i=0; i < alarmTimes; i++)
	{
		wait (.5);
		
		playsoundatposition("amb_alarm_buzz",(-664,110,436));	

		playsoundatposition("amb_alarm_buzz",(-664,-72,436));	
		
		playsoundatposition("amb_alarm_buzz",(-666,-602,436));
		
		playsoundatposition("amb_alarm_buzz",(-666,660,444));			
					
		wait (1.5);
	}
}	
//Self is the use triggers that activate the double doors
door_switch_setup()
{
	self usetriggerrequirelookat();
	if ( level.wagerMatch )
	{
		self SetHintString(&"MP_HOLD_DOOR_SWITCH_UNAVAILABLE");
		turnSwitchPanelRed();
	}
	else
	{
		self SetHintString(&"MP_HOLD_TO_OPERATE_DOORS");
		turnSwitchPanelGreen();
	}
	
	while ( !level.wagerMatch )
	{
		// self is the switch. who is the player that triggered switch
		self waittill("trigger", who);
		
		//Added "if" check for when the doors are triggered without a player -Leif
		if(IsDefined( who ))
		{
			who playsound ("evt_hydraulic_switch");
		}
		
		wait (1);
	}	
}
			
//Self is a trigger. The triggers are placed in places i'm afraid of players getting caught
kill_edge_players_func()
{
	level endon ("edge_check");
	
	//This only loops while the doors are moving
	while(1)
	{
		self waittill("trigger", player);
		
		if((player IsTouching(level._door1)) || (player IsTouching(level._door2)))
		{
			player DoDamage(player.health * 2, self.origin, player, player, 0, "MOD_SUICIDE" );
			// TODO: add crushing audio. CDC
		}
		else
		{
			wait .05;
		}
	}
}

//TO DO: Review this function for multiplayer API improvements. 
//'Self' is the struct within the panel that operates the double doors
switch_lights( element_number )
{
	if ( level.PrematchPeriod > 0 && level.inPrematchPeriod == true )
	{
		level waittill("prematch_over");
	}
	
	while(1)
	{
		effect_ent = Spawn("script_model", self.origin);
		effect_ent SetModel("tag_origin");
		
		//This wait is necesary to get the effect to work on the newly created script model.
		wait .1;
		
		//Green light signals the switch is not on cooldown
		turnSwitchPanelGreen();
		//PlayFXOnTag(level._effect["green_light"], effect_ent,"tag_origin" );
		
		waittill_any_ents(level._door_switch_trig1,"trigger",level._door_switch_trig2,"trigger");
		
		//This function is array threaded, so we must prevent FX from playing in the same frame using this loop
		for (i = 0; i < element_number; i++)
		{ 
			wait .1;
		}
		
		effect_ent Delete();
		
		blinky_effect_ent = Spawn("script_model", self.origin);
		blinky_effect_ent SetModel("tag_origin");
		
		//This wait is necesary to get the effect to work on the newly created script model.
		wait .1;
		
		//Blink red light signals the double doors are moving
		turnSwitchPanelRed();
		//PlayFXOnTag(level._effect["blink_light"], blinky_effect_ent,"tag_origin" );
		
		//This notify signals that the doors have stopped moving
		level waittill ("edge_check");
		
		for (i = 0; i < element_number; i++)
		{ 
			wait .1;
		}
		
		blinky_effect_ent Delete();
		
		final_effect_ent = Spawn("script_model", self.origin);
		final_effect_ent SetModel("tag_origin");
		
		//This wait is necesary to get the effect to work on the newly created script model.
		wait .1;
		
		//Red light signals the switch cannot be used
		//PlayFXOnTag(level._effect["red_light"], final_effect_ent,"tag_origin" );
		
		//This notify signals that the doors have stopped moving
		level waittill ("no_cooldown");
		
		for (i = 0; i < element_number; i++)
		{ 
			wait .1;
		}
		
		final_effect_ent Delete();
	}	
}

//'Self' is the struct within the light bulbs in the Radiation tunnel. This function manages FX in the tunnel
//'Element number' is equal to self's index number in the array that got array threaded. 
tunnel_lights(element_number)
{
	door_closed = true;
	
	while(1)
	{
		//Must define may variable to avoid SRE
		effect_ent = undefined;
		
		//When door is closed, play "solid" tunnel light effect
		if(door_closed)
		{
			effect_ent = Spawn("script_model", self.origin);
			effect_ent SetModel("tag_origin");
			
			//Must wait a moment for the script model to finish spawning
			wait .1;
			
			PlayFXOnTag(level._effect["green_light"], effect_ent,"tag_origin" );
		}
		
		//Wait until a tunnel double door switch is hit	
		waittill_any_ents(level._door_switch_trig1,"trigger",level._door_switch_trig2,"trigger");
		
		//This loop makes sure effects do not happen in the same frame, as this function has been array threaded to multiple ents.
		for (i = 0; i < element_number; i++)
		{ 
			wait .1;
		}
		
		//'New effect' is the blinking lights that occur while the double doors are moving
		new_effect_ent = Spawn("script_model", self.origin);
		new_effect_ent SetModel("tag_origin");
		
		if(IsDefined(effect_ent))
		{
			effect_ent Delete();
		}
		
		//Must wait a moment for the script model to finish spawning
		wait .1;
		
		PlayFXOnTag(level._effect["blink_light"], new_effect_ent,"tag_origin" );
		
		level waittill ("edge_check");
		
		for (i = 0; i < element_number; i++)
		{ 
			wait .1;
		}
		
		new_effect_ent Delete();
		
		if(!door_closed)
		{
			door_closed = true;
		}
		else
		{
			door_closed = false;
		}
	}	
}
	
//Open doors at start
double_doors_open_at_start()
{
	//Set up the double doors to open at the start of the match
	if ( level.PrematchPeriod > 0 && level.inPrematchPeriod == true )
	{
		level waittill("prematch_over");
	}

	
	//Slow down my door for other functions to hit waittil's
	wait .3;
	
	//Note I didn't use the "useby player[0]" convention due to a hesitance to grab specific players in MP.
	level._door_switch_trig1 notify ("trigger");
}
	
//Set up the devgui to have the ability to operate the doors, adjust door cooldown, rotate times, digger behavior, etc.
devgui_radiation(cmd)
{
	while(1)
	{
		wait(0.5);

		devgui_string = GetDvar( #"devgui_notify");

		switch(devgui_string)
		{
			case "":
			break;
			
			case "operate_doors":
				level._door_switch_trig1 notify ("trigger");		
			break;

			default:
				level notify(devgui_string);
			break;
		}

		SetDvar("devgui_notify", "");
	}
}

//*****TO DO: MOVE DIGGER FUNCTIONALITY CLIENT SIDE.*********

//Sets it up so I can handle multiple diggers doing a digging action
digger_dig_init()
{
	diggers = GetEntArray("digger_body","targetname");
	AssertEx( diggers.size > 0, "Unable to find entity with targetname 'digger_body'" );
	array_thread(diggers,::digger_dig_think);
}
	
//Self is the digger's body entity. Function creates a series of movements for the diggers to create a digging behavior
digger_dig_think()
{
	body = self;
	arm = GetEnt(self.target, "targetname");
	AssertEx(IsDefined(arm), "Unable to find arm entity for a digger at " + self.origin );
	blade_center = GetEnt(arm.target, "targetname");
	AssertEx(IsDefined(blade_center), "Unable to find blade entity for a digger at " + self.origin );
	
	blade_pieces = GetEntArray("digger_blade","targetname");
	
	for( i = 0; i < blade_pieces.size; i++)
	{
		blade_pieces[i] LinkTo(blade_center);
	}
	
	blade_center LinkTo( arm );
	arm LinkTo( body );
	
	//play idle sound on body 
	body playloopsound ("evt_excavator_idle", .5);
	
	if(IsDefined(self.script_float))
	{
		set_dvar_int_if_unset("scr_dig_delay", self.script_float );
	}
	else
	{
		//'20' is the default value for the cooldown on the digger's dig action
		set_dvar_int_if_unset("scr_dig_delay", 20 );
	}

	while(1)
	{
		arm_move_speed = set_dvar_int_if_unset("scr_arm_move_speed", 11);
		blade_spin_speed = set_dvar_int_if_unset("scr_blade_spin_speed", 80);
		blade_spin_up_time = set_dvar_int_if_unset("scr_blade_spin_up_time", 3);
		
		body_turn = RandomIntRange(-15,15);
		//Must grab the absolute value of the turn value to get proper time fraction, which is the "positive_value_func"
		body_turn_speed = (positive_value_func(body_turn)) * .3;
		
		body RotateYaw(body_turn, body_turn_speed, body_turn_speed/4, body_turn_speed/4 );
		
		// play move loop on arm, and rev one shot on body
		arm playloopsound ("evt_excavator_move", .5);
		body playsound ("evt_excavator_rev");
				
		body waittill ("rotatedone");
	
		arm Unlink(body);
		arm RotatePitch(-45, arm_move_speed, arm_move_speed/4, arm_move_speed/4);
		arm waittill ("rotatedone");

		blade_center UnLink(arm);
		blade_center RotatePitch(1800, blade_spin_speed, blade_spin_up_time, blade_spin_up_time);
		smokeAngles = ( 0, arm.angles[1]+180, arm.angles[2] );
		
		forward = anglesToForward( smokeAngles );
		
		//playfx ( level.chopper_fx["explode"]["death"], self.origin, forward );
		PlayFX( level._digger_fx, ( blade_center.origin[0], blade_center.origin[1], blade_center.origin[2]-560), forward );
		//stop loop on arm
		//iprintlnbold ("this is the stop I suspect");  //had to comment this out for playtest. -Leif
		arm stoploopsound (1);
		
		// play digging loop on blade
		blade_center playloopsound ("evt_excavator_blade", .5);
		
		blade_center waittill ("rotatedone");
		
		// stop diggin loop blade
		blade_center stoploopsound (.5);
		
		blade_center LinkTo(arm);
		
		arm RotatePitch(45, arm_move_speed, arm_move_speed/4, arm_move_speed/4 );
		
		// play move loop on arm, and rev one shot on body
		arm playloopsound ("evt_excavator_move", .5);
		body playsound ("evt_excavator_rev");
				
		arm waittill ("rotatedone");
		arm LinkTo( body );
		
		body RotateYaw((body_turn * -1), body_turn_speed, body_turn_speed/4, body_turn_speed/4);
		
		body waittill ("rotatedone");
		arm stoploopsound (.5);
		
		wait (GetDvarFloat( #"scr_dig_delay" ));
	}
}

//Sets it up so the script can easily handle multiple moving diggers
moving_diggers_init()
{
	diggers = GetEntArray("moving_digger","targetname");	
	//AssertEx( diggers.size > 0, "Unable to find entity with targetname 'moving_digger'" );
	array_thread(diggers, ::moving_diggers_think);
}

//Sets up diggers that follow structs. Note the script_int K/V pair sets up the move time.
moving_diggers_think()
{
	digger_struct = getstruct_and_assert(self.target);
	
	while(1)
	{
		//Each struct has a script_int key value pair that determines the length of time it takes to complete the move
		self MoveTo(digger_struct.origin, digger_struct.script_int);
		AssertEx(IsDefined(digger_struct.script_int), "Unable to find digger struct's 'script_int' key value pair for moving digger" );
		
		self waittill("movedone");
		
		//Structs target other structs to determine the digger's path. 
		if(IsDefined(digger_struct.target))
		{
			digger_struct = GetStruct(digger_struct.target,"targetname");
		}
		else
		{
			break;
		}
	}
}
	
//Function needed to get the absolute value of an integer and be sure its a positive number	
positive_value_func(num)
{
 return(max(1, abs(num)));
}	
	
//Starts a thread to alter player's velocity as long as they're in the trigger
conveyer_belt_init()
{
	//Need to set dvar to determine force of momentum in trigger
	set_dvar_int_if_unset( "scr_coveyer_speed", 45 );
	
	conveyer_trigger = getent_and_assert("coveyer_trig");
	
	//The trigger targets a script struct. The struct contains angles to determine the force direction.
	trigger_struct = getstruct_and_assert(conveyer_trigger.target);
	
	//Find direction that my trigger is pointed toward
	trigger_angles = AnglesToForward(trigger_struct.angles);
	
	//Create intensity of conveyer force equal to my script DVar. Store it on my trigger for a seperate function to use.
	conveyer_trigger._conveyer_vector = vector_scale(trigger_angles,GetDvarInt( #"scr_coveyer_speed"));
	
  while(1)
	{	
		conveyer_trigger waittill("trigger", player);
		if(IsPlayer(player))
		{
	  	conveyer_trigger thread trigger_thread(player, ::player_on_conveyer);
	  }
	  
	  wait .05;
	}	
}

//Self is trigger. Function is ran when player jumps into the trigger.
player_on_conveyer(player, endon_string)
{
	player endon ("death");
	player endon ("disconnect");
	player endon(endon_string);
	
	while(1)
	{
		player_velocity = player GetVelocity();
		
		//Don't want jumping player to be pulled by conveyer 
		if (player IsOnGround())
		{
			//Gives player momentum in the direction of the conveyer equal to a dvar I created earlier along with their own momentum
			player SetVelocity(player_velocity + self._conveyer_vector);
		}

		wait .05;	
	}
}

getent_and_assert(ent_name)
{
	thing = GetEnt( ent_name, "targetname");
	AssertEx(IsDefined(thing), "Unable to find targetname " + ent_name);
	
	return thing;
}

getstruct_and_assert(struct_name)
{
	thing = getstruct( struct_name, "targetname");
	AssertEx(IsDefined(thing), "Unable to find struct at " +struct_name);
	
	return thing;
}
		
dropEverythingOnDoorsToGround()
{
	level endon("edge_check");
	
	// keep dropping all to ground to keep the items in physics
	// if you only do it once or twice they come back to rest to fast
	// if there is a problem with this solution then we are going to need
	// to do something for keeping the crates in physics while in contact 
	// with the doors.
	while(1)
	{
		wait(0.1);
		dropAllToGround( (0,0,128), 181, 100 );
	}
}

destroyEquipment()
{
	level endon ( "edge_check" );
		
	for ( ;; )
	{
		wait( 2 );

		grenades = GetEntArray( "grenade", "classname" );

		for ( i = 0; i < grenades.size; i++ )
		{
			item = grenades[i];

			if ( !IsDefined( item.name ) )
			{
				continue;
			}

			if ( !IsDefined( item.owner ) )
			{
				continue;
			}

			if ( !IsWeaponEquipment( item.name ) )
			{
				continue;
			}

			if ( !item IsTouching( level._door1 ) && !item IsTouching( level._door2 ) )
			{
				continue;
			}

			watcher = item.owner getWatcherForWeapon( item.name );

			if ( !IsDefined( watcher ) )
			{
				continue;
			}

			watcher thread maps\mp\gametypes\_weaponobjects::waitAndDetonate( item, 0.0, undefined );
		}
	}
}

getWatcherForWeapon( weapname )
{
	if ( !IsDefined( self ) )
	{
		return undefined;
	}
	
	if ( !IsPlayer( self ) )
	{
		return undefined;
	}
	
	for ( i = 0; i < self.weaponObjectWatcherArray.size; i++ )
	{
		if ( self.weaponObjectWatcherArray[i].weapon != weapname )
		{ 
			continue;
		}

		return ( self.weaponObjectWatcherArray[i] );
	}

	return undefined;
}

	//spawns triggers to stop players from placing turrets
	addNoTurretTrigger( position, radius, height )
	{
                while( !IsDefined( level.noTurretPlacementTriggers ) )
                                wait( 0.1 );
                                
                trigger = Spawn( "trigger_radius", position, 0, radius, height );
                
                level.noTurretPlacementTriggers[level.noTurretPlacementTriggers.size] = trigger;
	}
