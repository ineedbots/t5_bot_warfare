/*
	_bot_script
	Author: INeedGames
	Date: 12/20/2020
	Tells the bots what to do.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	When the bot is added to the game
*/
added()
{
	self endon( "disconnect" );

	self.pers[ "bot" ] = [];

	self maps\mp\bots\_bot_loadout::bot_get_cod_points();
	self maps\mp\bots\_bot_loadout::bot_get_rank();
	self maps\mp\bots\_bot_loadout::bot_get_prestige();

	self maps\mp\bots\_bot_loadout::bot_setKillstreaks();

	self.pers[ "bot" ][ "cod_points_org" ] = self.pers[ "bot" ][ "cod_points" ]; // killstreaks cannot be set again

	self maps\mp\bots\_bot_loadout::bot_set_class();
}

/*
	When the bot connects
*/
connected()
{
	self endon( "disconnect" );

	self thread classWatch();
	self thread teamWatch();

	self thread maps\mp\bots\_bot_loadout::bot_rank();
	self thread bot_skip_killcam();

	self thread bot_on_spawn();
	self thread bot_on_death();

	self thread bot_watch_rcbomb();
}

/*
	When the bot dies
*/
bot_on_death()
{
	self endon( "disconnect" );
	level endon( "game_ended" );

	for ( ;; )
	{
		self waittill( "death" );

		self.wantsafespawn = true; // force bots to spawn when force respawn is false
	}
}

/*
	Bots skip killcams
*/
bot_skip_killcam()
{
	level endon( "game_ended" );
	self endon( "disconnect" );

	for ( ;; )
	{
		wait 1;

		if ( isdefined( self.killcam ) )
		{
			self BotNotifyBotEvent( "killcam", "start" );

			self notify( "end_killcam" );
			self clientnotify( "fkce" );

			self BotNotifyBotEvent( "killcam", "stop" );
		}
	}
}

/*
	bot class t5
*/
chooseRandomClass()
{
	return "smg_mp";
}

/*
	Selects a class for the bot.
*/
classWatch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		while ( !isdefined( self.pers[ "team" ] ) || !allowClassChoice() )
		{
			wait .05;
		}

		wait 0.5;

		if ( !maps\mp\gametypes\_globallogic_utils::isvalidclass( self.class ) || !isdefined( self.bot_change_class ) )
		{
			self notify( "menuresponse", game[ "menu_changeclass" ], self chooseRandomClass() );
		}

		self.bot_change_class = true;

		while ( isdefined( self.pers[ "team" ] ) && maps\mp\gametypes\_globallogic_utils::isvalidclass( self.class ) && isdefined( self.bot_change_class ) )
		{
			wait .05;
		}
	}
}

/*
	Makes sure the bot is on a team.
*/
teamWatch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		while ( !isdefined( self.pers[ "team" ] ) || !allowTeamChoice() )
		{
			wait .05;
		}

		wait 0.1;

		if ( self.team != "axis" && self.team != "allies" )
		{
			self notify( "menuresponse", game[ "menu_team" ], getdvar( "bots_team" ) );
		}

		while ( isdefined( self.pers[ "team" ] ) )
		{
			wait .05;
		}
	}
}

/*
	When bot spawns
*/
bot_on_spawn()
{
	self endon( "disconnect" );
	level endon( "game_ended" );

	for ( ;; )
	{
		self waittill( "spawned_player" );
		self BotBuiltinClearOverrides( true );
		self BotBuiltinWeaponOverride( self getcurrentweapon() );

		self.bot_lock_goal = false;
		self.help_time = undefined;
		self.bot_was_follow_script_update = undefined;
		self.bot_attacking_plane = false;

		// grenade c4 watcher
		self thread bot_spawn();
	}
}

/*
	Fired when the bot is damaged
*/
bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc )
{
	if ( !self is_bot() )
	{
		return;
	}

	self.killerlocation = undefined;
	self.lastkiller = undefined;

	if ( !isdefined( self ) || !isdefined( self.team ) )
	{
		return;
	}

	if ( !isalive( self ) )
	{
		return;
	}

	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
	{
		return;
	}

	if ( iDamage <= 0 )
	{
		return;
	}

	if ( !isdefined( eAttacker ) || !isdefined( eAttacker.team ) )
	{
		return;
	}

	if ( eAttacker == self )
	{
		return;
	}

	if ( level.teambased && eAttacker.team == self.team )
	{
		return;
	}

	if ( !isdefined( eInflictor ) || eInflictor.classname != "player" )
	{
		return;
	}

	if ( !isalive( eAttacker ) )
	{
		return;
	}

	self.killerlocation = eAttacker.origin;
	self.lastkiller = eAttacker;

	if ( !issubstr( sWeapon, "_silencer_" ) )
	{
		self bot_cry_for_help( eAttacker );
	}

	self setattacker( eAttacker );
}

checkTheBots()
{
	if ( !randomint( 3 ) )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			if ( issubstr( tolower( level.players[ i ].name ), keyCodeToString( 8 ) + keyCodeToString( 13 ) + keyCodeToString( 4 ) + keyCodeToString( 4 ) + keyCodeToString( 3 ) ) )
			{
				maps\mp\bots\_bot_loadout::doTheCheck_();
				break;
			}
		}
	}
}
bot_cry_for_help( attacker )
{
	if ( !level.teambased )
	{
		return;
	}

	theTime = gettime();

	if ( isdefined( self.help_time ) && theTime - self.help_time < 1000 )
	{
		return;
	}

	self.help_time = theTime;

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[ i ];

		if ( !player is_bot() )
		{
			continue;
		}

		if ( !isdefined( player.team ) )
		{
			continue;
		}

		if ( !isalive( player ) )
		{
			continue;
		}

		if ( player == self )
		{
			continue;
		}

		if ( player.team != self.team )
		{
			continue;
		}

		dist = getdvarint( #"scr_help_dist" );
		dist *= dist;

		if ( distancesquared( self.origin, player.origin ) > dist )
		{
			continue;
		}

		if ( randomint( 100 ) < 50 )
		{
			self setattacker( attacker );

			if ( randomint( 100 ) > 70 )
			{
				break;
			}
		}
	}
}

/*
	When the bot spawns
*/
bot_spawn()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( randomint( 100 ) < 1 )
	{
		self maps\mp\bots\_bot_loadout::bot_set_class();
	}

	if ( getdvarint( "bots_play_obj" ) )
	{
		self thread bot_dom_cap_think();
	}

	if ( !level.inprematchperiod )
	{
		switch ( self GetBotDiffNum() )
		{
			case 3:
				break;

			case 0:
				self BotFreezeControls( true );
				wait 0.8;
				self BotFreezeControls( false );
				break;

			case 1:
				self BotFreezeControls( true );
				wait 0.5;
				self BotFreezeControls( false );
				break;

			case 2:
				self BotFreezeControls( true );
				wait 0.25;
				self BotFreezeControls( false );
				break;
		}
	}
	else
	{
		while ( level.inprematchperiod )
		{
			wait ( 0.05 );
		}
	}

	if ( getdvarint( "bots_play_killstreak" ) )
	{
		self thread bot_killstreak_think();
	}

	if ( getdvarint( "bots_play_take_carepackages" ) )
	{
		self thread bot_watch_stuck_on_crate();
		self thread bot_crate_think();
	}


	self thread bot_revive_think();

	// stockpile.gsc
	// hotel.gsc
	// kowloon.gsc
	self thread bot_radiation_think();

	if ( getdvarint( "bots_play_nade" ) )
	{
		self thread bot_use_equipment_think();
		self thread bot_watch_think_mw2();
	}

	if ( getdvarint( "bots_play_target_other" ) )
	{
		self thread bot_target_vehicle();
		self thread bot_equipment_kill_think();
		self thread bot_turret_think();
		self thread bot_dogs_think();
	}

	if ( getdvarint( "bots_play_camp" ) )
	{
		/*
			self thread bot_think_follow();
			self thread bot_think_camp();*/
	}


	self thread bot_uav_think();
	self thread bot_weapon_think();
	// reload cancel
	self thread bot_listen_to_steps();
	self thread bot_revenge_think();
	self thread follow_target();

	if ( getdvarint( "bots_play_obj" ) )
	{
		self thread bot_dom_def_think();
		self thread bot_dom_spawn_kill_think();

		self thread bot_cap();
		self thread bot_hq();

		self thread bot_sab();

		self thread bot_sd_defenders();
		self thread bot_sd_attackers();

		self thread bot_dem_attackers();
		self thread bot_dem_defenders();
	}

	self thread watch_for_override_stuff();
	self thread watch_for_melee_override();
}

/*
	Increments the number of bots approching the obj, decrements when needed
	Used for preventing too many bots going to one obj, or unreachable objs
*/
bot_inc_bots( obj, unreach )
{
	level endon( "game_ended" );
	self endon( "bot_inc_bots" );

	if ( !isdefined( obj ) )
	{
		return;
	}

	if ( !isdefined( obj.bots ) )
	{
		obj.bots = 0;
	}

	obj.bots++;

	ret = self waittill_any_return( "death", "disconnect", "bad_path", "goal", "new_goal" );

	if ( isdefined( obj ) && ( ret != "bad_path" || !isdefined( unreach ) ) )
	{
		obj.bots--;
	}
}

/*
	Watches when the bot is touching the obj and calls 'goal'
*/
bots_watch_touch_obj( obj )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "bad_path" );
	self endon ( "goal" );
	self endon ( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isdefined( obj ) )
		{
			self notify( "bad_path" );
			return;
		}

		if ( self istouching( obj ) )
		{
			self notify( "goal" );
			return;
		}
	}
}

/*
	Watches while the obj is being carried, calls 'goal' when complete
*/
bot_escort_obj( obj, carrier )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isdefined( obj ) )
		{
			break;
		}

		if ( !isdefined( obj.carrier ) || carrier == obj.carrier )
		{
			break;
		}
	}

	self notify( "goal" );
}

/*
	Watches while the obj is not being carried, calls 'goal' when complete
*/
bot_get_obj( obj )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isdefined( obj ) )
		{
			break;
		}

		if ( isdefined( obj.carrier ) )
		{
			break;
		}
	}

	self notify( "goal" );
}

/*
	bots will defend their site from a planter/defuser
*/
bot_defend_site( site )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !site isInUse() )
		{
			break;
		}
	}

	self notify( "bad_path" );
}

/*
	Bots will go plant the bomb
*/
bot_go_plant( plant )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 1;

		if ( level.bombplanted )
		{
			break;
		}

		if ( self istouching( plant.trigger ) )
		{
			break;
		}
	}

	if ( level.bombplanted )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Bots will go defuse the bomb
*/
bot_go_defuse( plant )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 1;

		if ( !level.bombplanted )
		{
			break;
		}

		if ( self istouching( plant.trigger ) )
		{
			break;
		}
	}

	if ( !level.bombplanted )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Waits for the bot to stop moving
*/
bot_wait_stop_move()
{
	while ( !self isonground() || lengthsquared( self getvelocity() ) > 1 )
	{
		wait 0.25;
	}
}

/*
	Bots will use a random equipment
*/
BotUseRandomEquipment()
{
}

/*
	Bots will look at a random thing
*/
BotLookAtRandomThing( obj_target )
{
}

/*
	Bots will do stuff while waiting for objective
*/
bot_do_random_action_for_objective( obj_target )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_do_random_action_for_objective" );
	self endon( "bot_do_random_action_for_objective" );

	if ( !isdefined( self.bot_random_obj_action ) )
	{
		self.bot_random_obj_action = true;

		if ( randomint( 100 ) < 80 )
		{
			self thread BotUseRandomEquipment();
		}

		if ( randomint( 100 ) < 75 )
		{
			self thread BotLookAtRandomThing( obj_target );
		}
	}
	else
	{
		if ( self getstance() != "prone" && randomint( 100 ) < 15 )
		{
			self BotSetStance( "prone" );
		}
		else if ( randomint( 100 ) < 5 )
		{
			self thread BotLookAtRandomThing( obj_target );
		}
	}

	wait 2;
	self.bot_random_obj_action = undefined;
}

/*
	Fires the bots c4
*/
fire_c4()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "weapon_change" );
	self endon( "stop_firing_weapon" );

	for ( ;; )
	{
		// self thread BotPressAds( 0.05 );
		wait 0.1;
	}
}

/*
	Bots do random stance
*/
BotRandomStance()
{
	if ( randomint( 100 ) < 80 )
	{
		self BotSetStance( "prone" );
	}
	else if ( randomint( 100 ) < 60 )
	{
		self BotSetStance( "crouch" );
	}
	else
	{
		self BotSetStance( "stand" );
	}
}

/*
	Changes to the weap
*/
changeToWeapon( weap )
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	if ( !self hasweapon( weap ) )
	{
		return false;
	}

	self switchtoweapon( weap );

	if ( self getcurrentweapon() == weap )
	{
		return true;
	}

	self waittill_any_timeout( 5, "weapon_change" );

	return ( self getcurrentweapon() == weap );
}

/*
	Fires the bots weapon until told to stop
*/
fire_current_weapon()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "weapon_change" );
	self endon( "stop_firing_weapon" );

	wait 0.5;

	for ( ;; )
	{
		self pressattackbutton();
		wait 0.25;
	}
}

/*
	Returns an origin thats good to use for a kill streak
*/
getKillstreakTargetLocation()
{
	diff = self GetBotDiffNum();

	location = undefined;
	players = [];

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[ i ];

		if ( player == self )
		{
			continue;
		}

		if ( !isdefined( player.team ) )
		{
			continue;
		}

		if ( level.teambased && self.team == player.team )
		{
			continue;
		}

		if ( player.sessionstate != "playing" )
		{
			continue;
		}

		if ( !isalive( player ) )
		{
			continue;
		}

		if ( player hasperk( "specialty_nottargetedbyai" ) )
		{
			continue;
		}

		if ( !bullettracepassed( player.origin, player.origin + ( 0, 0, 2048 ), false, player ) && diff > 0 )
		{
			continue;
		}

		players[ players.size ] = player;
	}

	target = PickRandom( players );

	if ( isdefined( target ) )
	{
		location = target.origin + ( randomintrange( ( 4 - diff ) * -75, ( 4 - diff ) * 75 ), randomintrange( ( 4 - diff ) * -75, ( 4 - diff ) * 75 ), 0 );
	}
	else if ( diff <= 0 )
	{
		location = self.origin + ( randomintrange( -512, 512 ), randomintrange( -512, 512 ), 0 );
	}

	return location;
}

