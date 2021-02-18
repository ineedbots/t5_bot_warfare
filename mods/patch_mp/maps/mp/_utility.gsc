#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

triggerOff()
{
	if (!isdefined (self.realOrigin))
	{
		self.realOrigin = self.origin;
	}

	if (self.origin == self.realorigin)
	{
		self.origin += (0, 0, -10000);
	}
}

triggerOn()
{
	if (isDefined (self.realOrigin) )
	{
		self.origin = self.realOrigin;
	}
}

error(msg)
{
	println("^c*ERROR* ", msg);
	wait .05;	// waitframe
/#
	if (GetDvar( #"debug") != "1")
		assertmsg("This is a forced error - attach the log file");
#/
}

warning( msg )
{
	println( "^1WARNING: " + msg );
}

/* 
 ============= 
///ScriptDocBegin
"Name: spawn_array_struct()"
"Summary: Creates a struct with an attribute named "a" which is an empty array.  Array structs are useful for passing around arrays by reference."
"Module: Array"
"CallOn: "
"Example: fxemitters = spawn_struct_array(); fxemitters.a[ fxemitters.size ] = new_emitter;"
"SPMP: both"
///ScriptDocEnd
 ============= 
 */ 
spawn_array_struct()
{
	s= SpawnStruct();
	s.a= [];
	return s;
}

/* 
============= 
///ScriptDocBegin
"Name: within_fov( <start_origin> , <start_angles> , <end_origin> , <fov> )"
"Summary: Returns true if < end_origin > is within the players field of view, otherwise returns false."
"Module: Vector"
"CallOn: "
"MandatoryArg: <start_origin> : starting origin for FOV check( usually the players origin )"
"MandatoryArg: <start_angles> : angles to specify facing direction( usually the players angles )"
"MandatoryArg: <end_origin> : origin to check if it's in the FOV"
"MandatoryArg: <fov> : cosine of the FOV angle to use"
"Example: qBool = within_fov( level.player.origin, level.player.angles, target1.origin, cos( 45 ) );"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/ 
within_fov( start_origin, start_angles, end_origin, fov )
{
	normal = VectorNormalize( end_origin - start_origin ); 
	forward = AnglesToForward( start_angles ); 
	dot = VectorDot( forward, normal ); 

	return dot >= fov; 
}

 /* 
 ============= 
///ScriptDocBegin
"Name: append_array_struct( <dst>, <src> )"
"Summary: Append the array elements in the <src> (2nd) array struct parameter to the array in the <dst> (1st) array struct parameter."
"Module: Array"
"CallOn: "
"MandatoryArg: <dst> : Destination - Elements from <src>.a[] are appended to <dst>.a[]"
"MandatoryArg: <src> : Source - Elements from <src>.a[] are appended to <dst>.a[]"
"Example: players = spawn_array_struct(); worst_enemies = built_worst_enemies(); append_array_struct( players, worst_enemies ;"
"SPMP: both"
///ScriptDocEnd
 ============= 
 */ 
append_array_struct(
	dst_s,         ///< struct.a[]
	src_s )        ///< struct.a[]
{
	for ( i= 0; i < src_s.a.size; i++ )
	{
		dst_s.a[ dst_s.a.size ]= src_s.a[ i ];
	}
}

exploder( num )
{
	[[ level.exploderFunction ]]( num );
}

exploder_stop( num )
{
	stop_exploder( num );
}

exploder_sound()
{
	if(isdefined(self.script_delay))
	{
		wait self.script_delay;
	}
		
	self playSound(level.scr_sound[self.script_sound]);
}

cannon_effect()
{
	if( isdefined( self.v[ "repeat" ] ) )
	{
		for( i = 0;i < self.v[ "repeat" ];i ++ )
		{
			playfx( level._effect[ self.v[ "fxid" ] ], self.v[ "origin" ], self.v[ "forward" ], self.v[ "up" ] );
			//exploder_playSound();
			self exploder_delay();
		}
		return;
	}

	self exploder_delay();

//	playfx( level._effect[ self.v[ "fxid" ] ], self.v[ "origin" ], self.v[ "forward" ], self.v[ "up" ] );
	if ( isdefined( self.looper ) )
	{
		self.looper delete();
	}
	
	self.looper = spawnFx( getfx( self.v[ "fxid" ] ), self.v[ "origin" ], self.v[ "forward" ], self.v[ "up" ] );
	triggerFx( self.looper );
	exploder_playSound();
}

exploder_delay()
{
	if( !isdefined( self.v[ "delay" ] ) )
	{
		self.v[ "delay" ] = 0;
	}

	min_delay = self.v[ "delay" ];
	max_delay = self.v[ "delay" ] + 0.001;// cant randomfloatrange on the same #
	if( isdefined( self.v[ "delay_min" ] ) )
	{
		min_delay = self.v[ "delay_min" ];
	}

	if( isdefined( self.v[ "delay_max" ] ) )
	{
		max_delay = self.v[ "delay_max" ];
	}

	if( min_delay > 0 )
	{
		wait( randomfloatrange( min_delay, max_delay ) );
	}
}

exploder_playSound()
{
	if( !isdefined( self.v[ "soundalias" ] ) || self.v[ "soundalias" ] == "nil" )
	{
		return;
	}
	
	play_sound_in_space( self.v[ "soundalias" ], self.v[ "origin" ] );
}

brush_delete()
{
	num = self.v[ "exploder" ];
	
	if( isdefined( self.v[ "delay" ] ) )
	{
		wait( self.v[ "delay" ] );
	}
	else
	{
		wait( .05 );// so it disappears after the replacement appears
	}

	if( !isdefined( self.model ) )
	{
		return;
	}


	assert( isdefined( self.model ) );

	if( level.createFX_enabled )
	{
		if( isdefined( self.exploded ) )
		{
			return;
		}
			
		self.exploded = true;
		self.model hide();
		self.model notsolid();
		
		wait( 3 );
		self.exploded = undefined;
		self.model show();
		self.model solid();
		return;
	}

	if( !isdefined( self.v[ "fxid" ] ) || self.v[ "fxid" ] == "No FX" )
	{
		self.v[ "exploder" ] = undefined;
	}
		
	waittillframeend;// so it hides stuff after it shows the new stuff
	self.model delete();
}

brush_show()
{
	if( isdefined( self.v[ "delay" ] ) )
	{
		wait( self.v[ "delay" ] );
	}
	
	assert( isdefined( self.model ) );
	
	self.model show();
	self.model solid();

	if( level.createFX_enabled )
	{
		if( isdefined( self.exploded ) )
		{
			return;
		}

		self.exploded = true;
		wait( 3 );
		self.exploded = undefined;
		self.model hide();
		self.model notsolid();
	}
}

brush_throw()
{
	if( isdefined( self.v[ "delay" ] ) )
	{
		wait( self.v[ "delay" ] );
	}

	ent = undefined;
	
	if( isdefined( self.v[ "target" ] ) )
	{
		ent = getent( self.v[ "target" ], "targetname" );
	}

	if( !isdefined( ent ) )
	{
		self.model delete();
		return;
	}

	self.model show();

	startorg = self.v[ "origin" ];
	startang = self.v[ "angles" ];
	org = ent.origin;


	temp_vec = ( org - self.v[ "origin" ] );
	x = temp_vec[ 0 ];
	y = temp_vec[ 1 ];
	z = temp_vec[ 2 ];

	self.model rotateVelocity( ( x, y, z ), 12 );

	self.model moveGravity( ( x, y, z ), 12 );
	if( level.createFX_enabled )
	{
		if( isdefined( self.exploded ) )
		{
			return;
		}

		self.exploded = true;
		wait( 3 );
		self.exploded = undefined;
		self.v[ "origin" ] = startorg;
		self.v[ "angles" ] = startang;
		self.model hide();
		return;
	}
	
	self.v[ "exploder" ] = undefined;
	wait( 6 );
	self.model delete();
}

getPlant()
{
	start = self.origin + (0, 0, 10);

	range = 11;
	forward = anglesToForward(self.angles);
	forward = vector_scale(forward, range);

	traceorigins[0] = start + forward;
	traceorigins[1] = start;

	trace = bulletTrace(traceorigins[0], (traceorigins[0] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		//println("^6Using traceorigins[0], tracefraction is", trace["fraction"]);
		
		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	trace = bulletTrace(traceorigins[1], (traceorigins[1] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		//println("^6Using traceorigins[1], tracefraction is", trace["fraction"]);

		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	traceorigins[2] = start + (16, 16, 0);
	traceorigins[3] = start + (16, -16, 0);
	traceorigins[4] = start + (-16, -16, 0);
	traceorigins[5] = start + (-16, 16, 0);

	besttracefraction = undefined;
	besttraceposition = undefined;
	for(i = 0; i < traceorigins.size; i++)
	{
		trace = bulletTrace(traceorigins[i], (traceorigins[i] + (0, 0, -1000)), false, undefined);

		//ent[i] = spawn("script_model",(traceorigins[i]+(0, 0, -2)));
		//ent[i].angles = (0, 180, 180);
		//ent[i] setmodel("105");

		//println("^6trace ", i ," fraction is ", trace["fraction"]);

		if(!isdefined(besttracefraction) || (trace["fraction"] < besttracefraction))
		{
			besttracefraction = trace["fraction"];
			besttraceposition = trace["position"];

			//println("^6besttracefraction set to ", besttracefraction, " which is traceorigin[", i, "]");
		}
	}
	
	if(besttracefraction == 1)
		besttraceposition = self.origin;
	
	temp = spawnstruct();
	temp.origin = besttraceposition;
	temp.angles = orientToNormal(trace["normal"]);
	return temp;
}

orientToNormal(normal)
{
	hor_normal = (normal[0], normal[1], 0);
	hor_length = length(hor_normal);

	if(!hor_length)
		return (0, 0, 0);
	
	hor_dir = vectornormalize(hor_normal);
	neg_height = normal[2] * -1;
	tangent = (hor_dir[0] * neg_height, hor_dir[1] * neg_height, hor_length);
	plant_angle = vectortoangles(tangent);

	//println("^6hor_normal is ", hor_normal);
	//println("^6hor_length is ", hor_length);
	//println("^6hor_dir is ", hor_dir);
	//println("^6neg_height is ", neg_height);
	//println("^6tangent is ", tangent);
	//println("^6plant_angle is ", plant_angle);

	return plant_angle;
}

array_levelthread (ents, process, var, excluders)
{
	exclude = [];
	for (i=0;i<ents.size;i++)
		exclude[i] = false;

	if (isdefined (excluders))
	{
		for (i=0;i<ents.size;i++)
		for (p=0;p<excluders.size;p++)
		if (ents[i] == excluders[p])
			exclude[i] = true;
	}

	for (i=0;i<ents.size;i++)
	{
		if (!exclude[i])
		{
			if (isdefined (var))
				level thread [[process]](ents[i], var);
			else
				level thread [[process]](ents[i]);
		}
	}
}


deletePlacedEntity(entity)
{
	entities = getentarray(entity, "classname");
	for(i = 0; i < entities.size; i++)
	{
		//println("DELETED: ", entities[i].classname);
		entities[i] delete();
	}
}

playSoundOnPlayers( sound, team )
{
	assert( isdefined( level.players ) );
	
	if ( level.splitscreen )
	{	
		if ( isdefined( level.players[0] ) )
			level.players[0] playLocalSound(sound);
	}
	else
	{
		if ( isdefined( team ) )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];
				if ( isdefined( player.pers["team"] ) && (player.pers["team"] == team))
					player playLocalSound(sound);
			}
		}
		else
		{
			for ( i = 0; i < level.players.size; i++ )
				level.players[i] playLocalSound(sound);
		}
	}
}


get_player_height()
{
	return 70.0; // inches, see bg_pmove.cpp::playerMins/playerMaxs
}


IsBulletImpactMOD( sMeansOfDeath )
{
	return IsSubStr( sMeansOfDeath, "BULLET" ) || sMeansOfDeath == "MOD_HEAD_SHOT";
}


//entities_s.a[]
get_team_alive_players_s( teamName )
{	
	teamPlayers_s= spawn_array_struct();
	
	if (IsDefined(teamName) &&
		IsDefined( level.alivePlayers ) &&
		IsDefined( level.alivePlayers[ teamName ] ) )
	{
		for ( i= 0; i < level.alivePlayers[ teamName ].size; i++ )
		{
			teamPlayers_s.a[ teamPlayers_s.a.size ]= level.alivePlayers[ teamName ][ i ];
		}
	}
	
	return teamPlayers_s;
}


//entities_s.a[]
get_all_alive_players_s()
{
	allPlayers_s = spawn_array_struct();
	
	if ( IsDefined( level.alivePlayers ) )
	{
		keys = GetArrayKeys( level.alivePlayers );
		
		for ( i = 0; i < keys.size; i++ )
		{
			team = keys[ i ];
			
			for ( j = 0; j < level.alivePlayers[ team ].size; j++ )
			{
				allPlayers_s.a[ allPlayers_s.a.size ] = level.alivePlayers[ team ][ j ];
			}
		}
	}
	
	return allPlayers_s;
}


waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");

	while(self useButtonPressed() != true)
		wait .05;
}


setLowerMessage( text, time, combineMessageAndTimer )
{
	if ( !isDefined( self.lowerMessage ) )
		return;
	
	if ( isDefined( self.lowerMessageOverride ) && text != &"" )
	{
		text = self.lowerMessageOverride;
		time = undefined;
	}
	
	self notify("lower_message_set");
	if ( !IsDefined( combineMessageAndTimer ) || !combineMessageAndTimer )
		self.lowerMessage setText( text );
	else
		self.lowerMessage setText( "" );
	
	if ( isDefined( time ) && time > 0 )
	{
		if ( !IsDefined( combineMessageAndTimer ) || !combineMessageAndTimer )
			self.lowerTimer.label = &"";
		else
			self.lowerTimer.label = text;
		self.lowerTimer setTimer( time );
	}
	else
	{
		self.lowerTimer setText( "" );
		self.lowerTimer.label = &"";
	}
	if( self IsSplitscreen() )
		self.lowerMessage.fontscale = 1.4;
	
	self.lowerMessage fadeOverTime( 0.05 );
	self.lowerMessage.alpha = 1;
	self.lowerTimer fadeOverTime( 0.05 );
	self.lowerTimer.alpha = 1;
}

clearLowerMessage( fadetime )
{
	if ( !isDefined( self.lowerMessage ) )
		return;
	
	self notify("lower_message_set");
	
	if ( !isdefined( fadetime) || fadetime == 0 )
	{
		setLowerMessage( &"" );
	}
	else
	{
		self endon("disconnect");
		self endon("lower_message_set");
		
		self.lowerMessage fadeOverTime( fadetime );
		self.lowerMessage.alpha = 0;
		self.lowerTimer fadeOverTime( fadetime );
		self.lowerTimer.alpha = 0;
		
		wait fadetime;
		
		self setLowerMessage("");
	}
}

printOnTeam(text, team)
{
	assert( isdefined( level.players ) );
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( ( isdefined(player.pers["team"]) ) && (player.pers["team"] == team) )
			player iprintln(text);
	}
}


printBoldOnTeam(text, team)
{
	assert( isdefined( level.players ) );
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( ( isdefined(player.pers["team"]) ) && (player.pers["team"] == team) )
			player iprintlnbold(text);
	}
}



