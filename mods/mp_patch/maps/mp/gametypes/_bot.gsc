#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	level.bot_decoys = [];
	level.bot_planes = [];
	
	thread bot_fixGamemodes();
	thread onPlayerConnect();
	thread bot_kick_think();
	thread bot_watch_planes();
	
	if(GetDvar("bot_allow_laststand") == "")
		SetDvar("bot_allow_laststand", 1);
	
	if(GetDvar("bot_reasonable") == "")
		SetDvar("bot_reasonable", 0);
	
	if ( level.onlineGame && !GetDvarInt( #"xblive_basictraining" ) )
	{
		if( !level.console )
		{
			thread bot_spawner_Once();
		}
		return;
	}
	
	if ( IsDefined( game[ "bots_spawned" ] ) )
	{
		return;
	}
	
	if ( !level.onlineGame )
	{
		if ( GetDvarInt( "systemlink" ) != 0 )
		{
			return;
		}
	}
	
	thread bot_add();
}

bot_killBoost()
{
	return false;
}

bot_fixGamemodes()
{
	for(i=0;i<19;i++)
	{
		if(isDefined(level.bombZones) && level.gametype == "sd")
		{
			level.isKillBoosting = ::bot_killBoost;
			for(i = 0; i < level.bombZones.size; i++)
				level.bombZones[i].onUse = ::bot_onUsePlantObjectFix;
			break;
		}
		
		wait 0.05;
	}
}

bot_onUsePlantObjectFix( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bot_bombPlanted( self, player );
		player logString( "bomb planted: " + self.label );
		
		// disable all bomb zones except this one
		for ( index = 0; index < level.bombZones.size; index++ )
		{
			if ( level.bombZones[index] == self )
				continue;
				
			level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
		}
		thread playSoundOnPlayers( "mus_sd_planted"+"_"+level.teamPostfix[player.pers["team"]] );
// removed plant audio until finalization of assest TODO : new plant sounds when assests are online		
//		player playSound( "mpl_sd_bomb_plant" );
		player notify ( "bomb_planted" );
		
		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_PLANTED_BY", player );

		if( isdefined(player.pers["plants"]) )
		{
			player.pers["plants"]++;
			player.plants = player.pers["plants"];
		}

		player maps\mp\_medals::saboteur();
		player maps\mp\gametypes\_persistence::statAddWithGameType( "PLANTS", 1 );
		
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic_score::givePlayerScore( "plant", player );
		//player thread [[level.onXPEvent]]( "plant" );
	}
}

bot_bombPlanted( destroyedObj, player )
{
	maps\mp\gametypes\_globallogic_utils::pauseTimer();
	level.bombPlanted = true;
	
	destroyedObj.visuals[0] thread maps\mp\gametypes\_globallogic_utils::playTickingSound( "mpl_sab_ui_suitcasebomb_timer" );
	//Play suspense music
	level thread maps\mp\gametypes\sd::bombPlantedMusicDelay();

	//thread maps\mp\gametypes\_globallogic_audio::actionMusicSet();					
	
	level.tickingObject = destroyedObj.visuals[0];

	level.timeLimitOverride = true;
	setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
	setMatchFlag( "bomb_timer", 1 );
	
	if ( !level.multiBomb )
	{
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setDropped();
		level.sdBombModel = level.sdBomb.visuals[0];
	}
	else
	{
		
		for ( index = 0; index < level.players.size; index++ )
		{
			if ( isDefined( level.players[index].carryIcon ) )
				level.players[index].carryIcon destroyElem();
		}

		trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
		
		tempAngle = randomfloat( 360 );
		forward = (cos( tempAngle ), sin( tempAngle ), 0);
		forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
		dropAngles = vectortoangles( forward );
		
		level.sdBombModel = spawn( "script_model", trace["position"] );
		level.sdBombModel.angles = dropAngles;
		level.sdBombModel setModel( "prop_suitcase_bomb" );
	}
	destroyedObj maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	/*
	destroyedObj maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", undefined );
	*/
	label = destroyedObj maps\mp\gametypes\_gameobjects::getLabel();
	
	// create a new object to defuse with.
	trigger = destroyedObj.bombDefuseTrig;
	trigger.origin = level.sdBombModel.origin;
	visuals = [];
	defuseObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,32) );
	defuseObject maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	defuseObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" + label );
	defuseObject.label = label;
	defuseObject.onBeginUse = maps\mp\gametypes\sd::onBeginUse;
	defuseObject.onEndUse = maps\mp\gametypes\sd::onEndUse;
	defuseObject.onUse = maps\mp\gametypes\sd::onUseDefuseObject;
	defuseObject.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.defuseObject = defuseObject;//every cod...
	
	player.isBombCarrier = false;
	
	maps\mp\gametypes\sd::BombTimerWait();
	setMatchFlag( "bomb_timer", 0 );
	
	destroyedObj.visuals[0] maps\mp\gametypes\_globallogic_utils::stopTickingSound();
	
	if ( level.gameEnded || level.bombDefused )
		return;
	
	level.bombExploded = true;
	
	
	
	explosionOrigin = level.sdBombModel.origin+(0,0,12);
	level.sdBombModel hide();
	
	if ( isdefined( player ) )
	{
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
		level thread maps\mp\_popups::DisplayTeamMessageToAll( &"MP_EXPLOSIVES_BLOWUP_BY", player );
		player maps\mp\_medals::bomber();
		player maps\mp\gametypes\_persistence::statAddWithGameType( "DESTRUCTIONS", 1 );
	}
	else
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, undefined, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );
	
	thread playSoundinSpace( "mpl_sd_exp_suitcase_bomb_main", explosionOrigin );
	//thread maps\mp\gametypes\_globallogic_audio::set_music_on_team( "SILENT", "both" );	
	
	if ( isDefined( destroyedObj.exploderIndex ) )
		exploder( destroyedObj.exploderIndex );
	
	for ( index = 0; index < level.bombZones.size; index++ )
		level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
	defuseObject maps\mp\gametypes\_gameobjects::disableObject();
	
	setGameEndTime( 0 );
	
	wait 3;
	
	maps\mp\gametypes\sd::sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );
}

bot_watch_planes()
{
	for(;;)
	{
		level waittill("uav_update");
		
		ents = GetEntArray("script_model", "classname");
		for(i = 0; i < ents.size; i++)
		{
			ent = ents[i];
			
			if(isDefined(ent.bot_plane))
				continue;
			
			if(ent.model != level.spyplanemodel)
				continue;
			
			thread watch_plane(ent);
		}
	}
}

watch_plane(ent)
{
	ent.bot_plane = true;
	
	level.bot_planes[level.bot_planes.size] = ent;
	
	ent waittill_any("death", "delete");
	
	for ( entry = 0; entry < level.bot_planes.size; entry++ )
	{
		if ( level.bot_planes[entry] == ent )
		{
			while ( entry < level.bot_planes.size-1 )
			{
				level.bot_planes[entry] = level.bot_planes[entry+1];
				entry++;
			}
			level.bot_planes[entry] = undefined;
			break;
		}
	}
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		
		player thread watch_shoot();
		player thread watch_grenade();
		
		if(player is_bot())
		{
			player thread watch();
			player thread bot_start();
		}
	}
}

watch()
{
	self endon("disconnect");
	
	self.did = "";
	for(;;)
	{
/#
		if(self getVelocity() == (0, 0, 0) && self HasScriptGoal() && isAlive(self) && self.did != "")
		{
			self sayall(self.did + " " + getTime());
			self.did = "";
		}
#/
		wait 0.05;
	}
}

watch_grenade()
{
	self endon("disconnect");
	
	self.bot_scrambled = false;
	for(;;)
	{
		self waittill("grenade_fire", g, name);
		if(name == "scrambler_mp")
		{
			g thread watch_scrambler();
		}
		else if(name == "nightingale_mp")
		{
			self thread watch_decoy(g);
		}
	}
}

watch_decoy(g)
{
	g.team = self.team;
	
	level.bot_decoys[level.bot_decoys.size] = g;
	
	g waittill("death");
	
	for ( entry = 0; entry < level.bot_decoys.size; entry++ )
	{
		if ( level.bot_decoys[entry] == g )
		{
			while ( entry < level.bot_decoys.size-1 )
			{
				level.bot_decoys[entry] = level.bot_decoys[entry+1];
				entry++;
			}
			level.bot_decoys[entry] = undefined;
			break;
		}
	}
}

watch_scrambler()
{
	trig = spawn( "trigger_radius", self.origin + (0, 0, -1000), 0, 1000, 2000 );;
	
	self scramble_nearby(trig);
	
	trig delete();
}

scramble_nearby(trig)
{
	self endon("death");
	self endon("hacked");
	
	while(!isDefined(self.owner) || !isDefined(self.owner.team))
		wait 0.05;
	
	self.team = self.owner.team;
	for(;;)
	{
		trig waittill("trigger", player);
		
		if(self maps\mp\gametypes\_weaponobjects::isStunned())
			continue;
		
		if(player == self.owner)
			continue;
		
		if(level.teamBased && self.team == player.team)
			continue;
		
		player thread scramble_player();
	}
}

scramble_player()
{
	self notify("scramble_nearby");
	self endon("scramble_nearby");
	
	self.bot_scrambled = true;
	wait 0.1;
	
	if(isDefined(self))
		self.bot_scrambled = false;
}

watch_shoot()
{
	self endon("disconnect");
	
	self.bot_firing = false;
	for(;;)
	{
		self waittill( "weapon_fired" );
		self thread doFiringThread();
	}
}

doFiringThread()
{
	self endon("disconnect");
	self endon("weapon_fired");
	
	self.bot_firing = true;
	wait 1;
	self.bot_firing = false;
}