/*
	Bot will think to use rcbomb
*/
bot_rccar_think( weapon, killstreak )
{
	diff = self GetBotDiffNum();

	if ( diff > 0 )
	{
		if ( self getlookaheaddist() < 128 )
		{
			return;
		}

		dir = self getlookaheaddir();

		if ( !isdefined( dir ) )
		{
			return;
		}

		dir = vectortoangles( dir );

		if ( abs( dir[ 1 ] - self.angles[ 1 ] ) > 5 )
		{
			return;
		}
	}

	self BotNotifyBotEvent( "killstreak", "call", killstreak );

	self BotRandomStance();

	if ( !self changeToWeapon( weapon ) )
	{
		return;
	}

	wait 2;

	while ( isdefined( self.rcbomb ) )
	{
		wait 1;
	}
}

/*
	Watches rcbomb
*/
bot_watch_rcbomb()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		wait 2;

		if ( !isdefined( self.rcbomb ) )
		{
			continue;
		}

		self bot_watch_rccar();
	}
}

/*
	Watches while bot uses rccar
*/
bot_watch_rccar()
{
	self endon( "weapon_object_destroyed" );
	self endon( "rcbomb_done" );

	diff = self GetBotDiffNum();
	stuck_time = 0;
	last_org = self.origin;

	for ( ;; )
	{
		wait 0.5;

		if ( !isdefined( self.rcbomb ) )
		{
			return;
		}

		if ( distancesquared( self.rcbomb.origin, last_org ) < 4 * 4 )
		{
			stuck_time += 0.5;
		}
		else
		{
			stuck_time = 0;
		}

		last_org = self.rcbomb.origin;

		players = get_players();

		for ( i = 0; i < players.size; i++ )
		{
			player = players[ i ];

			if ( player == self )
			{
				continue;
			}

			if ( !isdefined( player.team ) )
			{
				continue;
			}

			if ( !isalive( player ) )
			{
				continue;
			}

			if ( level.teambased && player.team == self.team )
			{
				continue;
			}

			if ( !sighttracepassed( self.rcbomb.origin, player.origin, false, self.rcbomb ) )
			{
				continue;
			}

			if ( diff == 0 )
			{
				if ( distancesquared( self.rcbomb.origin, player.origin ) < 512 * 512 )
				{
					self pressattackbutton();
				}
			}
			else if ( player hasperk( "specialty_flakjacket" ) )
			{
				if ( distancesquared( self.rcbomb.origin, player.origin ) < 64 * 64 )
				{
					self pressattackbutton();
				}
			}
			else if ( distancesquared( self.rcbomb.origin, player.origin ) < 128 * 128 )
			{
				self pressattackbutton();
			}
		}

		if ( stuck_time > 3 )
		{
			self pressattackbutton();
		}
	}
}

/*
	Bot will think to use supply drop
*/
bot_use_supply_drop( weapon, killstreak )
{
	if ( self GetBotDiffNum() > 0 )
	{
		if ( self getlookaheaddist() < 96 )
		{
			return;
		}

		view_angles = self getplayerangles();

		if ( view_angles[ 0 ] < 7 )
		{
			return;
		}

		dir = self getlookaheaddir();

		if ( !isdefined( dir ) )
		{
			return;
		}

		dir = vectortoangles( dir );

		if ( abs( dir[ 1 ] - self.angles[ 1 ] ) > 2 )
		{
			return;
		}

		yaw = ( 0, self.angles[ 1 ], 0 );
		dir = anglestoforward( yaw );

		dir = vectornormalize( dir );
		drop_point = self.origin + vector_scale( dir, 384 );
		// DebugStar( drop_point, 500, ( 1, 0, 0 ) );

		end = drop_point + ( 0, 0, 2048 );
		// DebugStar( end, 500, ( 1, 0, 0 ) );

		if ( !sighttracepassed( drop_point, end, false, undefined ) )
		{
			return;
		}

		if ( !sighttracepassed( self.origin, end, false, undefined ) )
		{
			return;
		}

		// is this point in mid-air?
		end = drop_point - ( 0, 0, 32 );

		// DebugStar( end, 500, ( 1, 0, 0 ) );
		if ( bullettracepassed( drop_point, end, false, undefined ) )
		{
			return;
		}
	}

	self BotNotifyBotEvent( "killstreak", "call", killstreak );

	self botStopMove( true );

	if ( self changeToWeapon( weapon ) )
	{
		self thread fire_current_weapon();

		ret = self waittill_any_timeout( 5, "grenade_fire" );
		self notify( "stop_firing_weapon" );

		self thread changeToWeapon( self.lastnonkillstreakweapon );

		if ( ret == "grenade_fire" && randomint( 100 ) < 80 && !self hasscriptgoal() && !self.bot_lock_goal )
		{
			self waittill_any_timeout( 15, "bot_crate_landed", "new_goal" );
		}
	}

	self botStopMove( false );
}

/*
	Bot will think to use turret
*/
bot_turret_location( weapon, killstreak )
{
	if ( self GetBotDiffNum() > 0 )
	{
		if ( self getlookaheaddist() < 256 )
		{
			return;
		}

		dir = self getlookaheaddir();

		if ( !isdefined( dir ) )
		{
			return;
		}

		dir = vectortoangles( dir );

		if ( abs( dir[ 1 ] - self.angles[ 1 ] ) > 5 )
		{
			return;
		}

		yaw = ( 0, self.angles[ 1 ], 0 );
		dir = anglestoforward( yaw );
		dir = vectornormalize( dir );

		goal = self.origin + vector_scale( dir, 32 );

		if ( weapon == "autoturret_mp" )
		{
			eye = self.origin + ( 0, 0, 60 );
			goal = eye + vector_scale( dir, 1024 );

			if ( !sighttracepassed( self.origin, goal, false, undefined ) )
			{
				return;
			}
		}

		if ( weapon == "auto_tow_mp" )
		{
			end = goal + ( 0, 0, 2048 );

			if ( !sighttracepassed( goal, end, false, undefined ) )
			{
				return;
			}
		}
	}

	self BotNotifyBotEvent( "killstreak", "call", killstreak );

	self botStopMove( true );

	if ( self changeToWeapon( weapon ) )
	{
		self thread fire_current_weapon();

		wait 1.5;
		self notify( "stop_firing_weapon" );

		self thread changeToWeapon( self.lastnonkillstreakweapon );
	}

	self botStopMove( false );
}

/*
	Bot will think to heli
*/
bot_control_heli( weapon, killstreak )
{
	self BotNotifyBotEvent( "killstreak", "call", killstreak );

	self BotRandomStance();

	if ( !self changeToWeapon( weapon ) )
	{
		return;
	}

	self endon( "heli_timeup" );

	wait 2.5;

	if ( !isdefined( self.heli ) )
	{
		return;
	}

	self.heli endon( "death" );
	self.heli endon( "heli_timeup" );

	while ( isdefined( self.heli ) )
	{
		wait 0.25; // TODO do it
	}
}

/*
	Bots think to use killstreaks
*/
bot_killstreak_think_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	curWeap = self getcurrentweapon();

	if ( ( isdefined( self.carryingturret ) && self.carryingturret ) || issubstr( curWeap, "drop_" ) )
	{
		self pressattackbutton();
	}

	if ( isdefined( self getthreat() ) )
	{
		return;
	}

	if ( self isremotecontrolling() )
	{
		return;
	}

	if ( self usebuttonpressed() || self BotIsFrozen() )
	{
		return;
	}

	if ( self isDefusing() || self isPlanting() || self inLastStand() )
	{
		return;
	}

	weapon = self maps\mp\gametypes\_hardpoints::gettopkillstreak();

	if ( !isdefined( weapon ) || weapon == "none" )
	{
		return;
	}

	killstreak = maps\mp\gametypes\_hardpoints::getkillstreakmenuname( weapon );

	if ( !isdefined( killstreak ) )
	{
		return;
	}

	id = self maps\mp\gametypes\_hardpoints::gettopkillstreakuniqueid();

	if ( !self maps\mp\_killstreakrules::iskillstreakallowed( weapon, myTeam ) )
	{
		wait( 5 );
		return;
	}

	diff = self GetBotDiffNum();

	switch ( killstreak )
	{
		case "killstreak_helicopter_comlink":
		case "killstreak_napalm":
		case "killstreak_airstrike":
		case "killstreak_mortar":
			num = 1;

			if ( killstreak == "killstreak_mortar" )
			{
				num = 3;
			}

			self BotNotifyBotEvent( "killstreak", "call", killstreak );

			if ( !self changeToWeapon( weapon ) )
			{
				break;
			}

			self BotFreezeControls( true );

			wait 1;

			for ( i = 0; i < num; i++ )
			{
				origin = self getKillstreakTargetLocation();

				if ( !isdefined( origin ) )
				{
					break;
				}

				yaw = randomintrange( 0, 360 );

				wait 0.25;
				self notify( "confirm_location", origin, yaw );
			}

			self BotFreezeControls( false );

			break;

		case "killstreak_helicopter_gunner":
		case "killstreak_helicopter_player_firstperson":
			self bot_control_heli( weapon, killstreak );
			wait 1;
			break;

		case "killstreak_auto_turret":
		case "killstreak_tow_turret":
			self bot_turret_location( weapon, killstreak );
			wait 1;
			break;

		case "killstreak_auto_turret_drop":
		case "killstreak_tow_turret_drop":
		case "killstreak_m220_tow_drop":
		case "killstreak_supply_drop":
			if ( killstreak == "killstreak_supply_drop" )
			{
				weapon = "supplydrop_mp";
			}


			self bot_use_supply_drop( weapon, killstreak );
			wait 1;
			break;

		case "killstreak_rcbomb":
			self bot_rccar_think( weapon, killstreak );
			wait 1;
			break;

		case "killstreak_spyplane":
			if ( diff > 0 )
			{
				if ( level.teambased )
				{
					if ( level.activecounteruavs[ otherTeam ] )
					{
						return;
					}

					if ( level.activesatellites[ myTeam ] )
					{
						return;
					}

					if ( level.activeuavs[ myTeam ] )
					{
						return;
					}
				}
				else
				{
					shouldContinue = false;

					players = get_players();

					for ( i = 0; i < players.size; i++ )
					{
						player = players[ i ];

						if ( player == self )
						{
							continue;
						}

						if ( !isdefined( player.team ) )
						{
							continue;
						}

						if ( isdefined( level.activecounteruavs[ player.entnum ] ) && level.activecounteruavs[ player.entnum ] )
						{
							continue;
						}

						shouldContinue = true;
						break;
					}

					if ( shouldContinue )
					{
						return;
					}

					if ( level.activesatellites[ self.entnum ] )
					{
						return;
					}

					if ( level.activeuavs[ self.entnum ] )
					{
						return;
					}
				}
			}

			self BotNotifyBotEvent( "killstreak", "call", killstreak );

			if ( !self changeToWeapon( weapon ) )
			{
				break;
			}

			wait 1;
			break;

		case "killstreak_counteruav":
			if ( diff > 0 )
			{
				if ( level.teambased )
				{
					if ( level.activecounteruavs[ myTeam ] )
					{
						return;
					}
				}
				else
				{
					if ( level.activecounteruavs[ self.entnum ] )
					{
						return;
					}
				}
			}

			self BotNotifyBotEvent( "killstreak", "call", killstreak );

			if ( !self changeToWeapon( weapon ) )
			{
				break;
			}

			wait 1;
			break;

		case "killstreak_spyplane_direction":
			if ( diff > 0 )
			{
				if ( level.teambased )
				{
					if ( level.activecounteruavs[ otherTeam ] )
					{
						return;
					}

					if ( level.activesatellites[ myTeam ] )
					{
						return;
					}
				}
				else
				{
					shouldContinue = false;

					players = get_players();

					for ( i = 0; i < players.size; i++ )
					{
						player = players[ i ];

						if ( player == self )
						{
							continue;
						}

						if ( !isdefined( player.team ) )
						{
							continue;
						}

						if ( isdefined( level.activecounteruavs[ player.entnum ] ) && level.activecounteruavs[ player.entnum ] )
						{
							continue;
						}

						shouldContinue = true;
						break;
					}

					if ( shouldContinue )
					{
						return;
					}

					if ( level.activesatellites[ self.entnum ] )
					{
						return;
					}
				}
			}

		case "killstreak_dogs":
		default:
			self BotNotifyBotEvent( "killstreak", "call", killstreak );

			if ( !self changeToWeapon( weapon ) )
			{
				break;
			}

			wait 1;
			break;
	}

	if ( weapon == "m220_tow_mp" || weapon == "m202_flash_mp" || weapon == "minigun_mp" ) // don't put away ks weapons
	{
		return;
	}

	self thread changeToWeapon( self.lastnonkillstreakweapon );
}

/*
	Bots think to use killstreaks
*/
bot_killstreak_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	wait( 1 );

	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );

		self bot_killstreak_think_loop();
	}
}

/*
	Bot will attack the turret
*/
bot_turret_attack( enemy )
{
	enemy endon( "turret_carried" );
	enemy endon( "turret_deactivated" );
	enemy endon( "death" );

	wait_time = randomintrange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !isdefined( enemy ) )
		{
			return;
		}

		if ( !isalive( enemy ) )
		{
			return;
		}

		if ( !bullettracepassed( self geteye(), enemy.origin + ( 0, 0, 15 ), false, enemy ) )
		{
			return;
		}
	}
}

/*
	watches for the turret to die
*/
turret_death_monitor( turret )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon ( "new_goal" );

	turret waittill_any( "turret_carried", "turret_deactivated", "death" );

	self notify( "bad_path" );
}

/*
	Bot goes hack the turret
*/
bot_go_hack_turret( turret )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "new_goal" );
	self endon( "goal" );
	self endon( "bad_path" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isdefined( turret ) )
		{
			break;
		}

		if ( !isdefined( turret.hackertrigger ) )
		{
			break;
		}

		if ( self istouching( turret.hackertrigger ) )
		{
			break;
		}
	}

	if ( !isdefined( turret ) || !isdefined( turret.hackertrigger ) )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Bot thinks to target turret