printBoldOnTeamArg(text, team, arg)
{
	assert( isdefined( level.players ) );
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( ( isdefined(player.pers["team"]) ) && (player.pers["team"] == team) )
			player iprintlnbold(text, arg);
	}
}


printOnTeamArg(text, team, arg)
{
	//assert( isdefined( level.players ) );
	//for ( i = 0; i < level.players.size; i++ )
	//{
	//	player = level.players[i];
	//	if ( ( isdefined(player.pers["team"]) ) && (player.pers["team"] == team) )
	//	{
	//		player iprintln(text, arg);
	//	}
	//}
}


printOnPlayers( text, team )
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if ( isDefined( team ) )
		{
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i] iprintln(text);
		}
		else
		{
			players[i] iprintln(text);
		}
	}
}

printAndSoundOnEveryone( team, otherteam, printFriendly, printEnemy, soundFriendly, soundEnemy, printarg )
{
	shouldDoSounds = isDefined( soundFriendly );
	
	shouldDoEnemySounds = false;
	if ( isDefined( soundEnemy ) )
	{
		assert( shouldDoSounds ); // can't have an enemy sound without a friendly sound
		shouldDoEnemySounds = true;
	}
	
	if ( level.splitscreen || !shouldDoSounds )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			playerteam = player.pers["team"];
			if ( isdefined( playerteam ) )
			{
				if ( playerteam == team && isDefined( printFriendly ) && printFriendly != &"" )
					player iprintln( printFriendly, printarg );
				else if ( playerteam == otherteam && isDefined( printEnemy ) && printEnemy != &"" )
					player iprintln( printEnemy, printarg );
			}
		}
		if ( shouldDoSounds )
		{
			assert( level.splitscreen );
			level.players[0] playLocalSound( soundFriendly );
		}
	}
	else
	{
		assert( shouldDoSounds );
		if ( shouldDoEnemySounds )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];
				playerteam = player.pers["team"];
				if ( isdefined( playerteam ) )
				{
					if ( playerteam == team )
					{
						if( isDefined( printFriendly ) && printFriendly != &"" )
							player iprintln( printFriendly, printarg );
						player playLocalSound( soundFriendly );
					}
					else if ( playerteam == otherteam )
					{
						if( isDefined( printEnemy ) && printEnemy != &"" )
							player iprintln( printEnemy, printarg );
						player playLocalSound( soundEnemy );
					}
				}
			}
		}
		else
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];
				playerteam = player.pers["team"];
				if ( isdefined( playerteam ) )
				{
					if ( playerteam == team )
					{
						if( isDefined( printFriendly ) && printFriendly != &"" )
							player iprintln( printFriendly, printarg );
						player playLocalSound( soundFriendly );
					}
					else if ( playerteam == otherteam && isDefined( printEnemy ) && printEnemy != &"" )
					{
						player iprintln( printEnemy, printarg );
					}
				}
			}
		}
	}
}


