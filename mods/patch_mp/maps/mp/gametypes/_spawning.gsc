/*
_spawning.gsc
Copyright (c) 2008 Certain Affinity, Inc. All rights reserved.
Friday April 25, 2008 3:59pm Stefan S.

spawn_point[]:
--------------
"origin" - worldspace origin
"score" - desirability for spawning; calculated by applying influencers plus a small amount of randomness

spawn_influencer[]:
-------------------
"type" - one of: "static", "friend", "enemy", "enemy_weapon", "vehicle", "projectile", "airstrike", "dead_friend", "game_mode", "dog"
"shape" - one of: "sphere", "cylinder", "pill", "cone", "box"
"forward" - worldspace forward vector
"up" - worldspace up vector
"origin" - worldspace origin
"radius" - for sphere, cylinder, pill, cone
"axis_length" - for cylinder, pill, cone
"width", "height", "depth" - for box
"score" - base influencer score
"score_curve" - one of: "constant", "linear" (1->0), "inverse_linear" (0->1), "negative_to_positive" (-1 -> +1)

level.recently_deceased["<teamname>"][]:
--------------------------
deceased.angles - angles of the deceased player at TOD
deceased.origin - origin of the deceased player at TOD
deceased.timeOfDeathMillis - GetTime() value (in milliseconds) at TOD
*/

/*QUAKED mp_uspawn_point (1.0 0.549 0.0) (-16 -16 0) (16 16 72)
Unified spawn point.  A player from any team can spawn here, based on spawn influencers.  Use dvar "useUnifiedSpawning" to enable. Use targetname "allies_start" or "axis_start" to put a start influencer at that spawn point.*/

/*QUAKED mp_uspawn_influencer (1 0 0) (-16 -16 -16) (16 16 16)
Static influencer for unified spawning system
"script_shape"					Shape of this influencer.  Supported shapes for Radiant-placed static influencers are "cylinder" and "sphere".
"radius"						Radius of the influencer ( whether cylinder or sphere ).
"height"						Height of the cylinder ( ignored for sphere shapes ).
"script_score"					The maximum influence this influencer can have.
"script_score_curve"			The shape of the score falloff as a function of the distance from the primary cylinder axis.  Options are: "constant", "linear", "inverse_linear", "negative_to_positive"
"script_team"					Make this influencer team-specific by specifying "axis" or "allies"
"script_gameobjectname"			Gametypes for which the influencer is active (space-separated values), can be "[all_modes]" or combination of "dm", "hq", "iwar", "war", "twar", "sd", "dom"
"script_twar_flag"				Used to associate this influencer with a specific twar flag
default:"script_shape"			"cylinder"
default:"radius"				"400"
default:"height"				"100"
default:"script_score"			"25"
default:"script_score_curve"	"constant"
default:"script_team"			"neutral"
default:"script_gameobjectname"	"[all_modes]"
default:"script_twar_flag"		"NONE"
*/

/* ---------- includes */

#include maps\mp\_utility;
#include common_scripts\utility;

/* ---------- initialization */