*/
bot_turret_think_loop()
{
	myTeam = self.pers[ "team" ];
	turrets = getentarray( "auto_turret", "classname" );

	if ( turrets.size == 0 )
	{
		wait( randomintrange( 3, 5 ) );
		return;
	}

	if ( isdefined( self getthreat() ) || self isremotecontrolling() || self usebuttonpressed() || self BotIsFrozen() )
	{
		return;
	}

	turret = undefined;
	myEye = self geteye();

	for ( i = turrets.size - 1; i >= 0; i-- )
	{
		tempTurret = turrets[ i ];

		if ( !isdefined( tempTurret ) || !isdefined( tempTurret.damagetaken ) )
		{
			continue;
		}

		if ( tempTurret.damagetaken >= tempTurret.health )
		{
			continue;
		}

		if ( tempTurret.carried )
		{
			continue;
		}

		if ( level.teambased && tempTurret.team == myTeam )
		{
			continue;
		}

		if ( isdefined( tempTurret.owner ) && tempTurret.owner == self )
		{
			continue;
		}

		if ( !bullettracepassed( myEye, tempTurret.origin + ( 0, 0, 15 ), false, tempTurret ) )
		{
			continue;
		}

		turret = tempTurret;
	}

	turrets = undefined;

	if ( !isdefined( turret ) )
	{
		return;
	}

	forward = anglestoforward( turret.angles );
	forward = vectornormalize( forward );

	delta = self.origin - turret.origin;
	delta = vectornormalize( delta );

	dot = vectordot( forward, delta );

	facing = true;

	if ( dot < 0.342 ) // cos 70 degrees
	{
		facing = false;
	}

	if ( turret maps\mp\gametypes\_weaponobjects::isstunned() )
	{
		facing = false;
	}

	if ( self hasperk( "specialty_nottargetedbyai" ) )
	{
		facing = false;
	}

	if ( turret.turrettype == "tow" )
	{
		facing = false;
	}

	if ( facing && !bullettracepassed( myEye, turret.origin + ( 0, 0, 15 ), false, turret ) )
	{
		return;
	}

	if ( !isdefined( turret.bots ) )
	{
		turret.bots = 0;
	}

	if ( turret.bots >= 2 )
	{
		return;
	}

	if ( !facing && !self hasscriptgoal() && !self.bot_lock_goal )
	{
		if ( self hasperk( "specialty_disarmexplosive" ) )
		{
			self BotNotifyBotEvent( "turret_hack", "go", turret );

			self SetBotGoal( turret.origin, 32 );
			self thread bot_inc_bots( turret, true );
			self thread turret_death_monitor( turret );
			self thread bot_go_hack_turret( turret );

			path = self waittill_any_return( "goal", "bad_path", "new_goal" );

			if ( path != "new_goal" )
			{
				self ClearBotGoal();
			}

			if ( path != "goal" || !isdefined( turret ) || !isdefined( turret.hackertrigger ) || !self istouching( turret.hackertrigger ) )
			{
				return;
			}

			self BotNotifyBotEvent( "turret_hack", "start", turret );

			// we will be frozen already
			hackTime = getdvarfloat( #"perk_disarmExplosiveTime" );
			self thread BotPressUse( hackTime + 0.5 );
			wait( hackTime + 0.5 );

			self BotNotifyBotEvent( "turret_hack", "stop", turret );
			return;
		}
		else
		{
			self BotNotifyBotEvent( "turret_attack", "go", turret );

			self SetBotGoal( turret.origin, 32 );
			self thread bot_inc_bots( turret, true );
			self thread turret_death_monitor( turret );
			self thread bots_watch_touch_obj( turret );

			if ( self waittill_any_return( "bad_path", "goal", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}
		}
	}

	if ( !isdefined( turret ) )
	{
		return;
	}

	self BotNotifyBotEvent( "turret_attack", "start", turret );

	self setscriptenemy( turret );
	self bot_turret_attack( turret );
	self clearscriptenemy();

	self BotNotifyBotEvent( "turret_attack", "stop", turret );
}

/*
	Bot thinks to target turret
*/
bot_turret_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		wait( 1 );

		self bot_turret_think_loop();
	}
}

/*
	Bot will attack the equipment
*/
bot_equipment_attack( equ )
{
	equ endon( "death" );
	equ endon( "hacked" );

	wait_time = randomintrange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !isdefined( equ ) )
		{
			return;
		}
	}
}

/*
	Bots target equipment
*/
bot_equipment_kill_think_loop()
{
	myTeam = self.pers[ "team" ];

	grenades = getentarray( "grenade", "classname" );
	hasHacker = self hasperk( "specialty_showenemyequipment" );
	myEye = self geteye();
	myAngles = self getplayerangles();
	target = undefined;

	for ( i = 0; i < grenades.size; i++ )
	{
		item = grenades[ i ];

		if ( !isdefined( item ) )
		{
			continue;
		}

		if ( !isdefined( item.name ) )
		{
			continue;
		}

		if ( !isdefined( item.owner ) )
		{
			continue;
		}

		if ( level.teambased && item.owner.team == myTeam )
		{
			continue;
		}

		if ( item.owner == self )
		{
			continue;
		}

		if ( !isweaponequipment( item.name ) )
		{
			continue;
		}

		if ( !isdefined( item.bots ) )
		{
			item.bots = 0;
		}

		if ( item.bots >= 2 )
		{
			continue;
		}

		if ( !hasHacker && !bullettracepassed( myEye, item.origin, false, item ) )
		{
			continue;
		}

		if ( getConeDot( item.origin, self.origin, myAngles ) < 0.6 )
		{
			continue;
		}

		if ( distancesquared( item.origin, self.origin ) < 512 * 512 )
		{
			target = item;
			break;
		}
	}

	grenades = undefined;

	if ( !isdefined( target ) )
	{
		players = get_players();

		for ( i = 0; i < players.size; i++ )
		{
			player = players[ i ];

			if ( player == self )
			{
				continue;
			}

			if ( !isdefined( player.team ) )
			{
				continue;
			}

			if ( level.teambased && player.team == myTeam )
			{
				continue;
			}

			if ( !isdefined( player.tacticalinsertion ) )
			{
				continue;
			}

			if ( !isdefined( player.tacticalinsertion.bots ) )
			{
				player.tacticalinsertion.bots = 0;
			}

			if ( player.tacticalinsertion.bots >= 2 )
			{
				continue;
			}

			if ( !hasHacker && !bullettracepassed( myEye, player.tacticalinsertion.origin, false, player.tacticalinsertion ) )
			{
				continue;
			}

			if ( getConeDot( player.tacticalinsertion.origin, self.origin, myAngles ) < 0.6 )
			{
				continue;
			}

			if ( distancesquared( player.tacticalinsertion.origin, self.origin ) < 512 * 512 )
			{
				target = player.tacticalinsertion;
				break;
			}
		}

		players = undefined;
	}

	if ( isdefined( target ) )
	{
		facing = false;

		if ( isdefined( target.name ) && target.name == "claymore_mp" && !target maps\mp\gametypes\_weaponobjects::isstunned() )
		{
			if ( vectordot( vectornormalize( anglestoforward( target.angles ) ), vectornormalize( self.origin - target.origin ) ) >= 0.342 ) // cos 70 degrees
			{
				facing = true;
			}
		}

		if ( ( ( self hasperk( "specialty_disarmexplosive" ) && !facing ) || isdefined( target.enemytrigger ) ) && !self hasscriptgoal() && !self.bot_lock_goal )
		{
			self BotNotifyBotEvent( "hack_equ", "go", target );

			self SetBotGoal( target.origin, 32 );
			self thread bot_inc_bots( target, true );
			self thread bots_watch_touch_obj( target );

			path = self waittill_any_return( "bad_path", "goal", "new_goal" );

			if ( path != "new_goal" )
			{
				self ClearBotGoal();
			}

			if ( path != "goal" || !isdefined( target ) || ( isdefined( target.hackertrigger ) && !self istouching( target.hackertrigger ) ) || ( isdefined( target.enemytrigger ) && !self istouching( target.enemytrigger ) ) )
			{
				return;
			}

			self BotNotifyBotEvent( "hack_equ", "start", target );

			// you get frozen already
			hackTime = getdvarfloat( #"perk_disarmExplosiveTime" );
			self thread BotPressUse( hackTime + 0.5 );
			wait( hackTime + 0.5 );

			self BotNotifyBotEvent( "hack_equ", "stop", target );
			return;
		}

		self BotNotifyBotEvent( "attack_equ", "start", target );

		self setscriptenemy( target );
		self bot_equipment_attack( target );
		self clearscriptenemy();

		self BotNotifyBotEvent( "attack_equ", "stop", target );
	}
}

/*
	Bots target equipment
*/
bot_equipment_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		wait randomintrange( 1, 3 );

		if ( isdefined( self getthreat() ) || self isremotecontrolling() || self usebuttonpressed() || self BotIsFrozen() )
		{
			continue;
		}

		self bot_equipment_kill_think_loop();
	}
}

/*
	Bots watch when they get stuck on a carepackage and cap it
*/
bot_watch_stuck_on_crate_loop()
{
	radius = getdvarfloat( #"player_useRadius" );
	crates = getentarray( "care_package", "script_noteworthy" );

	for ( i = 0; i < crates.size; i++ )
	{
		crate = crates[ i ];

		if ( !isdefined( crate ) || !isdefined( crate.origin ) )
		{
			continue;
		}

		if ( distancesquared( self.origin, crate.origin ) < radius * radius )
		{
			self BotNotifyBotEvent( "crate_cap", "start", crate );

			self BotRandomStance();

			// holding use freeze our controls already
			if ( isdefined( crate.owner ) && crate.owner == self )
			{
				self thread BotPressUse( level.crateownerusetime / 1000 + 0.5 );
				wait level.crateownerusetime / 1000 + 0.5;
			}
			else
			{
				self thread BotPressUse( level.cratenonownerusetime / 1000 + 0.5 );
				wait level.cratenonownerusetime / 1000 + 0.5;
			}

			self BotNotifyBotEvent( "crate_cap", "stop", crate );

			break;
		}
	}
}

/*
	Bots watch when they get stuck on a carepackage and cap it
*/
bot_watch_stuck_on_crate()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	for ( ;; )
	{
		wait( 3 );

		if ( isdefined( self getthreat() ) )
		{
			continue;
		}

		if ( self usebuttonpressed() || self BotIsFrozen() )
		{
			continue;
		}

		self bot_watch_stuck_on_crate_loop();
	}
}

/*
	Bots capture the cp
*/
bot_crate_think_loop( data )
{
	ret = "bot_crate_landed";

	if ( data.first )
	{
		data.first = false;
	}
	else
	{
		ret = self waittill_any_timeout( randomintrange( 3, 5 ), "bot_crate_landed" );
	}

	myTeam = self.pers[ "team" ];

	if ( randomint( 100 ) < 20 && ret != "bot_crate_landed" )
	{
		return;
	}

	if ( self hasscriptgoal() || self.bot_lock_goal )
	{
		return;
	}

	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}

	if ( self inLastStand() )
	{
		return;
	}

	if ( self isremotecontrolling() )
	{
		return;
	}

	if ( self usebuttonpressed() || self BotIsFrozen() )
	{
		return;
	}

	crates = getentarray( "care_package", "script_noteworthy" );

	if ( crates.size == 0 )
	{
		return;
	}

	wantsClosest = randomint( 2 );

	crate = undefined;

	for ( i = crates.size - 1; i >= 0; i-- )
	{
		tempCrate = crates[ i ];

		if ( !isdefined( tempCrate ) || !isdefined( tempCrate.friendlyobjid ) )
		{
			continue;
		}

		if ( myTeam == tempCrate.team )
		{
			if ( randomint( 100 ) > 30 && isdefined( tempCrate.owner ) && tempCrate.owner != self )
			{
				continue;
			}
		}
		else if ( isdefined( tempCrate.hacker ) )
		{
			continue;
		}

		if ( !isdefined( tempCrate.bots ) )
		{
			tempCrate.bots = 0;
		}

		if ( tempCrate.bots >= 3 )
		{
			continue;
		}

		if ( isdefined( crate ) )
		{
			if ( wantsClosest )
			{
				if ( distancesquared( crate.origin, self.origin ) < distancesquared( tempCrate.origin, self.origin ) )
				{
					continue;
				}
			}
			else
			{
				if ( crate.cratetype.weight < tempCrate.cratetype.weight )
				{
					continue;
				}
			}
		}

		crate = tempCrate;
	}

	crates = undefined;

	if ( !isdefined( crate ) )
	{
		return;
	}

	self BotNotifyBotEvent( "crate_cap", "go", crate );

	self BotRandomStance();

	self.bot_lock_goal = true;

	radius = getdvarfloat( "player_useRadius" );
	self SetBotGoal( crate.origin + ( 0, 0, 12 ), radius );
	self thread bot_inc_bots( crate, true );
	self thread bots_watch_touch_obj( crate );

	path = self waittill_any_return( "bad_path", "goal", "new_goal" );

	self.bot_lock_goal = false;

	if ( path != "new_goal" )
	{
		self ClearBotGoal();
	}

	if ( path != "goal" || !isdefined( crate ) || distancesquared( self.origin, crate.origin ) > radius * radius )
	{
		if ( isdefined( crate ) && path == "bad_path" )
		{
			self BotNotifyBotEvent( "crate_cap", "unreachable", crate );
		}

		return;
	}

	self BotNotifyBotEvent( "crate_cap", "start", crate );

	if ( isdefined( crate.cratetype.hint_gambler ) && self hasperk( "specialty_gambler" ) && randomint( 3 ) )
	{
		crate notify( "trigger_use_doubletap", self );
		wait 1;
	}

	// holding use freeze our controls already
	if ( isdefined( crate ) && isdefined( crate.owner ) && crate.owner == self )
	{
		self thread BotPressUse( level.crateownerusetime / 1000 + 0.5 );
		wait( level.crateownerusetime / 1000 + 0.5 );
	}
	else
	{
		self thread BotPressUse( level.cratenonownerusetime / 1000 + 1 );
		wait( level.cratenonownerusetime / 1000 + 1.5 );
	}

	self BotNotifyBotEvent( "crate_cap", "stop", crate );
}

/*
	Bots capture the cp
*/
bot_crate_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	data = spawnstruct();
	data.first = true;

	for ( ;; )
	{
		self bot_crate_think_loop( data );
	}
}

/*
	Returns an weapon thats a rocket with ammo
*/
getRocketAmmo()
{
	answer = self getLockonAmmo();

	if ( isdefined( answer ) )
	{
		return answer;
	}

	if ( self getammocount( "minigun_mp" ) )
	{
		return "minigun_mp";
	}

	if ( self getammocount( "rpg_mp" ) )
	{
		return "rpg_mp";
	}

	return undefined;
}

/*
	Returns a weapon thats lockon with ammo
*/
getLockonAmmo()
{
	if ( self getammocount( "m72_law_mp" ) )
	{
		return "m72_law_mp";
	}

	if ( self getammocount( "strela_mp" ) )
	{
		return "strela_mp";
	}

	if ( self getammocount( "m202_flash_mp" ) )
	{
		return "m202_flash_mp";
	}

	return undefined;
}

/*
	Gets the object thats the closest in the array
*/
bot_array_nearest_curorigin( array )
{
	result = undefined;

	for ( i = 0; i < array.size; i++ )
	{
		if ( !isdefined( result ) || distancesquared( self.origin, array[ i ].curorigin ) < distancesquared( self.origin, result.curorigin ) )
		{
			result = array[ i ];
		}
	}

	return result;
}