_playLocalSound( soundAlias )
{
	if ( level.splitscreen && !self IsHost() )
		return;

	self playLocalSound( soundAlias );
}


dvarIntValue( dVar, defVal, minVal, maxVal )
{
	dVar = "scr_" + level.gameType + "_" + dVar;
	if ( getDvar( dVar ) == "" )
	{
		setDvar( dVar, defVal );
		return defVal;
	}
	
	value = getDvarInt( dVar );

	if ( value > maxVal )
		value = maxVal;
	else if ( value < minVal )
		value = minVal;
	else
		return value;
		
	setDvar( dVar, value );
	return value;
}


dvarFloatValue( dVar, defVal, minVal, maxVal )
{
	dVar = "scr_" + level.gameType + "_" + dVar;
	if ( getDvar( dVar ) == "" )
	{
		setDvar( dVar, defVal );
		return defVal;
	}
	
	value = getDvarFloat( dVar );

	if ( value > maxVal )
		value = maxVal;
	else if ( value < minVal )
		value = minVal;
	else
		return value;
		
	setDvar( dVar, value );
	return value;
}


play_sound_on_tag( alias, tag )
{
	if ( isdefined( tag) )
	{
		org = spawn( "script_origin", self getTagOrigin( tag ) );
		org linkto( self, tag, (0,0,0), (0,0,0) );
	}
	else
	{
		org = spawn( "script_origin", (0,0,0) );
		org.origin = self.origin;
		org.angles = self.angles;
		org linkto( self );
	}

	org playsound (alias);
	wait ( 5.0 );
	org delete();
}


createLoopEffect( fxid )
{
	ent = maps\mp\_createfx::createEffect( "loopfx", fxid );
	ent.v[ "delay" ] = 0.5;
	return ent;
}

createOneshotEffect( fxid )
{
	ent = maps\mp\_createfx::createEffect( "oneshotfx", fxid );
	ent.v[ "delay" ] = -15;
	return ent;
}

loop_fx_sound ( alias, origin, ender, timeout )
{
	org = spawn ("script_origin",(0,0,0));
	if ( isdefined( ender ) )
	{
		thread loop_sound_delete (ender, org);
		self endon( ender );
	}
	org.origin = origin;
	org playloopsound (alias);
	if (!isdefined (timeout))
		return;
		
	wait (timeout);
//	org delete();
}

exploder_damage()
{
	if( isdefined( self.v[ "delay" ] ) )
		delay = self.v[ "delay" ];
	else
		delay = 0;
		
	if( isdefined( self.v[ "damage_radius" ] ) )
		radius = self.v[ "damage_radius" ];
	else
		radius = 128;

	damage = self.v[ "damage" ];
	origin = self.v[ "origin" ];
	
	wait( delay );
	// Range, max damage, min damage
	radiusDamage( origin, radius, damage, damage );
}