bot_add()
{
	if ( !level.onlineGame )
	{
		humans = GetDvarInt( #"splitscreen_playerCount" );
		bot_friends = GetDvarInt( #"splitscreen_botFriends" );
		bot_enemies = GetDvarInt( #"splitscreen_botEnemies" );
		bot_difficulty = GetDvar( #"splitscreen_botDifficulty" );
	}
	else
	{
		if( level.console )
			humans = GetDvarInt( #"party_playerCount" );
		else
			humans = 1;
		bot_friends = GetDvarInt( #"bot_friends" );
		bot_enemies = GetDvarInt( #"bot_enemies" );
		bot_difficulty = GetDvar( #"bot_difficulty" );
	}
	
	if(getDvar("bot_enemies_extra") == "")
		setDvar("bot_enemies_extra", "0");
	if(getDvar("bot_friends_extra") == "")
		setDvar("bot_friends_extra", "0");
	
	bot_enemies += GetDvarInt("bot_enemies_extra");
	bot_friends += GetDvarInt("bot_friends_extra");
	
	// all humans playing
	if ( humans >= bot_friends + bot_enemies )
	{
		return;
	}

	level.autoassign = ::basic_training_auto_assign;
	bot_num_enemy = 0;
	bot_num_friendly = 0;
	
	// calculate the number of friendly bots
	if ( level.teambased )
	{
		bot_num_friendly = bot_friends - humans;
		bot_num_friendly = clamp( bot_num_friendly, 0, bot_num_friendly );
	}

	// calculate the number of enemy bots
	if ( level.teambased )
	{
		human_enemies = humans - bot_friends;
		human_enemies = clamp( human_enemies, 0, human_enemies );

		bot_num_enemy = bot_enemies - human_enemies;
	}
	else
	{
		bot_num_enemy = bot_enemies - humans + 1; //host
	}

	// sanity check
	if ( bot_num_enemy + bot_num_friendly <= 0 )
	{
		return;
	}
	
	if ( bot_difficulty == "" )
	{
		bot_difficulty = "normal";
	}
	
	bot_set_difficulty( bot_difficulty );
	
	bot_wait_for_host();
	
	player = GetHostPlayer();
	
	team = "allies";
	if(isDefined(player) && isDefined(player.pers[ "team" ]) && (player.pers[ "team" ] == "allies" || player.pers[ "team" ] == "axis"))
		team = player.pers[ "team" ];
	
	otherTeam = getOtherTeam(team);
	
	game[ "bots_spawned" ] = true;
	
	for(i = 0; i < bot_num_enemy; i++)
	{
		if(level.teamBased || randomInt(2))
			add_bot(otherTeam);
		else
			add_bot(team);
		
		wait 0.25;
	}
	
	for(i = 0; i < bot_num_friendly; i++)
	{
		add_bot(team);
		
		wait 0.25;
	}
	
	wait 5;
	
	players = get_players();
	actual_enemies = 0;
	actual_friends = 0;
	
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		
		if(!player is_bot())
			continue;
			
		if(!isDefined(player.team))
			continue;
		
		if(player.pers["team"] == team)
			actual_friends++;
		else if (player.pers["team"] == otherTeam)
			actual_enemies++;
	}
	
	if(!level.teamBased)
	{
		actual_enemies = actual_friends + actual_enemies;
		actual_friends = 0;
	}
	
	for(i = 0; i < bot_num_friendly - actual_friends; i++)
	{
		add_bot(team);
		
		wait 0.25;
	}
	
	for(i = 0; i < bot_num_enemy - actual_enemies; i++)
	{
		if(level.teamBased || randomInt(2))
			add_bot(otherTeam);
		else
			add_bot(team);
		
		wait 0.25;
	}
}

add_bot(team)
{
	bot = addtestclient();

	if (isdefined(bot))
	{
		bot.pers["isBot"] = true;
		bot thread bot_joined(team);
	}
}

bot_spawner_Once()
{
	level endon ( "game_ended" );
	
	if ( !GetDvarInt( #"scr_bots_managed_spawn" ) )
	{
		SetDvar( "scr_bots_managed_spawn", 0 );
	}
	
	if ( !GetDvarInt( #"scr_bots_managed_all" ) )
	{
		SetDvar( "scr_bots_managed_all", 0 );
	}
	
	if ( !GetDvarInt( #"scr_bots_managed_axis" ) )
	{
		SetDvar( "scr_bots_managed_axis", 0 );
	}
	
	if ( !GetDvarInt( #"scr_bots_managed_allies" ) )
	{
		SetDvar( "scr_bots_managed_allies", 0 );
	}
	
	if ( GetDvar( #"scr_bot_difficulty" ) == "" )
	{
		SetDvar( "scr_bot_difficulty", "normal" );
	}
	
	bot_set_difficulty( GetDvar( #"scr_bot_difficulty" ) );
	
	wait( 0.5 );	
	for( ;; )
	{		
		wait 10.0;
		
		if ( game["state"] == "postgame" )
			return;
			
		if( !GetDvarInt( #"scr_bots_managed_spawn" ) )
			continue;
			
		humans = 0;
		players = level.players;			
		for ( i = 0; i < players.size; i++ )
		{
			player = players[i];
			
			if( player is_bot() || player isdemoclient() )
				continue;
			
			humans++;
			break;
		}
		
		countAllies = 0;
		countAxis = 0;
		
		if( IsDefined( level.botsCount["axis"] ) )
			countAxis = level.botsCount["axis"];
	
		if( IsDefined( level.botsCount["allies"] ) )			
			countAllies = level.botsCount["allies"];
			
		num = GetDvarInt( #"scr_bots_managed_all" );
	
		if ( num > 0 )
		{
			axis_num = Ceil( num / 2 );
			allies_num = Floor( num / 2 );
		}
		else
		{
			axis_num = GetDvarInt( #"scr_bots_managed_axis" );
			allies_num = GetDvarInt( #"scr_bots_managed_allies" );
		}
		
		if( !humans )
		{
			
			players = level.players;
			for ( i = 0; i < players.size; i++ )
			{
				player = players[i];
				
				if( !player is_bot() )
					continue;
				
				kick( player getEntityNumber() );
				wait(0.25);
			}
			
			
			continue;
		}
		
		
		
		differenceAxis = axis_num - countAxis; 
		differenceAllies = allies_num - countAllies;
		
		if( differenceAxis == 0 && differenceAllies == 0 )
		{
			continue;
		}
		
		
		if( differenceAxis < 0 )
		{
			
			players = level.players;
			for ( i = 0; i < players.size; i++ )
			{
				if( differenceAxis >= 0 )
					break;
	
				player = players[i];
				
				if( !player is_bot() )
					continue;
				
				if(!isDefined(player.team))
					continue;
				
				if( "axis" == player.team )
				{
					kick( player getEntityNumber() );
					differenceAxis = differenceAxis + 1;
					wait(0.25);
				}
			}	
		}
		else 
		{
			
			for( ; differenceAxis > 0; differenceAxis = differenceAxis - 1 )
			{
				wait( 0.25 );
				bot_add( "axis" );
			} 
		} 
		
		if( differenceAllies < 0 )
		{
	
			players = level.players;
			for ( i = 0; i < players.size; i++ )
			{
				if( differenceAllies >= 0 )
					break;
	
				player = players[i];
				
				if( !player is_bot() )
					continue;
					
				if(!isDefined(player.team))
					continue;
				
				if( "allies" == player.team )
				{
					kick( player getEntityNumber() );
					differenceAllies = differenceAllies + 1;
					wait(0.25);
				}				
			} 
		}
		else 
		{
			
			for( ; differenceAllies > 0; differenceAllies = differenceAllies - 1 )
			{
				wait( 0.25 );
				bot_add( "allies" );
			}	
		} 
	}
}

bot_array_nearest_curorigin(array)
{
	result = undefined;
	
	for(i = 0; i < array.size; i++)
		if(!isDefined(result) || DistanceSquared(self.origin,array[i].curorigin) < DistanceSquared(self.origin,result.curorigin))
			result = array[i];
		
	return result;
}

basic_training_auto_assign()
{
	host = GetHostPlayer();

	if ( host == self )
	{
		self maps\mp\gametypes\_globallogic_ui::menuAutoAssign();
		return;
	}

	if ( self is_bot() )
	{
		if ( !level.teambased )
		{
			self maps\mp\gametypes\_globallogic_ui::menuAutoAssign();
		}
		return;
	}

	bot_wait_for_host();
	host = GetHostPlayer();
	host_team = host.pers[ "team" ];

	player_counts = self maps\mp\gametypes\_teams::CountPlayers();

	if ( !level.onlineGame )
	{
		friends = GetDvarInt( #"splitscreen_botFriends" ) - player_counts[ host_team ];
	}
	else
	{
		friends = GetDvarInt( #"bot_friends" ) - player_counts[ host_team ];
	}

	if ( friends > 0 )
	{
		assignment = host_team;
	}
	else
	{
		assignment = getOtherTeam( host_team );
	}

	// remainder of this function is taken directly from _globallogic_ui::menuAutoAssign()
	self.pers["team"] = assignment;
	self.team = assignment;
	self.pers["class"] = undefined;
	self.class = undefined;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;

	self maps\mp\gametypes\_globallogic_ui::updateObjectiveText();

	if ( level.teamBased )
		self.sessionteam = assignment;
	else
	{
		self.sessionteam = "none";
		self.ffateam = assignment;
	}
	
	if ( !isAlive( self ) )
		self.statusicon = "hud_status_dead";
	
	self notify("joined_team");
	level notify( "joined_team" );
	self notify("end_respawn");
	
	if( isPregameGameStarted() )
	{
		pclass = self GetPregameClass();
		if( IsDefined( pclass ) )
		{
			self closeMenu();
			self closeInGameMenu();
			
			self.selectedClass = true;
			self [[level.class]](pclass);
			return;
		}
	}

	self maps\mp\gametypes\_globallogic_ui::beginClassChoice();	
	self setclientdvar( "g_scriptMainMenu", game[ "menu_class_" + self.pers["team"] ] );
}

bot_kick_think()
{
	for ( ;; )
	{
		level waittill( "bot_kicked", team );
		level thread bot_reconnect_bot( team );
	}
}

bot_reconnect_bot(team)
{	
	wait( RandomIntRange( 3, 15 ) );
	
	add_bot(team);
}

bot_set_difficulty( difficulty )
{
	if ( difficulty == "fu" )
	{
		SetDvar( "sv_botMinDeathTime",		"250" );
		SetDvar( "sv_botMaxDeathTime",		"500" );
		SetDvar( "sv_botMinFireTime",		"100" );
		SetDvar( "sv_botMaxFireTime",		"300" );
		SetDvar( "sv_botYawSpeed",			"14" );
		SetDvar( "sv_botYawSpeedAds",		"14" );
		SetDvar( "sv_botPitchUp",			"-5" );
		SetDvar( "sv_botPitchDown",			"10" );
		SetDvar( "sv_botFov",				"160" );
		SetDvar( "sv_botMinAdsTime",		"3000" );
		SetDvar( "sv_botMaxAdsTime",		"5000" );
		SetDvar( "sv_botMinCrouchTime",		"100" );
		SetDvar( "sv_botMaxCrouchTime",		"400" );
		SetDvar( "sv_botTargetLeadBias",	"2" );
		SetDvar( "sv_botMinReactionTime",	"30" );
		SetDvar( "sv_botMaxReactionTime",	"100" );
		SetDvar( "sv_botStrafeChance",		"1" );
		SetDvar( "sv_botMinStrafeTime",		"3000" );
		SetDvar( "sv_botMaxStrafeTime",		"6000" );
		SetDvar( "scr_help_dist",			"512" );
		SetDvar( "sv_botAllowGrenades",		"1"	);
		SetDvar( "sv_botMinGrenadeTime",	"1500" );
		SetDvar( "sv_botMaxGrenadeTime",	"4000" );
		SetDvar( "sv_botSprintDistance",	"512"	);
		SetDvar( "sv_botMeleeDist",			"80" );
	}
	else if ( difficulty == "hard" )
	{
		SetDvar( "sv_botMinDeathTime",		"250" );
		SetDvar( "sv_botMaxDeathTime",		"500" );
		SetDvar( "sv_botMinFireTime",		"400" );
		SetDvar( "sv_botMaxFireTime",		"600" );
		SetDvar( "sv_botYawSpeed",			"8" );
		SetDvar( "sv_botYawSpeedAds",		"10" );
		SetDvar( "sv_botPitchUp",			"-5" );
		SetDvar( "sv_botPitchDown",			"10" );
		SetDvar( "sv_botFov",				"100" );
		SetDvar( "sv_botMinAdsTime",		"3000" );
		SetDvar( "sv_botMaxAdsTime",		"5000" );
		SetDvar( "sv_botMinCrouchTime",		"100" );
		SetDvar( "sv_botMaxCrouchTime",		"400" );
		SetDvar( "sv_botTargetLeadBias",	"2" );
		SetDvar( "sv_botMinReactionTime",	"400" );
		SetDvar( "sv_botMaxReactionTime",	"700" );
		SetDvar( "sv_botStrafeChance",		"0.9" );
		SetDvar( "sv_botMinStrafeTime",		"3000" );
		SetDvar( "sv_botMaxStrafeTime",		"6000" );
		SetDvar( "scr_help_dist",			"384" );
		SetDvar( "sv_botAllowGrenades",		"1"	);
		SetDvar( "sv_botMinGrenadeTime",	"1500" );
		SetDvar( "sv_botMaxGrenadeTime",	"4000" );
		SetDvar( "sv_botSprintDistance",	"512"	);
		SetDvar( "sv_botMeleeDist",			"80" );
	}
	else if ( difficulty == "easy" )
	{
		SetDvar( "sv_botMinDeathTime",		"1000" );
		SetDvar( "sv_botMaxDeathTime",		"2000" );
		SetDvar( "sv_botMinFireTime",		"900" );
		SetDvar( "sv_botMaxFireTime",		"1000" );
		SetDvar( "sv_botYawSpeed",			"2" );
		SetDvar( "sv_botYawSpeedAds",		"2.5" );
		SetDvar( "sv_botPitchUp",			"-20" );
		SetDvar( "sv_botPitchDown",			"40" );
		SetDvar( "sv_botFov",				"50" );
		SetDvar( "sv_botMinAdsTime",		"3000" );
		SetDvar( "sv_botMaxAdsTime",		"5000" );
		SetDvar( "sv_botMinCrouchTime",		"4000" );
		SetDvar( "sv_botMaxCrouchTime",		"6000" );
		SetDvar( "sv_botTargetLeadBias",	"8" );
		SetDvar( "sv_botMinReactionTime",	"1200" );
		SetDvar( "sv_botMaxReactionTime",	"1600" );
		SetDvar( "sv_botStrafeChance",		"0.1" );
		SetDvar( "sv_botMinStrafeTime",		"3000" );
		SetDvar( "sv_botMaxStrafeTime",		"6000" );
		SetDvar( "scr_help_dist",			"256" );
		SetDvar( "sv_botAllowGrenades",		"0"	);
		SetDvar( "sv_botSprintDistance",	"1024"	);
		SetDvar( "sv_botMeleeDist",			"40" );
	}
	else // 'normal' difficulty
	{
		SetDvar( "sv_botMinDeathTime",		"500" );
		SetDvar( "sv_botMaxDeathTime",		"1000" );
		SetDvar( "sv_botMinFireTime",		"600" );
		SetDvar( "sv_botMaxFireTime",		"800" );
		SetDvar( "sv_botYawSpeed",			"4" );
		SetDvar( "sv_botYawSpeedAds",		"5" );
		SetDvar( "sv_botPitchUp",			"-10" );
		SetDvar( "sv_botPitchDown",			"20" );
		SetDvar( "sv_botFov",				"70" );
		SetDvar( "sv_botMinAdsTime",		"3000" );
		SetDvar( "sv_botMaxAdsTime",		"5000" );
		SetDvar( "sv_botMinCrouchTime",		"2000" );
		SetDvar( "sv_botMaxCrouchTime",		"4000" );
		SetDvar( "sv_botTargetLeadBias",	"4" );
		SetDvar( "sv_botMinReactionTime",	"800" );
		SetDvar( "sv_botMaxReactionTime",	"1200" );
		SetDvar( "sv_botStrafeChance",		"0.6" );
		SetDvar( "sv_botMinStrafeTime",		"3000" );
		SetDvar( "sv_botMaxStrafeTime",		"6000" );
		SetDvar( "scr_help_dist",			"256" );
		SetDvar( "sv_botAllowGrenades",		"1"	);
		SetDvar( "sv_botMinGrenadeTime",	"1500" );
		SetDvar( "sv_botMaxGrenadeTime",	"4000" );
		SetDvar( "sv_botSprintDistance",	"512"	);
		SetDvar( "sv_botMeleeDist",			"80" );
	}

	if ( level.gameType == "oic" && difficulty == "fu" )
	{
		SetDvar( "sv_botMinReactionTime",		"400" );
		SetDvar( "sv_botMaxReactionTime",		"500" );
		SetDvar( "sv_botMinAdsTime",		"1000" );
		SetDvar( "sv_botMaxAdsTime",		"2000" );
	}

	if ( level.gameType == "oic" && ( difficulty == "hard" || difficulty == "fu" ) )
	{
		SetDvar( "sv_botSprintDistance",	"256" );
	}
	
	SetDvar( "bot_difficulty", difficulty );
}

bot_wait_for_host()
{
	host = undefined;
	
	for(i = 0; i < 100; i++)
	{
		host = GetHostPlayer();
		
		if(isDefined(host))
			break;
		
		wait 0.05;
	}
	
	if(!isDefined(host))
		return;
	
	for(i = 0; i < 100; i++)
	{
		if(IsDefined( host.pers[ "team" ] ))
			break;
		
		wait 0.05;
	}

	if(!IsDefined( host.pers[ "team" ] ))
		return;
	
	for(i = 0; i < 100; i++)
	{
		if(host.pers[ "team" ] == "allies" || host.pers[ "team" ] == "axis")
			break;
		
		wait 0.05;
	}
}

bot_get_cod_points()
{
	if ( !level.onlineGame )
	{
		self.pers["bot"][ "cod_points" ] = 999999;
		return;
	}
	
	players = get_players();
	total_points = [];

	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] is_bot() )
		{
			continue;
		}
		
		if(!isDefined(players[i].pers["currencyspent"]) || !isDefined(players[i].pers["codpoints"]))
			continue;

		total_points[ total_points.size ] = players[i].pers["currencyspent"] + players[i].pers["codpoints"];
	}
	
	if( !total_points.size )
		total_points[ total_points.size ] = 10000;

	point_average = array_average( total_points );
	self.pers["bot"][ "cod_points" ] = Int( point_average * RandomFloatRange( 0.6, 0.8 ) );
}

bot_get_rank()
{
	players = get_players();

	ranks = [];
	bot_ranks = [];
	human_ranks = [];
	
	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] == self )
			continue;
		
		if ( !IsDefined( players[i].pers[ "rank" ] ) )
			continue;
		
		if ( players[i] is_bot() )
		{
			bot_ranks[ bot_ranks.size ] = players[i].pers[ "rank" ];
		}
		else if ( !players[i] isdemoclient() )
		{
			human_ranks[ human_ranks.size ] = players[i].pers[ "rank" ];
		}
	}

	if( !human_ranks.size )
		human_ranks[ human_ranks.size ] = 10;

	human_avg = array_average( human_ranks );

	while ( bot_ranks.size + human_ranks.size < 5 )
	{
		// add some random ranks for better random number distribution
		rank = human_avg + RandomIntRange( -10, 10 );
		human_ranks[ human_ranks.size ] = rank;
	}

	ranks = array_combine( human_ranks, bot_ranks );

	avg = array_average( ranks );
	s = array_std_deviation( ranks, avg );
	
	rank = Int( random_normal_distribution( avg, s, 0, level.maxRank ) );

	self.pers["bot"]["rankxp"] = maps\mp\gametypes\_rank::getRankInfoMinXP( rank );
}

bot_setKillstreaks()
{
	allowed_killstreaks = [];

	allowed_killstreaks[ 0 ] = "killstreak_spyplane";
	allowed_killstreaks[ 1 ] = "killstreak_supply_drop";
	allowed_killstreaks[ 2 ] = "killstreak_helicopter_comlink";

	if ( self maps\mp\gametypes\_rank::getRankForXp( self.pers["bot"]["rankxp"] ) >= 9 || !level.onlineGame )
	{
		allowed_killstreaks[ 3 ] = "killstreak_auto_turret_drop";
		allowed_killstreaks[ 4 ] = "killstreak_tow_turret_drop";
		allowed_killstreaks[ 5 ] = "killstreak_napalm";
		allowed_killstreaks[ 6 ] = "killstreak_counteruav";
		allowed_killstreaks[ 7 ] = "killstreak_mortar";
		allowed_killstreaks[ 8 ] = "killstreak_spyplane_direction";
		allowed_killstreaks[ 9 ] = "killstreak_airstrike";
		allowed_killstreaks[ 10 ] = "killstreak_dogs";
		allowed_killstreaks[ 11 ] = "killstreak_rcbomb";
		allowed_killstreaks[ 12 ] = "killstreak_m220_tow_drop";
		allowed_killstreaks[ 13 ] = "killstreak_helicopter_gunner";
		allowed_killstreaks[ 14 ] = "killstreak_helicopter_player_firstperson";
	}

	used_levels = [];
	
	self.pers["bot"]["killstreaks"] = [];
	
	reason = GetDvarInt("bot_reasonable");
	
	for ( i = 0; i < 3; i++ )
	{
		killstreak = random( allowed_killstreaks );
		allowed_killstreaks = array_remove( allowed_killstreaks, killstreak );

		ks_level = maps\mp\gametypes\_hardpoints::GetKillstreakLevel( i, killstreak );

		if ( bot_killstreak_level_is_used( ks_level, used_levels ) )
		{
			i--;
			continue;
		}
		
		cost = bot_get_killstreak_cost(killstreak);
		
		if(self.pers["bot"]["cod_points"] < cost)
		{
			i--;
			continue;
		}
		
		if(reason)
		{
			switch(killstreak)
			{
				case "killstreak_helicopter_gunner":
				case "killstreak_helicopter_player_firstperson":
				case "killstreak_m220_tow_drop":
				case "killstreak_tow_turret_drop":
				case "killstreak_auto_turret_drop":
					i--;
					continue;
			}
		}

		self.pers["bot"]["cod_points"] = self.pers["bot"]["cod_points"] - cost;
		used_levels[ used_levels.size ] = ks_level;
		self.pers["bot"]["killstreaks"][i] = killstreak;
	}
}

bot_get_killstreak_cost(ks)
{
	//use table?? trey never included cost attribute tho
	switch(ks)
	{
		case "killstreak_auto_turret_drop":
			return 3200;
		case "killstreak_tow_turret_drop":
			return 1600;
		case "killstreak_napalm":
			return 2400;
		case "killstreak_counteruav":
			return 1600;
		case "killstreak_mortar":
			return 3200;
		case "killstreak_spyplane_direction":
			return 4500;
		case "killstreak_airstrike":
			return 4500;
		case "killstreak_dogs":
			return 6000;
		case "killstreak_rcbomb":
			return 1200;
		case "killstreak_helicopter_gunner":
			return 5000;
		case "killstreak_helicopter_player_firstperson":
			return 6000;
		case "killstreak_m220_tow_drop":
			return 4000;
		default:
			return 0;
	}
}

bot_giveKillstreaks()
{
	self.killstreak[0] = self.pers["bot"]["killstreaks"][0];
	self.killstreak[1] = self.pers["bot"]["killstreaks"][1];
	self.killstreak[2] = self.pers["bot"]["killstreaks"][2];
}

bot_killstreak_level_is_used( ks_level, used_levels )
{
	for ( used = 0; used < used_levels.size; used++ )
	{
		if ( ks_level == used_levels[ used ] )
		{
			return true;
		}
	}

	return false;
}

bot_joined(team)
{
	self.pers["bot"]["team"] = team;
	
	self bot_get_cod_points();
	self bot_get_rank();
	
	self bot_setKillstreaks();
	
	self.pers["bot"][ "cod_points_org" ] = self.pers["bot"][ "cod_points" ];//killstreaks cannot be set again
	
	self bot_set_class();
}

bot_start()
{
	self thread bot_rank();
	
	self thread bot_team_think();
	
	self thread bot_skip_killcam();
	
	self thread bot_on_spawn();
	self thread bot_on_death();
}

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

bot_team_think()
{
	self endon("disconnect");
	level endon("game_ended");
	
	while( !IsDefined( self.pers["team"] ) )
	{
		wait .05;
	}
	
	if ( level.teambased && self.pers["team"] != self.pers["bot"]["team"] )
	{
		self notify( "menuresponse", game["menu_team"], self.pers["bot"]["team"] );
	}
	
	wait 0.5;
	self notify( "menuresponse", "changeclass", "smg_mp" );
}

bot_rank()
{
	self endon("disconnect");
	
	wait 0.05;
	
	self.pers["rankxp"] = self.pers["bot"]["rankxp"];
	rankId = self maps\mp\gametypes\_rank::getRankForXp( self.pers["bot"]["rankxp"] );
	self.pers["rank"] = rankId;
	self setRank( rankId );
	
	if(!level.gameEnded)
		level waittill("game_ended");
	
	self.pers["bot"]["rankxp"] = self.pers["rankxp"];
}

bot_set_class()
{
	self.pers["bot"]["class_render_opts"] = 0;
	
	self.pers["bot"]["class_primary"] = "";
	self.pers["bot"]["class_primary_opts"] = 0;
	self.pers["bot"]["class_secondary"] = "";
	self.pers["bot"]["class_secondary_opts"] = 0;
	
	self.pers["bot"]["class_lethal"] = "";
	self.pers["bot"]["class_tacticle"] = "";
	self.pers["bot"]["class_equipment"] = "";
	
	self.pers["bot"]["class_perk1"] = "";
	self.pers["bot"]["class_perk2"] = "";
	self.pers["bot"]["class_perk3"] = "";
	
	self.pers["bot"][ "cod_points" ] = self.pers["bot"][ "cod_points_org" ];//refund prev payments for class
	
	rank = self maps\mp\gametypes\_rank::getRankForXp( self.pers["bot"]["rankxp"] );

	if ( !level.onlineGame )
	{
		rank = level.maxRank;
	}
	
	if (rank < 3 || (randomint(100) < 3 && !GetDvarInt("bot_reasonable")))
	{
		_class = "";
		while(_class == "")
		{
			switch(randomInt(5))
			{
				case 0:
					_class = "CLASS_ASSAULT";
				break;
				case 1:
					_class = "CLASS_SMG";
				break;
				case 2:
					_class = "CLASS_CQB";
				break;
				case 3:
					if(rank >= 1)
						_class = "CLASS_LMG";
				break;
				case 4:
					if(rank >= 2)
						_class = "CLASS_SNIPER";
				break;
			}
		}
		
		self.pers["bot"]["class_primary"] = level.classWeapons["axis"][_class][0];
		self.pers["bot"]["class_secondary"] = level.classSidearm["axis"][_class];
		self.pers["bot"]["class_perk1"] = level.default_perkIcon[_class][ 0 ];
		self.pers["bot"]["class_perk2"] = level.default_perkIcon[_class][ 1 ];
		self.pers["bot"]["class_perk3"] = level.default_perkIcon[_class][ 2 ];
		self.pers["bot"]["class_equipment"] = level.default_equipment[ _class ][ "type" ];
		self.pers["bot"]["class_lethal"] = level.classGrenades[_class]["primary"]["type"];
		self.pers["bot"]["class_tacticle"] = level.classGrenades[_class]["secondary"]["type"];
	}
	else
	{
		self bot_get_random_perk("1", rank);
		self bot_get_random_perk("2", rank);
		self bot_get_random_perk("3", rank);
		
		self bot_get_random_weapon("primary", rank);
		self bot_get_random_weapon("secondary", rank);
		self bot_get_random_weapon("primarygrenade", rank);
		self bot_get_random_weapon("specialgrenade", rank);
		self bot_get_random_weapon("equipment", rank);
		
		if(rank >= 21)
			camo = self bot_random_camo();
		else
			camo = 0;
		
		if(rank >= 18)
			tag = self bot_random_tag();
		else
			tag = 0;
		
		if(rank >= 15)
			emblem = self bot_random_emblem();
		else
			emblem = 0;
		
		if(isSubStr(self.pers["bot"]["class_primary"], "_elbit_") || isSubStr(self.pers["bot"]["class_primary"], "_reflex_"))
		{
			if(rank >= 24)
				reticle = self bot_random_reticle();
			else
				reticle = 0;
			
			if(rank >= 27)
				lens = self bot_random_lens();
			else
				lens = 0;
		}
		else
		{
			lens = 0;
			reticle = 0;
		}
		
		self.pers["bot"]["class_primary_opts"] = self calcWeaponOptions( camo, lens, reticle, tag, emblem );
		
		if(rank >= 30)
			face = self bot_random_face();
		else
			face = 0;
		
		self.pers["bot"]["class_render_opts"] = self calcPlayerOptions( face, 0 );
	}
	
	if(!GetDvarInt("bot_allow_laststand") && isSubStr(self.pers["bot"]["class_perk3"], "perk_second_chance"))
		self.pers["bot"]["class_perk3"] = "";
}

bot_get_random_weapon(slot, rank)
{
	if(!isDefined(level.bot_weapon_ids))
		level.bot_weapon_ids = [];
	
	if ( !IsDefined( level.bot_weapon_ids[ slot ] ) )
	{
		level.bot_weapon_ids[ slot ] = [];

		keys = GetArrayKeys( level.tbl_weaponIDs );

		for ( i = 0; i < keys.size; i++ )
		{
			key = keys[i];
			id = level.tbl_weaponIDs[ key ];

			if ( id[ "reference" ] == "weapon_null" )
				continue;
			
			if ( isSubStr(id[ "reference" ], "dw") )
				continue;

			if ( id[ "cost" ] == "-1" )
				continue;

			if ( id[ "slot" ] == slot )
			{
				level.bot_weapon_ids[ slot ][ level.bot_weapon_ids[ slot ].size ] = id;
			}
		}
	}
	
	reason = GetDvarInt("bot_reasonable");
	
	for(;;)
	{
		id = random( level.bot_weapon_ids[ slot ] );
		
		if(!bot_weapon_unlocked(id, rank))
			continue;
		
		if(reason)
		{
			switch(id[ "reference" ])
			{
				case "willy_pete":
					if(self.pers["bot"]["cod_points"] >= 1500)
						continue;
					break;
				
				case "camera_spike":
				case "satchel_charge":
				case "nightingale":
				case "tabun_gas":
				case "rottweil72":
				case "hs10":
				case "dragunov":
				case "wa2000":
				case "hk21":
				case "rpk":
				case "m14":
				case "fnfal":
				case "uzi":
				case "skorpion":
				case "pm63":
				case "kiparis":
				case "mac11":
				case "ithaca":
					continue;
			}
		}
		
		if ( id[ "reference" ] == "hatchet" && RandomInt( 100 ) > 20 )
		{
			continue;
		}

		if ( id[ "reference" ] == "willy_pete" && RandomInt( 100 ) > 20 )
		{
			continue;
		}

		if ( id[ "reference" ] == "nightingale" && RandomInt( 100 ) > 20 )
		{
			continue;
		}

		if ( id[ "reference" ] == "claymore" && GetDvar( #"bot_difficulty" ) == "easy" )
		{
			continue;
		}

		if ( id[ "reference" ] == "scrambler" && GetDvar( #"bot_difficulty" ) == "easy" )
		{
			continue;
		}
		
		if ( id[ "reference" ] == "camera_spike" && self IsSplitScreen() )
			continue;
		
		if ( id[ "reference" ] == level.tacticalInsertionWeapon && level.disable_tacinsert )
			continue;
		
		cost = bot_weapon_cost(id);
		if(self.pers["bot"]["cod_points"] < cost)
		{
			if(slot == "equipment" && self.pers["bot"]["cod_points"] < 2000)
				break;
			
			continue;
		}
		
		self.pers["bot"]["cod_points"] = self.pers["bot"]["cod_points"] - cost;
		
		maxAttachs = 1;
		if(isSubStr(self.pers["bot"]["class_perk2"], "perk_professional") && slot == "primary")
			maxAttachs = 2;
		
		if(RandomFloatRange( 0, 1 ) < ( rank / level.maxRank ))
			weap = bot_random_attachments(id[ "reference" ], id[ "attachment" ], maxAttachs);
		else
			weap = id[ "reference" ];
		
		weap = bot_validate_weapon(weap);
		weap = weap + "_mp";
		
		switch(slot)
		{
			case "equipment":
				self.pers["bot"]["class_equipment"] = weap;
			break;
			case "primary":
				self.pers["bot"]["class_primary"] = weap;
			break;
			case "secondary":
				self.pers["bot"]["class_secondary"] = weap;
			break;
			case "primarygrenade":
				self.pers["bot"]["class_lethal"] = weap;
			break;
			case "specialgrenade":
				self.pers["bot"]["class_tacticle"] = weap;
			break;
		}
		break;
	}
}

bot_get_random_perk(slot, rank)
{
	reason = GetDvarInt("bot_reasonable");
	
	for ( ;; )
	{
		id = random( level.allowedPerks[0] );
		id = level.tbl_PerkData[ id ];

		if ( id[ "reference" ] == "specialty_null" )
			continue;

		if ( id[ "slot" ] != "specialty" + slot )
			continue;
		
		if(isSubStr(id[ "reference_full" ], "_pro") && id[ "reference_full" ] != "perk_professional")
			continue;

		cost = Int( id[ "cost" ] );

		if ( cost > self.pers["bot"][ "cod_points" ] )
			continue;
		
		if(reason)
		{
			if(id[ "reference_full" ] == "perk_scout")
				continue;
		}

		self.pers["bot"][ "cod_points" ] = self.pers["bot"][ "cod_points" ] - cost;
		self.pers["bot"]["class_perk" + slot] = id[ "reference_full" ];
		break;
	}
	
	id = bot_perk_from_reference_full(self.pers["bot"]["class_perk" + slot]+"_pro");
	cost = Int( id[ "cost" ] );
	
	if ( Int( cost ) <= self.pers["bot"][ "cod_points" ] && RandomFloatRange( 0, 1 ) < ( rank / level.maxRank ) )
	{
		self.pers["bot"][ "cod_points" ] = self.pers["bot"][ "cod_points" ] - cost;
		self.pers["bot"]["class_perk" + slot] = id[ "reference_full" ];
	}
}

bot_random_face()
{
	for(;;)
	{
		face = randomint(25);
		
		if(face == 0)
			return face;
		
		if(face >= 17)
		{
			if(face >= 21)//pres faces
			{
				if(self.pers["bot"][ "cod_points" ] < 500)
					continue;
				
				self.pers["bot"][ "cod_points" ] -= 500;
				
				return face;
			}
			
			if(face == 17)
			{
				if(self.pers["bot"][ "cod_points" ] < 1500)
					continue;
				
				self.pers["bot"][ "cod_points" ] -= 1500;
				
				return face;
			}
			
			if(face == 18)
			{
				if(self.pers["bot"][ "cod_points" ] < 3500)
					continue;
				
				self.pers["bot"][ "cod_points" ] -= 3500;
				
				return face;
			}
			
			if(face == 19)
			{
				if(self.pers["bot"][ "cod_points" ] < 5500)
					continue;
				
				self.pers["bot"][ "cod_points" ] -= 5500;
				
				return face;
			}
			
			if(self.pers["bot"][ "cod_points" ] < 7500)
				continue;
			
			self.pers["bot"][ "cod_points" ] -= 7500;
			
			return face;
		}
		
		if(self.pers["bot"][ "cod_points" ] < 500)
			continue;
		
		self.pers["bot"][ "cod_points" ] -= 500;
		
		return face;
	}
}

bot_random_lens()
{
	for(;;)
	{
		lens = randomint(6);
		
		if(lens == 0)
			return lens;
		
		if(self.pers["bot"][ "cod_points" ] < 500)
			continue;
		
		self.pers["bot"][ "cod_points" ] -= 500;
		
		return lens;
	}
}

bot_random_reticle()
{
	for(;;)
	{
		ret = randomint(40);
		
		if(ret == 0)
			return ret;
		
		if(self.pers["bot"][ "cod_points" ] < 500)
			continue;
		
		self.pers["bot"][ "cod_points" ] -= 500;
		
		return ret;
	}
}

bot_random_tag()
{
	for(;;)
	{
		tag = randomInt(2);
		
		if(tag == 0)
			return tag;
		
		if(self.pers["bot"][ "cod_points" ] < 1000)
			continue;
		
		self.pers["bot"][ "cod_points" ] -= 1000;
		
		return tag;
	}
}

bot_random_emblem()
{
	for(;;)
	{
		emblem = randomInt(2);
		
		if(emblem == 0)
			return emblem;
		
		if(self.pers["bot"][ "cod_points" ] < 1000)
			continue;
		
		self.pers["bot"][ "cod_points" ] -= 1000;
		
		return emblem;
	}
}

bot_random_camo()
{
	for(;;)
	{
		camo = randomInt(16);
		
		if(camo == 0)
			return camo;
		
		if(camo == 15)//gold
		{
			if(self.pers["bot"][ "cod_points" ] < 50000)
				continue;
			
			self.pers["bot"][ "cod_points" ] -= 50000;
			
			return camo;
		}
		
		if(self.pers["bot"][ "cod_points" ] < 250)
			continue;
		
		self.pers["bot"][ "cod_points" ] -= 250;
		
		return camo;
	}
}

bot_weapon_cost(id)
{
	cost = int(id[ "cost" ]);
	
	if ( id[ "classified" ] != 0 )
	{
		slot = "primary";
		
		if(id[ "group" ] == "weapon_pistol")
			slot = "secondary";
		
		for(i = 0; i < level.bot_weapon_ids[ slot ].size; i++)
		{
			if(id["reference"] == level.bot_weapon_ids[ slot ][i]["reference"])
				continue;
			
			if(id["group"] != level.bot_weapon_ids[ slot ][i]["group"])
				continue;
			
			cost += int(level.bot_weapon_ids[ slot ][i]["cost"]);
		}
	}
	
	return cost;
}

bot_weapon_unlocked(id, rank)
{
	if ( id[ "classified" ] != 0 )
	{
		switch( id[ "group" ] )
		{
			case "weapon_pistol":
				return (rank >= 17);
			case "weapon_smg":
				return (rank >= 40);
			case "weapon_assault":
				return (rank >= 43);
			case "weapon_lmg":
				return (rank >= 20);
			case "weapon_sniper":
				return (rank >= 26);
			case "weapon_cqb":
				return (rank >= 23);
			default:
				return false;
		}
	}
	
	unlock = Int( id[ "unlock_level" ] );
	return (rank >= unlock);
}

bot_attachment_cost(att)
{
	switch(att)
	{
		case "upgradesight":
			return 250;
		case "snub":
			return 500;
		case "elbit":
		case "extclip":
		case "dualclip":
		case "acog":
		case "reflex":
		case "mk":
		case "ft":
		case "grip":
		case "lps":
		case "speed":
		case "dw":
			return 1000;
		case "ir":
		case "silencer":
		case "vzoom":
		case "auto":
			return 2000;
		case "gl":
		case "rf":
			return 3000;
		default:
			return 0;
	}
}

bot_validate_weapon(weap)
{
	weapon = weap;
	
	tokens = strtok(weap, "_");
	
	if(tokens.size <= 1)
		return weapon;
	
	if(tokens.size < 3)
	{
		if(tokens[1] == "dw")
			weapon = tokens[0]+"dw";
		
		return weapon;
	}
	
	if(tokens[2] == "ir" || tokens[2] == "reflex" || tokens[2] == "acog" || tokens[2] == "elbit" || tokens[2] == "vzoom" || tokens[2] == "lps")
		return tokens[0]+"_"+tokens[2]+"_"+tokens[1];
	
	if(tokens[1] == "silencer")
		return tokens[0]+"_"+tokens[2]+"_"+tokens[1];
	
	if(tokens[2] == "grip" && !(tokens[1] == "ir" || tokens[1] == "reflex" || tokens[1] == "acog" || tokens[1] == "elbit" || tokens[1] == "vzoom" || tokens[1] == "lps"))
		return tokens[0]+"_"+tokens[2]+"_"+tokens[1];
	
	return weapon;
}

bot_random_attachments(weap, atts, num)
{
	weapon = weap;
	attachments = StrTok( atts, " " );
	attachments[attachments.size] = "";
	
	reason = GetDvarInt("bot_reasonable");
	
	for(;;)
	{
		if ( attachments.size <= 0 )
		{
			return ( weapon );
		}
		
		attachment = random( attachments );
		attachments = array_remove( attachments, attachment );
		if(attachment == "")
			return weapon;
		
		if(reason)
		{
			switch(attachment)
			{
				case "snub":
				case "upgradesight":
				case "acog":
				case "mk":
				case "ft":
				case "ir":
				case "auto":
				case "gl":
					continue;
			}
			
			if(attachment == "silencer")
			{
				switch(weap)
				{
					case "l96a1":
					case "psg1":
						continue;
				}
			}
		}
		
		cost = bot_attachment_cost(attachment);
		if(cost > self.pers["bot"]["cod_points"])
			continue;
		
		self.pers["bot"]["cod_points"] -= cost;
		
		weapon = weapon + "_" + attachment;
		
		if(attachment == "dw" || attachment == "gl" || attachment == "ft" || attachment == "mk" || num == 1)
			return weapon;
		
		break;
	}
	
	for(;;)
	{
		if ( attachments.size <= 0 )
		{
			return ( weapon );
		}
		
		_attachment = random( attachments );
		attachments = array_remove( attachments, _attachment );
		
		if(_attachment == "")
			return weapon;
		
		if(reason)
		{
			switch(_attachment)
			{
				case "snub":
				case "upgradesight":
				case "acog":
				case "mk":
				case "ft":
				case "ir":
				case "auto":
				case "gl":
					continue;
			}
			
			if(attachment == "silencer")
			{
				switch(weap)
				{
					case "l96a1":
					case "psg1":
						continue;
				}
			}
		}
		
		if(_attachment == "dw" || _attachment == "gl" || _attachment == "ft" || _attachment == "mk")
			continue;
		
		if((attachment == "ir" || attachment == "reflex" || attachment == "acog" || attachment == "elbit" || attachment == "vzoom" || attachment == "lps") && (_attachment == "ir" || _attachment == "reflex" || _attachment == "acog" || _attachment == "elbit" || _attachment == "vzoom" || _attachment == "lps"))
			continue;
			
		if((attachment == "dualclip" || attachment == "extclip" || attachment == "rf") && (_attachment == "dualclip" || _attachment == "extclip" || _attachment == "rf"))
			continue;
		
		cost = bot_attachment_cost(_attachment);
		if(cost > self.pers["bot"]["cod_points"])
			continue;
		
		self.pers["bot"]["cod_points"] -= cost;
		weapon = weapon + "_" + _attachment;
		return weapon;
	}
}

bot_perk_from_reference_full( reference_full )
{
	keys = GetArrayKeys( level.tbl_PerkData );

	// start from the beginning of the array since our perk is most likely near the start
	for ( i = keys.size - 1; i >= 0; i-- )
	{
		key = keys[i];

		if ( level.tbl_PerkData[ key ][ "reference_full" ] == reference_full )
		{
			return level.tbl_PerkData[ key ];
		}
	}

	return undefined;
}

bot_give_loadout()
{
	self bot_giveKillstreaks();
	
	self clearPerks();
	
	self SetPlayerRenderOptions( int( self.pers["bot"]["class_render_opts"] ) );
	
	self.bot = [];
	
	self.bot[ "specialty1" ] = "specialty_null";
	self.bot[ "specialty2" ] = "specialty_null";
	self.bot[ "specialty3" ] = "specialty_null";
	
	if (self.pers["bot"]["class_perk1"] != "" && GetDvarInt( #"scr_game_perks" ) )
	{
		self.bot[ "specialty1" ] = self.pers["bot"]["class_perk1"];
		
		id = bot_perk_from_reference_full(self.pers["bot"]["class_perk1"]);
		tokens = strtok(id["reference"], "|");
		
		for (i = 0; i < tokens.size; i++)
			self setPerk(tokens[i]);
	}
	
	switch( self.pers["bot"]["class_perk1"] )
	{
		case "perk_ghost":
		case "perk_ghost_pro":
			self.cac_body_type = "camo_mp";
			break;

		case "perk_hardline":
		case "perk_hardline_pro":
			self.cac_body_type = "hardened_mp";
			break;

		case "perk_flak_jacket":
		case "perk_flak_jacket_pro":
			self.cac_body_type = "ordnance_disposal_mp";
			break;

		case "perk_scavenger":
		case "perk_scavenger_pro":
			self.cac_body_type = "utility_mp";
			break;

		case "perk_lightweight":
		case "perk_lightweight_pro":
		default:
			self.cac_body_type = "standard_mp";
			break;
	}
	
	self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
	self.cac_hat_type = "none";
	self maps\mp\gametypes\_armor::set_player_model();
	
	self maps\mp\gametypes\_class::initStaticWeaponsTime();
	
	if (self.pers["bot"]["class_perk2"] != "" && GetDvarInt( #"scr_game_perks" ))
	{
		self.bot[ "specialty2" ] = self.pers["bot"]["class_perk2"];
		
		id = bot_perk_from_reference_full(self.pers["bot"]["class_perk2"]);
		tokens = strtok(id["reference"], "|");
		
		for (i = 0; i < tokens.size; i++)
			self setPerk(tokens[i]);
	}
	
	if (self.pers["bot"]["class_perk3"] != "" && GetDvarInt( #"scr_game_perks" ))
	{
		self.bot[ "specialty3" ] = self.pers["bot"]["class_perk3"];
		
		id = bot_perk_from_reference_full(self.pers["bot"]["class_perk3"]);
		tokens = strtok(id["reference"], "|");
		
		for (i = 0; i < tokens.size; i++)
			self setPerk(tokens[i]);
	}
	
	if(self.pers["bot"]["class_primary"] != "")
	{
		primaryTokens = strtok( self.pers["bot"]["class_primary"], "_" );
		self.pers["primaryWeapon"] = primaryTokens[0];
		
		weap = self.pers["bot"]["class_primary"];
		if(GetDvarInt( #"scr_disable_attachments" ))
			weap = self.pers["primaryWeapon"] + "_mp";
		
		self GiveWeapon( weap, 0, int( self.pers["bot"]["class_primary_opts"] ) );
		
		if ( self hasPerk( "specialty_extraammo" ) )
			self giveMaxAmmo( weap );
		
		self setSpawnWeapon( weap );
	}
	else
	{
		weap = "ak47_mp";
		primaryTokens = strtok( weap, "_" );
		self.pers["primaryWeapon"] = primaryTokens[0];
		
		self GiveWeapon( weap, 0, 0 );
		
		if ( self hasPerk( "specialty_extraammo" ) )
			self giveMaxAmmo( weap );
		
		self setSpawnWeapon( weap );
	}
	
	if(self.pers["bot"]["class_secondary"] != "")
	{
		self GiveWeapon( self.pers["bot"]["class_secondary"], 0, int( self.pers["bot"]["class_secondary_opts"] ) );
		if ( self hasPerk( "specialty_extraammo" ) )
			self giveMaxAmmo( self.pers["bot"]["class_secondary"] );
	}
	
	self SetActionSlot( 3, "altMode" );
	self SetActionSlot( 4, "" );
	
	if(self.pers["bot"]["class_equipment"] != "" && self.pers["bot"]["class_equipment"] != "weapon_null_mp" && !GetDvarInt( #"scr_disable_equipment" ))
	{
		self GiveWeapon( self.pers["bot"]["class_equipment"] );
			
		self maps\mp\gametypes\_class::setWeaponAmmoOverall( self.pers["bot"]["class_equipment"], 1 );
			
		self SetActionSlot( 1, "weapon", self.pers["bot"]["class_equipment"] );
	}
	
	self GiveWeapon( level.weapons["frag"] );
	self SetWeaponAmmoClip( level.weapons["frag"], 0 );
	if(self.pers["bot"]["class_lethal"] != "")
	{
		self GiveWeapon( self.pers["bot"]["class_lethal"] );
		
		if(self hasPerk("specialty_twogrenades"))
			self SetWeaponAmmoClip( self.pers["bot"]["class_lethal"], 2 );
		else
			self SetWeaponAmmoClip( self.pers["bot"]["class_lethal"], 1 );
		
		self SwitchToOffhand( self.pers["bot"]["class_lethal"] );
	}
	
	if(self.pers["bot"]["class_tacticle"] != "")
	{
		self setOffhandSecondaryClass( self.pers["bot"]["class_tacticle"] );
		self giveWeapon( self.pers["bot"]["class_tacticle"] );
		
		if(self.pers["bot"]["class_tacticle"] == "willy_pete_mp")
			self SetWeaponAmmoClip( self.pers["bot"]["class_tacticle"], 1 );
		else if(self hasPerk("specialty_twogrenades"))
			self SetWeaponAmmoClip( self.pers["bot"]["class_tacticle"], 3 );
		else
			self SetWeaponAmmoClip( self.pers["bot"]["class_tacticle"], 2 );
	}
}

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

bot_on_spawn()
{
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		self waittill("spawned_player");
		
		self.bot_lock_goal = false;//so forced obj isn't conflicting with other obj
		self.help_time = undefined;
		
		self thread bot_spawn();
	}
}

bot_spawn()
{
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	
	self thread bot_dom_cap_think(); //before prematch so they play obj on first spawn
	
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
	
	if(randomInt(100) < 1)
		self bot_set_class();
	
	self thread bot_revive_think();
	self thread bot_crate_think();
	self thread bot_crate_touch_think();
	self thread bot_turret_think();
	self thread bot_killstreak_think();
	self thread bot_dogs_think();
	self thread bot_vehicle_think();
	self thread bot_equipment_think();
	self thread bot_equipment_kill_think();
	self thread bot_radiation_think();
	//stockpile.gsc
	//hotel.gsc
	//kowloon.gsc
	
	self thread bot_dom_def_think();
	self thread bot_dom_spawn_kill_think();
	
	self thread bot_dem_attackers();
	self thread bot_dem_defenders();
	
	self thread bot_sd_defenders();
	self thread bot_sd_attackers();
	
	self thread bot_hq();
	
	self thread bot_sab();
	
	self thread bot_cap();
	
	self thread bot_uav_think();
	self thread bot_weapon_think();
	self thread bot_revenge_think();
}

bot_is_idle()
{
	if ( !IsDefined( self ) )
	{
		return false;
	}

	if ( !IsAlive( self ) )
	{
		return false;
	}

	if ( !self is_bot() )
	{
		return false;
	}

	if ( IsDefined( self.laststand ) && self.laststand == true )
	{
		return false;
	}

	if ( self HasScriptGoal() )
	{
		return false;
	}

	if ( IsDefined( self GetThreat() ) )
	{
		return false;
	}
	
	if ( self IsRemoteControlling() || self.bot_lock_goal )
	{
		return false;
	}
	
	if(self UseButtonPressed())
		return false;
		
	if(isDefined(self.isDefusing) && self.isDefusing)
		return false;
			
	if(isDefined(self.isPlanting) && self.isPlanting)
		return false;

	return true;
}

bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc )
{
	if ( !IsDefined( self ) || !IsAlive( self ) )
	{
		return;
	}
	
	if ( !self is_bot() )
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

	if ( !IsDefined( eInflictor ) && !IsDefined( eAttacker ) )
	{
		return;
	}

	if ( !IsDefined( eInflictor ) )
	{
		eInflictor = eAttacker;
	}

	if ( eInflictor.classname == "script_vehicle" )
	{
		// ignore vehicle entities (rc bomb, choppers)
		return;
	}

	if ( IsDefined( eInflictor.classname ) && eInflictor.classname == "auto_turret" )
	{
		eAttacker = eInflictor;
	}

	if ( IsDefined( eAttacker ) )
	{
		if ( level.teamBased && IsDefined( eAttacker.team ) )
		{
			if ( level.hardcoreMode && eAttacker.team == self.team )
			{
				if ( cointoss() && iDamage > 5 )
				{
				}
				else
				{
					return;
				}
			}
			else if ( eAttacker.team == self.team )
			{
				return;
			}
		}

		if (!isSubStr(sWeapon, "_silencer_"))
			self bot_cry_for_help( eAttacker );
		
		self SetAttacker( eAttacker );
		self thread bot_find_attacker( eAttacker );
	}
}

bot_cry_for_help( attacker )
{
	if ( !level.teamBased )
	{
		return;
	}

	if ( level.teamBased && IsDefined( attacker.team ) )
	{
		if ( attacker.team == self.team )
		{
			return;
		}
	}
	
	if ( IsDefined( self.help_time ) && GetTime() - self.help_time < 1000 )
	{
		return;
	}
	
	self.help_time = GetTime();

	players = get_players();
	dist = GetDvarInt( #"scr_help_dist" );

	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

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

		if ( DistanceSquared( self.origin, player.origin ) > dist * dist )
		{
			continue;
		}

		if ( RandomInt( 100 ) < 50 )
		{
			player thread bot_find_attacker( attacker );

			if ( RandomInt( 100 ) > 70 )
			{
				break;
			}
		}
	}
}

bot_find_attacker( attacker )
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( !IsDefined( attacker ) || !IsAlive( attacker ) )
	{
		return;
	}
	
	if ( self IsRemoteControlling() || self.bot_lock_goal )
	{
		return;
	}

	if ( attacker.classname == "auto_turret" )
	{
		if(IsDefined( self GetThreat() ))
			return;
		
		self SetScriptEnemy( attacker );
		wait 1;
		self ClearScriptEnemy();
		return;
	}
	
	if ( self HasScriptGoal() )
		return;

	dir = VectorNormalize( attacker.origin - self.origin );
	dir = vector_scale( dir, 128 );

	goal = self.origin + dir;
	goal = ( goal[0], goal[1], self.origin[2] + 50 );

	//DebugStar( goal, 100, ( 1, 0, 0 ) );
	
	self.bot_lock_goal = true;

	self.did = "bot_find_attacker";
	self SetScriptGoal( goal, 128 );

	wait( 1 );

	self ClearScriptGoal();
	
	self.bot_lock_goal = false;
}

bot_escort_obj(obj, carrier)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(isDefined(obj.carrier) && carrier == obj.carrier)
		wait 0.5;
	
	self notify("goal");
}

bot_get_obj(obj)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(!isDefined(obj.carrier))
		wait 0.5;
	
	self notify("goal");
}

bot_check_unreachable(obj)
{
	self endon("bot_check_unreachable");
	self endon("goal");
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	
	self waittill("bad_path");
	
	if(isDefined(obj))
		obj.bots++;
}

bot_inc_bots(obj)
{
	level endon("game_ended");
	
	obj.bots++;
	
	self waittill_any("death", "disconnect", "bot_inc_bots");
	
	if (isDefined(obj))
		obj.bots--;
}

bot_go_defuse(defuse)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(level.bombPlanted && !self isTouching(defuse.trigger))
		wait 0.5;
	
	if(!level.bombPlanted)
		self notify("bad_path");
	else
		self notify("goal");
}

bot_go_plant(plant)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(!level.bombPlanted && !self isTouching(plant.trigger))
		wait 1;
	
	if(level.bombPlanted)
		self notify("bad_path");
	else
		self notify("goal");
}

bot_use_bomb_thread(bomb)
{
	self thread bot_use_bomb(bomb);
	self waittill_any("bot_try_use_fail", "bot_try_use_success");
}

bot_bomb_use_time(wait_time)
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	self endon("bot_try_use_fail");
	self endon("bot_try_use_success");
	
	self waittill("bot_try_use_weapon");
	
	elapsed = 0;
	while(wait_time > elapsed)
	{
		wait 0.05;//wait first so waittill can setup
		elapsed += 0.05;
		
		if(isDefined(self.laststand) && self.laststand)
		{
			self notify("bot_try_use_fail");
			return;//needed?
		}
	}
	
	self notify("bot_try_use_success");
}

bot_freeze_in_place(loc)
{
	level endon("game_ended");
	self endon("bot_try_use_fail");
	self endon("bot_try_use_success");
	self endon("death");
	self endon("disconnect");
	
	for(;;)
	{
		self setVelocity((0,0,0));
		self setOrigin(loc);
		wait 0.05;
	}
}

bot_use_bomb_weapon(weap)
{
	level endon("game_ended");
	self endon("death");
	self endon("disconnect");
	
	lastWeap = self getCurrentWeapon();
	
	if(self getCurrentWeapon() != weap)
	{
		self GiveWeapon( weap );
		self switchToWeapon(weap);
		self wait_endon(10, "weapon_change");
		if(self getCurrentWeapon() != weap)
		{
			self notify("bot_try_use_fail");
			return;
		}
	}
	else
	{
		wait 0.05;//allow a waittill to setup as the notify may happen on the same frame
	}
	
	self freeze_player_controls(true);
	
	self notify("bot_try_use_weapon");
	ret = self waittill_any_return("bot_try_use_fail", "bot_try_use_success");
	
	self freeze_player_controls(false);
	
	if(lastWeap != "none" && ret != "bot_try_use_fail" && lastWeap != weap)
		self switchToWeapon(lastWeap);
	else
		self takeWeapon(weap);
}

bot_use_bomb(bomb)
{
	level endon("game_ended");
	
	myteam = self.team;
	
	self thread bot_freeze_in_place(self.origin);
	
	bomb [[bomb.onBeginUse]](self);
	bomb.inUse = true;
	self clientClaimTrigger( bomb.trigger );
	self.claimTrigger = bomb.trigger;
	
	self thread bot_bomb_use_time(((bomb.useTime) / 1000) + 0.5);
	self thread bot_use_bomb_weapon(bomb.useWeapon);
	
	result = self waittill_any_return("death", "disconnect", "bot_try_use_fail", "bot_try_use_success");
	
	bomb [[bomb.onEndUse]](myteam, self, (result == "bot_try_use_success"));
	bomb.inUse = false;
	self.claimTrigger = undefined;
	bomb.trigger releaseClaimedTrigger();
	
	if(result == "bot_try_use_success")
		bomb [[bomb.onUse]](self);
}

bot_revive_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	
	if ( !level.teamBased )
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( !self bot_is_idle() )
			continue;
		
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
			
			if ( !IsAlive( player ) )
			{
				continue;
			}
			
			if ( player.team != self.team )
			{
				continue;
			}
			
			if ( !IsDefined( player.revivetrigger ) )
			{
				continue;
			}
			
			if ( DistanceSquared( self.origin, player.origin ) > 2048 * 2048 )
			{
				continue;
			}
			
			if(!isDefined(player.bots))
				player.bots = 0;
			
			if(player.bots >= 2)
				continue;
			
			self thread bot_check_unreachable(player);
			self thread bot_inc_bots(player);
			
			event = "bad_path";
			if(!self isTouching(player.revivetrigger))
			{
				self thread bot_revive_go(player);
				event = self waittill_any_return( "goal", "bad_path" );
			}
			else
			{
				self notify("goal");
				event = "goal";
			}
			
			self ClearScriptGoal();
			
			if (event == "bad_path")
			{
				self notify("bot_inc_bots");
				continue;
			}
			
			self.bot_lock_goal = true;
			
			self.did = "bot_revive_think";
			self SetScriptGoal( self.origin, 64 );
			
			if ( IsDefined( player ) && IsDefined( player.revivetrigger ) && self IsTouching( player.revivetrigger ) )
			{
				self PressUseButton( GetDvarInt( #"revive_time_taken" ) + 1 );
				wait( GetDvarInt( #"revive_time_taken" ) + 1.5 );
			}
			
			self notify("bot_inc_bots");
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			break;
		}
	}
}

bot_revive_go(player)
{
	self endon("goal");
	self endon("bad_path");
	level endon("game_ended");
	self endon( "death" );
	self endon( "disconnect" );
	
	while(isDefined(player) && isDefined(player.revivetrigger))
	{
		if(self isTouching(player.revivetrigger))
		{
			self notify("goal");
			return;//?
		}
		
		goal = player.origin;
		
		self.did = "bot_revive_go";
		self SetScriptGoal( goal, 32 );
		
		while(DistanceSquared(goal, player.origin) <= 32*32 && isDefined(player) && isDefined(player.revivetrigger) && !self isTouching(player.revivetrigger))
			wait 0.5;
	}
	
	self notify("bad_path");
}

bot_crate_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	
	myteam = self.pers[ "team" ];
	
	first = true;
	
	for ( ;; )
	{
		if(first)
			first = false;
		else
			self wait_endon( randomintrange( 3, 5 ), "bot_crate_landed" );
		
		if ( RandomInt( 100 ) < 20 )
		{
			continue;
		}
		
		if ( !self bot_is_idle() )
		{
			wait 0.05;//because bot_crate_landed notify causes a same frame ClearScriptGoal
			
			if(!self bot_is_idle())
				continue;
		}
		
		crates = GetEntArray( "care_package", "script_noteworthy" );
		if ( crates.size == 0 )
		{
			continue;
		}
		
		crate = random( crates );
		if ( IsDefined( crate.droppingToGround ) )
		{
			continue;
		}
		
		if ( level.teambased )
		{
			if ( myteam == crate.team )
			{
				if ( RandomInt( 100 ) > 30 && IsDefined( crate.owner ) && crate.owner != self )
				{
					continue;
				}
			}
			else if (isDefined(crate.hacker))
				continue;
		}
		
		if ( DistanceSquared( self.origin, crate.origin ) > 2048 * 2048 )
		{
			if ( !IsDefined( crate.owner ) )
			{
				continue;
			}
			
			if ( crate.owner != self )
			{
				continue;
			}
		}
		
		if ( !IsDefined( crate.bots ) )
		{
			crate.bots = 0;
		}
		
		if ( crate.bots >= 3 )
		{
			continue;
		}
		
		self thread bot_inc_bots(crate);
		self thread bot_check_unreachable(crate);
		
		origin = ( crate.origin[0], crate.origin[1], crate.origin[2] + 12 );
		self.did = "bot_crate_think";
		self SetScriptGoal( origin, 32 );
		
		path = "bad_path";
		if(DistanceSquared(self.origin, origin) > 32*32)
		{
			self thread crate_path_monitor( crate );
			self thread crate_touch_monitor( crate );
			
			path = self waittill_any_return( "goal", "bad_path" );
		}
		else
		{
			self notify("goal");
			path = "goal";
		}
		
		self ClearScriptGoal();
		
		if ( path == "bad_path" )
		{
			self notify("bot_inc_bots");
			continue;
		}
		
		self.bot_lock_goal = true;
		
		self.did = "bot_crate_think(2)";
		self SetScriptGoal( self.origin, 64 );
		
		if(isdefined( crate.crateType.hint_gambler ) && self hasPerk("specialty_gambler") && randomInt(3))
		{
			crate notify( "trigger_use_doubletap", self );
			wait 1;
		}
		
		if ( crate.owner == self )
		{
			self PressUseButton( level.crateOwnerUseTime / 1000 + 0.5 );
			wait( level.crateOwnerUseTime / 1000 + 0.5 );
		}
		else
		{
			self PressUseButton( level.crateNonOwnerUseTime / 1000 + 1 );
			wait( level.crateNonOwnerUseTime / 1000 + 1.5 );
		}
		
		self notify("bot_inc_bots");
		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
	}
}

crate_path_monitor( crate )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "bad_path" );
	self endon( "goal" );
	level endon("game_ended");
	
	crate waittill( "death" );
	
	self notify( "bad_path" );
}

crate_touch_monitor( crate )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "bad_path" );
	self endon( "goal" );
	level endon("game_ended");
	
	radius = GetDvarFloat( #"player_useRadius" );
	
	for ( ;; )
	{
		wait( 0.5 );
		
		if ( DistanceSquared( self.origin, crate.origin ) < radius * radius )
		{
			self notify( "goal" );
			return;
		}
	}
}

bot_crate_touch_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	radius = GetDvarFloat( #"player_useRadius" );

	for ( ;; )
	{
		wait( 3 );

		if ( IsDefined( self GetThreat() ) )
		{
			continue;
		}

		if ( self UseButtonPressed() )
		{
			continue;
		}

		crates = GetEntArray( "care_package", "script_noteworthy" );

		for ( i = 0; i < crates.size; i++ )
		{
			crate = crates[i];

			if ( DistanceSquared( self.origin, crate.origin ) < radius * radius )
			{
				if ( crate.owner == self )
				{
					self PressUseButton( level.crateOwnerUseTime / 1000 + 0.5 );
					wait level.crateOwnerUseTime / 1000 + 0.5;
				}
				else
				{
					self PressUseButton( level.crateNonOwnerUseTime / 1000 + 0.5 );
					wait level.crateNonOwnerUseTime / 1000 + 0.5;
				}
			}
		}
	}
}

turret_death_monitor( turret )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	level endon ( "game_ended" );
	
	turret waittill_any( "turret_carried", "turret_deactivated", "death" );
	
	self notify("bad_path");
}

bot_go_hack_turret(turret)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(isDefined(turret) && isDefined(turret.hackerTrigger) && !self isTouching(turret.hackerTrigger))
		wait 0.5;
	
	if(!isDefined(turret) || !isDefined(turret.hackerTrigger))
		self notify("bad_path");
	else
		self notify("goal");
}

bot_turret_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	myteam = self.pers[ "team" ];

	if ( GetDvar( #"bot_difficulty" ) == "easy" )
	{
		return;
	}

	for ( ;; )
	{
		wait( 1 );

		turrets = GetEntArray( "auto_turret", "classname" );

		if ( turrets.size == 0 || !self bot_is_idle() )
		{
			wait( randomintrange( 3, 5 ) );
			continue;
		}

		turret = Random( turrets );

		if ( turret.carried )
		{
			continue;
		}

		if ( turret.damageTaken >= turret.health )
		{
			continue;
		}

		if ( level.teambased && turret.team == myteam )
		{
			continue;
		}

		if ( IsDefined( turret.owner ) && turret.owner == self )
		{
			continue;
		}

		forward = AnglesToForward( turret.angles );
		forward = VectorNormalize( forward );

		delta = self.origin - turret.origin;
		delta = VectorNormalize( delta );
		
		dot = VectorDot( forward, delta );
		facing = true;

		if ( dot < 0.342 ) // cos 70 degrees
		{
			facing = false;
		}

		if ( turret.turrettype == "tow" )
		{
			facing = false;
		}

		if ( turret maps\mp\gametypes\_weaponobjects::isStunned() )
		{
			facing = false;
		}
		
		if(self hasPerk("specialty_nottargetedbyai"))
			facing = false;

		if ( facing && !BulletTracePassed( self getEye(), turret.origin + ( 0, 0, 15 ), false, turret ) )
		{
			continue;
		}
		
		if ( !IsDefined( turret.bots ) )
		{
			turret.bots = 0;
		}

		if ( turret.bots >= 2 )
		{
			continue;
		}
		
		self thread bot_inc_bots(turret);
		
		if(!facing)
		{
			self thread turret_death_monitor( turret );
			self thread bot_check_unreachable(turret);
			
			if ( self HasPerk( "specialty_disarmexplosive" ) )
			{
				self.did = "bot_turret_think";
				self SetScriptGoal( turret.origin, 32 );
				
				path = "bad_path";
				if(isDefined(turret.hackerTrigger) && !self isTouching(turret.hackerTrigger))
				{
					self thread bot_go_hack_turret(turret);
					path = self waittill_any_return( "goal", "bad_path" );
				}
				else
				{
					self notify("goal");
					path = "goal";
				}
				
				self ClearScriptGoal();
				
				if ( path == "bad_path" || !isDefined(turret) || !isDefined(turret.hackerTrigger) || !self isTouching(turret.hackerTrigger) )
				{
					self notify("bot_inc_bots");
					continue;
				}
				
				self.bot_lock_goal = true;
				
				self.did = "bot_turret_think(2)";
				self SetScriptGoal( self.origin, 32 );
				
				hackTime = GetDvarFloat( #"perk_disarmExplosiveTime" );
				self PressUseButton( hackTime + 0.5 );
				wait( hackTime + 0.5 );
				
				self notify("bot_inc_bots");
				self ClearScriptGoal();
				
				self.bot_lock_goal = false;
				continue;
			}
			else
			{
				self.did = "bot_turret_think(3)";
				self SetScriptGoal( turret.origin, 64 );
				
				path = "bad_path";
				if(DistanceSquared(self.origin, turret.origin) > 64*64)
				{
					path = self waittill_any_return( "goal", "bad_path" );
				}
				else
				{
					self notify("goal");
					path = "goal";
				}
				
				self ClearScriptGoal();
				
				if ( path == "bad_path" || !isDefined(turret) )
				{
					self notify("bot_inc_bots");
					continue;
				}
			}
		}
		
		self notify("bot_inc_bots");
		
		if(!isDefined(turret))
			continue;

		self SetScriptEnemy( turret );
		self bot_turret_attack(turret);
		self ClearScriptEnemy();
	}
}

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

bot_killstreak_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	myteam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	wait( 1 );

	for ( ;; )
	{
		wait( RandomIntRange( 1, 3 ) );
		
		if (isDefined(self GetThreat()))
			continue;
		
		if ( self IsRemoteControlling() )
		{
			continue;
		}
		
		if(self UseButtonPressed())
			continue;
			
		if(isDefined(self.isDefusing) && self.isDefusing)
			continue;
			
		if(isDefined(self.isPlanting) && self.isPlanting)
			continue;

		weapon = self maps\mp\gametypes\_hardpoints::getTopKillstreak();
		
		if ( !IsDefined( weapon ) || weapon == "none" )
		{
			continue;
		}

		killstreak = maps\mp\gametypes\_hardpoints::getKillStreakMenuName( weapon );

		if ( !IsDefined( killstreak ) )
		{
			continue;
		}

		id = self maps\mp\gametypes\_hardpoints::getTopKillstreakUniqueId();

		if ( !self maps\mp\_killstreakrules::isKillstreakAllowed( weapon, myteam ) )
		{
			wait( 5 );
			continue;
		}

		switch( killstreak )
		{
			case "killstreak_helicopter_comlink":
			case "killstreak_napalm":
			case "killstreak_airstrike":
				self bot_killstreak_location( 1, weapon );
				break;

			case "killstreak_mortar":
				self bot_killstreak_location( 3, weapon );
				break;
			
			case "killstreak_auto_turret_drop":
			case "killstreak_tow_turret_drop":
			case "killstreak_m220_tow_drop":
			case "killstreak_supply_drop":
				if(killstreak == "killstreak_supply_drop")
					weapon = "supplydrop_mp";
				
				self bot_use_supply_drop( weapon );
				break;

			case "killstreak_auto_turret":
			case "killstreak_tow_turret":
				self bot_turret_location( weapon );
				break;

			case "killstreak_helicopter_gunner":
			case "killstreak_helicopter_player_firstperson":
				self bot_control_heli(weapon);
				wait 1;
				self SwitchToWeapon( self.lastNonKillstreakWeapon );
				break;

			case "killstreak_rcbomb":
				if ( self GetLookaheadDist() < 128 )
				{
					continue;
				}

				dir = self GetLookaheadDir();

				if ( !IsDefined( dir ) )
				{
					continue;
				}

				dir = VectorToAngles( dir );

				if ( abs( dir[1] - self.angles[1] ) > 5 )
				{
					continue;
				}

				if(self getCurrentWeapon() != weapon)
				{
					self SwitchToWeapon( weapon );
					self wait_endon( 10, "weapon_change" );
					
					if(self getCurrentWeapon() != weapon)
						continue;
				}
				
				self bot_rccar_think();
				break;

			case "killstreak_spyplane":
				if ( GetDvar( #"bot_difficulty" ) != "easy" )
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
				
				if(self getCurrentWeapon() != weapon)
				{
					self SwitchToWeapon( weapon );
					self wait_endon( 10, "weapon_change" );
				}
				break;
			
			case "killstreak_counteruav":
				if ( GetDvar( #"bot_difficulty" ) != "easy" )
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
				
				if(self getCurrentWeapon() != weapon)
				{
					self SwitchToWeapon( weapon );
					self wait_endon( 10, "weapon_change" );
				}
				break;
				
			case "killstreak_spyplane_direction":
				if ( GetDvar( #"bot_difficulty" ) != "easy" )
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
				
				if(self getCurrentWeapon() != weapon)
				{
					self SwitchToWeapon( weapon );
					self wait_endon( 10, "weapon_change" );
				}
				break;
			
			case "killstreak_dogs":
			default:
				if(self getCurrentWeapon() != weapon)
				{
					self SwitchToWeapon( weapon );
					self wait_endon( 10, "weapon_change" );
				}
				break;
		}
		
		if (weapon == "m220_tow_mp" || weapon == "m202_flash_mp" || weapon == "minigun_mp")
			continue;

		// crazy fail-safe
		wait( 0.05 );
		if ( self GetCurrentWeapon() == weapon || self GetCurrentWeapon() == "none" )
		{
			self SwitchToWeapon( self.lastNonKillstreakWeapon );
		}
	}
}

bot_control_heli(weapon)
{
	if(self getCurrentWeapon() != weapon)
	{
		self SwitchToWeapon( weapon );
		self wait_endon( 10, "weapon_change" );
		
		if(weapon != self getCurrentWeapon())
			return;
	}
	
	self endon("heli_timeup");
	
	wait 2.5;
	
	if(!isDefined(self.heli))
		return;
	
	self.heli endon("death");
	self.heli endon("heli_timeup");
	
	while(isDefined(self.heli))
	{
		wait 0.25;
	}
}

bot_rccar_think()
{
	self thread bot_rccar_think_thread();
	self waittill_any("rcbomb_done", "weapon_object_destroyed", "bot_rc_done");
}

bot_rccar_think_thread()
{
	self endon( "disconnect" );
	self endon( "rcbomb_done" );
	self endon( "weapon_object_destroyed" );
	level endon ( "game_ended" );
	
	wait 2;

	self thread bot_rccar_kill();

	for ( ;; )
	{
		wait( 0.5 );

		if ( !IsDefined( self.rcbomb ) )
		{
			self notify("bot_rc_done");
			return;
		}

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

			if ( !IsAlive( player ) )
			{
				continue;
			}

			if ( level.teamBased && player.team == self.team )
			{
				continue;
			}

			if ( GetDvar( #"bot_difficulty" ) == "easy" )
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
	}
}

bot_rccar_kill()
{
	self endon( "disconnect" );
	self endon( "rcbomb_done" );
	self endon( "weapon_object_destroyed" );
	level endon ( "game_ended" );

	og_origin = self.origin;

	for ( ;; )
	{
		wait( 1 );

		if ( !IsDefined( self.rcbomb ) )
		{
			self notify("bot_rc_done");
			return;
		}

		if ( DistanceSquared( og_origin, self.rcbomb.origin ) < 16 * 16 )
		{
			wait( 2 );

			if ( !IsDefined( self.rcbomb ) )
			{
				self notify("bot_rc_done");
				return;
			}

			if ( DistanceSquared( og_origin, self.rcbomb.origin ) < 16 * 16 )
			{
				self PressAttackButton();
			}
		}

		og_origin = self.rcbomb.origin;
	}
}

bot_use_item( weapon )
{
	self PressAttackButton();
	wait( 0.5 );

	for ( i = 0; i < 5; i++ )
	{
		if ( self GetCurrentWeapon() == weapon || self GetCurrentWeapon() == "none" )
		{
			self PressAttackButton();
		}

		wait( 0.25 );
	}
}

bot_turret_location( weapon )
{
	for ( ;; )
	{
		wait( 0.5 );
		
		if( self getCurrentWeapon() != weapon && weapon != self maps\mp\gametypes\_hardpoints::getTopKillstreak() )
			return;
		
		if ( !self HasWeapon( weapon ) )
		{
			return;
		}

		if ( isDefined(self GetThreat()) )
		{
			continue;
		}
		
		if(self UseButtonPressed())
			continue;
			
		if(isDefined(self.isDefusing) && self.isDefusing)
			continue;
			
		if(isDefined(self.isPlanting) && self.isPlanting)
			continue;

		if ( GetDvar( #"bot_difficulty" ) == "easy" )
		{
			if ( self GetLookaheadDist() < 128 )
			{
				continue;
			}
		}
		else if ( self GetLookaheadDist() < 256 )
		{
			continue;
		}

		dir = self GetLookaheadDir();

		if ( !IsDefined( dir ) )
		{
			continue;
		}

		dir = VectorToAngles( dir );

		if ( abs( dir[1] - self.angles[1] ) > 5 )
		{
			continue;
		}

		yaw = ( 0, self.angles[1], 0 );
		dir = AnglesToForward( yaw );
		dir = VectorNormalize( dir );

		goal = self.origin + vector_scale( dir, 32 );

		if ( weapon == "autoturret_mp" && GetDvar( #"bot_difficulty" ) != "easy" )
		{
			eye = self.origin + ( 0, 0, 60 );
			goal = eye + vector_scale( dir, 1024 );

			if ( !SightTracePassed( self.origin, goal, false, undefined ) )
			{
				continue;
			}
		}

		if ( weapon == "auto_tow_mp" )
		{
			end = goal + ( 0, 0, 2048 );
		
			if ( !SightTracePassed( goal, end, false, undefined ) )
			{
				continue;
			}
		}
		
		if(self getCurrentWeapon() != weapon)
		{
			self SwitchToWeapon( weapon );
			self wait_endon( 10, "weapon_change_complete" );
			
			if(self getCurrentWeapon() != weapon)
				continue;
		}
		
		self freeze_player_controls(true);
		wait 1;
		self freeze_player_controls(false);
		
		self bot_use_item( weapon );
		self SwitchToWeapon( self.lastNonKillstreakWeapon );
		return;
	}
}

bot_use_supply_drop( weapon )
{
	wait_time = 1;

	for ( ;; )
	{
		wait( wait_time );
		wait_time = 1;
		
		if(weapon != "supplydrop_mp")
		{
			if( weapon != self maps\mp\gametypes\_hardpoints::getTopKillstreak() )
				return;
		}
		else
		{
			if(self maps\mp\gametypes\_hardpoints::getTopKillstreak() != "supply_drop_mp")
				return;
		}

		if ( !self HasWeapon( weapon ) )
		{
			return;
		}

		if ( !self bot_is_idle() )
		{
			continue;
		}

		if ( self GetLookaheadDist() < 96 )
		{
			continue;
		}

		view_angles = self GetPlayerAngles();

		if ( view_angles[0] < 7 )
		{
			continue;
		}

		dir = self GetLookaheadDir();

		if ( !IsDefined( dir ) )
		{
			continue;
		}

		dir = VectorToAngles( dir );

		if ( abs( dir[1] - self.angles[1] ) > 2 )
		{
			continue;
		}

		yaw = ( 0, self.angles[1], 0 );
		dir = AnglesToForward( yaw );

		dir = VectorNormalize( dir );
		drop_point = self.origin + vector_scale( dir, 384 );
		//DebugStar( drop_point, 500, ( 1, 0, 0 ) );

		end = drop_point + ( 0, 0, 2048 );
		//DebugStar( end, 500, ( 1, 0, 0 ) );

		if ( !SightTracePassed( drop_point, end, false, undefined ) )
		{
			continue;
		}

		if ( !SightTracePassed( self.origin, end, false, undefined ) )
		{
			continue;
		}

		// is this point in mid-air?
		end = drop_point - ( 0, 0, 32 );
		//DebugStar( end, 500, ( 1, 0, 0 ) );
		if ( BulletTracePassed( drop_point, end, false, undefined ) )
		{
			wait_time = 0.1;
			continue;
		}

		goal = self.origin + vector_scale( dir, 64 );
		//DebugStar( goal, 500, ( 0, 1, 0 ) );

		self.did = "bot_use_supply_drop";
		self SetScriptGoal( goal, 128 );
		
		path = "bad_path";
		if(DistanceSquared(self.origin, goal) > 128*128)
		{
			path = self waittill_any_return( "goal", "bad_path" );
		}
		else
		{
			self notify("goal");
			path = "goal";
		}
		
		self ClearScriptGoal();
		
		if (path == "bad_path")
		{
			continue;
		}
		
		self.bot_lock_goal = true;
		
		self.did = "bot_use_supply_drop(2)";
		self SetScriptGoal( self.origin, 128 );
		
		if(self getCurrentWeapon() != weapon)
		{
			self SwitchToWeapon( weapon );
			self wait_endon( 10, "weapon_change_complete" );
			
			if(self getCurrentWeapon() != weapon)
			{
				self ClearScriptGoal();
				self.bot_lock_goal = false;
				continue;
			}
		}
		
		self bot_use_item( weapon );
		self SwitchToWeapon( self.lastNonKillstreakWeapon );
		
		self wait_endon( RandomIntRange( 10, 15 ), "bot_crate_landed" );
		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
		return;
	}
}

bot_killstreak_location( num, weapon )
{
	if(self getCurrentWeapon() != weapon)
	{
		self SwitchToWeapon( weapon );
		self wait_endon( 10, "weapon_change" );
		
		if(self getCurrentWeapon() != weapon)
			return;
	}
	
	self freeze_player_controls( true );

	wait_time = 1;
	while ( !IsDefined( self.selectingLocation ) || self.selectingLocation == false )
	{
		wait( 0.05 );
		wait_time -= 0.05;

		if ( wait_time <= 0 )
		{
			self freeze_player_controls( false );
			self SwitchToWeapon( self.lastNonKillstreakWeapon );
			return;
		}
	}

	wait( 2 );
	myteam = self.pers[ "team" ];

	for ( i = 0; i < num; i++ )
	{
		wait( 0.05 );
		player = Random( get_players() );
		
		if(!isDefined(player.team))
		{
			i--;
			continue;
		}

		if ( player.sessionstate != "playing" )
		{
			i--;
			continue;
		}

		if ( player == self )
		{
			i--;
			continue;
		}

		if ( level.teambased )
		{
			if ( myteam == player.team )
			{
				i--;
				continue;
			}
		}

		x = RandomIntRange( -512, 512 );
		y = RandomIntRange( -512, 512 );

		origin = player.origin;
		origin = origin + ( x, y, 0 );
		yaw = RandomIntRange( 0, 360 );

		wait( 0.25 );
		self notify( "confirm_location", origin, yaw );
	}

	self freeze_player_controls( false );
}

bot_dogs_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	myteam = self.pers[ "team" ];

	if ( level.no_dogs )
	{
		return;
	}

	for ( ;; )
	{
		wait( 0.25 );

		if ( !IsDefined( level.dogs ) || level.dogs.size <= 0 )
		{
			level waittill( "called_in_the_dogs" );
		}
		
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

			if ( DistanceSquared( self.origin, dog.origin ) < ( 1024 * 1024 ) )
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

bot_vehicle_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	if ( GetDvar( #"bot_difficulty" ) == "easy" )
	{
		return;
	}

	myteam = self.pers[ "team" ];

	for ( i=5;;i++ )
	{
		wait( 1 );
		
		if ( !self bot_is_idle() )
		{
			continue;
		}
		
		airborne_enemies = GetEntArray( "script_vehicle", "classname" );
		target = undefined;
		if ( IsDefined( airborne_enemies ) && airborne_enemies.size > 0 )
		{
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
					if ( !self bot_vehicle_weapon() )
					{
						continue;
					}
				}

				if ( !BulletTracePassed( self.origin, enemy.origin, false, enemy ) )
				{
					continue;
				}

				target = enemy;
				break;
			}
		}
		
		if(i > 3)
		{
			i = 0;
			
			if(!isDefined(target) && level.bot_planes.size && self bot_vehicle_weapon_plane() != "")
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
					
					if ( !BulletTracePassed( self getEye(), enemy.origin, false, enemy ) )
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
		}
		else
		{
			self SetScriptEnemy( target );
			self bot_vehicle_attack( target );
			self ClearScriptEnemy();
		}
	}
}

bot_plane_attack(ent)
{
	weap = self bot_vehicle_weapon_plane();
	
	if(weap == "")
		return;
	
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
		self.bot_lock_goal = true;
		
		self.did = "bot_plane_attack";
		self SetScriptGoal(self.origin, 32);
	
		if(self getCurrentWeapon() != weap)
		{
			self SwitchToWeapon( weap );
			
			self wait_endon( 10, "weapon_change_complete" );
			
			if(self getCurrentWeapon() != weap)
			{
				self.bot_lock_goal = false;
				self ClearScriptGoal();
				return;
			}
		}
		
		if(!self GetWeaponAmmoClip(weap))
		{
			self PressAttackButton();
			self wait_endon(10, "reload");
		}
		
		self ClearScriptGoal();
		
		self freeze_player_controls(true);
		
		self.bot_lock_goal = false;
	}
	
	wait_time = 0;
	lock_time = 0;
	while(wait_time < 2)
	{
		if(!self GetWeaponAmmoClip(weap))
			return;
		
		if(self getCurrentWeapon() != weap)
			return;
		
		if(IsDefined( self.laststand ) && self.laststand == true)
			return;
		
		if ( !IsDefined( ent ) )
		{
			return;
		}

		if ( !IsAlive( ent ) )
		{
			return;
		}
		
		if ( !BulletTracePassed( self getEye(), ent.origin, false, ent ) )
		{
			wait_time += 0.05;
			lock_time = 0;
		}
		else
		{
			wait_time = 0;
			lock_time += 0.05;
			
			self thread bot_lookat(VectorToAngles(((ent.origin-self.origin)-(anglesToForward(self getplayerangles())))), 4);
			
			if(lock_time >= 2)
			{
				self SetWeaponAmmoClip(weap, self GetWeaponAmmoClip(weap)-1);
				
				missile = MagicBullet( weap, self getEye(), ent.origin, self );
				missile Missile_SetTarget( ent );
				
				self notify ( "missile_fire", missile, weap );
				ent notify( "stinger_fired_at_me", missile, weap, self );
				level notify ( "missile_fired", self, missile, ent, true );
				self notify( "stinger_fired", missile, weap );
				self notify("bots_aim_overlap");
				
				wait 1;
				return;
			}
		}
		
		wait 0.05;
	}
}

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
			if ( !self bot_vehicle_weapon() )
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

bot_vehicle_weapon_plane()
{
	weapons = [];
	weapons[0] = "m72_law_mp";
	weapons[1] = "strela_mp";
	weapons[2] = "m202_flash_mp";

	for ( i = 0; i < weapons.size; i++ )
	{
		if ( self HasWeapon( weapons[i] ) && self bot_vehicle_weapon_ammo( weapons[i] ) > 0 )
		{
			return weapons[i];
		}
	}

	return "";
}

bot_vehicle_weapon()
{
	weapons = [];
	weapons[0] = "m72_law_mp";
	weapons[1] = "strela_mp";
	weapons[2] = "m202_flash_mp";
	weapons[3] = "minigun_mp";
	weapons[4] = "rpg_mp";

	for ( i = 0; i < weapons.size; i++ )
	{
		if ( self HasWeapon( weapons[i] ) && self bot_vehicle_weapon_ammo( weapons[i] ) > 0 )
		{
			return true;
		}
	}

	return false;
}

bot_vehicle_weapon_ammo( weapon )
{
	return ( self GetWeaponAmmoClip( weapon ) + self GetWeaponAmmoStock( weapon ) );
}

bot_equipment_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	weapon = self.pers["bot"]["class_equipment"];
	
	if(weapon == "" || weapon == "weapon_null_mp" || weapon == "satchel_charge_mp")
		return;

	for ( ;; )
	{
		wait( RandomIntRange( 2, 15 ) );

		if ( !self HasWeapon( weapon ) )
		{
			return;
		}

		if ( !self bot_is_idle() )
		{
			continue;
		}

		if ( self._is_sprinting )
		{
			continue;
		}

		if ( weapon == "camera_spike_mp" )
		{
			if ( self GetLookaheadDist() < 384 )
			{
				continue;
			}

			view_angles = self GetPlayerAngles();

			if ( view_angles[0] < -5 )
			{
				continue;
			}
		}
		else
		{
			if ( self GetLookaheadDist() > 64 )
			{
				continue;
			}
		}

		dir = self GetLookaheadDir();

		if ( !IsDefined( dir ) )
		{
			continue;
		}

		dir = VectorToAngles( dir );

		if ( abs( dir[1] - self.angles[1] ) > 5 )
		{
			continue;
		}

		dir = VectorNormalize( AnglesToForward( self.angles ) );
		dir = vector_scale( dir, 32 );
		goal = self.origin + dir;

		self.did = "bot_equipment_think";
		self SetScriptGoal( goal, 128 );
		
		path = "bad_path";
		if(DistanceSquared(self.origin, goal) > 128*128)
		{
			path = self waittill_any_return( "goal", "bad_path" );
		}
		else
		{
			self notify("goal");
			path = "goal";
		}
		
		self ClearScriptGoal();
		
		if (path == "bad_path" || equipment_nearby( self.origin ))
		{
			continue;
		}
		
		self.bot_lock_goal = true;
		
		self.did = "bot_equipment_think(2)";
		self SetScriptGoal( self.origin, 128 );
		
		lastWeap = self getCurrentWeapon();
		
		if(self getCurrentWeapon() != weapon)
		{
			self SwitchToWeapon( weapon );
			self wait_endon( 10, "weapon_change_complete" );
			if(self getCurrentWeapon() != weapon)
			{
				self.bot_lock_goal = false;
				self ClearScriptGoal();
				continue;
			}
		}

		self bot_use_item( weapon );
		
		if(lastWeap != "none")
			self switchToWeapon(lastWeap);
		
		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
	}
}

equipment_nearby( origin )
{
	grenades = GetEntArray( "grenade", "classname" );

	for ( i = 0; i < grenades.size; i++ )
	{
		item = grenades[i];

		if ( !IsDefined( item.name ) )
		{
			continue;
		}

		if ( !IsWeaponEquipment( item.name ) )
		{
			continue;
		}

		if ( DistanceSquared( item.origin, origin ) < 128 * 128 )
		{
			return true;
		}
	}

	return false;
}

bot_equipment_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	if ( GetDvar( #"bot_difficulty" ) == "easy" )
	{
		return;
	}

	myteam = self.pers[ "team" ];

	for ( ;; )
	{
		if ( self HasPerk( "specialty_showenemyequipment" ) )
		{
			wait( RandomIntRange( 2, 5 ) );
		}
		else
		{
			wait( RandomIntRange( 5, 7 ) );
		}

		if ( !self bot_is_idle() )
		{
			continue;
		}

		grenades = GetEntArray( "grenade", "classname" );
		target = undefined;

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

			if ( self HasPerk( "specialty_showenemyequipment" ) && DistanceSquared( item.origin, self.origin ) < 512 * 512 )
			{
				target = item;
				break;
			}

			if ( DistanceSquared( item.origin, self.origin ) < 256 * 256 )
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
				
				if ( self HasPerk( "specialty_showenemyequipment" ) && DistanceSquared( player.tacticalInsertion.origin, self.origin ) < 512 * 512 )
				{
					target = player.tacticalInsertion;
					break;
				}

				if ( DistanceSquared( player.tacticalInsertion.origin, self.origin ) < 256 * 256 )
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
				if ( VectorDot( VectorNormalize( AnglesToForward( target.angles ) ), VectorNormalize( self.origin - target.origin ) ) >= 0.342 || target maps\mp\gametypes\_weaponobjects::isStunned() ) // cos 70 degrees
				{
					facing = true;
				}
			}
			
			if ( ( self HasPerk( "specialty_disarmexplosive" ) && !facing ) || isDefined(target.enemyTrigger) )
			{
				self thread bot_check_unreachable(target);
				self thread bot_inc_bots(target);
				
				self.did = "bot_equipment_kill_think";
				self SetScriptGoal( target.origin, 32 );
				
				path = "bad_path";
				if((isDefined(target.hackerTrigger) && !self isTouching(target.hackerTrigger)) || (isDefined(target.enemyTrigger) && !self isTouching(target.enemyTrigger)))
				{
					self thread bot_go_hack_equ(target);
					path = self waittill_any_return( "goal", "bad_path" );
				}
				else
				{
					self notify("goal");
					path = "goal";
				}
				
				self ClearScriptGoal();
				
				if(path == "bad_path" || !isDefined(target) || (isDefined(target.hackerTrigger) && !self isTouching(target.hackerTrigger)) || (isDefined(target.enemyTrigger) && !self isTouching(target.enemyTrigger)))
				{
					self notify("bot_inc_bots");
					continue;
				}
				
				self.bot_lock_goal = true;
				
				self.did = "bot_equipment_kill_think(2)";
				self SetScriptGoal( self.origin, 32 );
				
				hackTime = GetDvarFloat( #"perk_disarmExplosiveTime" );
				self PressUseButton( hackTime + 0.5 );
				wait( hackTime + 0.5 );
				self ClearScriptGoal();
				self notify("bot_inc_bots");
				
				self.bot_lock_goal = false;
				continue;
			}

			self SetScriptEnemy( target );
			self bot_equipment_attack(target);
			self ClearScriptEnemy();
		}
	}
}

bot_go_hack_equ(equ)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(isDefined(equ) && ((isDefined(equ.enemyTrigger) && !self isTouching(equ.enemyTrigger)) || (isDefined(equ.hackerTrigger) && !self isTouching(equ.hackerTrigger))))
		wait 0.5;
	
	if(!isDefined(equ))
		self notify("bad_path");
	else
		self notify("goal");
}

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

bot_revenge_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );
	
	if ( GetDvar( #"bot_difficulty" ) == "easy" )
	{
		return;
	}
	
	went = isDefined(self.lastDeathPos);
	
	for(;;)
	{
		if(!went)
			return;
		
		wait( RandomIntRange( 1, 7 ) );
		
		if(self HasScriptGoal())
			continue;
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( randomint( 100 ) < 75 )
			continue;
		
		went = false;
		
		self.did = "bot_revenge_think";
		self SetScriptGoal( self.lastDeathPos, 64 );
		
		if(DistanceSquared(self.origin, self.lastDeathPos) > 64*64)
			self waittill_any( "goal", "bad_path" );
		
		self ClearScriptGoal();
	}
}

bot_weapon_think()//alt weapon mode impossible?
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );
	
	for(;;)
	{
		wait( RandomIntRange( 5, 15 ) );
		
		if(self UseButtonPressed())
			continue;
		
		weapon = self getCurrentWeapon();
		if(!isDefined(weapon) || weapon == "none")
		{
			weaps = self GetWeaponsList();
			for(i = 0; i < weaps.size; i++)
			{
				if(isSubStr(weaps[i], self.pers["primaryWeapon"]))
				{
					self switchToWeapon(weaps[i]);
					break;
				}
			}
			
			continue;
		}
		
		//self setSpawnWeapon(WeaponAltWeaponName(self getCurrentWeapon()));
		//swtich to a random weapon?
	}
}

bot_radiation_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	if ( level.script != "mp_radiation" )
	{
		return;
	}

	if ( level.wagerMatch )
	{
		return;
	}

	origins = [];
	origins[0] = ( 813, 5, 267 );
	origins[1] = ( -811, 30, 363 );

	for ( ;; )
	{
		wait( RandomIntRange( 5, 10 ) );
		
		if ( self HasScriptGoal() )
			continue;
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}

		origin = random( origins );

		if ( DistanceSquared( self.origin, origin ) < 256 * 256 )
		{
			self.did = "bot_radiation_think";
			self SetScriptGoal( origin, 32 );
			
			event = "bad_path";
			if(DistanceSquared(origin, self.origin) > 32*32)
			{
				event = self waittill_any_return( "goal", "bad_path" );
			}
			else
			{
				self notify("goal");
				event = "goal";
			}
			
			self ClearScriptGoal();
			
			if(event == "bad_path")
			{
				continue;
			}
			
			self.bot_lock_goal = true;
			
			self SetScriptGoal( self.origin, 32 );
			
			self PressUseButton( 3 );
			wait( 3 );
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			
			
			wait( RandomIntRange( 5, 10 ) );
		}
	}
}

bot_uav_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	
	myTeam = self.pers[ "team" ];		
	otherTeam = getOtherTeam( myTeam );
	diff = GetDvar( #"bot_difficulty" );
	
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
				
				if(diff != "easy")
					wasFooled = true;
				
				self.did = "bot_uav_think";
				self SetScriptGoal( g.origin, 128 );
				
				if(DistanceSquared(g.origin, self.origin) > 128*128)
				{
					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				
				shouldContinue = true;
				break;
			}
			
			if(shouldContinue)
				continue;
		}
		
		if ( diff == "easy" )
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
	}
}

bot_cap()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "ctf" )
		return;

	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		if(!isDefined(level.teamFlagZones) || !level.teamFlagZones.size)
			continue;
		
		if(!isDefined(level.teamFlags) || !level.teamFlags.size)
			continue;
		
		myflag = level.teamFlags[myteam];
		myzone = level.teamFlagZones[myteam];
		
		theirflag = level.teamFlags[otherTeam];
		theirzone = level.teamFlagZones[otherTeam];
		
		if(myflag maps\mp\gametypes\_gameobjects::isObjectAwayFromHome())
		{
			carrier = myflag.carrier;
			
			if(!isDefined(carrier))//someone doesnt has our flag
			{
				if(!isDefined(theirflag.carrier) && DistanceSquared(self.origin, theirflag.curorigin) < DistanceSquared(self.origin, myflag.curorigin)) //no one has their flag and its closer
					self bot_cap_get_flag(theirflag);
				else//go get it
					self bot_cap_get_flag(myflag);
					
				continue;
			}
			else
			{
				if(!theirflag maps\mp\gametypes\_gameobjects::isObjectAwayFromHome() && randomint(100) < 50)
				{ //take their flag
					self bot_cap_get_flag(theirflag);
				}
				else
				{
					if(self HasScriptGoal())
						continue;
					
					if(!isDefined(theirzone.bots))
						theirzone.bots = 0;
					
					origin = theirzone.curorigin;
					
					if(theirzone.bots > 2 || randomInt(100) < 45)
					{
						//kill carrier
						if(carrier hasPerk( "specialty_gpsjammer" ))
							continue;
						
						origin = carrier.origin;
						
						self.did = "bot_cap(kill_flag)";
						self SetScriptGoal( origin, 64 );
						
						if(DistanceSquared(origin, self.origin) > 64*64)
						{
							self thread bot_escort_obj(myflag, carrier);

							self waittill_any( "goal", "bad_path" );
						}
						
						self ClearScriptGoal();
						continue;
					}
					
					self thread bot_inc_bots(theirzone);
					
					//camp their zone
					if(DistanceSquared(origin, self.origin) <= 1024*1024)
					{
						wait 4;
						self notify("bot_inc_bots");
						continue;
					}
					
					self.did = "bot_cap(theirzone)";
					self SetScriptGoal( origin, 256 );
				
					if(DistanceSquared(origin, self.origin) > 256*256)
					{
						self thread bot_escort_obj(myflag, carrier);
						self waittill_any( "goal", "bad_path" );
					}
					
					self notify("bot_inc_bots");
					
					self ClearScriptGoal();
				}
			}
		}
		else//our flag is ok
		{
			if(isDefined(self.isFlagCarrier) && self.isFlagCarrier)//if have flag
			{
				//go cap
				origin = myzone.curorigin;
				
				self.bot_lock_goal = true;
			
				self notify("bot_check_unreachable");
				self notify("bad_path");
				
				wait 0.05;
				self.did = "bot_cap(cap)";
				self SetScriptGoal( origin, 32 );
				
				if(DistanceSquared(origin, self.origin) > 32*32)
				{
					self thread bot_get_obj(myflag);
					self waittill_any( "goal", "bad_path" );
				}
				
				wait 1;
				self ClearScriptGoal();
				self.bot_lock_goal = false;
				continue;
			}
			
			carrier = theirflag.carrier;
			
			if(!isDefined(carrier))//if no one has enemy flag
			{
				self bot_cap_get_flag(theirflag);
				continue;
			}
			
			//escort them
			
			if(self HasScriptGoal())
				continue;
			
			origin = carrier.origin;
			
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.did = "bot_cap(escort)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self thread bot_escort_obj(theirflag, carrier);

				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
		}
	}
}

bot_cap_get_flag(flag)
{
	origin = flag.curorigin;
	
	//go get it
	
	self.bot_lock_goal = true;

	self notify("bot_check_unreachable");
	self notify("bad_path");
	
	wait 0.05;
	if(!self isTouching(flag.trigger))
	{
		self.did = "bot_cap(flag_get)";
		self SetScriptGoal( origin, 32 );
		
		self thread bot_get_obj(flag);
	
		self waittill_any( "goal", "bad_path" );
	}
	wait 1;
	
	self.bot_lock_goal = false;
	self ClearScriptGoal();
}

bot_hq()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "koth" )
		return;

	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		if(!isDefined(level.radio))
			continue;
		
		if(!isDefined(level.radio.gameobject))
			continue;
		
		radio = level.radio;
		gameobj = radio.gameobject;
		origin = ( radio.origin[0], radio.origin[1], radio.origin[2]+5 );
		
		//if neut or enemy
		if(gameobj.ownerTeam != myTeam)
		{
			if(gameobj.interactTeam == "none")//wait for it to become active
			{
				if(self HasScriptGoal())
					continue;
			
				if(DistanceSquared(origin, self.origin) <= 1024*1024)
					continue;
				
				self.did = "bot_hq(wait)";
				self SetScriptGoal( origin, 256 );
				
				if(DistanceSquared(origin, self.origin) > 256*256)
				{
					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				continue;
			}
			
			//capture it
			
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			if(!self isTouching(gameobj.trigger) && level.radio == radio)
			{
				self.did = "bot_hq(cap)";
				self SetScriptGoal( origin, 64 );
				
				self thread bot_hq_go_cap(gameobj, radio);
			
				event = self waittill_any_return( "goal", "bad_path" );

				self ClearScriptGoal();
				
				if (event == "bad_path")
				{
					self.bot_lock_goal = false;
					continue;
				}
			}
			
			if(!self isTouching(gameobj.trigger) || level.radio != radio)
			{
				self.bot_lock_goal = false;
				continue;
			}
			
			self.did = "bot_hq(cap)(2)";
			self SetScriptGoal( self.origin, 64 );
			
			while(self isTouching(gameobj.trigger) && gameobj.ownerTeam != myTeam && level.radio == radio)
			{
				cur = gameobj.curProgress;
				wait 0.5;
				
				if(cur == gameobj.curProgress)
					break;//no prog made, enemy must be capping
			}
			
			self ClearScriptGoal();
			self.bot_lock_goal = false;
		}
		else//we own it
		{
			if(gameobj.objPoints[myteam].isFlashing)//underattack
			{
				self.bot_lock_goal = true;
			
				self notify("bot_check_unreachable");
				self notify("bad_path");
				
				wait 0.05;
				self.did = "bot_hq(kill_cap)";
				self SetScriptGoal( origin, 64 );
				
				self thread bot_hq_watch_flashing(gameobj, radio);
				
				self waittill_any( "goal", "bad_path" );
				
				self ClearScriptGoal();
				self.bot_lock_goal = false;
				continue;
			}
			
			if(self HasScriptGoal())
				continue;
		
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.did = "bot_hq(wait_capped)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
		}
	}
}

bot_hq_go_cap(obj, radio)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(!self isTouching(obj.trigger) && level.radio == radio)
		wait randomintrange(2,4);
	
	if(level.radio != radio)
		self notify("bad_path");
	else
		self notify("goal");
}

bot_hq_watch_flashing(obj, radio)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	myteam = self.team;
	
	while(isDefined(obj) && obj.objPoints[myteam].isFlashing && level.radio == radio)
		wait 0.5;
	
	self notify("bad_path");
}

bot_sab()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "sab" )
		return;

	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		if(!isDefined(level.sabBomb))
			continue;
		
		if(!isDefined(level.bombZones) || !level.bombZones.size)
			continue;
		
		bomb = level.sabBomb;
		bombteam = bomb.ownerTeam;
		carrier = bomb.carrier;
		timeleft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining()/1000;
		
		if(bombteam == myTeam)
		{
			site = level.bombZones[otherTeam];
			origin = ( site.curorigin[0]+50, site.curorigin[1]+50, site.curorigin[2]+32 );
			
			if(level.bombPlanted)
			{
				if(isDefined(site.inUse) && site.inUse)//somebody is defusing
				{
					self.bot_lock_goal = true;
					
					self notify("bot_check_unreachable");
					self notify("bad_path");
					
					wait 0.05;
					self.did = "bot_sab(defend_plant)";
					self SetScriptGoal( origin, 64 );
					
					if(DistanceSquared(origin, self.origin) > 64*64)
					{
						self thread bot_defend_site(site);

						self waittill_any( "goal", "bad_path" );
					}
					
					self ClearScriptGoal();
					
					self.bot_lock_goal = false;
					continue;
				}
			
				//else hang around the site
				
				if(DistanceSquared(origin, self.origin) <= 1024*1024)
					continue;
				
				self.bot_lock_goal = true;
				
				self notify("bot_check_unreachable");
				self notify("bad_path");
				
				wait 0.05;
				self.did = "bot_sab(defend)";
				self SetScriptGoal( origin, 256 );
				
				if(DistanceSquared(origin, self.origin) > 256*256)
				{
					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				
				self.bot_lock_goal = false;
				continue;
			}
			
			if(!isDefined(self.isBombCarrier) || !self.isBombCarrier)
			{
				//escort bomb
				if(self HasScriptGoal())
					continue;
				
				origin = carrier.origin;
				
				if(DistanceSquared(origin, self.origin) <= 1024*1024)
					continue;
				
				self.did = "bot_sab(escort_bomb)";
				self SetScriptGoal( origin, 256 );
				
				if(DistanceSquared(origin, self.origin) > 256*256)
				{
					self thread bot_escort_obj(bomb, carrier);

					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				continue;
			}
		
			timepassed = maps\mp\gametypes\_globallogic_utils::getTimePassed()/1000;
			
			if(timepassed < 120 && timeleft >= 90 && randomInt(100) < 98)
				continue;
		
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			if(!self isTouching(site.trigger))
			{
				self.did = "bot_sab(go_plant)";
				self SetScriptGoal( origin, 64 );
				
				self thread bot_go_plant(site);
			
				event = self waittill_any_return( "goal", "bad_path" );

				self ClearScriptGoal();
				
				if (event == "bad_path")
				{
					self.bot_lock_goal = false;
					continue;
				}
			}
			
			if(level.bombPlanted || !self isTouching(site.trigger) || (isDefined(self.laststand) && self.laststand))
			{
				self.bot_lock_goal = false;
				continue;
			}
			
			self.did = "bot_sab(go_plant)(2)";
			self SetScriptGoal( self.origin, 64 );
			
			self bot_use_bomb_thread(site);
			wait 1;
			
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
		}
		else if(bombteam == otherTeam)
		{
			site = level.bombZones[myteam];
			
			if(!isDefined(site.bots))
				site.bots = 0;
			
			if(!level.bombPlanted)
			{
				//kill bomb carrier
				if(site.bots > 2)
				{
					if(self HasScriptGoal())
						continue;
					
					if(carrier hasPerk( "specialty_gpsjammer" ))
						continue;
					
					origin = carrier.origin;
					
					self.did = "bot_sab(kill_bomb)";
					self SetScriptGoal( origin, 64 );
					
					if(DistanceSquared(origin, self.origin) > 64*64)
					{
						self thread bot_escort_obj(bomb, carrier);

						self waittill_any( "goal", "bad_path" );
					}
					
					self ClearScriptGoal();
					continue;
				}
				
				//protect bomb site
				
				origin = ( site.curorigin[0]+50, site.curorigin[1]+50, site.curorigin[2]+32 );
				
				self thread bot_inc_bots(site);
			
				if(isDefined(site.inUse) && site.inUse)//somebody is planting
				{
					self.bot_lock_goal = true;
					
					self notify("bot_check_unreachable");
					self notify("bad_path");
					
					wait 0.05;
					self.did = "bot_sab(defend_site)";
					self SetScriptGoal( origin, 64 );
					
					if(DistanceSquared(origin, self.origin) > 64*64)
					{
						self thread bot_defend_site(site);

						self waittill_any( "goal", "bad_path" );
					}
					
					self ClearScriptGoal();
					self notify("bot_inc_bots");
					self.bot_lock_goal = false;
					continue;
				}
				
				//else hang around the site
				
				if(DistanceSquared(origin, self.origin) <= 1024*1024)
				{
					wait 4;
					self notify("bot_inc_bots");
					continue;
				}
				
				self.bot_lock_goal = true;
				
				self notify("bot_check_unreachable");
				self notify("bad_path");
				
				wait 0.05;
				self.did = "bot_sab(defend_around_site)";
				self SetScriptGoal( origin, 256 );
				
				if(DistanceSquared(origin, self.origin) > 256*256)
				{
					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				self notify("bot_inc_bots");
				self.bot_lock_goal = false;
				continue;
			}
			
			origin = ( site.curorigin[0]+50, site.curorigin[1]+50, site.curorigin[2]+32 );
			
			if(site.bots > 1)
			{
				if(self HasScriptGoal())
					continue;
			
				if(DistanceSquared(origin, self.origin) <= 1024*1024)
					continue;
				
				self.did = "bot_sab(hang_plant)";
				self SetScriptGoal( origin, 256 );
				
				if(DistanceSquared(origin, self.origin) > 256*256)
				{
					self thread bot_go_defuse(site);

					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				continue;
			}
			
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			self thread bot_inc_bots(site);
			
			wait 0.05;
			if(!self isTouching(site.trigger))
			{
				self.did = "bot_sab(defuse)";
				self SetScriptGoal( origin, 64 );
				
				self thread bot_go_defuse(site);
			
				event = self waittill_any_return( "goal", "bad_path" );

				self ClearScriptGoal();
				
				if (event == "bad_path")
				{
					self.bot_lock_goal = false;
					self notify("bot_inc_bots");
					continue;
				}
			}
			
			if(!level.bombPlanted || (isDefined(site.inUse) && site.inUse) || !self isTouching(site.trigger) || (isDefined(self.laststand) && self.laststand))
			{
				self.bot_lock_goal = false;
				self notify("bot_inc_bots");
				continue;
			}
			
			self.did = "bot_sab(defuse)(2)";
			self SetScriptGoal( self.origin, 64 );
			
			self bot_use_bomb_thread(site);
			wait 1;
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
		}
		else
		{
			origin = ( bomb.curorigin[0], bomb.curorigin[1], bomb.curorigin[2]+32 );
			
			self.bot_lock_goal = true;
		
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			self.did = "bot_sab(bomb_get)";
			self SetScriptGoal( origin, 64 );
			
			if(!self isTouching(bomb.trigger))
			{
				self thread bot_get_obj(bomb);
			
				self waittill_any( "goal", "bad_path" );
			}
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			continue;
		}
	}
}

bot_sd_defenders()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "sd" )
		return;

	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );
	
	if(myTeam == game["attackers"])
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		if(!level.bombPlanted)
		{
			timeleft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining()/1000;
			
			if(timeleft >= 90)
				continue;
			
			if(!level.multiBomb && isDefined(level.sdBomb))
			{
				bomb = level.sdBomb;
				carrier = level.sdBomb.carrier;
				
				if(!isDefined(carrier))
				{
					origin = ( bomb.curorigin[0], bomb.curorigin[1], bomb.curorigin[2]+32 );
					
					//hang around the bomb
					if(self HasScriptGoal())
						continue;
				
					if(DistanceSquared(origin, self.origin) <= 1024*1024)
						continue;
					
					self.did = "bot_sd_defenders(bomb_hang)";
					self SetScriptGoal( origin, 256 );
					
					if(DistanceSquared(origin, self.origin) > 256*256)
					{
						self thread bot_get_obj(bomb);

						self waittill_any( "goal", "bad_path" );
					}
					
					self ClearScriptGoal();
					continue;
				}
			}
			
			if(!isDefined(level.bombZones) || !level.bombZones.size)
				continue;
			
			sites = [];
			for(i = 0; i < level.bombZones.size; i++)
			{
				sites[sites.size] = level.bombZones[i];
			}
			
			if(!sites.size)
				continue;
			
			site = self bot_array_nearest_curorigin(sites);
			
			if(!isDefined(site))
				continue;
			
			origin = ( site.curorigin[0]+50, site.curorigin[1]+50, site.curorigin[2]+32 );
			
			if(isDefined(site.inUse) && site.inUse)//somebody is planting
			{
				self.bot_lock_goal = true;
				
				self notify("bot_check_unreachable");
				self notify("bad_path");
				
				wait 0.05;
				self.did = "bot_sd_defenders(defend_site)";
				self SetScriptGoal( origin, 64 );
				
				if(DistanceSquared(origin, self.origin) > 64*64)
				{
					self thread bot_defend_site(site);

					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				
				self.bot_lock_goal = false;
				continue;
			}
			
			//else hang around the site
			
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			self.did = "bot_sd_defenders(defend)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			continue;
		}
		
		if(!isDefined(level.defuseObject))
			continue;
		
		defuse = level.defuseObject;
		
		if(!isDefined(defuse.bots))
			defuse.bots = 0;
		
		origin = ( defuse.curorigin[0], defuse.curorigin[1], defuse.curorigin[2]+32 );
		
		if(defuse.bots > 1)
		{
			if(self HasScriptGoal())
				continue;
		
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.did = "bot_sd_defenders(hang)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self thread bot_go_defuse(defuse);

				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			continue;
		}
		
		self.bot_lock_goal = true;
		
		self notify("bot_check_unreachable");
		self notify("bad_path");
		
		self thread bot_inc_bots(defuse);
		
		wait 0.05;
		if(!self isTouching(defuse.trigger))
		{
			self.did = "bot_sd_defenders";
			self SetScriptGoal( origin, 64 );
			
			self thread bot_go_defuse(defuse);
		
			event = self waittill_any_return( "goal", "bad_path" );

			self ClearScriptGoal();
			
			if (event == "bad_path")
			{
				self.bot_lock_goal = false;
				self notify("bot_inc_bots");
				continue;
			}
		}
		
		if(!level.bombPlanted || (isDefined(defuse.inUse) && defuse.inUse) || !self isTouching(defuse.trigger) || (isDefined(self.laststand) && self.laststand))
		{
			self.bot_lock_goal = false;
			self notify("bot_inc_bots");
			continue;
		}
		
		self.did = "bot_sd_defenders(2)";
		self SetScriptGoal( self.origin, 64 );
		
		self bot_use_bomb_thread(defuse);
		wait 1;
		self ClearScriptGoal();
		self notify("bot_inc_bots");
		self.bot_lock_goal = false;
	}
}

bot_sd_attackers()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "sd" )
		return;

	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );
	
	if(myTeam != game["attackers"])
		return;
	
	first = true;

	for ( ;; )
	{
		if(first)
			first = false;
		else
			wait( randomintrange( 3, 5 ) );
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		//bomb planted
		if(level.bombPlanted)
		{
			if(!isDefined(level.defuseObject))
				continue;
			
			site = level.defuseObject;
			
			origin = ( site.curorigin[0], site.curorigin[1], site.curorigin[2]+32 );
			
			if(isDefined(site.inUse) && site.inUse)//somebody is defusing
			{
				self.bot_lock_goal = true;
				
				self notify("bot_check_unreachable");
				self notify("bad_path");
				
				wait 0.05;
				self.did = "bot_sd_attackers(defend_plant)";
				self SetScriptGoal( origin, 64 );
				
				if(DistanceSquared(origin, self.origin) > 64*64)
				{
					self thread bot_defend_site(site);

					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				
				self.bot_lock_goal = false;
				continue;
			}
			
			//else hang around the site
			
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			self.did = "bot_sd_attackers(defend)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			continue;
		}
		
		timeleft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining()/1000;
		timepassed = maps\mp\gametypes\_globallogic_utils::getTimePassed()/1000;
		
		//dont have a bomb
		if((!isDefined(self.isBombCarrier) || !self.isBombCarrier) && !level.multiBomb)
		{
			if(!isDefined(level.sdBomb))
				continue;
			
			bomb = level.sdBomb;
			carrier = level.sdBomb.carrier;
			
			//bomb is picked up
			if(isDefined(carrier))
			{
				//escort the bomb carrier
				if(self HasScriptGoal())
					continue;
				
				origin = carrier.origin;
				
				if(DistanceSquared(origin, self.origin) <= 1024*1024)
					continue;
				
				self.did = "bot_sd_attackers(escort_bomb)";
				self SetScriptGoal( origin, 256 );
				
				if(DistanceSquared(origin, self.origin) > 256*256)
				{
					self thread bot_escort_obj(bomb, carrier);

					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				continue;
			}
			
			if(!isDefined(bomb.bots))
				bomb.bots = 0;
			
			origin = ( bomb.curorigin[0], bomb.curorigin[1], bomb.curorigin[2]+32 );
			
			//hang around the bomb if other is going to go get it
			if(bomb.bots > 1)
			{
				if(self HasScriptGoal())
					continue;
			
				if(DistanceSquared(origin, self.origin) <= 1024*1024)
					continue;
				
				self.did = "bot_sd_attackers(bomb_hang)";
				self SetScriptGoal( origin, 256 );
				
				if(DistanceSquared(origin, self.origin) > 256*256)
				{
					self thread bot_get_obj(bomb);

					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				continue;
			}
			
			self.bot_lock_goal = true;
		
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			self thread bot_inc_bots(bomb);
			
			wait 0.05;
			self.did = "bot_sd_attackers(bomb_get)";
			self SetScriptGoal( origin, 64 );
			
			if(!self isTouching(bomb.trigger))
			{
				self thread bot_get_obj(bomb);
			
				self waittill_any( "goal", "bad_path" );
			}
			
			self notify("bot_inc_bots");
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			continue;
		}
		
		if(timepassed < 120 && timeleft >= 90 && randomInt(100) < 98)
			continue;
		
		if(!isDefined(level.bombZones) || !level.bombZones.size)
			continue;
		
		sites = [];
		for(i = 0; i < level.bombZones.size; i++)
		{
			sites[sites.size] = level.bombZones[i];
		}
		
		if(!sites.size)
			continue;
		
		if(randomint(2))
			plant = self bot_array_nearest_curorigin(sites);
		else
			plant = random(sites);
		
		if(!isDefined(plant))
			continue;
		
		origin = ( plant.curorigin[0]+50, plant.curorigin[1]+50, plant.curorigin[2]+32 );
		
		self.bot_lock_goal = true;
		
		self notify("bot_check_unreachable");
		self notify("bad_path");
		
		wait 0.05;
		if(!self isTouching(plant.trigger))
		{
			self.did = "bot_sd_attackers";
			self SetScriptGoal( origin, 64 );
			
			self thread bot_go_plant(plant);
		
			event = self waittill_any_return( "goal", "bad_path" );

			self ClearScriptGoal();
			
			if (event == "bad_path")
			{
				self.bot_lock_goal = false;
				continue;
			}
		}
		
		if(level.bombPlanted || plant.visibleTeam == "none" || !self isTouching(plant.trigger) || (isDefined(self.laststand) && self.laststand))
		{
			self.bot_lock_goal = false;
			continue;
		}
		
		self.did = "bot_sd_attackers(2)";
		self SetScriptGoal( self.origin, 64 );
		
		self bot_use_bomb_thread(plant);
		wait 1;
		
		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
	}
}

bot_dem_attackers()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "dem" )
		return;

	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );
	
	if(myTeam != game["attackers"])
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		if(!isDefined(level.bombZones) || !level.bombZones.size)
			continue;
		
		bombs = [];//sites with bombs
		sites = [];//sites to bomb at
		bombed = 0;//exploded sites
		for ( i = 0; i < level.bombZones.size; i++ )
		{
			bomb = level.bombZones[i];
			
			if(isDefined(bomb.bombExploded) && bomb.bombExploded)
			{
				bombed++;
				continue;
			}
			
			if(bomb.label == "_a")
			{
				if(level.bombAPlanted)
					bombs[bombs.size] = bomb;
				else
					sites[sites.size] = bomb;
				
				continue;
			}
			
			if(bomb.label == "_b")
			{
				if(level.bombBPlanted)
					bombs[bombs.size] = bomb;
				else
					sites[sites.size] = bomb;
				
				continue;
			}
		}
		timeleft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining()/1000;
		
		shouldLet = (game["teamScores"][myteam] > game["teamScores"][otherTeam] && timeleft < 90 && bombed == 1);
		//spawnkill conditions
		//if we have bombed one site or 1 bomb is planted with lots of time left, spawn kill
		//if we want the other team to win for overtime and they do not need to defuse, spawn kill
		if(((bombed + bombs.size == 1 && timeleft >= 90) || (shouldLet && !bombs.size)) && randomInt(100) < 95)
		{
			if(self HasScriptGoal())
				continue;
			
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dem_spawn_defender_start" );
			
			if(!spawnPoints.size)
				continue;
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			
			if(DistanceSquared(spawnpoint.origin, self.origin) <= 2048*2048)
				continue;
			
			self.did = "bot_dem_attackers(spawnkill)";
			self SetScriptGoal( spawnpoint.origin, 1024 );
			
			if(DistanceSquared(spawnpoint.origin, self.origin) > 1024*1024)
			{
				self thread bot_dem_attack_spawnkill();

				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			continue;
		}
		
		//let defuse conditions
		//if enemy is going to lose and lots of time left, let them defuse to play longer
		//or if want to go into overtime near end of the extended game
		if(((bombs.size + bombed == 2 && timeleft >= 90) || (shouldLet && bombs.size)) && randomInt(100) < 95)
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dem_spawn_attacker_start" );
			
			if(!spawnPoints.size)
				continue;
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			
			if(DistanceSquared(spawnpoint.origin, self.origin) <= 1024*1024)
				continue;
			
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			self.did = "bot_dem_attackers(let)";
			self SetScriptGoal( spawnpoint.origin, 512 );
			
			if(DistanceSquared(spawnpoint.origin, self.origin) > 512*512)
			{
				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			continue;
		}
		
		//defend bomb conditions
		//if time is running out and we have a bomb planted
		if(bombs.size && timeleft < 90 && (!sites.size || randomInt(100) < 95))
		{
			site = self bot_array_nearest_curorigin(bombs);
			origin = ( site.curorigin[0]+50, site.curorigin[1]+50, site.curorigin[2]+32 );
			
			if(isDefined(site.inUse) && site.inUse)//somebody is defusing
			{
				self.bot_lock_goal = true;
				
				self notify("bot_check_unreachable");
				self notify("bad_path");
				
				wait 0.05;
				self.did = "bot_dem_attackers(defend_plant)";
				self SetScriptGoal( origin, 64 );
				
				if(DistanceSquared(origin, self.origin) > 64*64)
				{
					self thread bot_defend_site(site);

					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				
				self.bot_lock_goal = false;
				continue;
			}
			
			//else hang around the site
			
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			self.did = "bot_dem_attackers(defend)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			continue;
		}
		
		//else go plant
		
		if(!sites.size)
			continue;
		
		plant = self bot_array_nearest_curorigin(sites);
		
		if(!isDefined(plant))
			continue;
		
		if(!isDefined(plant.bots))
			plant.bots = 0;
		
		origin = ( plant.curorigin[0]+50, plant.curorigin[1]+50, plant.curorigin[2]+32 );
		
		//hang around the site if lots of time left
		if(plant.bots > 1 && timeleft >= 60)
		{
			if(self HasScriptGoal())
				continue;
			
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.did = "bot_dem_attackers(hang)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self thread bot_dem_go_plant(plant);

				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			continue;
		}
		
		self.bot_lock_goal = true;
		
		self notify("bot_check_unreachable");
		self notify("bad_path");
		
		self thread bot_inc_bots(plant);
		
		wait 0.05;
		if(!self isTouching(plant.trigger))
		{
			self.did = "bot_dem_attackers";
			self SetScriptGoal( origin, 64 );
			
			self thread bot_dem_go_plant(plant);
		
			event = self waittill_any_return( "goal", "bad_path" );

			self ClearScriptGoal();
			
			if (event == "bad_path")
			{
				self.bot_lock_goal = false;
				self notify("bot_inc_bots");
				continue;
			}
		}
		
		if((plant.label == "_b" && level.bombBPlanted) || (plant.label == "_a" && level.bombAPlanted) || (isDefined(plant.inUse) && plant.inUse) || !self isTouching(plant.trigger) || (isDefined(self.laststand) && self.laststand))
		{
			self.bot_lock_goal = false;
			self notify("bot_inc_bots");
			continue;
		}
		
		self.did = "bot_dem_attackers(2)";
		self SetScriptGoal( self.origin, 64 );
		
		self bot_use_bomb_thread(plant);
		wait 1;
		
		self notify("bot_inc_bots");
		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
	}
}

bot_dem_go_plant(plant)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(((plant.label == "_b" && !level.bombBPlanted) || (plant.label == "_a" && !level.bombAPlanted)) && !self isTouching(plant.trigger))
		wait 0.5;
	
	if((plant.label == "_b" && level.bombBPlanted) || (plant.label == "_a" && level.bombAPlanted))
		self notify("bad_path");
	else
		self notify("goal");
}

bot_dem_attack_spawnkill()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	l1 = level.bombAPlanted;
	l2 = level.bombBPlanted;
	
	while(l1 == level.bombAPlanted || l2 == level.bombBPlanted)
		wait 0.5;
	
	self notify("bad_path");
}

bot_dem_defenders()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "dem" )
		return;

	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );
	
	if(myTeam == game["attackers"])
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
		if(!isDefined(level.bombZones) || !level.bombZones.size)
			continue;
		
		bombs = [];//sites with bombs
		sites = [];//sites to bomb at
		bombed = 0;//exploded sites
		for ( i = 0; i < level.bombZones.size; i++ )
		{
			bomb = level.bombZones[i];
			
			if(isDefined(bomb.bombExploded) && bomb.bombExploded)
			{
				bombed++;
				continue;
			}
			
			if(bomb.label == "_a")
			{
				if(level.bombAPlanted)
					bombs[bombs.size] = bomb;
				else
					sites[sites.size] = bomb;
				
				continue;
			}
			
			if(bomb.label == "_b")
			{
				if(level.bombBPlanted)
					bombs[bombs.size] = bomb;
				else
					sites[sites.size] = bomb;
				
				continue;
			}
		}
		timeleft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining()/1000;
		
		shouldLet = (timeleft < 60 && ((bombed == 0 && bombs.size != 2) || (game["teamScores"][myteam] > game["teamScores"][otherTeam] && bombed == 1)) && randomInt(100) < 98);
		
		//spawnkill conditions
		//if nothing to defuse with a lot of time left, spawn kill
		//or letting a bomb site to explode but a bomb is planted, so spawnkill
		if((!bombs.size && timeleft >= 60 && randomInt(100) < 95) || (shouldLet && bombs.size == 1))
		{
			if(self HasScriptGoal())
				continue;
			
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dem_spawn_attacker_start" );
			
			if(!spawnPoints.size)
				continue;
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			
			if(DistanceSquared(spawnpoint.origin, self.origin) <= 2048*2048)
				continue;
			
			self.did = "bot_dem_defenders(spawnkill)";
			self SetScriptGoal( spawnpoint.origin, 1024 );
			
			if(DistanceSquared(spawnpoint.origin, self.origin) > 1024*1024)
			{
				self thread bot_dem_defend_spawnkill();

				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			continue;
		}
		
		//let blow up conditions
		//let enemy blow up at least one to extend play time
		//or if want to go into overtime after extended game
		if(shouldLet)
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dem_spawn_defender_start" );
			
			if(!spawnPoints.size)
				continue;
			
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
			
			if(DistanceSquared(spawnpoint.origin, self.origin) <= 1024*1024)
				continue;
			
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			self.did = "bot_dem_defenders(let)";
			self SetScriptGoal( spawnpoint.origin, 512 );
			
			if(DistanceSquared(spawnpoint.origin, self.origin) > 512*512)
			{
				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			continue;
		}
		
		//defend conditions
		//if no bombs planted with little time left
		if(!bombs.size && timeleft < 60 && randomInt(100) < 95 && sites.size)
		{
			site = self bot_array_nearest_curorigin(sites);
			origin = ( site.curorigin[0]+50, site.curorigin[1]+50, site.curorigin[2]+32 );
			
			if(isDefined(site.inUse) && site.inUse)//somebody is planting
			{
				self.bot_lock_goal = true;
				
				self notify("bot_check_unreachable");
				self notify("bad_path");
				
				wait 0.05;
				self.did = "bot_dem_defenders(defend_plant)";
				self SetScriptGoal( origin, 64 );
				
				if(DistanceSquared(origin, self.origin) > 64*64)
				{
					self thread bot_defend_site(site);

					self waittill_any( "goal", "bad_path" );
				}
				
				self ClearScriptGoal();
				
				self.bot_lock_goal = false;
				continue;
			}
			
			//else hang around the site
			
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.bot_lock_goal = true;
			
			self notify("bot_check_unreachable");
			self notify("bad_path");
			
			wait 0.05;
			self.did = "bot_dem_defenders(defend)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			
			self.bot_lock_goal = false;
			continue;
		}
		
		//else go defuse
		
		if(!bombs.size)
			continue;
		
		defuse = self bot_array_nearest_curorigin(bombs);
		
		if(!isDefined(defuse))
			continue;
		
		if(!isDefined(defuse.bots))
			defuse.bots = 0;
		
		origin = ( defuse.curorigin[0]+50, defuse.curorigin[1]+50, defuse.curorigin[2]+32 );
		
		//hang around the site if not in danger of losing
		if(defuse.bots > 1 && bombed + bombs.size != 2)
		{
			if(self HasScriptGoal())
				continue;
			
			if(DistanceSquared(origin, self.origin) <= 1024*1024)
				continue;
			
			self.did = "bot_dem_defenders(hang)";
			self SetScriptGoal( origin, 256 );
			
			if(DistanceSquared(origin, self.origin) > 256*256)
			{
				self thread bot_dem_go_defuse(defuse);

				self waittill_any( "goal", "bad_path" );
			}
			
			self ClearScriptGoal();
			continue;
		}
		
		self.bot_lock_goal = true;
		
		self notify("bot_check_unreachable");
		self notify("bad_path");//force play obj
		
		self thread bot_inc_bots(defuse);
		
		wait 0.05;
		
		if(!self isTouching(defuse.trigger))
		{
			self.did = "bot_dem_defenders";
			self SetScriptGoal( origin, 64 );
			
			self thread bot_dem_go_defuse(defuse);
		
			event = self waittill_any_return( "goal", "bad_path" );
			
			self ClearScriptGoal();

			if (event == "bad_path")
			{
				self.bot_lock_goal = false;
				self notify("bot_inc_bots");
				continue;
			}
		}
		
		if((defuse.label == "_b" && !level.bombBPlanted) || (defuse.label == "_a" && !level.bombAPlanted) || (isDefined(defuse.inUse) && defuse.inUse) || !self isTouching(defuse.trigger) || (isDefined(self.laststand) && self.laststand))
		{
			self.bot_lock_goal = false;
			self notify("bot_inc_bots");
			continue;
		}
		
		self.did = "bot_dem_defenders(2)";
		self SetScriptGoal( self.origin, 64 );
		
		self bot_use_bomb_thread(defuse);
		wait 1;
		
		self notify("bot_inc_bots");
		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
	}
}

bot_dem_go_defuse(defuse)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(((defuse.label == "_b" && level.bombBPlanted) || (defuse.label == "_a" && level.bombAPlanted)) && !self isTouching(defuse.trigger))
		wait 0.5;
	
	if((defuse.label == "_b" && !level.bombBPlanted) || (defuse.label == "_a" && !level.bombAPlanted))
		self notify("bad_path");
	else
		self notify("goal");
}

bot_dem_defend_spawnkill()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(!level.bombBPlanted && !level.bombAPlanted)
		wait 0.5;
	
	self notify("bad_path");
}

bot_defend_site(site)
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	self endon( "goal" );
	self endon( "bad_path" );
	
	while(isDefined(site.inUse) && site.inUse)
		wait 0.5;
	
	self notify("bad_path");
}

bot_dom_spawn_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];		
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 10, 20 ) );
		
		if ( randomint( 100 ) < 20 )
			continue;
		
		if ( self HasScriptGoal() )
			continue;
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
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

		self.did = "bot_dom_spawn_kill_think";
		self SetScriptGoal( flag.origin, 1024 );
		
		self thread bot_dom_watch_flags(myFlagCount, myTeam);

		self waittill_any( "goal", "bad_path" );
		
		self ClearScriptGoal();
	}
}

bot_dom_watch_flags(count, myTeam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	level endon("game_ended");
	
	while(maps\mp\gametypes\dom::getTeamFlagCount( myTeam ) == count)
		wait 0.5;
	
	self notify("bad_path");
}

bot_dom_def_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");

	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];

	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );
		
		if ( randomint( 100 ) < 35 )
			continue;
		
		if ( self HasScriptGoal() )
			continue;
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
		{
			continue;
		}
		
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

		self.did = "bot_dom_def_think";
		self SetScriptGoal( flag.origin, 128 );
		
		if(DistanceSquared(flag.origin, self.origin) > 128*128)
		{
			self thread bot_dom_watch_for_flashing(flag, myTeam);

			self waittill_any( "goal", "bad_path" );
		}
		
		self ClearScriptGoal();
	}
}