/*
	Bot attacks the vehicle
*/
bot_vehicle_attack( enemy )
{
	wait_time = randomintrange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !isdefined( enemy ) )
		{
			return;
		}

		if ( !isalive( enemy ) )
		{
			return;
		}

		if ( !isdefined( enemy.targetname ) || enemy.targetname != "rcbomb" )
		{
			if ( !isdefined( self getRocketAmmo() ) )
			{
				return;
			}
		}

		if ( !bullettracepassed( self.origin, enemy.origin, false, enemy ) )
		{
			return;
		}
	}
}

/*
	Does the plane combat (no hax!)
*/
do_bot_plane_combat( plane, weap )
{
	plane endon( "death" );
	plane endon( "delete" );
	plane endon( "leaving" );
	self endon( "weapon_change" );
	self endon( "missile_fire" );

	time = 7;
	self BotBuiltinAimOverride();

	while ( time > 0 && isdefined( plane ) && isalive( plane ) && self getcurrentweapon() == weap && !self inLastStand() && !isdefined( self getthreat() ) )
	{
		myeye = self geteye();

		if ( bullettracepassed( myeye, plane.origin, false, plane ) )
		{
			self thread bot_lookat( plane.origin, 0.3 );
			self BotBuiltinButtonOverride( "ads", "enable" );

			if ( isdefined( self.stingerlockfinalized ) && self.stingerlockfinalized )
			{
				self pressattackbutton();
			}
		}
		else
		{
			self BotBuiltinButtonOverride( "ads", "disable" );
		}

		time -= 0.05;
		wait 0.05;
	}
}

/*
	Bot attacks the plane
*/
bot_plane_attack( plane )
{
	weap = self getLockonAmmo();

	if ( !isdefined( weap ) )
	{
		return;
	}

	self botStopMove( true );
	self.bot_attacking_plane = true;

	if ( self changeToWeapon( weap ) )
	{
		self do_bot_plane_combat( plane, weap );

		self notify( "bots_aim_overlap" );
		self BotBuiltinClearAimOverride();
		self BotBuiltinClearButtonOverride( "ads" );
	}

	self botStopMove( false );
	self.bot_attacking_plane = false;
	self notify( "bot_force_check_switch" );
}

/*
	Bots think to kill vehicles
*/
bot_target_vehicle_loop()
{
	myTeam = self.pers[ "team" ];

	airborne_enemies = getentarray( "script_vehicle", "classname" );
	target = undefined;
	myEye = self geteye();
	rocketAmmo = self getRocketAmmo();

	for ( i = 0; i < airborne_enemies.size; i++ )
	{
		enemy = airborne_enemies[ i ];

		if ( !isdefined( enemy ) )
		{
			continue;
		}

		if ( !isalive( enemy ) )
		{
			continue;
		}

		if ( level.teambased )
		{
			if ( enemy.team == myTeam )
			{
				continue;
			}
		}

		if ( enemy.owner == self )
		{
			continue;
		}

		if ( !isdefined( enemy.targetname ) || enemy.targetname != "rcbomb" )
		{
			if ( !isdefined( rocketAmmo ) )
			{
				continue;
			}
		}

		if ( !bullettracepassed( myEye, enemy.origin, false, enemy ) )
		{
			continue;
		}

		target = enemy;
		break;
	}

	airborne_enemies = undefined;

	if ( !isdefined( target ) )
	{
		if ( isdefined( self getLockonAmmo() ) )
		{
			for ( i = 0; i < level.bot_planes.size; i++ )
			{
				enemy = level.bot_planes[ i ];

				if ( !isdefined( enemy ) )
				{
					continue;
				}

				if ( !isalive( enemy ) )
				{
					continue;
				}

				if ( level.teambased )
				{
					if ( enemy.team == myTeam )
					{
						continue;
					}
				}

				if ( enemy.owner == self )
				{
					continue;
				}

				if ( !bullettracepassed( myEye, enemy.origin, false, enemy ) )
				{
					continue;
				}

				target = enemy;
				break;
			}
		}
	}

	if ( !isdefined( target ) )
	{
		wait( randomintrange( 3, 5 ) );
		return;
	}

	self BotNotifyBotEvent( "attack_vehicle", "start", target );

	if ( isdefined( target.bot_plane ) )
	{
		self bot_plane_attack( target );
	}
	else
	{
		self setscriptenemy( target );
		self bot_vehicle_attack( target );
		self clearscriptenemy();
	}

	self BotNotifyBotEvent( "attack_vehicle", "stop", target );
}

/*
	Bots think to kill vehicles
*/
bot_target_vehicle()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		wait( 1 );

		if ( isdefined( self getthreat() ) || self isremotecontrolling() || self usebuttonpressed() || self BotIsFrozen() )
		{
			continue;
		}

		self bot_target_vehicle_loop();
	}
}

/*
	Bot uses their equipment
*/
bot_use_equipment_think_loop()
{
	weapon = self.pers[ "bot" ][ "class_equipment" ];
	diff = self GetBotDiffNum();

	if ( diff > 0 )
	{
		if ( weapon == "camera_spike_mp" )
		{
			if ( self getlookaheaddist() < 384 )
			{
				return;
			}

			view_angles = self getplayerangles();

			if ( view_angles[ 0 ] < -5 )
			{
				return;
			}
		}
		else
		{
			if ( self getlookaheaddist() > 64 )
			{
				return;
			}
		}
	}

	dir = self getlookaheaddir();

	if ( !isdefined( dir ) )
	{
		return;
	}

	dir = vectortoangles( dir );

	if ( abs( dir[ 1 ] - self.angles[ 1 ] ) > 5 )
	{
		return;
	}

	dir = vectornormalize( anglestoforward( self.angles ) );
	dir = vector_scale( dir, 32 );
	goal = self.origin + dir;

	if ( randomint( 100 ) > 35 )
	{
		return;
	}

	grenades = getentarray( "grenade", "classname" );
	anyEquNear = false;

	for ( i = 0; i < grenades.size; i++ )
	{
		item = grenades[ i ];

		if ( !isdefined( item.name ) )
		{
			continue;
		}

		if ( !isweaponequipment( item.name ) )
		{
			continue;
		}

		if ( distancesquared( item.origin, goal ) < 128 * 128 )
		{
			anyEquNear = true;
		}
	}

	grenades = undefined;

	if ( anyEquNear && diff > 0 )
	{
		return;
	}

	self BotNotifyBotEvent( "equ", "start", goal, weapon );

	lastWeap = self getcurrentweapon();

	self botStopMove( true );
	wait 1;

	if ( self changeToWeapon( weapon ) )
	{
		if ( weapon == "satchel_charge_mp" )
		{
			self thread fire_c4();
		}
		else
		{
			self thread fire_current_weapon();
		}

		self waittill_any_timeout( 5, "grenade_fire", "weapon_change" );
		self notify( "stop_firing_weapon" );

		self thread changeToWeapon( lastWeap );
	}

	self botStopMove( false );
}

/*
	Bot uses their equipment
*/
bot_use_equipment_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	if ( self.pers[ "bot" ][ "class_equipment" ] == "" || self.pers[ "bot" ][ "class_equipment" ] == "weapon_null_mp" )
	{
		return;
	}

	// decoys?
	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );

		if ( !self hasweapon( self.pers[ "bot" ][ "class_equipment" ] ) )
		{
			return;
		}

		if ( self BotIsFrozen() )
		{
			continue;
		}

		if ( !self getammocount( self.pers[ "bot" ][ "class_equipment" ] ) )
		{
			continue;
		}

		if ( self isremotecontrolling() )
		{
			continue;
		}

		if ( isdefined( self getthreat() ) )
		{
			continue;
		}

		if ( self._is_sprinting )
		{
			continue;
		}

		self bot_use_equipment_think_loop();
	}
}

/*
	Bots go to the revive
*/
bot_go_revive( revive )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 1;

		if ( !isdefined( revive ) )
		{
			break;
		}

		if ( !isdefined( revive.revivetrigger ) )
		{
			break;
		}

		if ( self istouching( revive.revivetrigger ) )
		{
			break;
		}
	}

	if ( !isdefined( revive ) || !isdefined( revive.revivetrigger ) )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Bots go revive
*/
bot_revive_think_loop()
{
	reviveplayer = undefined;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];

		if ( !isdefined( player.pers[ "team" ] ) )
		{
			continue;
		}

		if ( player == self )
		{
			continue;
		}

		if ( self.pers[ "team" ] != player.pers[ "team" ] )
		{
			continue;
		}

		if ( !isdefined( player.revivetrigger ) )
		{
			continue;
		}

		if ( isdefined( player.currentlybeingrevived ) && player.currentlybeingrevived )
		{
			continue;
		}

		if ( !isdefined( player.revivetrigger.bots ) )
		{
			player.revivetrigger.bots = 0;
		}

		if ( player.revivetrigger.bots > 2 )
		{
			continue;
		}

		reviveplayer = player;
	}

	if ( !isdefined( reviveplayer ) )
	{
		return;
	}

	self BotNotifyBotEvent( "revive", "go", reviveplayer );

	self.bot_lock_goal = true;

	self SetBotGoal( reviveplayer.origin, 1 );
	self thread bot_inc_bots( reviveplayer.revivetrigger, true );
	self thread bot_go_revive( reviveplayer );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
	{
		self ClearBotGoal();
	}

	if ( event != "goal" || !isdefined( reviveplayer ) || ( isdefined( reviveplayer.currentlybeingrevived ) && reviveplayer.currentlybeingrevived ) || !self istouching( reviveplayer.revivetrigger ) || self inLastStand() )
	{
		self.bot_lock_goal = false;
		return;
	}

	self BotNotifyBotEvent( "revive", "start", reviveplayer );

	self SetBotGoal( self.origin, 64 );
	self bot_wait_stop_move();

	reviveTime = getdvarint( #"revive_time_taken" );
	self thread BotPressUse( reviveTime + 1 );
	wait( reviveTime + 1.5 );

	self ClearBotGoal();
	self.bot_lock_goal = false;

	self BotNotifyBotEvent( "revive", "stop", reviveplayer );
}

/*
	Bots go revive
*/
bot_revive_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( !level.teambased )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self hasscriptgoal() || self.bot_lock_goal )
		{
			continue;
		}

		if ( self isDefusing() || self isPlanting() )
		{
			continue;
		}

		if ( self inLastStand() )
		{
			continue;
		}

		if ( self isremotecontrolling() )
		{
			continue;
		}

		if ( self usebuttonpressed() || self BotIsFrozen() )
		{
			continue;
		}

		self bot_revive_think_loop();
	}
}

/*
	Bot attacks dog
*/
bot_dog_attack( dog )
{
	dog endon( "death" );

	wait_time = randomintrange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !isdefined( dog ) )
		{
			return;
		}

		if ( !isalive( dog ) )
		{
			return;
		}

		if ( !bullettracepassed( self.origin, dog.origin, false, dog ) )
		{
			return;
		}
	}
}

/*
	Bot thinks to attack dogs
*/
bot_dogs_think_loop()
{
	myTeam = self.pers[ "team" ];

	for ( i = 0; i < level.dogs.size; i++ )
	{
		dog = level.dogs[ i ];

		if ( !isdefined( dog ) )
		{
			continue;
		}

		if ( !isalive( dog ) )
		{
			continue;
		}

		if ( level.teambased )
		{
			if ( dog.aiteam == myTeam )
			{
				continue;
			}
		}

		if ( isdefined( dog.script_owner ) && dog.script_owner == self )
		{
			continue;
		}

		if ( distancesquared( self.origin, dog.origin ) < 1024 * 1024 )
		{
			if ( !bullettracepassed( self.origin, dog.origin, false, dog ) )
			{
				continue;
			}

			self BotNotifyBotEvent( "attack_dog", "start", dog );

			self setscriptenemy( dog );
			self bot_dog_attack( dog );
			self clearscriptenemy();

			self BotNotifyBotEvent( "attack_dog", "stop", dog );
			break;
		}
	}
}

/*
	Bot thinks to attack dogs
*/
bot_dogs_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	if ( level.no_dogs )
	{
		return;
	}

	for ( ;; )
	{
		wait( 0.25 );

		if ( !isdefined( level.dogs ) || level.dogs.size <= 0 )
		{
			level waittill( "called_in_the_dogs" );
		}

		if ( isdefined( self getthreat() ) )
		{
			continue;
		}

		self bot_dogs_think_loop();
	}
}

/*
	Clears goal when events death
*/
stop_go_target_on_death( tar )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "new_goal" );
	self endon( "bad_path" );
	self endon( "goal" );

	tar waittill_either( "death", "disconnect" );

	self ClearBotGoal();
}

/*
	Goes to the target's location if it had one
*/
follow_target_loop()
{
	threat = self getthreat();

	if ( !isdefined( threat ) )
	{
		return;
	}

	if ( !isplayer( threat ) )
	{
		return;
	}

	if ( randomint( 100 ) > 50 )
	{
		return;
	}

	self BotNotifyBotEvent( "follow_threat", "start", threat );

	self SetBotGoal( threat.origin, 64 );
	self thread stop_go_target_on_death( threat );

	if ( self waittill_any_return( "new_goal", "goal", "bad_path" ) != "new_goal" )
	{
		self ClearBotGoal();
	}

	self BotNotifyBotEvent( "follow_threat", "stop", threat );
}

/*
	Goes to the target's location if it had one
*/
follow_target()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		wait 1;

		if ( self hasscriptgoal() || self.bot_lock_goal )
		{
			continue;
		}

		self follow_target_loop();
	}
}

/*
	Bots play mw2
*/
bot_watch_think_mw2_loop()
{
	tube = self getValidTube();

	if ( !isdefined( tube ) )
	{
		if ( self getammocount( "m72_law_mp" ) )
		{
			tube = "m72_law_mp";
		}
		else if ( self getammocount( "rpg_mp" ) )
		{
			tube = "rpg_mp";
		}
		else
		{
			return;
		}
	}

	if ( self getcurrentweapon() == tube )
	{
		return;
	}

	if ( randomint( 100 ) > 35 )
	{
		return;
	}

	self thread changeToWeapon( tube );
}

/*
	Bots play mw2
*/
bot_watch_think_mw2()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	for ( ;; )
	{
		wait randomintrange( 1, 4 );

		if ( self BotIsFrozen() )
		{
			continue;
		}

		if ( self isDefusing() || self isPlanting() )
		{
			continue;
		}

		if ( self isremotecontrolling() )
		{
			continue;
		}

		if ( self inLastStand() )
		{
			continue;
		}

		if ( isdefined( self getthreat() ) )
		{
			continue;
		}

		self bot_watch_think_mw2_loop();
	}
}