exploder_before_load( num )
{
	// gotta wait twice because the createfx_init function waits once then inits all exploders. This guarentees
	// that if an exploder is run on the first frame, it happens after the fx are init.
	waittillframeend;
	waittillframeend;
	activate_exploder( num );
}

exploder_after_load( num )
{
	activate_exploder( num );
}

activate_exploder( num )
{
	num = int( num );
	for( i = 0;i < level.createFXent.size;i ++ )
	{
		ent = level.createFXent[ i ];
		if( !isdefined( ent ) )
			continue;
	
		if( ent.v[ "type" ] != "exploder" )
			continue;	
	
		// make the exploder actually removed the array instead?
		if( !isdefined( ent.v[ "exploder" ] ) )
			continue;

		if( ent.v[ "exploder" ] != num )
			continue;

		if( isdefined( ent.v[ "firefx" ] ) )
			ent thread fire_effect();

		if( isdefined( ent.v[ "fxid" ] ) && ent.v[ "fxid" ] != "No FX" )
			ent thread cannon_effect();
		else
		if( isdefined( ent.v[ "soundalias" ] ) )
			ent thread sound_effect();

		if( isdefined( ent.v[ "damage" ] ) )
			ent thread exploder_damage();

		if( isdefined( ent.v[ "earthquake" ] ) )
		{
			eq = ent.v[ "earthquake" ];
			earthquake( level.earthquake[ eq ][ "magnitude" ], 
						level.earthquake[ eq ][ "duration" ], 
						ent.v[ "origin" ], 
						level.earthquake[ eq ][ "radius" ] );
		}

		if( ent.v[ "exploder_type" ] == "exploder" )
			ent thread brush_show();
		else
		if( ( ent.v[ "exploder_type" ] == "exploderchunk" ) || ( ent.v[ "exploder_type" ] == "exploderchunk visible" ) )
			ent thread brush_throw();
		else
			ent thread brush_delete();
	}
}

stop_exploder( num )
{
	num = int( num );
	for( i = 0;i < level.createFXent.size;i ++ )
	{
		ent = level.createFXent[ i ];
		if( !isdefined( ent ) )
			continue;
	
		if( ent.v[ "type" ] != "exploder" )
			continue;	
	
		// make the exploder actually removed the array instead?
		if( !isdefined( ent.v[ "exploder" ] ) )
			continue;

		if( ent.v[ "exploder" ] != num )
			continue;

		if ( isdefined( ent.looper ) )
		{
			ent.looper delete();
		}
	}
}

sound_effect ()
{
	self effect_soundalias();
}

effect_soundalias ( )
{
	if (!isdefined (self.v["delay"]))
		self.v["delay"] = 0;
	
	// save off this info in case we delete the effect
	origin = self.v["origin"];
	alias = self.v["soundalias"];
	wait (self.v["delay"]);
	play_sound_in_space ( alias, origin );
}

play_sound_in_space (alias, origin, master)
{
	org = spawn ("script_origin",(0,0,1));
	if (!isdefined (origin))
		origin = self.origin;
	org.origin = origin;
	if (isdefined(master) && master)
		org playsoundasmaster (alias);
	else
		org playsound (alias);
	wait ( 10.0 );
	org delete();
}

loop_sound_in_space(alias, origin, ender)
{
	org = spawn("script_origin",(0,0,1));
	
	if(!isdefined(origin))
	{
		origin = self.origin;
	}
	
	org.origin = origin;
	org playLoopSound(alias);
	
	level waittill(ender);
	
	org stopLoopSound();
	wait 0.1;
	org delete();
}

fire_effect()
{
	if( !isdefined( self.v[ "delay" ] ) )
		self.v[ "delay" ] = 0;

	delay = self.v[ "delay" ];
	if( ( isdefined( self.v[ "delay_min" ] ) ) && ( isdefined( self.v[ "delay_max" ] ) ) )
		delay = self.v[ "delay_min" ] + randomfloat( self.v[ "delay_max" ] - self.v[ "delay_min" ] );

	forward = self.v[ "forward" ];
	up = self.v[ "up" ];

	org = undefined;

	firefxSound = self.v[ "firefxsound" ];
	origin = self.v[ "origin" ];
	firefx = self.v[ "firefx" ];
	ender = self.v[ "ender" ];
	if( !isdefined( ender ) )
		ender = "createfx_effectStopper";
	timeout = self.v[ "firefxtimeout" ];

	fireFxDelay = 0.5;
	if( isdefined( self.v[ "firefxdelay" ] ) )
		fireFxDelay = self.v[ "firefxdelay" ];

	wait( delay );

	if( isdefined( firefxSound ) )	
		level thread loop_fx_sound( firefxSound, origin, ender, timeout );

	playfx( level._effect[ firefx ], self.v[ "origin" ], forward, up );

// 	loopfx( 				fxId, 	fxPos, 	waittime, 	fxPos2, 	fxStart, 	fxStop, 	timeout )
// 	maps\_fx::loopfx( 	firefx, 	origin, 	delay, 		org, 	undefined, 	ender, 	timeout );
}

loop_sound_delete ( ender, ent )
{
	ent endon ("death");
	self waittill (ender);
	ent delete();
}

createExploder( fxid )
{
	ent = maps\mp\_createfx::createEffect( "exploder", fxid );
	ent.v["delay"] = 0;
	ent.v["exploder_type"] = "normal";
	return ent;
}

getOtherTeam( team )
{
	if ( team == "allies" )
		return "axis";
	else if ( team == "axis" )
		return "allies";
		
	assertMsg( "getOtherTeam: invalid team " + team );
}


wait_endon( waitTime, endOnString, endonString2, endonString3 )
{
	self endon ( endOnString );
	if ( isDefined( endonString2 ) )
		self endon ( endonString2 );
	if ( isDefined( endonString3 ) )
		self endon ( endonString3 );
	
	wait ( waitTime );
}

isMG( weapon )
{
	return isSubStr( weapon, "_bipod_" );
}

plot_points( plotpoints, r, g, b, timer )
{
	lastpoint = plotpoints[ 0 ];
	if( !IsDefined( r ) )
		r = 1; 
	if( !IsDefined( g ) )
		g = 1; 
	if( !IsDefined( b ) )
		b = 1; 
	if( !IsDefined( timer ) )
		timer = 0.05; 
	for( i = 1;i < plotpoints.size;i ++ )
	{
		// AE 10-26-09: line function must have changed to Line( <start>, <end>, <color>, <depthTest>, <duration> )
		line( lastpoint, plotpoints[ i ], ( r, g, b ), 1, timer ); 
		//line( lastpoint, plotpoints[ i ], ( r, g, b ), 1, 1, int(timer) ); 
		lastpoint = plotpoints[ i ];	
	}
}