bot_dom_watch_for_flashing(flag, myTeam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	level endon("game_ended");
	
	while(flag maps\mp\gametypes\dom::getFlagTeam() == myTeam && flag.useObj.objPoints[myTeam].isFlashing)
		wait 0.5;
	
	self notify("bad_path");
}
 
bot_dom_cap_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	
	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];		
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 3, 12 ) );
		
		if ( self IsRemoteControlling() || self.bot_lock_goal )
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
		for ( i = 0; i < level.flags.size; i++ )
		{
			if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() == myTeam )
				continue;

			if ( !isDefined(flag) || DistanceSquared(self.origin,level.flags[i].origin) < DistanceSquared(self.origin,flag.origin) )
				flag = level.flags[i];
		}

		if ( !isDefined(flag) )
			continue;
		
		self.bot_lock_goal = true;
		
		self notify("bot_check_unreachable");
		self notify("bad_path");//force play obj

		wait 0.05;//bad_path can call ClearScriptGoal
		self.did = "bot_dom_cap_think";
		self SetScriptGoal( flag.origin, 64 );
		
		if(!self isTouching(flag))
		{
			self thread bot_dom_go_cap_flag(flag, myteam);
		
			event = self waittill_any_return( "goal", "bad_path" );
			
			self ClearScriptGoal();

			if (event == "bad_path")
			{
				self.bot_lock_goal = false;
				continue;
			}
		}
		
		self.did = "bot_dom_cap_think(2)";
		self SetScriptGoal( self.origin, 64 );

		while ( flag maps\mp\gametypes\dom::getFlagTeam() != myTeam && self isTouching(flag) )
			wait 0.5;

		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
	}
}

bot_dom_go_cap_flag(flag, myteam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	level endon("game_ended");
	
	while(flag maps\mp\gametypes\dom::getFlagTeam() != myTeam && !self isTouching(flag))
		wait 0.5;
	
	if(flag maps\mp\gametypes\dom::getFlagTeam() == myTeam)
		self notify("bad_path");
	else
		self notify("goal");
}