init()
{	
	if ( !IsDefined(level.gamemodeSpawnDvars) )
	{
		level.gamemodeSpawnDvars = ::default_gamemodeSpawnDvars;
	}
	
	level init_spawn_system();
	
	level.teams= [];
	level.teams[ 0 ]= "allies";
	level.teams[ 1 ]= "axis";
	
	
	level.recently_deceased= [];
	for ( iTeam= 0; iTeam < level.teams.size; iTeam++ )
	{
		level.recently_deceased[ level.teams[ iTeam ] ]= spawn_array_struct();
	}
	
	level thread onPlayerConnect();
	
	if ( GetDvar( #"scr_spawn_visibility_check_max") == "" )
	{
		level.spawn_visibility_check_max = 20;
	}
	else 
	{
		level.spawn_visibility_check_max = GetDvarInt( #"scr_spawn_visibility_check_max");
	}
	
	level.spawnProtectionTime = GetDvarFloat( #"scr_spawn_protection_time" );
	
	/#
	// this dvar stores the name for whom to display debug spawning information
	SetDvar("scr_debug_spawn_player", "");
	SetDvar("scr_debug_render_spawn_data", "1");
	SetDvar("scr_debug_render_snapshotmode", "0");
	// for testing spawn point placements
	SetDvar("scr_spawn_point_test_mode", "0");
	level.test_spawn_point_index= 0;
	//###stefan $NOTE turning off debug text only saves 1-2 sv ms/frame
	SetDvar("scr_debug_render_spawn_text", "1");
	// spawn thread for debug rendering of spawn influencer state
	//thread spawn_influencers_debug_render_thread();
	#/

	return;
}

default_gamemodeSpawnDvars(reset_dvars)
{
}

init_spawn_system()
{
	level.spawnsystem = spawnstruct();
	spawnsystem = level.spawnsystem;

	level thread initialize_player_spawning_dvars();
	
	// code enums - these must match the code versions
	spawnsystem.eINFLUENCER_SHAPE_SPHERE = 0;
	spawnsystem.eINFLUENCER_SHAPE_CYLINDER = 1;

	spawnsystem.eINFLUENCER_TYPE_NORMAL = 0;
	spawnsystem.eINFLUENCER_TYPE_PLAYER = 1;
	spawnsystem.eINFLUENCER_TYPE_WEAPON = 2;
	spawnsystem.eINFLUENCER_TYPE_DOG = 3;
	spawnsystem.eINFLUENCER_TYPE_VEHICLE = 4;
	spawnsystem.eINFLUENCER_TYPE_GAME_MODE = 6;
	spawnsystem.eINFLUENCER_TYPE_ENEMY_SPAWNED = 7;

	spawnsystem.eINFLUENCER_CURVE_CONSTANT = 0;
	spawnsystem.eINFLUENCER_CURVE_LINEAR = 1;
	spawnsystem.eINFLUENCER_CURVE_STEEP = 2;
	spawnsystem.eINFLUENCER_CURVE_INVERSE_LINEAR = 3;
	spawnsystem.eINFLUENCER_CURVE_NEGATIVE_TO_POSITIVE = 4;

	spawnsystem.iSPAWN_TEAMMASK_FREE = 1;
	spawnsystem.iSPAWN_TEAMMASK_AXIS = 2;
	spawnsystem.iSPAWN_TEAMMASK_ALLIES = 4;
}


/*
=============
onPlayerConnect

=============
*/
onPlayerConnect()
{
	level endon ( "game_ended" );

	for( ;; )
	{
		level waittill( "connecting", player );

		//println("SPAWN:onPlayerConnect()");
		
		player thread onPlayerSpawned();
		player thread onDisconnect();
		player thread onTeamChange();
		player thread onGrenadeThrow();
	}
}


/*
=============
onPlayerSpawned

=============
*/
onPlayerSpawned()
{
	self endon( "disconnect" );
	level endon ( "game_ended" );
	
	for(;;)
	{
		self waittill( "spawned_player" );
		
		//println("SPAWN:onPlayerSpawned() - spawned player event");
		
		self thread initialSpawnProtection();
		
		// If radar permanently enabled for the player, enable it
		if ( isDefined( self.pers["hasRadar"] ) && self.pers["hasRadar"] )
		{
			self.hasSpyplane = true;
		}
		
		self enable_player_influencers( true );
		self thread onDeath();
	}
}


/*
=============
onDeath

Drops any carried object when the player dies
=============
*/
onDeath()
{
	self endon( "disconnect" );
	level endon ( "game_ended" );

	self waittill ( "death" );
	self enable_player_influencers( false );
	self create_body_influencers();
}

/*
=============
onTeamChange

Changes influencer teams when player changes teams
=============
*/
onTeamChange()
{
	self endon( "disconnect" );
	level endon ( "game_ended" );

	while(1)
	{
		self waittill ( "joined_team" );
		self player_influencers_set_team();
		wait(0.05);
	}
}


/*
=============
onGrenadeThrow

Creates an influencer on grenade 
=============
*/
onGrenadeThrow()
{
	self endon( "disconnect" );
	level endon ( "game_ended" );

	while(1)
	{
		self waittill ( "grenade_fire", grenade, weaponName );
		level thread create_grenade_influencers( self.pers["team"], weaponName, grenade );
		wait(0.05);
	}
}

/*
=============
onDisconnect

Drops any carried object when the player disconnects
=============
*/
onDisconnect()
{
	level endon ( "game_ended" );

	self waittill ( "disconnect" );
}


get_team_mask( team )
{
	// this can be undefined on connect
	if ( !level.teambased || !isdefined(team))
	 return level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	 
	switch( team )
	{
	case "axis":
		return level.spawnsystem.iSPAWN_TEAMMASK_AXIS;
	case "allies":
		return level.spawnsystem.iSPAWN_TEAMMASK_ALLIES; 	
	case "all":
	return (level.spawnsystem.iSPAWN_TEAMMASK_FREE | level.spawnsystem.iSPAWN_TEAMMASK_AXIS |level.spawnsystem.iSPAWN_TEAMMASK_ALLIES);
	case "free":
	default:
		return level.spawnsystem.iSPAWN_TEAMMASK_FREE;	
	}
}

get_score_curve_index( curve )
{
	switch( curve )
	{
	case "linear":
		return level.spawnsystem.eINFLUENCER_CURVE_LINEAR; 	
	case "steep":
		return level.spawnsystem.eINFLUENCER_CURVE_STEEP; 	
	case "inverse_linear":
		return level.spawnsystem.eINFLUENCER_CURVE_LINEAR; 	
	case "negative_to_positive":
		return level.spawnsystem.eINFLUENCER_CURVE_NEGATIVE_TO_POSITIVE;
	case "constant":
	default:
		return level.spawnsystem.eINFLUENCER_CURVE_CONSTANT;
	}
}

get_influencer_type_index( curve )
{
//	switch( curve )
//	{
//	case "linear":
//		return level.spawnsystem.eINFLUENCER_CURVE_LINEAR; 	
//	case "inverse_linear":
//		return level.spawnsystem.eINFLUENCER_CURVE_LINEAR; 	
//	case "negative_to_positive":
//		return level.spawnsystem.eINFLUENCER_CURVE_NEGATIVE_TO_POSITIVE;
//	case "constant":
//	default:
//		return level.spawnsystem.eINFLUENCER_CURVE_CONSTANT;
//	}
}

create_player_influencers()
{
	assert( !isdefined(self.influencer_enemy_sphere) );
	assert( !isdefined(self.influencer_weapon_cylinder) );
	assert( !level.teambased || !isdefined(self.influencer_friendly_sphere) );
	assert( !level.teambased || !isdefined(self.influencer_friendly_cylinder) );

	if ( !level.teambased )
	{
		team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
		other_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
		weapon_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	}
	else if ( isdefined( self.pers["team"] ) )
	{
		team_mask = get_team_mask( self.pers["team"] );
		other_team_mask = get_team_mask( getotherteam(self.pers["team"]) );
		weapon_team_mask = get_team_mask( getotherteam(self.pers["team"]) );
	}
	else
	{
		team_mask = 0;
		other_team_mask = 0;
		weapon_team_mask = 0;
	}

	// if this is hardcore then we do not want to spawn infront of the weapon either
	if ( level.hardcoreMode )
	{
		weapon_team_mask |= team_mask;
	}
	
	angles = self.angles;
	origin = self.origin;
//	up = AnglesToUp(angles);
//	forward = AnglesToForward(angles);
	up = (0,0,1);
	forward = (1,0,0);
	cylinder_forward = up;
	cylinder_up = forward;

	self.influencer_enemy_sphere = AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_PLAYER,
														 origin, 
														 level.spawnsystem.enemy_influencer_radius,
														 level.spawnsystem.enemy_influencer_score,
														 other_team_mask,
														 "enemy,r,s",
														 get_score_curve_index(level.spawnsystem.enemy_influencer_score_curve),
														 0,
														 self );

//	self.influencer_weapon_cylinder = AddCylinderInfluencer( level.spawnsystem.eINFLUENCER_TYPE_WEAPON,
//															 origin, 
//															 cylinder_forward,
//															 cylinder_up,
//															 level.spawnsystem.enemy_weapon_influencer_radius,
//															 level.spawnsystem.enemy_weapon_influencer_length,
//															 level.spawnsystem.enemy_weapon_influencer_score,
//															 weapon_team_mask,
//															 "enemy_weapon,r,s",
//															 get_score_curve_index(level.spawnsystem.enemy_weapon_influencer_score_curve),
//															 0,
//															 self );

	if ( level.teambased )
	{
		// aim cylinder backwards for friends
		cylinder_up = -1.0 * forward;
	
		self.influencer_friendly_sphere = AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_PLAYER,
																 origin, 
																 level.spawnsystem.friend_weak_influencer_radius,
																 level.spawnsystem.friend_weak_influencer_score,
																 team_mask,
																 "friend_weak,r,s",
																 get_score_curve_index(level.spawnsystem.friend_weak_influencer_score_curve),
																 0,
																 self );
																													 
//		self.influencer_friendly_cylinder = AddCylinderInfluencer( level.spawnsystem.eINFLUENCER_TYPE_PLAYER,
//																	 origin, 
//																	 cylinder_forward,
//																	 cylinder_up,
//																	 level.spawnsystem.friend_strong_influencer_radius,
//																	 level.spawnsystem.friend_strong_influencer_length,
//																	 level.spawnsystem.friend_strong_influencer_score,
//																	 team_mask,
//																	 "friend_strong,r,s",
//																	 get_score_curve_index(level.spawnsystem.friend_strong_influencer_score_curve),
//																	 0,
//																	 self );
	
	}
	
	self.spawn_influencers_created = true;
	
	if ( !isdefined(self.pers["team"]) || self.pers["team"] == "spectator" )
	{
		self enable_player_influencers( false );
	}
}

remove_player_influencers()
{
	if ( level.teambased && isdefined(self.influencer_friendly_sphere) )
	{
		removeinfluencer(self.influencer_friendly_sphere);
		self.influencer_friendly_sphere = undefined;
	}
	if ( level.teambased && isdefined(self.influencer_friendly_cylinder) )
	{
		removeinfluencer(self.influencer_friendly_cylinder);
		self.influencer_friendly_cylinder = undefined;
	}
	if ( isdefined(self.influencer_enemy_sphere) )
	{
		removeinfluencer(self.influencer_enemy_sphere);
		self.influencer_enemy_sphere = undefined;
	}
	if ( isdefined(self.influencer_weapon_cylinder) )
	{
		removeinfluencer(self.influencer_weapon_cylinder);
		self.influencer_weapon_cylinder = undefined;
	}
	
}

enable_player_influencers( enabled )
{
	if (!isdefined(self.spawn_influencers_created))
		self create_player_influencers();

	if ( isdefined(self.influencer_friendly_sphere) )
		enableinfluencer(self.influencer_friendly_sphere, enabled);
	if ( isdefined(self.influencer_friendly_cylinder) )
		enableinfluencer(self.influencer_friendly_cylinder, enabled);
	if ( isdefined(self.influencer_enemy_sphere) )
		enableinfluencer(self.influencer_enemy_sphere, enabled);
	if ( isdefined(self.influencer_weapon_cylinder) )
		enableinfluencer(self.influencer_weapon_cylinder, enabled);
}

player_influencers_set_team()
{
	if ( !level.teambased )
	{
		team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
		other_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
		weapon_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	}
	else
	{
		// for the player influencers we need to pay attention to the switchedsides
		team = self.pers["team"];
//		if ( isdefined( game["switchedsides"] ) && game["switchedsides"] )
//		{
//			team = getotherteam(team);
//		}
		
		team_mask = get_team_mask( team );
		other_team_mask = get_team_mask( getotherteam(team) );
		weapon_team_mask = get_team_mask( getotherteam(team) );
	}
	
	// if friendly fire is on then we do not want to spawn infront of the weapon either
	if ( level.friendlyfire != 0 && level.teamBased )
	{
		weapon_team_mask |= team_mask;
	}

	if ( isdefined(self.influencer_friendly_sphere) )
		setinfluencerteammask(self.influencer_friendly_sphere, team_mask);
	if ( isdefined(self.influencer_friendly_cylinder) )
		setinfluencerteammask(self.influencer_friendly_cylinder, team_mask);
	if ( isdefined(self.influencer_enemy_sphere) )
		setinfluencerteammask(self.influencer_enemy_sphere, other_team_mask);
	if ( isdefined(self.influencer_weapon_cylinder) )
		setinfluencerteammask(self.influencer_weapon_cylinder, weapon_team_mask);
}

create_body_influencers()
{
	if ( level.teambased )
	{
		team_mask = get_team_mask( self.pers["team"] );
	}
	else
	{
		team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	}
	AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
						 self.origin, 
						 level.spawnsystem.dead_friend_influencer_radius,
						 level.spawnsystem.dead_friend_influencer_score,
						 team_mask,
						 "dead_friend,r,s",
						 get_score_curve_index(level.spawnsystem.dead_friend_influencer_score_curve),
						 level.spawnsystem.dead_friend_influencer_timeout_seconds);
}

create_grenade_influencers( parent_team, weaponName, grenade )
{	
	pixbeginevent("create_grenade_influencers");
	if ( !level.teambased )
	{
		weapon_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	}
	else
	{
		weapon_team_mask = get_team_mask( getotherteam(parent_team) );

		// if this is hardcore then we do not want to spawn infront of the weapon either
		if ( level.friendlyfire )
		{
			weapon_team_mask |= get_team_mask( parent_team );
		}
	}
	
	if ( issubstr(weaponName,"napalmblob") || issubstr(weaponName,"gl_") )
	{
		pixendevent("create_grenade_influencers");
		return;
	}
	
	timeout = 0;
	
	// these have lasting effects after detonation so hang it around a bit longer 
	if ( weaponName == "tabun_gas_mp" )
	{
		timeout = 7.0;
	}
	
	if (isdefined( grenade.origin ))
	{
		if ( weaponName == "claymore_mp" )
		{
			AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
								 grenade.origin, 
								 level.spawnsystem.claymore_influencer_radius,
								 level.spawnsystem.claymore_influencer_score,
								 weapon_team_mask,
								 "claymore,r,s",
								 get_score_curve_index(level.spawnsystem.claymore_influencer_score_curve),
								 timeout,
								 grenade );
		}
		else
		{
			AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
								 grenade.origin, 
								 level.spawnsystem.grenade_influencer_radius,
								 level.spawnsystem.grenade_influencer_score,
								 weapon_team_mask,
								 "grenade,r,s",
								 get_score_curve_index(level.spawnsystem.grenade_influencer_score_curve),
								 timeout,
								 grenade );
		}
	}
						 
	// also create an influencer at the predicted end point, and update the prediction at intervals
	while (isdefined(grenade.origin))
	{
		landpos = grenade predictgrenade();
		//landpos = (0,0,0);
		if (landpos != (0,0,0))
		{
			grenade_endpoint_influencer = AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
								 landpos, 
								 level.spawnsystem.grenade_endpoint_influencer_radius,
								 level.spawnsystem.grenade_endpoint_influencer_score,
								 0,
								 //weapon_team_mask,
								 "grenade_endpoint,r,s",
								 get_score_curve_index(level.spawnsystem.grenade_endpoint_influencer_score_curve) );

			wait(0.5);
			
			if (!isdefined(grenade.origin) && timeout > 0)
				wait(timeout);	// wait till the effects have gone
			
			removeinfluencer( grenade_endpoint_influencer );
		}
		else
		{
			break;
		}
	}
	pixendevent("create_grenade_influencers");
}