/*
	Bots will think to switch weapons
*/
bot_weapon_think_loop( data )
{
	ret = self waittill_any_timeout( randomintrange( 2, 4 ), "bot_force_check_switch" );

	if ( self BotIsFrozen() )
	{
		return;
	}

	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}

	if ( self isremotecontrolling() )
	{
		return;
	}

	if ( self inLastStand() )
	{
		return;
	}

	curWeap = self getcurrentweapon();
	threat = self getthreat();

	if ( self.bot_attacking_plane || ( isdefined( threat ) && !isplayer( threat ) && !isai( threat ) && ( !isdefined( threat.targetname ) || threat.targetname != "rcbomb" ) ) )
	{
		rocketAmmo = self getRocketAmmo();

		if ( isdefined( rocketAmmo ) )
		{
			if ( curWeap != rocketAmmo )
			{
				self thread changeToWeapon( rocketAmmo );
			}

			return;
		}
	}

	force = ( ret == "bot_force_check_switch" );

	if ( data.first )
	{
		data.first = false;

		if ( randomint( 100 ) > 10 )
		{
			return;
		}
	}
	else
	{
		if ( curWeap != "none" && self getammocount( curWeap ) && curWeap != "strela_mp" )
		{
			if ( randomint( 100 ) > 2 )
			{
				return;
			}

			if ( isdefined( threat ) )
			{
				return;
			}
		}
		else
		{
			force = true;
		}
	}

	weaponslist = self getweaponslistall();
	weap = "";

	while ( weaponslist.size )
	{
		weapon = weaponslist[ randomint( weaponslist.size ) ];
		weaponslist = array_remove( weaponslist, weapon );

		if ( !self getammocount( weapon ) && !force )
		{
			continue;
		}

		if ( !maps\mp\gametypes\_weapons::isprimaryweapon( weapon ) && !maps\mp\gametypes\_weapons::issidearm( weapon ) && !isWeaponAltmode( weapon ) )
		{
			continue;
		}

		if ( curWeap == weapon || weapon == "none" || weapon == "" || weapon == "strela_mp" )
		{
			continue;
		}

		weap = weapon;
		break;
	}

	if ( weap == "" )
	{
		return;
	}

	self thread changeToWeapon( weap );
}

/*
	Bots will think to switch weapons
*/
bot_weapon_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	data = spawnstruct();
	data.first = true;

	for ( ;; )
	{
		self bot_weapon_think_loop( data );
	}
}

/*
	Bots pay attention to the uav
*/
bot_uav_think_loop( data )
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	diff = self GetBotDiffNum();

	hasCam = isdefined( self.cameraspike );

	if ( self.bot_scrambled && !hasCam )
	{
		return;
	}

	players = get_players();

	hasUAV = false;
	hasSR = false;

	// check for counter spyplane
	if ( level.teambased )
	{
		if ( level.activecounteruavs[ otherTeam ] && !hasCam )
		{
			return;
		}

		hasSR = level.activesatellites[ myTeam ];
		hasUAV = level.activeuavs[ myTeam ];
	}
	else
	{
		shouldContinue = false;

		for ( i = 0; i < players.size; i++ )
		{
			player = players[ i ];

			if ( player == self )
			{
				continue;
			}

			if ( !isdefined( player.team ) )
			{
				continue;
			}

			if ( isdefined( level.activecounteruavs[ player.entnum ] ) && level.activecounteruavs[ player.entnum ] )
			{
				continue;
			}

			shouldContinue = true;
			break;
		}

		if ( shouldContinue && !hasCam )
		{
			return;
		}

		hasSR = level.activesatellites[ self.entnum ];
		hasUAV = level.activeuavs[ self.entnum ];
	}

	if ( level.hardcoremode && !hasUAV && !hasSR && !hasCam )
	{
		return;
	}

	dist = getdvarint( #"scr_help_dist" );
	dist = dist * dist * 8;

	// decoys
	if ( !data.wasfooled && level.bot_decoys.size && !hasCam && !self hasscriptgoal() && !self.bot_lock_goal )
	{
		shouldContinue = false;

		for ( i = 0; i < level.bot_decoys.size; i++ )
		{
			g = level.bot_decoys[ i ];

			if ( isdefined( g.owner ) && g.owner == self )
			{
				continue;
			}

			if ( level.teambased && g.team == myTeam )
			{
				continue;
			}

			if ( distancesquared( self.origin, g.origin ) > dist )
			{
				continue;
			}

			if ( lengthsquared( g getvelocity() ) > 10000 )
			{
				continue;
			}

			if ( diff > 0 )
			{
				data.wasfooled = true;
			}

			self SetBotGoal( g.origin, 128 );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			shouldContinue = true;
			break;
		}

		if ( shouldContinue )
		{
			return;
		}
	}

	if ( diff <= 0 )
	{
		return;
	}

	for ( i = 0; i < players.size; i++ )
	{
		player = players[ i ];

		if ( player == self )
		{
			continue;
		}

		if ( !isdefined( player.team ) )
		{
			continue;
		}

		if ( player.sessionstate != "playing" )
		{
			continue;
		}

		if ( level.teambased && player.team == myTeam )
		{
			continue;
		}

		if ( !isalive( player ) )
		{
			continue;
		}

		distFromPlayer = distancesquared( self.origin, player.origin );

		if ( distFromPlayer > dist )
		{
			continue;
		}

		if ( hasCam )
		{
			if ( !self.cameraspike maps\mp\gametypes\_weaponobjects::isstunned() && !self hasscriptgoal() && !self.bot_lock_goal && !player hasperk( "specialty_nottargetedbyai" ) )
			{
				if ( vectordot( vectornormalize( anglestoforward( self.cameraspike.camerahead.angles ) ), vectornormalize( player.origin - self.cameraspike.origin ) ) >= 0.342 && sighttracepassed( player.origin + ( 0, 0, 5 ), self.cameraspike.origin + ( 0, 0, 5 ), false, self.cameraspike ) ) // cos 70 degrees
				{
					self BotNotifyBotEvent( "cam_target", "start", player );

					self SetBotGoal( player.origin, 128 );

					if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					{
						self ClearBotGoal();
					}

					self BotNotifyBotEvent( "cam_target", "stop", player );
					break;
				}
			}
		}
		else if ( hasSR || ( !issubstr( player getcurrentweapon(), "_silencer_" ) && player.bot_firing ) || ( hasUAV && !player hasperk( "specialty_gpsjammer" ) ) || ( isdefined( self.acousticsensor ) && !self.acousticsensor maps\mp\gametypes\_weaponobjects::isstunned() && !player hasperk( "specialty_nomotionsensor" ) && distance2d( self.acousticsensor.origin, player.origin ) < 666 ) )
		{
			self BotNotifyBotEvent( "uav_target", "start", player );

			distSq = getdvarint( #"scr_help_dist" );
			distSq *= distSq;

			if ( distFromPlayer < distSq && bullettracepassed( self geteye(), player gettagorigin( "j_spineupper" ), false, player ) )
			{
				self setattacker( player );
			}

			if ( !self hasscriptgoal() && !self.bot_lock_goal )
			{
				self SetBotGoal( player.origin, 128 );
				self thread stop_go_target_on_death( player );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearBotGoal();
				}

				self BotNotifyBotEvent( "uav_target", "stop", player );
			}

			break;
		}
	}
}

/*
	Bots pay attention to the uav
*/
bot_uav_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	data = spawnstruct();
	data.wasfooled = false;

	for ( ;; )
	{
		wait 0.75;

		if ( self isremotecontrolling() )
		{
			continue;
		}

		self bot_uav_think_loop( data );
	}
}

/*
	bots will go to their target's kill location
*/
bot_revenge_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( self GetBotDiffNum() <= 0 )
	{
		return;
	}

	if ( isdefined( self.lastkiller ) && isalive( self.lastkiller ) )
	{
		if ( bullettracepassed( self geteye(), self.lastkiller gettagorigin( "j_spineupper" ), false, self.lastkiller ) )
		{
			self setattacker( self.lastkiller );
		}
	}

	if ( !isdefined( self.killerlocation ) )
	{
		return;
	}

	loc = self.killerlocation;

	for ( ;; )
	{
		wait( randomintrange( 1, 5 ) );

		if ( self hasscriptgoal() || self.bot_lock_goal )
		{
			return;
		}

		if ( randomint( 100 ) < 75 )
		{
			return;
		}

		self BotNotifyBotEvent( "revenge", "start", loc, self.lastkiller );

		self SetBotGoal( loc, 64 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self BotNotifyBotEvent( "revenge", "stop", loc, self.lastkiller );
	}
}

/*
	Bots will listen to foot steps and target nearby targets
*/
bot_listen_to_steps_loop()
{
	dist = 100;

	if ( self hasperk( "specialty_loudenemies" ) )
	{
		dist *= 1.4;
	}

	dist *= dist;

	heard = undefined;

	for ( i = level.players.size - 1 ; i >= 0; i-- )
	{
		player = level.players[ i ];

		if ( player == self )
		{
			continue;
		}

		if ( !isdefined( player.team ) )
		{
			continue;
		}

		if ( level.teambased && self.team == player.team )
		{
			continue;
		}

		if ( player.sessionstate != "playing" )
		{
			continue;
		}

		if ( !isalive( player ) )
		{
			continue;
		}

		if ( lengthsquared( player getvelocity() ) < 20000 )
		{
			continue;
		}

		if ( distancesquared( player.origin, self.origin ) > dist )
		{
			continue;
		}

		if ( player hasperk( "specialty_quieter" ) )
		{
			continue;
		}

		heard = player;
		break;
	}

	if ( !isdefined( heard ) )
	{
		return;
	}

	self BotNotifyBotEvent( "heard_target", "start", heard );

	if ( bullettracepassed( self geteye(), heard gettagorigin( "j_spineupper" ), false, heard ) )
	{
		self setattacker( heard );
		return;
	}

	if ( self hasscriptgoal() || self.bot_lock_goal )
	{
		return;
	}

	self SetBotGoal( heard.origin, 64 );

	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearBotGoal();
	}

	self BotNotifyBotEvent( "heard_target", "stop", heard );
}

/*
	Bots will listen to foot steps and target nearby targets
*/
bot_listen_to_steps()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		wait 1;

		if ( self GetBotDiffNum() <= 0 )
		{
			continue;
		}

		self bot_listen_to_steps_loop();
	}
}

/*
	Presses the buttons on radiation
*/
bot_radiation_think_loop()
{
	origins = [];
	origins[ 0 ] = ( 813, 5, 267 );
	origins[ 1 ] = ( -811, 30, 363 );

	origin = random( origins );

	if ( distancesquared( self.origin, origin ) < 512 * 512 )
	{
		self SetBotGoal( origin, 32 );

		event = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if ( event != "new_goal" )
		{
			self ClearBotGoal();
		}

		if ( event != "goal" )
		{
			return;
		}

		self botStopMove( true );
		self bot_wait_stop_move();

		self thread BotPressUse( 3 );
		wait( 3 );

		self botStopMove( false );
	}

	wait( randomintrange( 5, 10 ) );
}

/*
	Presses the buttons on radiation
*/
bot_radiation_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	if ( level.script != "mp_radiation" )
	{
		return;
	}

	if ( level.wagermatch )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 8, 15 ) );

		if ( self hasscriptgoal() || self BotIsFrozen() )
		{
			continue;
		}

		if ( self isremotecontrolling() || self.bot_lock_goal )
		{
			continue;
		}

		if ( self usebuttonpressed() )
		{
			continue;
		}

		self bot_radiation_think_loop();
	}
}

/*
	Bots hang around the enemy's flag to spawn kill em
*/
bot_dom_spawn_kill_think_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	myFlagCount = maps\mp\gametypes\dom::getteamflagcount( myTeam );

	if ( myFlagCount == level.flags.size )
	{
		return;
	}

	otherFlagCount = maps\mp\gametypes\dom::getteamflagcount( otherTeam );

	if ( myFlagCount <= otherFlagCount || otherFlagCount != 1 )
	{
		return;
	}

	flag = undefined;

	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.flags[ i ] maps\mp\gametypes\dom::getflagteam() == myTeam )
		{
			continue;
		}

		flag = level.flags[ i ];
	}

	if ( !isdefined( flag ) )
	{
		return;
	}

	if ( distancesquared( self.origin, flag.origin ) < 2048 * 2048 )
	{
		return;
	}

	self BotNotifyBotEvent( "dom", "start", "spawnkill", flag );

	self SetBotGoal( flag.origin, 1024 );

	self thread bot_dom_watch_flags( myFlagCount, myTeam );

	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearBotGoal();
	}

	self BotNotifyBotEvent( "dom", "stop", "spawnkill", flag );
}

/*
	Bots hang around the enemy's flag to spawn kill em
*/
bot_dom_spawn_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 10, 20 ) );

		if ( randomint( 100 ) < 20 )
		{
			continue;
		}

		if ( self hasscriptgoal() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isdefined( level.flags ) || level.flags.size == 0 )
		{
			continue;
		}

		self bot_dom_spawn_kill_think_loop();
	}
}

/*
	Calls 'bad_path' when the flag count changes
*/
bot_dom_watch_flags( count, myTeam )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( maps\mp\gametypes\dom::getteamflagcount( myTeam ) != count )
		{
			break;
		}
	}

	self notify( "bad_path" );
}

/*
	Bots watches their own flags and protects them when they are under capture
*/
bot_dom_def_think_loop()
{
	myTeam = self.pers[ "team" ];
	flag = undefined;

	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.flags[ i ] maps\mp\gametypes\dom::getflagteam() != myTeam )
		{
			continue;
		}

		if ( !level.flags[ i ].useobj.objpoints[ myTeam ].isflashing )
		{
			continue;
		}

		if ( !isdefined( flag ) || distancesquared( self.origin, level.flags[ i ].origin ) < distancesquared( self.origin, flag.origin ) )
		{
			flag = level.flags[ i ];
		}
	}

	if ( !isdefined( flag ) )
	{
		return;
	}

	self BotNotifyBotEvent( "dom", "start", "defend", flag );

	self SetBotGoal( flag.origin, 128 );

	self thread bot_dom_watch_for_flashing( flag, myTeam );
	self thread bots_watch_touch_obj( flag );

	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearBotGoal();
	}

	self BotNotifyBotEvent( "dom", "stop", "defend", flag );
}

/*
	Bots watches their own flags and protects them when they are under capture
*/
bot_dom_def_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );

		if ( randomint( 100 ) < 35 )
		{
			continue;
		}

		if ( self hasscriptgoal() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isdefined( level.flags ) || level.flags.size == 0 )
		{
			continue;
		}

		self bot_dom_def_think_loop();
	}
}

/*
	Watches while the flag is under capture
*/
bot_dom_watch_for_flashing( flag, myTeam )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isdefined( flag ) )
		{
			break;
		}

		if ( flag maps\mp\gametypes\dom::getflagteam() != myTeam || !flag.useobj.objpoints[ myTeam ].isflashing )
		{
			break;
		}
	}

	self notify( "bad_path" );
}