registerClientSys(sSysName)
{
	if(!isdefined(level._clientSys))
	{
		level._clientSys = [];
	}
	
	if(level._clientSys.size >= 32)	
	{
		error("Max num client systems exceeded.");
		return;
	}
	
	if(isdefined(level._clientSys[sSysName]))
	{
		error("Attempt to re-register client system : " + sSysName);
		return;
	}
	else
	{
		level._clientSys[sSysName] = spawnstruct();
		level._clientSys[sSysName].sysID = ClientSysRegister(sSysName);
	}	
}

setClientSysState(sSysName, sSysState, player)
{
	if(!isdefined(level._clientSys))
	{
		error("setClientSysState called before registration of any systems.");
		return;
	}
	
	if(!isdefined(level._clientSys[sSysName]))
	{
		error("setClientSysState called on unregistered system " + sSysName);
		return;
	}
	
	if(isdefined(player))
	{
		player ClientSysSetState(level._clientSys[sSysName].sysID, sSysState);
	}
	else
	{
		ClientSysSetState(level._clientSys[sSysName].sysID, sSysState);
		level._clientSys[sSysName].sysState = sSysState;
	}
}

getClientSysState(sSysName)
{
	if(!isdefined(level._clientSys))
	{
		error("Cannot getClientSysState before registering any client systems.");
		return "";
	}
	
	if(!isdefined(level._clientSys[sSysName]))
	{
		error("Client system " + sSysName + " cannot return state, as it is unregistered.");
		return "";
	}
	
	if(isdefined(level._clientSys[sSysName].sysState))
	{
		return level._clientSys[sSysName].sysState;
	}
	
	return "";
}

clientNotify(event)
{
	if(level.clientscripts)
	{
		if(IsPlayer(self))
		{
			maps\mp\_utility::setClientSysState("levelNotify", event, self);
		}
		else
		{
			maps\mp\_utility::setClientSysState("levelNotify", event);
		}
	}
}

alphabet_compare( a, b )
{
	list = [];
	val = 1;
	list[ "0" ] = val; val++;
	list[ "1" ] = val; val++;
	list[ "2" ] = val; val++;
	list[ "3" ] = val; val++;
	list[ "4" ] = val; val++;
	list[ "5" ] = val; val++;
	list[ "6" ] = val; val++;
	list[ "7" ] = val; val++;
	list[ "8" ] = val; val++;
	list[ "9" ] = val; val++;
	list[ "_" ] = val; val++;
	list[ "a" ] = val; val++;
	list[ "b" ] = val; val++;
	list[ "c" ] = val; val++;
	list[ "d" ] = val; val++;
	list[ "e" ] = val; val++;
	list[ "f" ] = val; val++;
	list[ "g" ] = val; val++;
	list[ "h" ] = val; val++;
	list[ "i" ] = val; val++;
	list[ "j" ] = val; val++;
	list[ "k" ] = val; val++;
	list[ "l" ] = val; val++;
	list[ "m" ] = val; val++;
	list[ "n" ] = val; val++;
	list[ "o" ] = val; val++;
	list[ "p" ] = val; val++;
	list[ "q" ] = val; val++;
	list[ "r" ] = val; val++;
	list[ "s" ] = val; val++;
	list[ "t" ] = val; val++;
	list[ "u" ] = val; val++;
	list[ "v" ] = val; val++;
	list[ "w" ] = val; val++;
	list[ "x" ] = val; val++;
	list[ "y" ] = val; val++;
	list[ "z" ] = val; val++;

	a = tolower( a );
	b = tolower( b );
	val1 = 0;
	if ( isdefined( list[ a ] ) )
		val1 = list[ a ];

	val2 = 0;
	if ( isdefined( list[ b ] ) )
		val2 = list[ b ];
	
	if ( val1 > val2 )
		return "1st";
	if ( val1 < val2 )
		return "2nd";
	return "same";
}

is_later_in_alphabet( string1, string2 )
{
	count = string1.size;
	if ( count >= string2.size )
		count = string2.size;
		
	for ( i = 0; i < count; i++ )
	{
		val = alphabet_compare( string1[ i ], string2[ i ] );
		if ( val == "1st" )
			return true;
		if ( val == "2nd" )
			return false;
	}
	
	return string1.size > string2.size;
}

alphabetize( array )
{
	if ( array.size <= 1 )
		return array;
		
	count = 0;
	for ( ;; )
	{
		changed = false;
		for ( i = 0; i < array.size - 1; i++ )
		{
			if ( is_later_in_alphabet( array[ i ], array[ i + 1 ] ) )
			{
				val = array[ i ];
				array[ i ] = array[ i + 1 ];
				array[ i + 1 ] = val;
				changed = true;
				count++;
				if ( count >= 9 )
				{
					count = 0;
					wait( 0.05 );
				}
			}
		}
		
		if ( !changed )
			return array;
	}
	
	return array;
}

//------------------------------------------------------//
// get_players()										//
//		Returns all of the current players in the level	//
//------------------------------------------------------//
get_players()
{
	players = GetEntArray( "player", "classname" ); 

	return players; 
}

getfx( fx )
{
	assertEx( IsDefined( level._effect[ fx ] ), "Fx " + fx + " is not defined in level._effect." );
	return level._effect[ fx ];
}

struct_arraySpawn()
{
	struct = SpawnStruct();
	struct.array = [];
	struct.lastindex = 0;
	return struct;
}

structarray_add( struct, object )
{
	assert( !isdefined( object.struct_array_index ) );// can't have elements of two structarrays on these. can add that later if it's needed
	struct.array[ struct.lastindex ] = object;
	object.struct_array_index = struct.lastindex; 
	struct.lastindex ++ ;
}

structarray_remove( struct, object )
{
	structarray_swaptolast( struct, object ); 
	struct.array[ struct.lastindex - 1 ] = undefined;
	struct.lastindex -- ;
}

structarray_swaptolast( struct, object )
{
	struct structarray_swap( struct.array[ struct.lastindex - 1 ], object );
}

structarray_shuffle( struct, shuffle )
{
	for( i = 0;i < shuffle;i ++ )
		struct structarray_swap( struct.array[ i ], struct.array[ randomint( struct.lastindex ) ] );
}

structarray_swap( object1, object2 )
{
	index1 = object1.struct_array_index;
	index2 = object2.struct_array_index; 
	self.array[ index2 ] = object1;
	self.array[ index1 ] = object2;
	self.array[ index1 ].struct_array_index = index1;
	self.array[ index2 ].struct_array_index = index2;
}

waittill_either( msg1, msg2 )
{
	self endon( msg1 ); 
	self waittill( msg2 ); 
}

 /* 
 ============= 
///ScriptDocBegin
"Name: getClosest( <org> , <array> , <dist> )"
"Summary: Returns the closest entity in < array > to location < org > "
"Module: Distance"
"CallOn: "
"MandatoryArg: <org> : Origin to be closest to."
"MandatoryArg: <array> : Array of entities to check distance on"
"OptionalArg: <dist> : Minimum distance to check"
"Example: friendly = getclosest( level.player.origin, allies );"
"SPMP: singleplayer"
///ScriptDocEnd
 ============= 
 */