create_napalm_fire_influencers( point, direction, parent_team, duration )
{
	timeout = duration;
	
	// just going to leave this blank to indicate all teams
	weapon_team_mask = 0;

	offset = vector_scale( anglestoforward( direction ), 1100 );	

	AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
					 (point + ( 2.0 * offset)), 
					 level.spawnsystem.napalm_influencer_radius,
					 level.spawnsystem.napalm_influencer_score,
					 weapon_team_mask,
					 "napalm,r,s",
					 get_score_curve_index(level.spawnsystem.napalm_influencer_score_curve),
					 timeout );

	AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
					 (point + offset), 
					 level.spawnsystem.napalm_influencer_radius,
					 level.spawnsystem.napalm_influencer_score,
					 weapon_team_mask,
					 "napalm,r,s",
					 get_score_curve_index(level.spawnsystem.napalm_influencer_score_curve),
					 timeout );

	AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
					 point, 
					 level.spawnsystem.napalm_influencer_radius,
					 level.spawnsystem.napalm_influencer_score,
					 weapon_team_mask,
					 "napalm,r,s",
					 get_score_curve_index(level.spawnsystem.napalm_influencer_score_curve),
					 timeout );

	AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
					 (point - offset), 
					 level.spawnsystem.napalm_influencer_radius,
					 level.spawnsystem.napalm_influencer_score,
					 weapon_team_mask,
					 "napalm,r,s",
					 get_score_curve_index(level.spawnsystem.napalm_influencer_score_curve),
					 timeout );
}