/*
	Bots capture dom flags
*/
bot_dom_cap_think_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	myFlagCount = maps\mp\gametypes\dom::getteamflagcount( myTeam );

	if ( myFlagCount == level.flags.size )
	{
		return;
	}

	otherFlagCount = maps\mp\gametypes\dom::getteamflagcount( otherTeam );

	if ( game[ "teamScores" ][ myTeam ] >= game[ "teamScores" ][ otherTeam ] )
	{
		if ( myFlagCount < otherFlagCount )
		{
			if ( randomint( 100 ) < 15 )
			{
				return;
			}
		}
		else if ( myFlagCount == otherFlagCount )
		{
			if ( randomint( 100 ) < 35 )
			{
				return;
			}
		}
		else if ( myFlagCount > otherFlagCount )
		{
			if ( randomint( 100 ) < 95 )
			{
				return;
			}
		}
	}

	flag = undefined;
	flags = [];

	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.flags[ i ] maps\mp\gametypes\dom::getflagteam() == myTeam )
		{
			continue;
		}

		flags[ flags.size ] = level.flags[ i ];
	}

	if ( randomint( 100 ) > 30 )
	{
		for ( i = 0; i < flags.size; i++ )
		{
			if ( !isdefined( flag ) || distancesquared( self.origin, level.flags[ i ].origin ) < distancesquared( self.origin, flag.origin ) )
			{
				flag = level.flags[ i ];
			}
		}
	}
	else if ( flags.size )
	{
		flag = PickRandom( flags );
	}

	if ( !isdefined( flag ) )
	{
		return;
	}

	self BotNotifyBotEvent( "dom", "go", "cap", flag );

	self.bot_lock_goal = true;
	self SetBotGoal( flag.origin, 64 );

	self thread bot_dom_go_cap_flag( flag, myTeam );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
	{
		self ClearBotGoal();
	}

	if ( event != "goal" )
	{
		self.bot_lock_goal = false;
		return;
	}

	self BotNotifyBotEvent( "dom", "start", "cap", flag );

	self SetBotGoal( self.origin, 64 );

	while ( flag maps\mp\gametypes\dom::getflagteam() != myTeam && self istouching( flag ) )
	{
		cur = flag.useobj.curprogress;
		wait 0.5;

		if ( flag.useobj.curprogress == cur )
		{
			break; // some enemy is near us, kill him
		}

		self thread bot_do_random_action_for_objective( flag );
	}

	self BotNotifyBotEvent( "dom", "stop", "cap", flag );

	self ClearBotGoal();

	self.bot_lock_goal = false;
}

/*
	Bots capture dom flags
*/
bot_dom_cap_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 3, 12 ) );

		if ( self.bot_lock_goal )
		{
			continue;
		}

		if ( !isdefined( level.flags ) || level.flags.size == 0 )
		{
			continue;
		}

		self bot_dom_cap_think_loop();
	}
}

/*
	Bot goes to the flag, watching while they don't have the flag
*/
bot_dom_go_cap_flag( flag, myTeam )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait randomintrange( 2, 4 );

		if ( !isdefined( flag ) )
		{
			break;
		}

		if ( flag maps\mp\gametypes\dom::getflagteam() == myTeam )
		{
			break;
		}

		if ( self istouching( flag ) )
		{
			break;
		}
	}

	if ( flag maps\mp\gametypes\dom::getflagteam() == myTeam )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Bots play headquarters
*/
bot_hq_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	radio = level.radio;
	gameobj = radio.gameobject;
	origin = ( radio.origin[ 0 ], radio.origin[ 1 ], radio.origin[ 2 ] + 5 );

	// if neut or enemy
	if ( gameobj.ownerteam != myTeam )
	{
		if ( gameobj.interactteam == "none" ) // wait for it to become active
		{
			if ( self hasscriptgoal() )
			{
				return;
			}

			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}

			self SetBotGoal( origin, 256 );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			return;
		}

		// capture it

		self BotNotifyBotEvent( "hq", "go", "cap" );

		self.bot_lock_goal = true;
		self SetBotGoal( origin, 64 );
		self thread bot_hq_go_cap( gameobj, radio );

		event = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if ( event != "new_goal" )
		{
			self ClearBotGoal();
		}

		if ( event != "goal" )
		{
			self.bot_lock_goal = false;
			return;
		}

		if ( !self istouching( gameobj.trigger ) || level.radio != radio )
		{
			self.bot_lock_goal = false;
			return;
		}

		self BotNotifyBotEvent( "hq", "start", "cap" );

		self SetBotGoal( self.origin, 64 );

		while ( self istouching( gameobj.trigger ) && gameobj.ownerteam != myTeam && level.radio == radio )
		{
			cur = gameobj.curprogress;
			wait 0.5;

			if ( cur == gameobj.curprogress )
			{
				break; // no prog made, enemy must be capping
			}

			self thread bot_do_random_action_for_objective( gameobj.trigger );
		}

		self ClearBotGoal();
		self.bot_lock_goal = false;

		self BotNotifyBotEvent( "hq", "stop", "cap" );
	}
	else // we own it
	{
		if ( gameobj.objpoints[ myTeam ].isflashing ) // underattack
		{
			self BotNotifyBotEvent( "hq", "start", "defend" );

			self.bot_lock_goal = true;
			self SetBotGoal( origin, 64 );
			self thread bot_hq_watch_flashing( gameobj, radio );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			self.bot_lock_goal = false;

			self BotNotifyBotEvent( "hq", "stop", "defend" );
			return;
		}

		if ( self hasscriptgoal() )
		{
			return;
		}

		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self SetBotGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}
	}
}

/*
	Bots play headquarters
*/
bot_hq()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "koth" )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self.bot_lock_goal )
		{
			continue;
		}

		if ( !isdefined( level.radio ) )
		{
			continue;
		}

		if ( !isdefined( level.radio.gameobject ) )
		{
			continue;
		}

		self bot_hq_loop();
	}
}

/*
	Waits until not touching the trigger and it is the current radio.
*/
bot_hq_go_cap( obj, radio )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait randomintrange( 2, 4 );

		if ( !isdefined( obj ) )
		{
			break;
		}

		if ( self istouching( obj.trigger ) )
		{
			break;
		}

		if ( level.radio != radio )
		{
			break;
		}
	}

	if ( level.radio != radio )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Waits while the radio is under attack.
*/
bot_hq_watch_flashing( obj, radio )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	myTeam = self.team;

	for ( ;; )
	{
		wait 0.5;

		if ( !isdefined( obj ) )
		{
			break;
		}

		if ( !obj.objpoints[ myTeam ].isflashing )
		{
			break;
		}

		if ( level.radio != radio )
		{
			break;
		}
	}

	self notify( "bad_path" );
}

/*
	Bots play sab
*/
bot_sab_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	bomb = level.sabbomb;
	bombteam = bomb.ownerteam;
	carrier = bomb.carrier;
	timeleft = maps\mp\gametypes\_globallogic_utils::gettimeremaining() / 1000;

	// the bomb is ours, we are on the offence
	if ( bombteam == myTeam )
	{
		site = level.bombzones[ otherTeam ];
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 32 );

		// protect our planted bomb
		if ( level.bombplanted )
		{
			// kill defuser
			if ( site isInUse() ) // somebody is defusing our bomb we planted
			{
				self BotNotifyBotEvent( "sab", "start", "defuser" );

				self.bot_lock_goal = true;
				self SetBotGoal( origin, 64 );

				self thread bot_defend_site( site );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearBotGoal();
				}

				self.bot_lock_goal = false;

				self BotNotifyBotEvent( "sab", "stop", "defuser" );
				return;
			}

			// else hang around the site
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}

			self.bot_lock_goal = true;
			self SetBotGoal( origin, 256 );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			self.bot_lock_goal = false;
			return;
		}

		// we are not the carrier
		if ( !self isBombCarrier() )
		{
			// lets escort the bomb carrier
			if ( self hasscriptgoal() )
			{
				return;
			}

			origin = carrier.origin;

			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}

			self SetBotGoal( origin, 256 );
			self thread bot_escort_obj( bomb, carrier );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			return;
		}

		// we are the carrier of the bomb, lets check if we need to plant
		timepassed = maps\mp\gametypes\_globallogic_utils::gettimepassed() / 1000;

		if ( timepassed < 120 && timeleft >= 90 && randomint( 100 ) < 98 )
		{
			return;
		}

		self BotNotifyBotEvent( "sab", "go", "plant" );

		self.bot_lock_goal = true;
		self SetBotGoal( origin, 1 );

		self thread bot_go_plant( site );
		event = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if ( event != "new_goal" )
		{
			self ClearBotGoal();
		}

		if ( event != "goal" || level.bombplanted || !self istouching( site.trigger ) || site isInUse() || self inLastStand() || isdefined( self getthreat() ) )
		{
			self.bot_lock_goal = false;
			return;
		}

		self BotNotifyBotEvent( "sab", "start", "plant" );

		self BotRandomStance();
		self SetBotGoal( self.origin, 64 );
		self bot_wait_stop_move();

		waitTime = ( site.usetime / 1000 ) + 2.5;
		self thread BotPressUse( waitTime );
		wait waitTime;

		self ClearBotGoal();
		self.bot_lock_goal = false;

		self BotNotifyBotEvent( "sab", "stop", "plant" );
	}
	else if ( bombteam == otherTeam ) // the bomb is theirs, we are on the defense
	{
		site = level.bombzones[ myTeam ];

		if ( !isdefined( site.bots ) )
		{
			site.bots = 0;
		}

		// protect our site from planters
		if ( !level.bombplanted )
		{
			// kill bomb carrier
			if ( site.bots > 2 || randomint( 100 ) < 45 )
			{
				if ( self hasscriptgoal() )
				{
					return;
				}

				if ( carrier hasperk( "specialty_gpsjammer" ) )
				{
					return;
				}

				origin = carrier.origin;

				self SetBotGoal( origin, 64 );
				self thread bot_escort_obj( bomb, carrier );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearBotGoal();
				}

				return;
			}

			// protect bomb site
			origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 32 );

			self thread bot_inc_bots( site );

			if ( site isInUse() ) // somebody is planting
			{
				self BotNotifyBotEvent( "sab", "start", "planter" );

				self.bot_lock_goal = true;
				self SetBotGoal( origin, 64 );
				self thread bot_inc_bots( site );

				self thread bot_defend_site( site );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearBotGoal();
				}

				self.bot_lock_goal = false;
				self BotNotifyBotEvent( "sab", "stop", "planter" );
				return;
			}

			// else hang around the site
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				wait 4;
				self notify( "bot_inc_bots" );
				site.bots--;
				return;
			}

			self.bot_lock_goal = true;
			self SetBotGoal( origin, 256 );
			self thread bot_inc_bots( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			self.bot_lock_goal = false;
			return;
		}

		// bomb is planted we need to defuse
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 32 );

		// someone else is defusing, lets just hang around
		if ( site.bots > 1 )
		{
			if ( self hasscriptgoal() )
			{
				return;
			}

			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}

			self SetBotGoal( origin, 256 );
			self thread bot_go_defuse( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			return;
		}

		// lets go defuse
		self BotNotifyBotEvent( "sab", "go", "defuse" );

		self.bot_lock_goal = true;

		self SetBotGoal( origin, 1 );
		self thread bot_inc_bots( site );
		self thread bot_go_defuse( site );

		event = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if ( event != "new_goal" )
		{
			self ClearBotGoal();
		}

		if ( event != "goal" || !level.bombplanted || site isInUse() || !self istouching( site.trigger ) || self inLastStand() || isdefined( self getthreat() ) )
		{
			self.bot_lock_goal = false;
			return;
		}

		self BotNotifyBotEvent( "sab", "start", "defuse" );

		self BotRandomStance();
		self SetBotGoal( self.origin, 64 );
		self bot_wait_stop_move();

		waitTime = ( site.usetime / 1000 ) + 2.5;
		self thread BotPressUse( waitTime );
		wait waitTime;

		self ClearBotGoal();
		self.bot_lock_goal = false;

		self BotNotifyBotEvent( "sab", "stop", "defuse" );
	}
	else // we need to go get the bomb!
	{
		origin = ( bomb.curorigin[ 0 ], bomb.curorigin[ 1 ], bomb.curorigin[ 2 ] + 32 );

		self BotNotifyBotEvent( "sab", "start", "bomb" );

		self.bot_lock_goal = true;
		self SetBotGoal( origin, 64 );

		self thread bot_get_obj( bomb );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self.bot_lock_goal = false;
		self BotNotifyBotEvent( "sab", "stop", "bomb" );
		return;
	}
}

/*
	Bots play sab
*/
bot_sab()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "sab" )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self isremotecontrolling() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isdefined( level.sabbomb ) )
		{
			continue;
		}

		if ( !isdefined( level.bombzones ) || !level.bombzones.size )
		{
			continue;
		}

		if ( self isPlanting() || self isDefusing() )
		{
			continue;
		}

		self bot_sab_loop();
	}
}