getClosest( org, array, dist )
{
	return compareSizes( org, array, dist, ::closerFunc ); 
}

 /* 
 ============= 
///ScriptDocBegin
"Name: getClosestFx( <org> , <fxarray> , <dist> )"
"Summary: Returns the closest fx struct created by createfx in < fxarray > to location < org > "
"Module: Distance"
"CallOn: "
"MandatoryArg: <org> : Origin to be closest to."
"MandatoryArg: <array> : Array of createfx structs to check distance on. These are obtained with getfxarraybyID( <fxid> )"
"OptionalArg: <dist> : Minimum distance to check"
"Example: fxstruct = getClosestFx( hallway_tv, fxarray );"
"SPMP: singleplayer"
///ScriptDocEnd
 ============= 
 */ 
getClosestFx( org, fxarray, dist )
{
	return compareSizesFx( org, fxarray, dist, ::closerFunc );
}

 /* 
 ============= 
///ScriptDocBegin
"Name: getFarthest( <org> , <array> , <dist> )"
"Summary: Returns the farthest entity in < array > to location < org > "
"Module: Distance"
"CallOn: "
"MandatoryArg: <org> : Origin to be farthest from."
"MandatoryArg: <array> : Array of entities to check distance on"
"OptionalArg: <dist> : Maximum distance to check"
"Example: target = getFarthest( level.player.origin, targets );"
"SPMP: singleplayer"
///ScriptDocEnd
 ============= 
 */ 
getFarthest( org, array, dist )
{
	return compareSizes( org, array, dist, ::fartherFunc ); 
}

compareSizesFx( org, array, dist, compareFunc )
{
	if( !array.size )
		return undefined;
	if( isdefined( dist ) )
	{
		distSqr = dist * dist;
		struct = undefined;
		keys = getArrayKeys( array );
		for( i = 0; i < keys.size; i ++ )
		{
			newdistSqr = DistanceSquared( array[ keys[ i ] ].v[ "origin" ], org );
			if( [[ compareFunc ]]( newdistSqr, distSqr ) )
				continue;
			distSqr = newdistSqr;
			struct = array[ keys[ i ] ];
		}
		return struct;
	}

	keys = getArrayKeys( array );
	struct = array[ keys[ 0 ] ];
	distSqr = DistanceSquared( struct.v[ "origin" ], org );
	for( i = 1; i < keys.size; i ++ )
	{
		newdistSqr = DistanceSquared( array[ keys[ i ] ].v[ "origin" ], org );
		if( [[ compareFunc ]]( newdistSqr, distSqr ) )
			continue;
		distSqr = newdistSqr;
		struct = array[ keys[ i ] ];
	}
	return struct;
}

compareSizes( org, array, dist, compareFunc )
{
	if( !array.size )
		return undefined; 
	if( IsDefined( dist ) )
	{
		distSqr = dist * dist;
		ent = undefined; 
		keys = GetArrayKeys( array ); 
		for( i = 0; i < keys.size; i ++ )
			{
			newdistSqr = DistanceSquared( array[ keys[ i ] ].origin, org );
			if( [[ compareFunc ]]( newdistSqr, distSqr ) )
				continue; 
			distSqr = newdistSqr; 
			ent = array[ keys[ i ] ];
		}
		return ent; 
	}

	keys = GetArrayKeys( array ); 
	ent = array[ keys[ 0 ] ];
	distSqr = DistanceSquared( ent.origin, org ); 
	for( i = 1; i < keys.size; i ++ )
	{
		newdistSqr = DistanceSquared( array[ keys[ i ] ].origin, org );
		if( [[ compareFunc ]]( newdistSqr, distSqr ) )
			continue; 
		distSqr = newdistSqr; 
		ent = array[ keys[ i ] ];
	}
	return ent; 
}

closerFunc( dist1, dist2 )
{
	return dist1 >= dist2; 
}

fartherFunc( dist1, dist2 )
{
	return dist1 <= dist2; 
}

/* 
 ============= 
///ScriptDocBegin
"Name: get_array_of_closest( <org> , <array> , <excluders> , <max>, <maxdist> )"
"Summary: Returns an array of all the entities in < array > sorted in order of closest to farthest."
"Module: Distance"
"CallOn: "
"MandatoryArg: <org> : Origin to be closest to."
"MandatoryArg: <array> : Array of entities to check distance on."
"OptionalArg: <excluders> : Array of entities to exclude from the check."
"OptionalArg: <max> : Max size of the array to return"
"OptionalArg: <maxdist> : Max distance from the origin to return acceptable entities"
"Example: allies_sort = get_array_of_closest( originFC1.origin, allies );"
"SPMP: singleplayer"
///ScriptDocEnd
 ============= 
 */ 
get_array_of_closest( org, array, excluders, max, maxdist )
{
	// pass an array of entities to this function and it will return them in the order of closest
	// to the origin you pass, you can also set max to limit how many ents get returned
	if( !IsDefined( max ) )
		max = array.size; 
	if( !isdefined( excluders ) )
		excluders = [];
	
	maxdists2rd = undefined;
	if( isdefined( maxdist ) )
		maxdists2rd = maxdist * maxdist;
		
	// return the array, reordered from closest to farthest
	dist = []; 
	index = []; 
	for( i = 0;i < array.size;i ++ )
	{
		excluded = false; 
		for( p = 0;p < excluders.size;p ++ )
			{
			if( array[ i ] != excluders[ p ] )
				continue; 
			excluded = true; 
			break; 
		}
		if( excluded )
			continue; 
			
		length = distancesquared( org, array[ i ].origin );
		
		if( isdefined( maxdists2rd ) && maxdists2rd < length )
			continue;
			
		dist[ dist.size ] = length;
		
		
		index[ index.size ] = i;
	}
		
	for( ;; )
	{
		change = false; 
		for( i = 0;i < dist.size - 1;i ++ )
			{
			if( dist[ i ] <= dist[ i + 1 ] )
				continue; 
			change = true; 
			temp = dist[ i ];
			dist[ i ] = dist[ i + 1 ];
			dist[ i + 1 ] = temp;
			temp = index[ i ];
			index[ i ] = index[ i + 1 ];
			index[ i + 1 ] = temp;
		}
		if( !change )
			break; 
		}
	
	newArray = []; 
	if( max > dist.size )
		max = dist.size; 
	for( i = 0;i < max;i ++ )
		newArray[ i ] = array[ index[ i ] ];
	return newArray; 
}

set_dvar_if_unset(
	dvar,
	value,
	force)
{
	if (GetDvar(dvar)=="" || ( isdefined( force ) && force ) )
	{
		SetDvar(dvar, value);
		return value;
	}
	
	return GetDvar(dvar);
}

set_dvar_float_if_unset(
	dvar,
	value,
	force)
{
	if (GetDvar(dvar)=="" || ( isdefined( force ) && force ) )
	{
		SetDvar(dvar, value);
	}
	
	return GetDvarFloat(dvar);
}

set_dvar_int_if_unset(
	dvar,
	value,
	force)
{
	if (GetDvar(dvar)=="" || ( isdefined( force ) && force ) )
	{
		SetDvar(dvar, value);
		return int(value);
	}
	
	return GetDvarInt(dvar);
}