create_auto_turret_influencer( point, parent_team, angles )
{
	if ( !level.teambased )
	{
		weapon_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	}
	else
	{
		weapon_team_mask = get_team_mask( getotherteam(parent_team) );
	}
	
	// place the influencer out infront of the turret
	projected_point = point + vector_scale( anglestoforward( angles ), level.spawnsystem.auto_turret_influencer_radius * 0.7 );

	influencerid = AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
					 projected_point, 
					 level.spawnsystem.auto_turret_influencer_radius,
					 level.spawnsystem.auto_turret_influencer_score,
					 weapon_team_mask,
					 "auto_turret,r,s",
					 get_score_curve_index(level.spawnsystem.auto_turret_influencer_score_curve) );
					 
	return influencerid;
}

create_dog_influencers()
{
	if ( !level.teambased )
	{
		dog_enemy_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	}
	else
	{
		dog_enemy_team_mask = get_team_mask( getotherteam(self.aiteam) );
	}
	
	AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_DOG,
						 self.origin, 
						 level.spawnsystem.dog_influencer_radius,
						 level.spawnsystem.dog_influencer_score,
						 dog_enemy_team_mask,
						 "dog,r,s",
						 get_score_curve_index(level.spawnsystem.dog_influencer_score_curve),
						 0,
						 self );
}

create_helicopter_influencers( parent_team )
{
	if ( !level.teambased )
	{
		team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	}
	else
	{
		team_mask = get_team_mask( getotherteam(parent_team) );
	}

	self.influencer_helicopter_cylinder = AddCylinderInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
																 self.origin, 
																 (0,0,0),
																 (0,0,0),
																 level.spawnsystem.helicopter_influencer_radius,
																 level.spawnsystem.helicopter_influencer_length,
																 level.spawnsystem.helicopter_influencer_score,
																 team_mask,
																 "helicopter,r,s",
																 get_score_curve_index(level.spawnsystem.helicopter_influencer_score_curve),
																 0,
																 self );
}

remove_helicopter_influencers()
{
	if (isdefined( self.influencer_helicopter_cylinder ))
		RemoveInfluencer( self.influencer_helicopter_cylinder );
	
	self.influencer_helicopter_cylinder = undefined;
}

create_tvmissile_influencers( parent_team )
{
	if ( !level.teambased || is_hardcore() )
	{
		team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	}
	else
	{
		team_mask = get_team_mask( getotherteam(parent_team) );
	}

	self.influencer_tvmissile_cylinder = AddCylinderInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
																 self.origin, 
																 (0,0,0),
																 (0,0,0),
																 level.spawnsystem.tvmissile_influencer_radius,
																 level.spawnsystem.tvmissile_influencer_length,
																 level.spawnsystem.tvmissile_influencer_score,
																 team_mask,
																 "tvmissile,r,s",
																 get_score_curve_index(level.spawnsystem.tvmissile_influencer_score_curve),
																 0,
																 self );
}

remove_tvmissile_influencers()
{
	if (isdefined( self.influencer_tvmissile_cylinder ))
		RemoveInfluencer( self.influencer_tvmissile_cylinder );

	self.influencer_tvmissile_cylinder = undefined;
}

create_artillery_influencers( point, radius )
{
	// just going to leave this blank to indicate all teams
	weapon_team_mask = 0;
	
//	return AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
//								 point, 
//								 radius,
//								 level.spawnsystem.artillery_influencer_score,
//								 weapon_team_mask,
//								 "artillery,s",
//								 get_score_curve_index(level.spawnsystem.artillery_influencer_score_curve) );
								 
	if (radius < 0)
		thisradius = level.spawnsystem.artillery_influencer_radius;
	else
		thisradius = radius;
								 
	return AddCylinderInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
									 point + (0,0,-2000), 
									 (1,0,0),
									 (0,0,1),
									 thisradius,
									 5000,
									 level.spawnsystem.artillery_influencer_score,
									 weapon_team_mask,
									 "artillery,s,r",
									 get_score_curve_index(level.spawnsystem.artillery_influencer_score_curve) );
}

create_vehicle_influencers( )
{
	// just going to leave this blank to indicate all teams
	// because we dont want anyone spawning directly infront of the tank
	weapon_team_mask = 0;
	
	vehicleRadius= 144;
//	cylinderLength = (vehicleRadius*0.5) + (vehSpeedIPS*spawn_vehicle_influencer_lead_seconds);
	
	// code will always maintain the length at half the radius 
	// plus the given length * the vehicle speed in inches per second
	cylinderLength = level.spawnsystem.vehicle_influencer_lead_seconds;
	
	up = (0,0,1);
	forward = (1,0,0);
	cylinder_forward = up;
	cylinder_up = forward;
	
	return AddCylinderInfluencer( level.spawnsystem.eINFLUENCER_TYPE_VEHICLE,
									 self.origin, 
									 cylinder_forward,
									 cylinder_up,
									 vehicleRadius,
									 cylinderLength,
									 level.spawnsystem.vehicle_influencer_score,
									 weapon_team_mask,
									 "vehicle,s",
									 get_score_curve_index(level.spawnsystem.vehicle_influencer_score_curve),
									 0,
									 self );
}

create_rcbomb_influencers( team )
{
	if ( !level.teambased )
		other_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	else
		other_team_mask = get_team_mask( getotherteam( team ) );
		
	return AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_NORMAL,
						 self.origin, 
						 level.spawnsystem.rcbomb_influencer_radius,
						 level.spawnsystem.rcbomb_influencer_score,
						 other_team_mask,
						 "rcbomb,r,s",
						 get_score_curve_index(level.spawnsystem.rcbomb_influencer_score_curve),
						 0,
						 self );
}

create_map_placed_influencers()
{
	staticInfluencerEnts = GetEntArray( "mp_uspawn_influencer", "classname" );
	
	for ( i = 0; i < staticInfluencerEnts.size; i++ )
	{
		staticInfluencerEnt = staticInfluencerEnts[ i ];

		// don't include ones which have a twar-flag affiliation
		// those will be activated by twar code
		if (IsDefined(staticInfluencerEnt.script_gameobjectname) &&
			staticInfluencerEnt.script_gameobjectname=="twar")
		{
			continue;
		}
		
		create_map_placed_influencer(staticInfluencerEnt);
	}
}