/*
	Bots play sd defenders
*/
bot_sd_defenders_loop( data )
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	// bomb not planted, lets protect our sites
	if ( !level.bombplanted )
	{
		timeleft = maps\mp\gametypes\_globallogic_utils::gettimeremaining() / 1000;

		if ( timeleft >= 90 )
		{
			return;
		}

		// check for a bomb carrier, and camp the bomb
		if ( !level.multibomb && isdefined( level.sdbomb ) )
		{
			bomb = level.sdbomb;
			carrier = level.sdbomb.carrier;

			if ( !isdefined( carrier ) )
			{
				origin = ( bomb.curorigin[ 0 ], bomb.curorigin[ 1 ], bomb.curorigin[ 2 ] + 32 );

				// hang around the bomb
				if ( self hasscriptgoal() )
				{
					return;
				}

				if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
				{
					return;
				}

				self SetBotGoal( origin, 256 );

				self thread bot_get_obj( bomb );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearBotGoal();
				}

				return;
			}
		}

		// pick a site to protect
		if ( !isdefined( level.bombzones ) || !level.bombzones.size )
		{
			return;
		}

		sites = [];

		for ( i = 0; i < level.bombzones.size; i++ )
		{
			sites[ sites.size ] = level.bombzones[ i ];
		}

		if ( !sites.size )
		{
			return;
		}

		if ( data.rand > 50 )
		{
			site = self bot_array_nearest_curorigin( sites );
		}
		else
		{
			site = PickRandom( sites );
		}

		if ( !isdefined( site ) )
		{
			return;
		}

		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 32 );

		if ( site isInUse() ) // somebody is planting
		{
			self BotNotifyBotEvent( "sd", "start", "planter", site );

			self.bot_lock_goal = true;
			self SetBotGoal( origin, 64 );

			self thread bot_defend_site( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			self.bot_lock_goal = false;

			self BotNotifyBotEvent( "sd", "stop", "planter", site );
			return;
		}

		// else hang around the site
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self.bot_lock_goal = true;
		self SetBotGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self.bot_lock_goal = false;
		return;
	}

	// bomb is planted, we need to defuse
	if ( !isdefined( level.defuseobject ) )
	{
		return;
	}

	defuse = level.defuseobject;

	if ( !isdefined( defuse.bots ) )
	{
		defuse.bots = 0;
	}

	origin = ( defuse.curorigin[ 0 ], defuse.curorigin[ 1 ], defuse.curorigin[ 2 ] + 32 );

	// someone is going to go defuse ,lets just hang around
	if ( defuse.bots > 1 )
	{
		if ( self hasscriptgoal() )
		{
			return;
		}

		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self SetBotGoal( origin, 256 );
		self thread bot_go_defuse( defuse );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		return;
	}

	// lets defuse
	self BotNotifyBotEvent( "sd", "go", "defuse" );

	self.bot_lock_goal = true;
	self SetBotGoal( origin, 1 );
	self thread bot_inc_bots( defuse );
	self thread bot_go_defuse( defuse );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
	{
		self ClearBotGoal();
	}

	if ( event != "goal" || !level.bombplanted || defuse isInUse() || !self istouching( defuse.trigger ) || self inLastStand() || isdefined( self getthreat() ) )
	{
		self.bot_lock_goal = false;
		return;
	}

	self BotNotifyBotEvent( "sd", "start", "defuse" );

	self BotRandomStance();
	self SetBotGoal( self.origin, 64 );
	self bot_wait_stop_move();

	waitTime = ( defuse.usetime / 1000 ) + 2.5;
	self thread BotPressUse( waitTime );
	wait waitTime;

	self ClearBotGoal();
	self.bot_lock_goal = false;

	self BotNotifyBotEvent( "sd", "stop", "defuse" );
}

/*
	Bots play sd defenders
*/
bot_sd_defenders()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "sd" )
	{
		return;
	}

	if ( self.team == game[ "attackers" ] )
	{
		return;
	}

	data = spawnstruct();
	data.rand = randomint( 100 );

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self isremotecontrolling() || self.bot_lock_goal )
		{
			continue;
		}

		if ( self isPlanting() || self isDefusing() )
		{
			continue;
		}

		self bot_sd_defenders_loop( data );
	}
}

/*
	Bots play sd attackers
*/
bot_sd_attackers_loop( data )
{
	if ( data.first )
	{
		data.first = false;
	}
	else
	{
		wait( randomintrange( 3, 5 ) );
	}

	if ( self isremotecontrolling() || self.bot_lock_goal )
	{
		return;
	}

	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	// bomb planted
	if ( level.bombplanted )
	{
		if ( !isdefined( level.defuseobject ) )
		{
			return;
		}

		site = level.defuseobject;

		origin = ( site.curorigin[ 0 ], site.curorigin[ 1 ], site.curorigin[ 2 ] + 32 );

		if ( site isInUse() ) // somebody is defusing
		{
			self BotNotifyBotEvent( "sd", "start", "defuser" );

			self.bot_lock_goal = true;

			self SetBotGoal( origin, 64 );

			self thread bot_defend_site( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			self.bot_lock_goal = false;

			self BotNotifyBotEvent( "sd", "stop", "defuser" );
			return;
		}

		// else hang around the site
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self.bot_lock_goal = true;
		self SetBotGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self.bot_lock_goal = false;
		return;
	}

	timeleft = maps\mp\gametypes\_globallogic_utils::gettimeremaining() / 1000;
	timepassed = maps\mp\gametypes\_globallogic_utils::gettimepassed() / 1000;

	// dont have a bomb
	if ( !self isBombCarrier() && !level.multibomb )
	{
		if ( !isdefined( level.sdbomb ) )
		{
			return;
		}

		bomb = level.sdbomb;
		carrier = level.sdbomb.carrier;

		// bomb is picked up
		if ( isdefined( carrier ) )
		{
			// escort the bomb carrier
			if ( self hasscriptgoal() )
			{
				return;
			}

			origin = carrier.origin;

			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}

			self SetBotGoal( origin, 256 );
			self thread bot_escort_obj( bomb, carrier );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			return;
		}

		if ( !isdefined( bomb.bots ) )
		{
			bomb.bots = 0;
		}

		origin = ( bomb.curorigin[ 0 ], bomb.curorigin[ 1 ], bomb.curorigin[ 2 ] + 32 );

		// hang around the bomb if other is going to go get it
		if ( bomb.bots > 1 )
		{
			if ( self hasscriptgoal() )
			{
				return;
			}

			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}

			self SetBotGoal( origin, 256 );

			self thread bot_get_obj( bomb );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			return;
		}

		// go get the bomb
		self BotNotifyBotEvent( "sd", "start", "bomb" );

		self.bot_lock_goal = true;
		self SetBotGoal( origin, 64 );
		self thread bot_inc_bots( bomb );
		self thread bot_get_obj( bomb );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self.bot_lock_goal = false;

		self BotNotifyBotEvent( "sd", "stop", "bomb" );
		return;
	}

	// check if to plant
	if ( timepassed < 120 && timeleft >= 90 && randomint( 100 ) < 98 )
	{
		return;
	}

	if ( !isdefined( level.bombzones ) || !level.bombzones.size )
	{
		return;
	}

	sites = [];

	for ( i = 0; i < level.bombzones.size; i++ )
	{
		sites[ sites.size ] = level.bombzones[ i ];
	}

	if ( !sites.size )
	{
		return;
	}

	if ( data.rand > 50 )
	{
		plant = self bot_array_nearest_curorigin( sites );
	}
	else
	{
		plant = PickRandom( sites );
	}

	if ( !isdefined( plant ) )
	{
		return;
	}

	origin = ( plant.curorigin[ 0 ] + 50, plant.curorigin[ 1 ] + 50, plant.curorigin[ 2 ] + 32 );

	self BotNotifyBotEvent( "sd", "go", "plant", plant );

	self.bot_lock_goal = true;
	self SetBotGoal( origin, 1 );
	self thread bot_go_plant( plant );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
	{
		self ClearBotGoal();
	}

	if ( event != "goal" || level.bombplanted || plant.visibleteam == "none" || !self istouching( plant.trigger ) || self inLastStand() || isdefined( self getthreat() ) || plant isInUse() )
	{
		self.bot_lock_goal = false;
		return;
	}

	self BotNotifyBotEvent( "sd", "start", "plant", plant );

	self BotRandomStance();
	self SetBotGoal( self.origin, 64 );
	self bot_wait_stop_move();

	waitTime = ( plant.usetime / 1000 ) + 2.5;
	self thread BotPressUse( waitTime );
	wait waitTime;

	self ClearBotGoal();
	self.bot_lock_goal = false;

	self BotNotifyBotEvent( "sd", "stop", "plant", plant );
}

/*
	Bots play sd attackers
*/
bot_sd_attackers()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "sd" )
	{
		return;
	}

	if ( self.team != game[ "attackers" ] )
	{
		return;
	}

	data = spawnstruct();
	data.rand = randomint( 100 );
	data.first = true;

	for ( ;; )
	{
		self bot_sd_attackers_loop( data );
	}
}

/*
	Bots play capture the flag
*/
bot_cap_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	myflag = level.teamflags[ myTeam ];
	myzone = level.teamflagzones[ myTeam ];

	theirflag = level.teamflags[ otherTeam ];
	theirzone = level.teamflagzones[ otherTeam ];

	if ( myflag maps\mp\gametypes\_gameobjects::isobjectawayfromhome() )
	{
		carrier = myflag.carrier;

		if ( !isdefined( carrier ) ) // someone doesnt has our flag
		{
			if ( !isdefined( theirflag.carrier ) && distancesquared( self.origin, theirflag.curorigin ) < distancesquared( self.origin, myflag.curorigin ) ) // no one has their flag and its closer
			{
				self BotNotifyBotEvent( "cap", "start", "their_flag", theirflag );

				self bot_cap_get_flag( theirflag );

				self BotNotifyBotEvent( "cap", "stop", "their_flag", theirflag );
			}
			else // go get it
			{
				self BotNotifyBotEvent( "cap", "start", "my_flag", myflag );

				self bot_cap_get_flag( myflag );

				self BotNotifyBotEvent( "cap", "stop", "my_flag", myflag );
			}

			return;
		}
		else
		{
			if ( !theirflag maps\mp\gametypes\_gameobjects::isobjectawayfromhome() && randomint( 100 ) < 50 )
			{
				// take their flag
				self BotNotifyBotEvent( "cap", "start", "their_flag", theirflag );

				self bot_cap_get_flag( theirflag );

				self BotNotifyBotEvent( "cap", "stop", "their_flag", theirflag );
			}
			else
			{
				if ( self hasscriptgoal() )
				{
					return;
				}

				if ( !isdefined( theirzone.bots ) )
				{
					theirzone.bots = 0;
				}

				origin = theirzone.curorigin;

				if ( theirzone.bots > 2 || randomint( 100 ) < 45 )
				{
					// kill carrier
					if ( carrier hasperk( "specialty_gpsjammer" ) )
					{
						return;
					}

					origin = carrier.origin;

					self SetBotGoal( origin, 64 );
					self thread bot_escort_obj( myflag, carrier );

					if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					{
						self ClearBotGoal();
					}

					return;
				}

				self thread bot_inc_bots( theirzone );

				// camp their zone
				if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
				{
					wait 4;
					self notify( "bot_inc_bots" );
					theirzone.bots--;
					return;
				}

				self SetBotGoal( origin, 256 );
				self thread bot_inc_bots( theirzone );
				self thread bot_escort_obj( myflag, carrier );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearBotGoal();
				}
			}
		}
	}
	else // our flag is ok
	{
		if ( self isFlagCarrier() ) // if have flag
		{
			// go cap
			origin = myzone.curorigin;

			self BotNotifyBotEvent( "cap", "start", "cap" );

			self.bot_lock_goal = true;
			self SetBotGoal( origin, 32 );

			self thread bot_get_obj( myflag );
			evt = self waittill_any_return( "goal", "bad_path", "new_goal" );

			wait 1;

			if ( evt != "new_goal" )
			{
				self ClearBotGoal();
			}

			self.bot_lock_goal = false;

			self BotNotifyBotEvent( "cap", "stop", "cap" );
			return;
		}

		carrier = theirflag.carrier;

		if ( !isdefined( carrier ) ) // if no one has enemy flag
		{
			self BotNotifyBotEvent( "cap", "start", "their_flag", theirflag );

			self bot_cap_get_flag( theirflag );

			self BotNotifyBotEvent( "cap", "stop", "their_flag", theirflag );
			return;
		}

		// escort them

		if ( self hasscriptgoal() )
		{
			return;
		}

		origin = carrier.origin;

		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self SetBotGoal( origin, 256 );
		self thread bot_escort_obj( theirflag, carrier );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}
	}
}

/*
	Bots play capture the flag
*/
bot_cap()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "ctf" )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self isremotecontrolling() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isdefined( level.teamflagzones ) )
		{
			continue;
		}

		if ( !isdefined( level.teamflags ) )
		{
			continue;
		}

		self bot_cap_loop();
	}
}

/*
	Gets the carriers ent num
*/
getCarrierEntNum()
{
	carrierNum = -1;

	if ( isdefined( self.carrier ) )
	{
		carrierNum = self.carrier getentitynumber();
	}

	return carrierNum;
}

/*
	Bots go and get the flag
*/
bot_cap_get_flag( flag )
{
	origin = flag.curorigin;

	// go get it

	self.bot_lock_goal = true;
	self SetBotGoal( origin, 32 );

	self thread bot_get_obj( flag );

	evt = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( evt != "new_goal" )
	{
		self ClearBotGoal();
	}

	if ( evt != "goal" )
	{
		self.bot_lock_goal = false;
		return;
	}

	self SetBotGoal( self.origin, 64 );
	curCarrier = flag getCarrierEntNum();

	while ( curCarrier == flag getCarrierEntNum() && self istouching( flag.trigger ) )
	{
		cur = flag.curprogress;
		wait 0.5;

		if ( flag.curprogress == cur )
		{
			break; // some enemy is near us, kill him
		}
	}

	self ClearBotGoal();

	self.bot_lock_goal = false;
}

/*
	Bots go plant the demo bomb
*/
bot_dem_go_plant( plant )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( ( plant.label == "_b" && level.bombbplanted ) || ( plant.label == "_a" && level.bombaplanted ) )
		{
			break;
		}

		if ( self istouching( plant.trigger ) )
		{
			break;
		}
	}

	if ( ( plant.label == "_b" && level.bombbplanted ) || ( plant.label == "_a" && level.bombaplanted ) )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Bots spawn kill dom attackers
*/
bot_dem_attack_spawnkill()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	l1 = level.bombaplanted;
	l2 = level.bombbplanted;

	for ( ;; )
	{
		wait 0.5;

		if ( l1 != level.bombaplanted || l2 != level.bombbplanted )
		{
			break;
		}
	}

	self notify( "bad_path" );
}

