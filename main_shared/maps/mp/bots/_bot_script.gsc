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
    switch(GetDvar( #"bot_difficulty" ))
    {
      case "fu":
      break;
      case "easy":
        self freeze_player_controls(true);
        wait 0.6;
        self freeze_player_controls(false);
      break;
      case "normal":
        self freeze_player_controls(true);
        wait 0.4;
        self freeze_player_controls(false);
      break;
      case "hard":
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

  /*if (getDvarInt("bots_play_killstreak"))
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

  /*  self thread bot_hq();

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