create_map_placed_influencer(	influencer_entity, optional_score_override )
{
	influencer_id = -1;
	
	if (IsDefined(influencer_entity.script_shape) &&
		IsDefined(influencer_entity.script_score) &&
		IsDefined(influencer_entity.script_score_curve))
	{
		switch (influencer_entity.script_shape)
		{
			case "sphere":
			{
				if (IsDefined(influencer_entity.radius))
				{
					if (IsDefined(optional_score_override))
					{
						score= optional_score_override;
					}
					else
					{
						score= influencer_entity.script_score;
					}
					
					influencer_id = AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE,
														 influencer_entity.origin, 
														 influencer_entity.radius,
														 score,
														 get_team_mask(influencer_entity.script_team),
														 "*map_defined",
														 get_score_curve_index(influencer_entity.script_score_curve) );
				}
				else
				{
					assertmsg( "Radiant-placed sphere spawn influencers require 'radius' parameter" );
				}
				break;
			}
			case "cylinder":
			{
				if (IsDefined(influencer_entity.radius) &&
					IsDefined(influencer_entity.height))
				{
					if (IsDefined(optional_score_override))
					{
						score= optional_score_override;
					}
					else
					{
						score= influencer_entity.script_score;
					}
					
					influencer_id  = AddCylinderInfluencer( level.spawnsystem.eINFLUENCER_TYPE_GAME_MODE,
															 influencer_entity.origin,
															 AnglesToForward(influencer_entity.angles), 
															 AnglesToUp(influencer_entity.angles),
															 influencer_entity.radius,
															 influencer_entity.height,
															 score,
															 get_team_mask(influencer_entity.script_team),
															 "*map_defined",
															 get_score_curve_index(influencer_entity.script_score_curve) );
				}
				else
				{
					assertmsg( "Radiant-placed cylinder spawn influencers require 'radius' and 'height' parameters" );
				}
				break;
			}
			default:
			{
				assertmsg( "Unsupported script_shape value (\""+influencer_entity.script_shape+"\") for unified spawning system static influencer.  Supported shapes are \"cylinder\" and \"sphere\"." );
				break;
			}
		}
	}
	else
	{
		assertmsg( "Radiant-placed spawn influencers require 'script_shape', 'script_score' and 'script_score_curve' parameters" );
	}
	
	return influencer_id;
}

create_enemy_spawned_influencers( origin, team )
{
	if ( !level.teambased )
		other_team_mask = level.spawnsystem.iSPAWN_TEAMMASK_FREE;
	else
		other_team_mask = get_team_mask( getotherteam( team ) );
		
	return AddSphereInfluencer( level.spawnsystem.eINFLUENCER_TYPE_ENEMY_SPAWNED,
						 origin, 
						 level.spawnsystem.enemy_spawned_influencer_radius,
						 level.spawnsystem.enemy_spawned_influencer_score,
						 other_team_mask,
						 "enemy_spawned,r,s",
						 get_score_curve_index(level.spawnsystem.enemy_spawned_influencer_score_curve),
						 7 );
}


updateAllSpawnPoints()
{
	// force spawn points to get precached
	gatherSpawnEntities( "allies" );
	gatherSpawnEntities( "axis" );
	
	// raise all the spawn points
//	raise_all_points_in_height( level.unified_spawn_points[ "allies" ] );
//	raise_all_points_in_height( level.unified_spawn_points[ "axis" ] );

	clearspawnpoints();
	
	if ( level.teambased )
	{
		addspawnpoints( "allies", level.unified_spawn_points[ "allies" ].a );
		addspawnpoints( "axis", level.unified_spawn_points[ "axis" ].a );
	}
	else
	{
		addspawnpoints( "free", level.unified_spawn_points[ "allies" ].a );
		addspawnpoints( "free", level.unified_spawn_points[ "axis" ].a );
	}
	
	// this will remove all spawnpoints for the other gametypes which are not used
	remove_unused_spawn_entities();
}

initialize_player_spawning_dvars()
{
	reset_dvars = true;
	while( 1 )
	{
		get_player_spawning_dvars(reset_dvars);
		reset_dvars = false;
		wait(2);  // dont need this to happen frequently
	}
}