drawcylinder( pos, rad, height, duration, stop_notify )
{
/#
	if ( !IsDefined( duration ) )
	{
		duration = 0;
	}
	
	level thread drawcylinder_think( pos, rad, height, duration, stop_notify );
#/
}

drawcylinder_think( pos, rad, height, seconds, stop_notify )
{
/#
	if ( IsDefined( stop_notify ) )
	{
		level endon( stop_notify );
	}

	stop_time = GetTime() + ( seconds * 1000 );

	currad = rad; 
	curheight = height; 

	for ( ;; )
	{
		if ( seconds > 0 && stop_time <= GetTime() )
		{
			return;
		}

		for( r = 0; r < 20; r++ )
		{
			theta = r / 20 * 360; 
			theta2 = ( r + 1 ) / 20 * 360; 

			line( pos +( cos( theta ) * currad, sin( theta ) * currad, 0 ), pos +( cos( theta2 ) * currad, sin( theta2 ) * currad, 0 ) ); 
			line( pos +( cos( theta ) * currad, sin( theta ) * currad, curheight ), pos +( cos( theta2 ) * currad, sin( theta2 ) * currad, curheight ) ); 
			line( pos +( cos( theta ) * currad, sin( theta ) * currad, 0 ), pos +( cos( theta ) * currad, sin( theta ) * currad, curheight ) ); 
		}

		wait( 0.05 );
	}
#/
}

/#
debug_replay(string)
{
	if( GetDvar( #"replay_debug" ) == "1" )
	{
		println("time=" + GetTime() + " " + string);
	}
}
#/

is_bot()
{
	return ( IsDefined ( self.pers["isBot"] ) && self.pers["isBot"] != 0 );
}

add_trigger_to_ent(ent) // Self == The trigger volume
{
	if(!IsDefined(ent._triggers))
	{
		ent._triggers = [];
	}
	
	ent._triggers[self GetEntityNumber()] = 1;
}

remove_trigger_from_ent(ent)	// Self == The trigger volume.
{
	if(!IsDefined(ent))
		return;

	if(!IsDefined(ent._triggers))
		return;
		
	if(!IsDefined(ent._triggers[self GetEntityNumber()]))
		return;
		
	ent._triggers[self GetEntityNumber()] = 0;
}

ent_already_in_trigger(trig)	// Self == The entity in the trigger volume.
{
	if(!IsDefined(self._triggers))
		return false;
		
	if(!IsDefined(self._triggers[trig GetEntityNumber()]))
		return false;
		
	if(!self._triggers[trig GetEntityNumber()])
		return false;
		
	return true;	// We're already in this trigger volume.
}

trigger_thread_death_monitor(ent, ender)
{
	ent waittill("death");
	self endon(ender);
	self remove_trigger_from_ent(ent);
}

trigger_thread(ent, on_enter_payload, on_exit_payload)	// Self == The trigger.
{
	ent endon("entityshutdown");
	ent endon("death");
	
	if(ent ent_already_in_trigger(self))
		return;
		
	self add_trigger_to_ent(ent);
	
	ender = "end_trig_death_monitor" + self GetEntityNumber() + " " + ent GetEntityNumber();
	self thread trigger_thread_death_monitor(ent, ender);  // If ent dies in trigger, clear trigger off of ent.

//	iprintlnbold("Trigger " + self.targetname + " hit by ent " + ent getentitynumber());
	
	endon_condition = "leave_trigger_" + self GetEntityNumber();
	
	if(IsDefined(on_enter_payload))
	{
		self thread [[on_enter_payload]](ent, endon_condition);
	}
	
	while(IsDefined(ent) && ent IsTouching(self))
	{
		wait(0.01);
	}

	ent notify(endon_condition);

//	iprintlnbold(ent getentitynumber() + " leaves trigger " + self.targetname + ".");

	if(IsDefined(ent) && IsDefined(on_exit_payload))
	{
		self thread [[on_exit_payload]](ent);
	}

	if(IsDefined(ent))
	{
		self remove_trigger_from_ent(ent);
	}

	self notify(ender);	// Get rid of the death monitor thread.
}

isOneRound()
{		
	if ( level.roundLimit == 1 )
		return true;

	return false;
}

isFirstRound()
{
	if ( level.roundLimit > 1 && game[ "roundsplayed" ] == 0 )
		return true;
		
	return false;
}

isLastRound()
{		
	if ( level.roundLimit > 1 && game[ "roundsplayed" ] >= ( level.roundLimit - 1 ) )
		return true;
		
	return false;
}

wasLastRound()
{		
	if ( level.forcedEnd )
		return true;

	if ( hitRoundLimit() || hitScoreLimit() || hitRoundWinLimit() )
		return true;
		
	return false;
}

hitRoundLimit()
{
	if( level.roundLimit <= 0 )
		return false;

	return ( getRoundsPlayed() >= level.roundLimit );
}

hitRoundWinLimit()
{
	if( !IsDefined(level.roundWinLimit) || level.roundWinLimit <= 0 )
		return false;

	if ( getRoundsWon("allies") >= level.roundWinLimit || getRoundsWon("axis") >= level.roundWinLimit)
	{
		//"True" means that we should end the game
		return true;
	}
	
	//No over-time should occur if either team has more rounds won, even if there were rounds that ended in draw.
	// For example, If the round win limit is 5 and one team has one win and 4 draws occur in a row, we want to declare the 
	//team with the victory as the winner and not enter an over-time round.
	if( getRoundsWon("allies") + game["roundswon"]["tie"] >= level.roundWinLimit ||
		getRoundsWon("axis") + game["roundswon"]["tie"] >= level.roundWinLimit)
	{
		//We want the game to have an over-time round if the teams are tied.
		//In a game with a win limit of 3, 3 ties in a row would cause the previous 'if' check to return 'true'.
		// We want to make sure the game doesn't end if that's the case.
		if(getRoundsWon("allies") != getRoundsWon("axis"))
		{
			return true;
		}
	}
	
	return false;
}


hitScoreLimit()
{
	if ( isScoreRoundBased() )
		return false;
		
	if( level.scoreLimit <= 0 )
		return false;

	if ( level.teamBased )
	{
		if( game["teamScores"]["allies"] >= level.scoreLimit || game["teamScores"]["axis"] >= level.scoreLimit )
			return true;
	}
	else
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( isDefined( player.score ) && player.score >= level.scorelimit )
				return true;
		}
	}
	return false;
}

getRoundsWon( team )
{
	return game["roundswon"][team];
}

getRoundsPlayed()
{
	return game["roundsplayed"];
}

isScoreRoundBased()
{
	return level.scoreRoundBased;
}

isRoundBased()
{
	if ( level.roundLimit != 1 && level.roundWinLimit != 1 )
		return true;

	return false;
}

waitTillNotMoving()
{
	if ( self maps\mp\gametypes\_weaponobjects::isHacked() )
	{
		wait( 0.05 );
		return;
	}
	
	if ( self.classname == "grenade" )
	{
		self waittill("stationary");
	}
	else
	{
		prevorigin = self.origin;
		while(1)
		{
			wait .15;
			if ( self.origin == prevorigin )
				break;
			prevorigin = self.origin;
		}
	}
}