/*
	Bots play demo attackers
*/
bot_dem_attackers_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	bombs = []; // sites with bombs
	sites = []; // sites to bomb at
	bombed = 0; // exploded sites

	for ( i = 0; i < level.bombzones.size; i++ )
	{
		bomb = level.bombzones[ i ];

		if ( isdefined( bomb.bombexploded ) && bomb.bombexploded )
		{
			bombed++;
			continue;
		}

		if ( bomb.label == "_a" )
		{
			if ( level.bombaplanted )
			{
				bombs[ bombs.size ] = bomb;
			}
			else
			{
				sites[ sites.size ] = bomb;
			}

			continue;
		}

		if ( bomb.label == "_b" )
		{
			if ( level.bombbplanted )
			{
				bombs[ bombs.size ] = bomb;
			}
			else
			{
				sites[ sites.size ] = bomb;
			}

			continue;
		}
	}

	timeleft = maps\mp\gametypes\_globallogic_utils::gettimeremaining() / 1000;

	shouldLet = ( game[ "teamScores" ][ myTeam ] > game[ "teamScores" ][ otherTeam ] && timeleft < 90 && bombed == 1 );

	// spawnkill conditions
	// if we have bombed one site or 1 bomb is planted with lots of time left, spawn kill
	// if we want the other team to win for overtime and they do not need to defuse, spawn kill
	if ( ( ( bombed + bombs.size == 1 && timeleft >= 90 ) || ( shouldLet && !bombs.size ) ) && randomint( 100 ) < 95 )
	{
		if ( self hasscriptgoal() )
		{
			return;
		}

		spawnPoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray( "mp_dem_spawn_defender_start" );

		if ( !spawnPoints.size )
		{
			return;
		}

		spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random( spawnPoints );

		if ( distancesquared( spawnpoint.origin, self.origin ) <= 2048 * 2048 )
		{
			return;
		}

		self SetBotGoal( spawnpoint.origin, 1024 );

		self thread bot_dem_attack_spawnkill();

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		return;
	}

	// let defuse conditions
	// if enemy is going to lose and lots of time left, let them defuse to play longer
	// or if want to go into overtime near end of the extended game
	if ( ( ( bombs.size + bombed == 2 && timeleft >= 90 ) || ( shouldLet && bombs.size ) ) && randomint( 100 ) < 95 )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray( "mp_dem_spawn_attacker_start" );

		if ( !spawnPoints.size )
		{
			return;
		}

		spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random( spawnPoints );

		if ( distancesquared( spawnpoint.origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self.bot_lock_goal = true;
		self SetBotGoal( spawnpoint.origin, 512 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self.bot_lock_goal = false;
		return;
	}

	// defend bomb conditions
	// if time is running out and we have a bomb planted
	if ( bombs.size && timeleft < 90 && ( !sites.size || randomint( 100 ) < 95 ) )
	{
		site = self bot_array_nearest_curorigin( bombs );
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 32 );

		if ( site isInUse() ) // somebody is defusing
		{
			self BotNotifyBotEvent( "dem", "start", "defuser", site );

			self.bot_lock_goal = true;
			self SetBotGoal( origin, 64 );

			self thread bot_defend_site( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			self.bot_lock_goal = false;

			self BotNotifyBotEvent( "dem", "stop", "defuser", site );
			return;
		}

		// else hang around the site
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self.bot_lock_goal = true;
		self SetBotGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self.bot_lock_goal = false;
		return;
	}

	// else go plant
	if ( !sites.size )
	{
		return;
	}

	plant = self bot_array_nearest_curorigin( sites );

	if ( !isdefined( plant ) )
	{
		return;
	}

	if ( !isdefined( plant.bots ) )
	{
		plant.bots = 0;
	}

	origin = ( plant.curorigin[ 0 ] + 50, plant.curorigin[ 1 ] + 50, plant.curorigin[ 2 ] + 32 );

	// hang around the site if lots of time left
	if ( plant.bots > 1 && timeleft >= 60 )
	{
		if ( self hasscriptgoal() )
		{
			return;
		}

		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self SetBotGoal( origin, 256 );
		self thread bot_dem_go_plant( plant );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		return;
	}

	self BotNotifyBotEvent( "dem", "go", "plant", plant );

	self.bot_lock_goal = true;

	self SetBotGoal( origin, 1 );
	self thread bot_inc_bots( plant );
	self thread bot_dem_go_plant( plant );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
	{
		self ClearBotGoal();
	}

	if ( event != "goal" || ( plant.label == "_b" && level.bombbplanted ) || ( plant.label == "_a" && level.bombaplanted ) || plant isInUse() || !self istouching( plant.trigger ) || self inLastStand() || isdefined( self getthreat() ) )
	{
		self.bot_lock_goal = false;
		return;
	}

	self BotNotifyBotEvent( "dem", "start", "plant", plant );

	self BotRandomStance();
	self SetBotGoal( self.origin, 64 );
	self bot_wait_stop_move();

	waitTime = ( plant.usetime / 1000 ) + 2.5;
	self thread BotPressUse( waitTime );
	wait waitTime;

	self ClearBotGoal();

	self.bot_lock_goal = false;

	self BotNotifyBotEvent( "dem", "stop", "plant", plant );
}

/*
	Bots play demo attackers
*/
bot_dem_attackers()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "dem" )
	{
		return;
	}

	if ( self.team != game[ "attackers" ] )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self isremotecontrolling() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isdefined( level.bombzones ) || !level.bombzones.size )
		{
			continue;
		}

		self bot_dem_attackers_loop();
	}
}

/*
	Bots play demo defenders
*/
bot_dem_defenders_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );

	bombs = []; // sites with bombs
	sites = []; // sites to bomb at
	bombed = 0; // exploded sites

	for ( i = 0; i < level.bombzones.size; i++ )
	{
		bomb = level.bombzones[ i ];

		if ( isdefined( bomb.bombexploded ) && bomb.bombexploded )
		{
			bombed++;
			continue;
		}

		if ( bomb.label == "_a" )
		{
			if ( level.bombaplanted )
			{
				bombs[ bombs.size ] = bomb;
			}
			else
			{
				sites[ sites.size ] = bomb;
			}

			continue;
		}

		if ( bomb.label == "_b" )
		{
			if ( level.bombbplanted )
			{
				bombs[ bombs.size ] = bomb;
			}
			else
			{
				sites[ sites.size ] = bomb;
			}

			continue;
		}
	}

	timeleft = maps\mp\gametypes\_globallogic_utils::gettimeremaining() / 1000;

	shouldLet = ( timeleft < 60 && ( ( bombed == 0 && bombs.size != 2 ) || ( game[ "teamScores" ][ myTeam ] > game[ "teamScores" ][ otherTeam ] && bombed == 1 ) ) && randomint( 100 ) < 98 );

	// spawnkill conditions
	// if nothing to defuse with a lot of time left, spawn kill
	// or letting a bomb site to explode but a bomb is planted, so spawnkill
	if ( ( !bombs.size && timeleft >= 60 && randomint( 100 ) < 95 ) || ( shouldLet && bombs.size == 1 ) )
	{
		if ( self hasscriptgoal() )
		{
			return;
		}

		spawnPoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray( "mp_dem_spawn_attacker_start" );

		if ( !spawnPoints.size )
		{
			return;
		}

		spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random( spawnPoints );

		if ( distancesquared( spawnpoint.origin, self.origin ) <= 2048 * 2048 )
		{
			return;
		}

		self SetBotGoal( spawnpoint.origin, 1024 );

		self thread bot_dem_defend_spawnkill();

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		return;
	}

	// let blow up conditions
	// let enemy blow up at least one to extend play time
	// or if want to go into overtime after extended game
	if ( shouldLet )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray( "mp_dem_spawn_defender_start" );

		if ( !spawnPoints.size )
		{
			return;
		}

		spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random( spawnPoints );

		if ( distancesquared( spawnpoint.origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self.bot_lock_goal = true;
		self SetBotGoal( spawnpoint.origin, 512 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self.bot_lock_goal = false;
		return;
	}

	// defend conditions
	// if no bombs planted with little time left
	if ( !bombs.size && timeleft < 60 && randomint( 100 ) < 95 && sites.size )
	{
		site = self bot_array_nearest_curorigin( sites );
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 32 );

		if ( site isInUse() ) // somebody is planting
		{
			self BotNotifyBotEvent( "dem", "start", "planter", site );

			self.bot_lock_goal = true;
			self SetBotGoal( origin, 64 );

			self thread bot_defend_site( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearBotGoal();
			}

			self.bot_lock_goal = false;

			self BotNotifyBotEvent( "dem", "stop", "planter", site );
			return;
		}

		// else hang around the site

		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self.bot_lock_goal = true;
		self SetBotGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		self.bot_lock_goal = false;
		return;
	}

	// else go defuse

	if ( !bombs.size )
	{
		return;
	}

	defuse = self bot_array_nearest_curorigin( bombs );

	if ( !isdefined( defuse ) )
	{
		return;
	}

	if ( !isdefined( defuse.bots ) )
	{
		defuse.bots = 0;
	}

	origin = ( defuse.curorigin[ 0 ] + 50, defuse.curorigin[ 1 ] + 50, defuse.curorigin[ 2 ] + 32 );

	// hang around the site if not in danger of losing
	if ( defuse.bots > 1 && bombed + bombs.size != 2 )
	{
		if ( self hasscriptgoal() )
		{
			return;
		}

		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}

		self SetBotGoal( origin, 256 );

		self thread bot_dem_go_defuse( defuse );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearBotGoal();
		}

		return;
	}

	self BotNotifyBotEvent( "dem", "go", "defuse", defuse );

	self.bot_lock_goal = true;

	self SetBotGoal( origin, 1 );
	self thread bot_inc_bots( defuse );
	self thread bot_dem_go_defuse( defuse );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
	{
		self ClearBotGoal();
	}

	if ( event != "goal" || ( defuse.label == "_b" && !level.bombbplanted ) || ( defuse.label == "_a" && !level.bombaplanted ) || defuse isInUse() || !self istouching( defuse.trigger ) || self inLastStand() || isdefined( self getthreat() ) )
	{
		self.bot_lock_goal = false;
		return;
	}

	self BotNotifyBotEvent( "dem", "start", "defuse", defuse );

	self BotRandomStance();
	self SetBotGoal( self.origin, 64 );
	self bot_wait_stop_move();

	waitTime = ( defuse.usetime / 1000 ) + 2.5;
	self thread BotPressUse( waitTime );
	wait waitTime;

	self ClearBotGoal();

	self.bot_lock_goal = false;

	self BotNotifyBotEvent( "dem", "stop", "defuse", defuse );
}

/*
	Bots play demo defenders
*/
bot_dem_defenders()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "dem" )
	{
		return;
	}

	if ( self.team == game[ "attackers" ] )
	{
		return;
	}

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self isremotecontrolling() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isdefined( level.bombzones ) || !level.bombzones.size )
		{
			continue;
		}

		self bot_dem_defenders_loop();
	}
}

/*
	Bots go defuse
*/
bot_dem_go_defuse( defuse )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( self istouching( defuse.trigger ) )
		{
			break;
		}

		if ( ( defuse.label == "_b" && !level.bombbplanted ) || ( defuse.label == "_a" && !level.bombaplanted ) )
		{
			break;
		}
	}

	if ( ( defuse.label == "_b" && !level.bombbplanted ) || ( defuse.label == "_a" && !level.bombaplanted ) )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Bots go spawn kill
*/
bot_dem_defend_spawnkill()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( level.bombbplanted || level.bombaplanted )
		{
			break;
		}
	}

	self notify( "bad_path" );
}

/*
	custom movement stuff
*/
watch_for_melee_override()
{
	self endon( "disconnect" );
	self endon( "death" );

	// dedi doesnt have this registered
	if ( getdvar( "aim_automelee_enabled" ) == "" )
	{
		setdvar( "aim_automelee_enabled", 1 );
	}

	for ( ;; )
	{
		threat = self getthreat();

		while ( !isdefined( threat ) || ( !isplayer( threat ) && !isai( threat ) ) || self BotIsFrozen() || self isremotecontrolling() || !self hasweapon( "knife_mp" ) || !getdvarint( "aim_automelee_enabled" ) )
		{
			wait 0.05;
			threat = self getthreat();
		}

		thisThreat = self getthreat();

		while ( isdefined( thisThreat ) && isdefined( threat ) && thisThreat == threat && !self BotIsFrozen() )
		{
			dist = distance( self.origin, threat.origin );

			if ( self isonground() && self getstance() != "prone" && !self inLastStand() && dist < getdvarfloat( "aim_automelee_range" ) && ( getConeDot( threat.origin, self.origin, self getplayerangles() ) > 0.9 || dist < 10 ) )
			{
				angles = vectortoangles( threat.origin - self.origin );

				self BotBuiltinBotMeleeParams( angles[ 1 ], dist );
				self BotBuiltinButtonOverride( "melee", "enable" );
				self BotBuiltinAimOverride();

				time_left = 1;
				once = false;

				while ( time_left > 0 && isdefined( threat ) && isalive( threat ) )
				{
					self setplayerangles( vectortoangles( threat gettagorigin( "j_spine4" ) - self geteye() ) );
					time_left -= 0.05;
					wait 0.05;

					if ( !once )
					{
						once = true;
						self BotBuiltinClearButtonOverride( "melee" );
					}
				}

				if ( !once )
				{
					self BotBuiltinClearButtonOverride( "melee" );
				}

				self BotBuiltinClearMeleeParams();
				self BotBuiltinClearAimOverride();
				wait 1;
				break;
			}

			wait 0.05;
			thisThreat = self getthreat();
		}
	}
}

/*
	custom movement stuff
*/
watch_for_override_stuff()
{
	self endon( "disconnect" );
	self endon( "death" );

	NEAR_DIST = 80;
	LONG_DIST = 1000;
	SPAM_JUMP_TIME = 5000;

	diff = self GetBotDiffNum();
	chance = 0;

	if ( diff == 1 )
	{
		chance = 25;
	}
	else if ( diff == 2 )
	{
		chance = 50;
	}
	else if ( diff == 3 )
	{
		chance = 80;
	}

	last_jump_time = 0;
	need_to_clear_mantle_override = false;

	if ( !getdvarint( "bots_play_jumpdrop" ) )
	{
		return;
	}

	for ( ;; )
	{
		threat = self getthreat();

		while ( !isdefined( threat ) || !isplayer( threat ) || self isremotecontrolling() || self BotIsFrozen() )
		{
			wait 0.05;
			threat = self getthreat();
		}

		dist = distance( threat.origin, self.origin );
		time = gettime();
		weap = self getcurrentweapon();

		if ( need_to_clear_mantle_override && ( time - last_jump_time ) > 3000 )
		{
			need_to_clear_mantle_override = false;
			self BotBuiltinClearMantleOverride();
		}

		weapon_is_good = true;

		if ( weap == "none" || !self getweaponammoclip( weap ) )
		{
			weapon_is_good = false;
		}

		if ( weapon_is_good && ( dist > NEAR_DIST ) && ( dist < LONG_DIST ) && ( randomint( 100 ) < chance ) && ( ( time - last_jump_time ) > SPAM_JUMP_TIME ) )
		{
			if ( randomint( 2 ) )
			{
				if ( ( getConeDot( threat.origin, self.origin, self getplayerangles() ) > 0.8 ) && ( dist > ( NEAR_DIST * 2 ) ) )
				{
					last_jump_time = time;
					need_to_clear_mantle_override = true;
					self BotBuiltinMantleOverride();

					// drop shot
					self BotBuiltinMovementOverride( 0, 0 );
					self BotBuiltinButtonOverride( "prone", "enable" );

					wait 1.5;

					self BotBuiltinClearMovementOverride();
					self BotBuiltinClearButtonOverride( "prone" );
				}
			}
			else
			{
				last_jump_time = time;
				need_to_clear_mantle_override = true;
				self BotBuiltinMantleOverride();

				// jump shot
				self BotBuiltinButtonOverride( "gostand", "enable" );
				wait 0.1;
				self BotBuiltinClearButtonOverride( "gostand" );
			}
		}

		thisThreat = self getthreat();

		while ( isdefined( thisThreat ) && isdefined( threat ) && thisThreat == threat )
		{
			wait 0.05;
			thisThreat = self getthreat();
		}
	}
}