get_player_spawning_dvars(reset_dvars)
{
	k_player_height= get_player_height();
	player_height_times_10 = "" + 10.0*k_player_height;
	ss = level.spawnsystem;

	player_influencer_radius = 15.0*k_player_height;
	player_influencer_score = 150.0;
	dog_influencer_radius = 10.0*k_player_height;
	dog_influencer_score = 150.0;
	
	// this controls the original script driven influencer system
	ss.script_based_influencer_system =	set_dvar_int_if_unset("scr_script_based_influencer_system", "0", reset_dvars);

	// general parameters
	// amount of randomness applied to spawning scores
	ss.randomness_range =	set_dvar_float_if_unset("scr_spawn_randomness_range", "10", reset_dvars);
	// bonus applied to spawn points which face the current objective in certain objective-based games
	ss.objective_facing_bonus =	set_dvar_float_if_unset("scr_spawn_objective_facing_bonus", "50", reset_dvars);
	
	// strong friend influencers are now a cylinder projected behind the player
	//ss.friend_strong_influencer_score =	set_dvar_float_if_unset("scr_spawn_friend_strong_influencer_score", "75", reset_dvars);
	//ss.friend_strong_influencer_score_curve =	set_dvar_if_unset("scr_spawn_friend_strong_influencer_score_curve", "linear", reset_dvars);
	//ss.friend_strong_influencer_radius =	set_dvar_float_if_unset("scr_spawn_friend_strong_influencer_radius", player_height_times_10, reset_dvars);
	//ss.friend_strong_influencer_length =	set_dvar_float_if_unset("scr_spawn_friend_strong_influencer_length", player_height_times_10, reset_dvars);
	
	// weak friend influencers are a sphere about the player
	ss.friend_weak_influencer_score =	set_dvar_float_if_unset("scr_spawn_friend_weak_influencer_score", "10", reset_dvars);
	ss.friend_weak_influencer_score_curve =	set_dvar_if_unset("scr_spawn_friend_weak_influencer_score_curve", "steep", reset_dvars);
	ss.friend_weak_influencer_radius =	set_dvar_float_if_unset("scr_spawn_friend_weak_influencer_radius", player_height_times_10, reset_dvars);
	
	// enemy player influencer
	ss.enemy_influencer_score =	set_dvar_float_if_unset("scr_spawn_enemy_influencer_score", "-150", reset_dvars);
	ss.enemy_influencer_score_curve =	set_dvar_if_unset("scr_spawn_enemy_influencer_score_curve", "steep", reset_dvars);
	ss.enemy_influencer_radius =	set_dvar_float_if_unset("scr_spawn_enemy_influencer_radius", "" + 30.0*k_player_height, reset_dvars);
	
	// enemy weapon influencer
	//ss.enemy_weapon_influencer_score =	set_dvar_float_if_unset("scr_spawn_enemy_weapon_influencer_score", "-100", reset_dvars);
	//ss.enemy_weapon_influencer_score_curve =	set_dvar_if_unset("scr_spawn_enemy_weapon_influencer_score_curve", "linear", reset_dvars);
	//ss.enemy_weapon_influencer_radius =	set_dvar_float_if_unset("scr_spawn_enemy_weapon_influencer_radius", "" + 5.0*k_player_height, reset_dvars);
	//ss.enemy_weapon_influencer_length =	set_dvar_float_if_unset("scr_spawn_enemy_weapon_influencer_length", "" + 25.0*k_player_height, reset_dvars);
	
	// dead friends
	ss.dead_friend_influencer_timeout_seconds =	set_dvar_float_if_unset("scr_spawn_dead_friend_influencer_timeout_seconds", "20", reset_dvars);
	ss.dead_friend_influencer_count =	set_dvar_float_if_unset("scr_spawn_dead_friend_influencer_count", "7", reset_dvars);
	ss.dead_friend_influencer_score =	set_dvar_float_if_unset("scr_spawn_dead_friend_influencer_score", "-100", reset_dvars);
	ss.dead_friend_influencer_score_curve =	set_dvar_if_unset("scr_spawn_dead_friend_influencer_score_curve", "steep", reset_dvars);
	ss.dead_friend_influencer_radius =	set_dvar_float_if_unset("scr_spawn_dead_friend_influencer_radius", player_height_times_10, reset_dvars);
	
	// moving vehicle influencer
	ss.vehicle_influencer_score =	set_dvar_float_if_unset("scr_spawn_vehicle_influencer_score", "-50", reset_dvars);
	ss.vehicle_influencer_score_curve =	set_dvar_if_unset("scr_spawn_vehicle_influencer_score_curve", "linear", reset_dvars);
	ss.vehicle_influencer_lead_seconds =	set_dvar_float_if_unset("scr_spawn_vehicle_influencer_lead_seconds", "3", reset_dvars); // The influencer will project out this far in time, based on vehicle speed
	
	// dog influencer
	ss.dog_influencer_score =	set_dvar_float_if_unset("scr_spawn_dog_influencer_score", "-150", reset_dvars);
	ss.dog_influencer_score_curve =	set_dvar_if_unset("scr_spawn_dog_influencer_score_curve", "steep", reset_dvars);
	ss.dog_influencer_radius =	set_dvar_float_if_unset("scr_spawn_dog_influencer_radius", "" + 15.0*k_player_height, reset_dvars);
	
	// artillery strike influencer
	ss.artillery_influencer_score =	set_dvar_float_if_unset("scr_spawn_artillery_influencer_score", "-600", reset_dvars);
	ss.artillery_influencer_score_curve =	set_dvar_if_unset("scr_spawn_artillery_influencer_score_curve", "linear", reset_dvars);
	ss.artillery_influencer_radius =	set_dvar_float_if_unset("scr_spawn_artillery_influencer_radius", "1200", reset_dvars);
	// radius determined @ runtime
	
	// grenade influencer
	ss.grenade_influencer_score =	set_dvar_float_if_unset("scr_spawn_grenade_influencer_score", "-300", reset_dvars);
	ss.grenade_influencer_score_curve =	set_dvar_if_unset("scr_spawn_grenade_influencer_score_curve", "linear", reset_dvars);
	ss.grenade_influencer_radius =	set_dvar_float_if_unset("scr_spawn_grenade_influencer_radius", "" + 8.0*k_player_height, reset_dvars);
	
	ss.grenade_endpoint_influencer_score =	set_dvar_float_if_unset("scr_spawn_grenade_endpoint_influencer_score", "-300", reset_dvars);
	ss.grenade_endpoint_influencer_score_curve =	set_dvar_if_unset("scr_spawn_grenade_endpoint_influencer_score_curve", "linear", reset_dvars);
	ss.grenade_endpoint_influencer_radius =	set_dvar_float_if_unset("scr_spawn_grenade_endpoint_influencer_radius", "" + 8.0*k_player_height, reset_dvars);

	// claymore influencer
	ss.claymore_influencer_score =	set_dvar_float_if_unset("scr_spawn_claymore_influencer_score", "-450", reset_dvars);
	ss.claymore_influencer_score_curve =	set_dvar_if_unset("scr_spawn_claymore_influencer_score_curve", "linear", reset_dvars);
	ss.claymore_influencer_radius =	set_dvar_float_if_unset("scr_spawn_claymore_influencer_radius", "" + 9.0*k_player_height, reset_dvars);

	// napalm influencer
	ss.napalm_influencer_score =	set_dvar_float_if_unset("scr_spawn_napalm_influencer_score", "-500", reset_dvars);
	ss.napalm_influencer_score_curve =	set_dvar_if_unset("scr_spawn_napalm_influencer_score_curve", "linear", reset_dvars);
	ss.napalm_influencer_radius =	set_dvar_float_if_unset("scr_spawn_napalm_influencer_radius", "" + 750, reset_dvars);

	// auto-turret influencer
	ss.auto_turret_influencer_score =	set_dvar_float_if_unset("scr_spawn_auto_turret_influencer_score", "-650", reset_dvars);
	ss.auto_turret_influencer_score_curve =	set_dvar_if_unset("scr_spawn_auto_turret_influencer_score_curve", "linear", reset_dvars);
	ss.auto_turret_influencer_radius =	set_dvar_float_if_unset("scr_spawn_auto_turret_influencer_radius", "" + 1200, reset_dvars);

	// moving vehicle influencer
	ss.rcbomb_influencer_score =	set_dvar_float_if_unset("scr_spawn_rcbomb_influencer_score", "-200", reset_dvars);
	ss.rcbomb_influencer_score_curve =	set_dvar_if_unset("scr_spawn_rcbomb_influencer_score_curve", "steep", reset_dvars);
	ss.rcbomb_influencer_radius =	set_dvar_float_if_unset("scr_spawn_rcbomb_influencer_radius", "" + 25.0*k_player_height, reset_dvars);


	// enemy spawned influencer
	ss.enemy_spawned_influencer_score_curve =	set_dvar_if_unset("scr_spawn_enemy_spawned_influencer_score_curve", "constant", reset_dvars);
	if( level.teambased )
	{
		ss.enemy_spawned_influencer_score =	set_dvar_float_if_unset("scr_spawn_enemy_spawned_influencer_score", "-200", reset_dvars);
		ss.enemy_spawned_influencer_radius =	set_dvar_float_if_unset("scr_spawn_enemy_spawned_influencer_radius", "" + 1100, reset_dvars);
	}
	else
	{
		ss.enemy_spawned_influencer_score =	set_dvar_float_if_unset("scr_spawn_enemy_spawned_influencer_score", "-100", reset_dvars);
		ss.enemy_spawned_influencer_radius =	set_dvar_float_if_unset("scr_spawn_enemy_spawned_influencer_radius", "" + 400, reset_dvars);
	}


	// helicopter influencer
	ss.helicopter_influencer_score =	set_dvar_float_if_unset("scr_spawn_helicopter_influencer_score", "-500", reset_dvars);
	ss.helicopter_influencer_score_curve =	set_dvar_if_unset("scr_spawn_helicopter_influencer_score_curve", "linear", reset_dvars);
	ss.helicopter_influencer_radius =	set_dvar_float_if_unset("scr_spawn_helicopter_influencer_radius", "" + 2000, reset_dvars);
	ss.helicopter_influencer_length =	set_dvar_float_if_unset("scr_spawn_helicopter_influencer_length", "" + 3500, reset_dvars);

	// tvmissile influencer
	ss.tvmissile_influencer_score =	set_dvar_float_if_unset("scr_spawn_tvmissile_influencer_score", "-400", reset_dvars);
	ss.tvmissile_influencer_score_curve =	set_dvar_if_unset("scr_spawn_tvmissile_influencer_score_curve", "linear", reset_dvars);
	ss.tvmissile_influencer_radius =	set_dvar_float_if_unset("scr_spawn_tvmissile_influencer_radius", "" + 2000, reset_dvars);
	ss.tvmissile_influencer_length =	set_dvar_float_if_unset("scr_spawn_tvmissile_influencer_length", "" + 3000, reset_dvars);

	if (!IsDefined( ss.unifiedSideSwitching ))
		ss.unifiedSideSwitching = 1;
	
	// let the game modes set up their dvars
	[[level.gamemodeSpawnDvars]](reset_dvars);
	
	setspawnpointrandomvariation( ss.randomness_range );
}