mayApplyScreenEffect()
{
	if ( isDefined( self.viewlockedentity ) )
		return false;
	
	return true;
}

getDvarFloatDefault( dvarName, defaultValue)
{
	returnVal = defaultValue;	
	if (getDvar(dvarName) != "")
	{
		return getDvarFloat(dvarName);
	}	
	return returnVal;
}	

getDvarIntDefault( dvarName, defaultValue)
{
	returnVal = defaultValue;	
	if (getDvar(dvarName) != "")
	{
		return getDvarInt(dvarName);
	}	
	return returnVal;
}	

dropAllToGround( origin, radius, stickyObjectRadius )
{
	PhysicsExplosionSphere( origin, radius, radius, 0 );
	wait(0.05);
	maps\mp\gametypes\_weapons::dropWeaponsToGround( origin, radius );
	// grenades are now done in code when an entity they were on gets deleted
//	maps\mp\gametypes\_weapons::dropGrenadesToGround( origin, radius );
	maps\mp\gametypes\_supplydrop::dropCratesToGround( origin, radius );
	level notify( "drop_objects_to_ground", origin, stickyObjectRadius );
}

closestPointOnLine( point, lineStart, lineEnd )
{
	lineMagSqrd = lengthsquared(lineEnd - lineStart);
 
  t =	( ( ( point[0] - lineStart[0] ) * ( lineEnd[0] - lineStart[0] ) ) +
			( ( point[1] - lineStart[1] ) * ( lineEnd[1] - lineStart[1] ) ) +
			( ( point[2] - lineStart[2] ) * ( lineEnd[2] - lineStart[2] ) ) ) /
			( lineMagSqrd );
 
  if( t < 0.0  )
	{
		return lineStart;
	}
	else if( t > 1.0 )
	{
		return lineEnd;
	}

	start_x = lineStart[0] + t * ( lineEnd[0] - lineStart[0] );
	start_y = lineStart[1] + t * ( lineEnd[1] - lineStart[1] );
	start_z = lineStart[2] + t * ( lineEnd[2] - lineStart[2] );
	
	return (start_x,start_y,start_z);
}


isStrStart( string1, subStr )
{
	return ( getSubStr( string1, 0, subStr.size ) == subStr );
}

/* 
============= 
///ScriptDocBegin
"Name: spread_array_thread( <entities> , <process> , <var1> , <var2> , <var3> )"
"Summary: Threads the < process > function on every entity in the < entities > array. The entity will become "self" in the specified function.  Each thread is started 1 network frame apart from the next."
"Module: Array"
"CallOn: "
"MandatoryArg: <entities> : array of entities to thread the process"
"MandatoryArg: <process> : pointer to a script function"
"OptionalArg: <var1> : parameter 1 to pass to the process"
"OptionalArg: <var2> : parameter 2 to pass to the process"
"OptionalArg: <var3> : parameter 3 to pass to the process"
"Example: array_thread( getaiarray( "allies" ), ::set_ignoreme, false );"
"SPMP: Both"
///ScriptDocEnd
============= 
*/ 

spread_array_thread( entities, process, var1, var2, var3 )
{
	keys = getArrayKeys( entities );

	if ( IsDefined( var3 ) )
	{
		for( i = 0 ; i < keys.size ; i++ )
		{
			entities[ keys[ i ] ] thread [[ process ]]( var1, var2, var3 );
			wait .1;
		}

		return;
	}

	if ( IsDefined( var2 ) )
	{
		for( i = 0 ; i < keys.size ; i++ )
		{
			entities[ keys[ i ] ] thread [[ process ]]( var1, var2 );
			wait .1;
		}

		return;
	}

	if ( IsDefined( var1 ) )
	{
		for( i = 0 ; i < keys.size ; i++ )
		{
			entities[ keys[ i ] ] thread [[ process ]]( var1 );
			wait .1;
		}

		return;
	}

	for( i = 0 ; i < keys.size ; i++ )
	{
		entities[ keys[ i ] ] thread [[ process ]]();
		wait .1;
	}
}

/* 
============= 
///ScriptDocBegin
"Name: freeze_player_controls( <boolean> )"
"Summary:  Freezes the player's controls with appropriate 'if' checks"
"Module: Player"
"CallOn: Player"
"MandatoryArg: <boolean> : true or false"
"Example: freeze_player_controls( true )"
"SPMP: MP"
///ScriptDocEnd
============= 
*/ 

freeze_player_controls( boolean )
{
	AssertEx( IsDefined( boolean ), "'freeze_player_controls()' has not been passed an argument properly." );

	if( boolean && IsAlive( self ) )
	{
		self FreezeControls( boolean );

	}
	//'!level.gameEnded' check prevents the player from having their controls unfrozen during the end of rounds
	else if( !boolean && IsAlive( self ) && !level.gameEnded )
	{
		self FreezeControls( boolean );

	}
}

getHostPlayer()
{
	players = get_players();
	
	for ( index = 0; index < players.size; index++ )
	{
		if ( players[index] IsHost() )
			return players[index];
	}
}


isPreGame()
{
	return IsDefined( level.pregame ) && level.pregame;
}

isKillStreaksEnabled()
{
	return IsDefined( level.killstreaksenabled ) && level.killstreaksenabled;
}

ishardPointsEnabled()
{
	return IsDefined( level.hardpointsenabled ) && level.hardpointsenabled;
}

isRankEnabled()
{
	return IsDefined( level.rankEnabled ) && level.rankEnabled;
}

playSmokeSound( position, duration, startSound, stopSound, loopSound )
{	
	smokeSound = spawn ("script_origin",(0,0,1));
	smokeSound.origin = position;
	
	smokeSound playsound( startSound );
	smokeSound playLoopSound ( loopSound );
	if ( duration > 0.5 )
		wait( duration - 0.5 );
	thread playSoundinSpace( stopSound, position );	
	smokeSound StopLoopSound( .5);
	wait(.5);
	smokeSound delete();
}

playSoundinSpace (alias, origin, master)
{
	org = spawn ( "script_origin",(0,0,1) );
	if (!isdefined (origin))
		origin = self.origin;
	org.origin = origin;
	if (isdefined(master) && master)
		org playsoundasmaster (alias);
	else
		org playsound (alias);
	wait ( 10.0 );
	org delete();
}

get2DYaw( start, end )
{
	yaw = 0;
	vector = (end[0] - start[0], end[1] - start[1], 0);

	return vecToAngles( vector );
}

vecToAngles( vector )
{
	yaw = 0;
	
	vecX = vector[0];
	vecY = vector[1];
	
	if ( vecX == 0 && vecY == 0 )
		return 0;
		
	if ( vecY < 0.001 && vecY > -0.001 )
		vecY = 0.001;

	yaw = atan( vecX / vecY );
	
	if ( vecY < 0 )
		yaw += 180;	

	return ( 90 - yaw );
}