level_use_unified_spawning( use )
{
//	if ( use )
//	{
//		level.onSpawnPlayerUnified = ::onSpawnPlayer_Unified;
//	}
//	else
//	{
//		level.onSpawnPlayerUnified = undefined;
//	}
}

/* ---------- spawn_point */

//void - self= player entity for the player who is spawning
onSpawnPlayer_Unified()
{
	prof_begin("onSpawnPlayer_Unified");
	
	//println("SPAWN:onSpawnPlayer_Unified()");
	
	/#
	if (GetDvarInt( #"scr_spawn_point_test_mode")!=0)
	{
		spawn_point = get_debug_spawnpoint( self );
		self spawn( spawn_point.origin, spawn_point.angles );
		return;
	}
	#/

	use_new_spawn_system= true;
	initial_spawn= true;
	
	if (IsDefined(self.uspawn_already_spawned))
	{
		initial_spawn= !self.uspawn_already_spawned;
	}
	
	if ( level.useStartSpawns )
	{
		use_new_spawn_system= false;
	}
	
	// no respawn points for search & destroy, so don't run the new spawning system (it would needlessly abort on respawn attempt otherwise)
	if (level.gametype=="sd")
	{
		use_new_spawn_system= false;
	}
	
	set_dvar_if_unset("scr_spawn_force_unified", "0");
	
	spawnOverride = self maps\mp\_tacticalinsertion::overrideSpawn();
	if (use_new_spawn_system || (GetDvarInt( #"scr_spawn_force_unified")!=0))
	{
		if ( !spawnOverride )
		{
			// find the most desireable spawn point, and spawn there
			spawn_point= getSpawnPoint(self);
			
			if (IsDefined(spawn_point))
			{
				// create a negative influencer for the opposition here
				create_enemy_spawned_influencers( spawn_point.origin, self.pers["team"] );

				self spawn( spawn_point.origin, spawn_point.angles );
			}
			else
			{
				println("ERROR: unable to locate a usable spawn point for player");
				maps\mp\gametypes\_callbacksetup::AbortLevel();
			}
		}
		self.lastspawntime = gettime();
		self enable_player_influencers( true );
	}
	else if ( !spawnOverride )
	{
		// old spawning logic
		[[level.onSpawnPlayer]]();
	}
	
	// remember that the player has initially spawned
	self.uspawn_already_spawned= true;
	
	prof_end("onSpawnPlayer_Unified");

	return;
}

// spawnPoint: .origin, .angles
getSpawnPoint(
	player_entity)
{
	if (level.teambased )
	{
		point_team = player_entity.pers["team"];
		influencer_team = player_entity.pers["team"];
	}
	else
	{
		point_team = "free";
		influencer_team = "free";
	}

	if (level.teambased && IsDefined(game["switchedsides"]) &&	game["switchedsides"] && level.spawnsystem.unifiedSideSwitching)
	{
		point_team = GetOtherTeam(point_team);
	}
	
	best_spawn_entity = get_best_spawnpoint( point_team, influencer_team, player_entity );
	
	player_entity.last_spawn_origin = best_spawn_entity.origin;
	
	return best_spawn_entity;
}

get_debug_spawnpoint( player )
{
	if (level.teambased )
	{
		team = player.pers["team"];
	}
	else
	{
		team = "free";
	}
	
	index = level.test_spawn_point_index;
	level.test_spawn_point_index++;
	
	if ( team == "free" )
	{
		spawn_counts = level.unified_spawn_points[ "allies" ].a.size;
		spawn_counts += level.unified_spawn_points[ "axis" ].a.size;
		
		if (level.test_spawn_point_index >= spawn_counts)
		{
			level.test_spawn_point_index= 0;
		}
		
		if (level.test_spawn_point_index >= level.unified_spawn_points[ "allies" ].a.size)
		{
			return level.unified_spawn_points[ "axis" ].a[level.test_spawn_point_index - level.unified_spawn_points[ "allies" ].a.size];
		}
		else
		{
			return level.unified_spawn_points[ "allies" ].a[level.test_spawn_point_index];
		}
	}
	else
	{
		if (level.test_spawn_point_index >= level.unified_spawn_points[ team ].a.size)
		{
			level.test_spawn_point_index= 0;
		}

		return level.unified_spawn_points[ team ].a[level.test_spawn_point_index];

	}
}

get_best_spawnpoint( point_team, influencer_team, player )
{
	scored_spawn_points = getsortedspawnpoints( point_team, influencer_team, player );
	assert(scored_spawn_points.size > 0 );
	
	if (level.teambased )
	{
		other_team = GetOtherTeam( player.pers["team"] );
	}
	else
	{
		other_team = "free";
	}
	
	spawnid = getplayerspawnid( player );
	
	best_spawn_no_sight = undefined;
	
	prof_begin("get_best_spawnpoint__");
	for (i = 0 ; i < scored_spawn_points.size; i++)
	{
		scored_spawn = scored_spawn_points[i];
		if (PositionWouldTelefrag(scored_spawn_points[i].origin))
		{
			bbPrint( "mpspawnpointsignored: reason %s spawninstanceid %i x %f y %f z %f", "telefrag", spawnid, scored_spawn_points[i].origin );
			continue;
		}
			
		if ( !isdefined(best_spawn_no_sight) )
		{
			best_spawn_no_sight = scored_spawn_points[i];
		}
		
		/*
		// RF, removed this by request. Leaving it around in case we decide to revert back to it.
		if ( isdefined( player.last_spawn_origin ) )
		{
			if ( distance( player.last_spawn_origin, scored_spawn.origin ) < 16 )
			{
 				bbPrint( "mpspawnpointsignored: reason %s spawninstanceid %i x %f y %f z %f", "repetitive spawn", spawnid, scored_spawn_points[i].origin );
				continue;
			}
		}
		*/
		
		if ( level.spawn_visibility_check_max <= i )
		{
			bbPrint( "mpspawnpointsused: reason %s spawninstanceid %i x %f y %f z %f", "reached max vis checks", spawnid, scored_spawn_points[i].origin );
			RecordUsedSpawnPoint( player, point_team, scored_spawn_points[i].origin );
			
			return best_spawn_no_sight; 
		}
		 
		if ( isspawnpointvisible(scored_spawn_points[i].origin, scored_spawn_points[i].angles, other_team, player ) )
		{
			bbPrint( "mpspawnpointsignored: reason %s spawninstanceid %i x %f y %f z %f", "enemy visible", spawnid, scored_spawn_points[i].origin );
			continue;
		}
		
		prof_end("get_best_spawnpoint__");

		bbPrint( "mpspawnpointsused: reason %s spawninstanceid %i x %f y %f z %f", "passed all checks", spawnid, scored_spawn_points[i].origin );

		RecordUsedSpawnPoint( player, point_team, scored_spawn_points[i].origin );

		return scored_spawn_points[i];
	}
	
	prof_end("get_best_spawnpoint__");
	
	// could not find anything
	if( isdefined( best_spawn_no_sight ) )
	{
		bbPrint( "mpspawnpointsused: reason %s spawninstanceid %i x %f y %f z %f", "all points checked - best_spawn_no_sight used", spawnid, best_spawn_no_sight.origin );

		RecordUsedSpawnPoint( player, point_team, best_spawn_no_sight.origin );
		
		return best_spawn_no_sight;
	}
	else
	{
		bbPrint( "mpspawnpointsused: reason %s spawninstanceid %i x %f y %f z %f", "all points checked - first point used", spawnid, scored_spawn_points[0].origin );

		RecordUsedSpawnPoint( player, point_team, scored_spawn_points[0].origin );
		
		return scored_spawn_points[0];
	}
}

// struct.a[] = a contains spawn entities
gatherSpawnEntities( player_team )
{	
	// use cached spawn points when they are available
	if ( !IsDefined( level.unified_spawn_points ) )
	{
		level.unified_spawn_points = [];
	}
	else
	{
		if ( IsDefined( level.unified_spawn_points[ player_team ] ) )
		{
			return level.unified_spawn_points[ player_team ];
		}
	}
	
	spawn_entities_s= spawn_array_struct();
	
	// We grab both new & old spawn points here. The idea is
	// that there are alot of maps already setup & designers are not
	// going to want to lay down new spawn points. So, just use the existing points
	// for each game mode.
	// For new maps, designers now only have to lay down one set of points
	// instead of one set *per game mode* (the new unified spawn points).
	// This system here allows the use of either or both.
	
	// get placed unified spawn points (the new world order)
	spawn_entities_s.a= GetEntArray( "mp_uspawn_point", "classname" );
	if ( !IsDefined(spawn_entities_s.a))
	{
		spawn_entities_s.a= [];
	}
	// also gather any old-style spawn points (the old world order)
	legacy_spawn_points= maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints(player_team);
	for (legacy_spawn_index= 0; legacy_spawn_index<legacy_spawn_points.size; legacy_spawn_index++)
	{
		spawn_entities_s.a[spawn_entities_s.a.size]= legacy_spawn_points[legacy_spawn_index];
	}
	
	level.unified_spawn_points[player_team]= spawn_entities_s;
	
	return spawn_entities_s;
}

/* ---------- private code */

/* ---------- spawn_influencer */

// These functions add the new influencers to the provided influencers array.

is_hardcore()
{
	return IsDefined( level.hardcoreMode )
		&& level.hardcoreMode;
}

teams_have_enmity(
	team1,
	team2)
{
	// If either is undefined, then we don't know; assume they are enemies.
	// If the game is straight-up deathmatch, everyone is enemies (regardless of their assigned teams).
	if ( !IsDefined( team1 ) || !IsDefined( team2 ) || (level.gameType=="dm"))
		return true;
	
	return team1 != "neutral"
		&& team2 != "neutral"
		&& team1 != team2;
}

// Really would like to get rid of these gametype specific references to spawn points
// from this file, however right now there is no way of getting a array of
// all spawnpoints in a level.  They have to be asked for by classname.
remove_unused_spawn_entities()
{
	spawn_entity_types = [];
	
	// dm
	spawn_entity_types[ spawn_entity_types.size ] = "mp_dm_spawn";
	
	// tdm 
	spawn_entity_types[ spawn_entity_types.size ] = "mp_tdm_spawn_allies_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_tdm_spawn_axis_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_tdm_spawn";
	
	// ctf
	spawn_entity_types[ spawn_entity_types.size ] = "mp_ctf_spawn_allies_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_ctf_spawn_axis_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_ctf_spawn_allies";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_ctf_spawn_axis";
	
	// dom
	spawn_entity_types[ spawn_entity_types.size ] = "mp_dom_spawn_allies_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_dom_spawn_axis_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_dom_spawn";

	// koth
	// uses TDM spawns
	
	// sab
	spawn_entity_types[ spawn_entity_types.size ] = "mp_sab_spawn_allies_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_sab_spawn_axis_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_sab_spawn_allies";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_sab_spawn_axis";
	
	// sd
	spawn_entity_types[ spawn_entity_types.size ] = "mp_sd_spawn_attacker";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_sd_spawn_defender";
	
	// twar
	spawn_entity_types[ spawn_entity_types.size ] = "mp_twar_spawn_axis_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_twar_spawn_allies_start";
	spawn_entity_types[ spawn_entity_types.size ] = "mp_twar_spawn";
	
	for ( i = 0; i < spawn_entity_types.size; i++ )
	{
		if ( spawn_point_class_name_being_used( spawn_entity_types[i] ) )
			continue;
			
		spawnpoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( spawn_entity_types[i] );
		
		delete_all_spawns( spawnpoints );
	}
}

delete_all_spawns( spawnpoints )
{
	for ( i = 0; i < spawnpoints.size; i++ )
	{
		spawnpoints[i] delete();
	}
}

spawn_point_class_name_being_used( name )
{
	if ( !IsDefined( level.spawn_point_class_names ) )
	{
		return false;
	}
	
	for ( i = 0; i < level.spawn_point_class_names.size; i++ )
	{
		if ( level.spawn_point_class_names[i] == name )
		{
			return true;
		}
	}
	
	return false;
}

// callback to process spawn point changes from Radiant Live Update
CodeCallback_UpdateSpawnPoints()
{
	// rebuild the legacy spawn points
	maps\mp\gametypes\_spawnlogic::rebuildSpawnPoints( "axis" );
	maps\mp\gametypes\_spawnlogic::rebuildSpawnPoints( "allies" );
	
	// make sure the list gets completely rebuilt
	level.unified_spawn_points = undefined;
	updateAllSpawnPoints();	
}

initialSpawnProtection()
{
	if ( !IsDefined( level.spawnProtectionTime ) || level.spawnProtectionTime == 0 )
		return;
	
	self endon( "death" );
	self endon( "disconnect" );
	
	if ( !self HasPerk( "specialty_nottargetedbyai" ) )
	{
		self setPerk( "specialty_nottargetedbyai" );
		wait level.spawnProtectionTime;
		self unsetPerk( "specialty_nottargetedbyai" );
	}
}