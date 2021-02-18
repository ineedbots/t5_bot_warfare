#include maps\mp\_utility;

updateMatchBonusScores( winner )
{
	if ( !game["timepassed"] )
		return;

	if ( !level.rankedMatch )
		return;

	// dont give the bonus until the game is over
	if ( level.teamBased && isDefined( winner ) )
	{
		if ( winner == "endregulation" )
			return;
	}

	if ( !level.timeLimit || level.forcedEnd )
	{
		gameLength = maps\mp\gametypes\_globallogic_utils::getTimePassed() / 1000;		
		// cap it at 20 minutes to avoid exploiting
		gameLength = min( gameLength, 1200 );

		// the bonus for final fight needs to be based on the total time played
		if ( level.gameType == "twar" && game["roundsplayed"] > 0 )
			gameLength += level.timeLimit * 60;
	}
	else
	{
		gameLength = level.timeLimit * 60;
	}
		
	if ( level.teamBased )
	{
		if ( winner == "allies" )
		{
			winningTeam = "allies";
			losingTeam = "axis";
		}
		else if ( winner == "axis" )
		{
			winningTeam = "axis";
			losingTeam = "allies";
		}
		else
		{
			winningTeam = "tie";
			losingTeam = "tie";
		}

		if ( winningTeam != "tie" )
		{
			winnerScale = maps\mp\gametypes\_rank::getScoreInfoValue( "win" );
			loserScale = maps\mp\gametypes\_rank::getScoreInfoValue( "loss" );
		}
		else
		{
			winnerScale = maps\mp\gametypes\_rank::getScoreInfoValue( "tie" );
			loserScale = maps\mp\gametypes\_rank::getScoreInfoValue( "tie" );
		}
		
		players = level.players;
		for( i = 0; i < players.size; i++ )
		{
			player = players[i];
			
			if ( player.timePlayed["total"] < 1 || player.pers["participation"] < 1 )
			{
				player thread maps\mp\gametypes\_rank::endGameUpdate();
				continue;
			}
	
			totalTimePlayed = player.timePlayed["total"];
			
			// make sure the players total time played is no 
			// longer then the game length to prevent exploits
			if ( totalTimePlayed > gameLength )
			{
				totalTimePlayed = gameLength;
			}
			
			// no bonus for hosts who force ends
			if ( level.hostForcedEnd && player IsHost() )
				continue;

			// no match bonus if negative game score
			if ( player.pers["score"] < 0 )
				continue;
				
			spm = player maps\mp\gametypes\_rank::getSPM();				
			if ( winningTeam == "tie" )
			{
				playerScore = int( (winnerScale * ((gameLength/60) * spm)) * (totalTimePlayed / gameLength) );
				player thread giveMatchBonus( "tie", playerScore );
				player.matchBonus = playerScore;
			}
			else if ( isDefined( player.pers["team"] ) && player.pers["team"] == winningTeam )
			{
				playerScore = int( (winnerScale * ((gameLength/60) * spm)) * (totalTimePlayed / gameLength) );
				player thread giveMatchBonus( "win", playerScore );
				player.matchBonus = playerScore;
			}
			else if ( isDefined(player.pers["team"] ) && player.pers["team"] == losingTeam )
			{
				playerScore = int( (loserScale * ((gameLength/60) * spm)) * (totalTimePlayed / gameLength) );
				player thread giveMatchBonus( "loss", playerScore );
				player.matchBonus = playerScore;
			}
		}
	}
	else
	{
		if ( isDefined( winner ) )
		{
			winnerScale = maps\mp\gametypes\_rank::getScoreInfoValue( "win" );
			loserScale = maps\mp\gametypes\_rank::getScoreInfoValue( "loss" );
		}
		else
		{
			winnerScale = maps\mp\gametypes\_rank::getScoreInfoValue( "tie" );
			loserScale = maps\mp\gametypes\_rank::getScoreInfoValue( "tie" );
		}
		
		players = level.players;
		for( i = 0; i < players.size; i++ )
		{
			player = players[i];
			
			if ( player.timePlayed["total"] < 1 || player.pers["participation"] < 1 )
			{
				player thread maps\mp\gametypes\_rank::endGameUpdate();
				continue;
			}
			
			totalTimePlayed = player.timePlayed["total"];
			
			// make sure the players total time played is no 
			// longer then the game length to prevent exploits
			if ( totalTimePlayed > gameLength )
			{
				totalTimePlayed = gameLength;
			}
			
			spm = player maps\mp\gametypes\_rank::getSPM();

			isWinner = false;
			for ( pIdx = 0; pIdx < min( level.placement["all"][0].size, 3 ); pIdx++ )
			{
				if ( level.placement["all"][pIdx] != player )
					continue;
				isWinner = true;				
			}
			
			if ( isWinner )
			{
				playerScore = int( (winnerScale * ((gameLength/60) * spm)) * (totalTimePlayed / gameLength) );
				player thread giveMatchBonus( "win", playerScore );
				player.matchBonus = playerScore;
			}
			else
			{
				playerScore = int( (loserScale * ((gameLength/60) * spm)) * (totalTimePlayed / gameLength) );
				player thread giveMatchBonus( "loss", playerScore );
				player.matchBonus = playerScore;
			}
		}
	}
}


giveMatchBonus( scoreType, score )
{
	self endon ( "disconnect" );

	level waittill ( "give_match_bonus" );
	
	self maps\mp\gametypes\_rank::giveRankXP( scoreType, score );
	logXPGains();
	
	self maps\mp\gametypes\_rank::endGameUpdate();
}


setXenonRanks( winner )
{
	players = level.players;

	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if( !isdefined(player.score) || !isdefined(player.pers["team"]) )
			continue;

	}

	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if( !isdefined(player.score) || !isdefined(player.pers["team"]) )
			continue;		
		
		setPlayerTeamRank( player, i, player.score - 5 * player.deaths );
		player logString( "team: score " + player.pers["team"] + ":" + player.score );
	}
	sendranks();
}


getHighestScoringPlayer()
{
	players = level.players;
	winner = undefined;
	tie = false;
	
	for( i = 0; i < players.size; i++ )
	{
		if ( !isDefined( players[i].score ) )
			continue;
			
		if ( players[i].score < 1 )
			continue;
			
		if ( !isDefined( winner ) || players[i].score > winner.score )
		{
			winner = players[i];
			tie = false;
		}
		else if ( players[i].score == winner.score )
		{
			tie = true;
		}
	}
	
	if ( tie || !isDefined( winner ) )
		return undefined;
	else
		return winner;
}


onXPEvent( event )
{
	self maps\mp\gametypes\_rank::giveRankXP( event );
}

givePlayerScore( event, player, victim )
{
	if ( level.overridePlayerScore )
		return;
	
	pixbeginevent("level.onPlayerScore");
	score = player.pers["score"];
	[[level.onPlayerScore]]( event, player, victim );
	newScore = player.pers["score"];	
	pixendevent();
	
	bbPrint( "mpplayerscore: gametime %d type %s player %s delta %d", getTime(), event, player.name, newScore - score );
	
	if ( score == newScore )
		return;
		
	pixbeginevent("givePlayerScore");
	recordPlayerStats( player, "score" , newScore );
	
	if ( level.rankedMatch || level.wagerMatch )
	{
		player maps\mp\gametypes\_persistence::statAdd( "score", (newScore - score), false );
		player maps\mp\gametypes\_persistence::statAddWithGameType( "SCORE", (newScore - score) );
		if ( isDefined( player.pers["lastHighestScore"] ) && newScore > player.pers["lastHighestScore"] )
		{
			player setDStat( "HighestStats", "highest_score", newScore );
		}

		if( !level.wagerMatch )
		{
			player maps\mp\gametypes\_persistence::addRecentStat( false, 0, "score", (newScore - score) );
			player maps\mp\gametypes\_persistence::addRecentStat( true, 0, "score", (newScore - score) );
		}
	}
	pixendevent();
}

default_onPlayerScore( event, player, victim )
{
	score = maps\mp\gametypes\_rank::getScoreInfoValue( event );

	assert( isDefined( score ) );
	/*
	if ( event == "assist" )
		player.pers["score"] += 2;
	else
		player.pers["score"] += 10;
	*/
	
	if ( level.wagerMatch )
	{
		player thread maps\mp\gametypes\_rank::updateRankScoreHUD( score );
	}
	
	_setPlayerScore( player, player.pers["score"] + score );
}


_setPlayerScore( player, score )
{
	if ( score == player.pers["score"] )
		return;

	if ( !level.onlineGame || ( GetDvarInt( #"xblive_privatematch" ) && !GetDvarInt( #"xblive_basictraining" ) ) )
	{
		player thread maps\mp\gametypes\_rank::updateRankScoreHUD( score - player.pers["score"] );
	}

	player.pers["score"] = score;
	player.score = player.pers["score"];
	recordPlayerStats( player, "score" , player.pers["score"] );

	player notify ( "update_playerscore_hud" );
	if ( level.wagerMatch )
		player thread maps\mp\gametypes\_wager::playerScored();
	player thread maps\mp\gametypes\_globallogic::checkScoreLimit();
	player thread maps\mp\gametypes\_globallogic::checkPlayerScoreLimitSoon();

}


_getPlayerScore( player )
{
	return player.pers["score"];
}


giveTeamScore( event, team, player, victim )
{
	if ( level.overrideTeamScore )
		return;
		
	pixbeginevent("level.onTeamScore");
	teamScore = game["teamScores"][team];
	[[level.onTeamScore]]( event, team, player, victim );
	pixendevent();
	
	newScore = game["teamScores"][team];
	
	bbPrint( "mpteamscores: gametime %d event %s team %d diff %d score %d", getTime(), event, team, newScore - teamScore, newScore );
	
	if ( teamScore == newScore )
		return;
	
	updateTeamScores( team );

	thread maps\mp\gametypes\_globallogic::checkScoreLimit();
}

_setTeamScore( team, teamScore )
{
	if ( teamScore == game["teamScores"][team] )
		return;

	game["teamScores"][team] = teamScore;
	
	updateTeamScores( team );
	
	thread maps\mp\gametypes\_globallogic::checkScoreLimit();
}

resetTeamScores()
{
	game["teamScores"]["allies"] = 0;
	game["teamScores"]["axis"] = 0;
	maps\mp\gametypes\_globallogic_score::updateTeamScores("allies","axis");
}

resetAllScores()
{
	resetTeamScores();
	resetPlayerScores();
}

resetPlayerScores()
{
	players = level.players;
	winner = undefined;
	tie = false;
	
	for( i = 0; i < players.size; i++ )
	{

		if ( IsDefined( players[i].pers["score"] ) )
			_setPlayerScore( players[i], 0 );
		
	}
}

updateTeamScores( team1, team2 )
{
	setTeamScore( team1, getGameScore( team1 ) );
	level thread maps\mp\gametypes\_globallogic::checkTeamScoreLimitSoon( team1 );
	if ( isdefined( team2 ) )
	{
		setTeamScore( team2, getGameScore( team2 ) );
		level thread maps\mp\gametypes\_globallogic::checkTeamScoreLimitSoon( team2 );
	}
}

_getTeamScore( team )
{
	return game["teamScores"][team];
}

onTeamScore( score, team, player, victim )
{
	otherTeam = level.otherTeam[team];
	
	if ( game["teamScores"][team] > game["teamScores"][otherTeam] )
		level.wasWinning = team;
	else if ( game["teamScores"][otherTeam] > game["teamScores"][team] )
		level.wasWinning = otherTeam;
		
	game["teamScores"][team] += score;

	isWinning = "none";
	if ( game["teamScores"][team] > game["teamScores"][otherTeam] )
		isWinning = team;
	else if ( game["teamScores"][otherTeam] > game["teamScores"][team] )
		isWinning = otherTeam;

	if ( !level.splitScreen && isWinning != "none" && isWinning != level.wasWinning && getTime() - level.lastStatusTime  > 5000 )
	{
		level.lastStatusTime = getTime();
		maps\mp\gametypes\_globallogic_audio::leaderDialog( "lead_taken", isWinning, "status" );
		if ( level.wasWinning != "none")
			maps\mp\gametypes\_globallogic_audio::leaderDialog( "lead_lost", level.wasWinning, "status" );		
	}

	if ( isWinning != "none" )
		level.wasWinning = isWinning;
}


default_onTeamScore( event, team, player, victim )
{
	score = maps\mp\gametypes\_rank::getScoreInfoValue( event );
	
	assert( isDefined( score ) );

	onTeamScore( score, team, player, victim );	
}

initPersStat( dataName, record_stats )
{
	if( !isDefined( self.pers[dataName] ) )
	{
		self.pers[dataName] = 0;
	}
	
	if ( !isdefined(record_stats) || record_stats == true )
	{
		recordPlayerStats( self, dataName, int(self.pers[dataName]) );
	}	
}


getPersStat( dataName )
{
	return self.pers[dataName];
}


incPersStat( dataName, increment, record_stats, includeGametype )
{
	pixbeginevent( "incPersStat" );

	self.pers[dataName] += increment;
	self maps\mp\gametypes\_persistence::statAdd( dataName, increment, includeGametype );
	
	if ( !isdefined(record_stats) || record_stats == true )
	{
		self thread threadedRecordPlayerStats( dataName );
	}

	pixendevent();
}

threadedRecordPlayerStats( dataName )
{
	self endon("disconnect");
	waittillframeend;
	
	recordPlayerStats( self, dataName, self.pers[dataName] );
}

updatePersRatio( ratio, num, denom )
{
	pixbeginevent( "updatePersRatio" );
	numValue = self maps\mp\gametypes\_persistence::statGet( num );
	denomValue = self maps\mp\gametypes\_persistence::statGet( denom );
	if ( denomValue == 0 )
		denomValue = 1;
		
	self maps\mp\gametypes\_persistence::statSet( ratio, int( (numValue * 1000) / denomValue ) );
	
	numValue = self maps\mp\gametypes\_persistence::statGetWithGameType( num );
	denomValue = self maps\mp\gametypes\_persistence::statGetWithGameType( denom );
	if ( denomValue == 0 )
		denomValue = 1;

	self maps\mp\gametypes\_persistence::statSetWithGameType( ratio, int( (numValue * 1000) / denomValue ) );

	if( ratio == "kdratio" && !level.wagerMatch )
	{
		self maps\mp\gametypes\_persistence::setRecentStat( true, 0, "kills", self.kills );
		self maps\mp\gametypes\_persistence::setRecentStat( true, 0, "deaths", self.deaths );
	}
	pixendevent(); // "updatePersRatio"
}

updateWinStats( winner )
{
	winner maps\mp\gametypes\_persistence::statAdd( "losses", -1, true );
	
	println( "setting winner: " + winner maps\mp\gametypes\_persistence::statGet( "wins" ) );
	winner maps\mp\gametypes\_persistence::statAdd( "wins", 1, true );
	winner updatePersRatio( "wlratio", "wins", "losses" );
	
	// restore winstreak, this is set to 0 on connect
	restoreWinStreaks( winner );
	
	// add this win to the winstreak
	winner maps\mp\gametypes\_persistence::statAdd( "cur_win_streak", 1 );
	
	// This notify is used for the contracts system. It allows it to reset a contract's progress on this notify.
	winner notify( "win" );
	
	cur_gamemode_win_streak = winner maps\mp\gametypes\_persistence::statGetWithGameType( "cur_win_streak" );
	gamemode_win_streak = winner maps\mp\gametypes\_persistence::statGetWithGameType( "win_streak" );

	cur_win_streak = winner maps\mp\gametypes\_persistence::statGet( "cur_win_streak" );
	if ( cur_win_streak > winner getDStat( "HighestStats", "win_streak" ) )
	{
		winner setDStat( "HighestStats", "win_streak", cur_win_streak );
	}
	
	if ( cur_gamemode_win_streak > gamemode_win_streak )
	{
		winner maps\mp\gametypes\_persistence::statSetWithGameType( "win_streak", cur_gamemode_win_streak );
	}
	
}

updateLossStats( loser )
{	
	loser maps\mp\gametypes\_persistence::statAdd( "losses", 1, true );
	loser updatePersRatio( "wlratio", "wins", "losses" );
	// This notify is used for the contracts system. It allows it to reset a contract's progress on this notify.
	loser notify( "loss" );
}


updateTieStats( loser )
{	
	loser maps\mp\gametypes\_persistence::statAdd( "losses", -1, true );
	
	loser maps\mp\gametypes\_persistence::statAdd( "ties", 1, true );
	loser updatePersRatio( "wlratio", "wins", "losses" ); 
	loser maps\mp\gametypes\_persistence::statSet( "cur_win_streak", 0 );	
	// This notify is used for the contracts system. It allows it to reset a contract's progress on this notify.
	loser notify( "tie" );
}

updateWinLossStats( winner )
{
	if ( !wasLastRound() && !level.hostForcedEnd )
		return;
		
	players = level.players;

	if ( !isDefined( winner ) || ( isDefined( winner ) && !isPlayer( winner ) && winner == "tie" ) )
	{
		for ( i = 0; i < players.size; i++ )
		{
			if ( !isDefined( players[i].pers["team"] ) )
				continue;

			if ( level.hostForcedEnd && players[i] IsHost() )
				continue;
				
			updateTieStats( players[i] );
		}		
	} 
	else if ( isPlayer( winner ) )
	{
		if ( level.hostForcedEnd && winner IsHost() )
			return;
				
		updateWinStats( winner );
	}
	else
	{
		for ( i = 0; i < players.size; i++ )
		{
			if ( !isDefined( players[i].pers["team"] ) )
				continue;

			if ( level.hostForcedEnd && players[i] IsHost() )
				continue;

			if ( winner == "tie" )
				updateTieStats( players[i] );
			else if ( players[i].pers["team"] == winner )
				updateWinStats( players[i] );
			else
				players[i] maps\mp\gametypes\_persistence::statSet( "cur_win_streak", 0 );	

		}
	}
}

// self is the player
backupAndClearWinStreaks()
{
	// Global
	self.pers[ "winStreak" ] = maps\mp\gametypes\_persistence::statGet( "cur_win_streak" );
	self maps\mp\gametypes\_persistence::statSet( "cur_win_streak", 0 );	
	
	// Gametype
	self.pers[ "winStreakForGametype" ] = maps\mp\gametypes\_persistence::statGetWithGameType( "cur_win_streak" ); 
	self maps\mp\gametypes\_persistence::statSetWithGameType( "cur_win_streak", 0 );
}

restoreWinStreaks( winner )
{
	// Global
	winner maps\mp\gametypes\_persistence::statSet( "cur_win_streak", winner.pers[ "winStreak" ] );
	
	// Gametype
	winner maps\mp\gametypes\_persistence::statSetWithGameType( "cur_win_streak", winner.pers[ "winStreakForGametype" ] );
}

getGameScore( team )
{
	return game["teamScores"][team];
}


incKillstreakTracker( sWeapon )
{
	self endon("disconnect");
	
	waittillframeend;
	
	if( sWeapon == "artillery_mp" )
		self.pers["artillery_kills"]++;
	
	if( sWeapon == "dog_bite_mp" )
		self.pers["dog_kills"]++;
}

trackLeaderBoardDeathStats( sWeapon, sMeansOfDeath )
{
	self thread threadedSetWeaponStatByName( sWeapon, 1, "deaths" );
}

trackLeaderBoardDeathsDuringUseStats( sWeapon )
{
	self thread threadedSetWeaponStatByName( sWeapon, 1, "deathsDuringUse" );
}

trackAttackerLeaderBoardDeathStats( sWeapon, sMeansOfDeath )
{
	if ( isdefined( self ) && isplayer( self ) )
	{
		if ( sMeansOfDeath != "MOD_FALLING" )
		{
			self thread threadedSetWeaponStatByName( sWeapon, 1, "kills" );
		}
		
		if ( sMeansOfDeath == "MOD_HEAD_SHOT" )
		{
			self thread threadedSetWeaponStatByName( sWeapon, 1, "headshots" );
		}
	}
}

trackAttackerKill( name, rank, xp, prestige, xuid )
{
	self endon("disconnect");
	attacker = self;
	
	waittillframeend;

	pixbeginevent("trackAttackerKill");
	
	if ( !isDefined( attacker.pers["killed_players"][name] ) )
		attacker.pers["killed_players"][name] = 0;

	if ( !isDefined( attacker.killedPlayersCurrent[name] ) )
		attacker.killedPlayersCurrent[name] = 0;

	if ( !isDefined( attacker.pers["nemesis_tracking"][name] ) )
		attacker.pers["nemesis_tracking"][name] = 0;

	attacker.pers["killed_players"][name]++;
	attacker.killedPlayersCurrent[name]++;
	attacker.pers["nemesis_tracking"][name] += 1.0;

	if( attacker.pers["nemesis_name"] == "" || attacker.pers["nemesis_tracking"][name] > attacker.pers["nemesis_tracking"][attacker.pers["nemesis_name"]] )
	{
		attacker.pers["nemesis_name"] = name;
		attacker.pers["nemesis_rank"] = rank;
		attacker.pers["nemesis_rankIcon"] = prestige;
		attacker.pers["nemesis_xp"] = xp;
		attacker.pers["nemesis_xuid"] = xuid;
	}
	else if( isDefined( attacker.pers["nemesis_name"] ) && ( attacker.pers["nemesis_name"] == name ) )
	{
		attacker.pers["nemesis_rank"] = rank;
		attacker.pers["nemesis_xp"] = xp;
	}
	
	pixendevent();
}

trackAttackeeDeath( attackerName, rank, xp, prestige, xuid )
{
	self endon("disconnect");

	waittillframeend;

	pixbeginevent("trackAttackeeDeath");

	if ( !isDefined( self.pers["killed_by"][attackerName] ) )
		self.pers["killed_by"][attackerName] = 0;

		self.pers["killed_by"][attackerName]++;

	if ( !isDefined( self.pers["nemesis_tracking"][attackerName] ) )
		self.pers["nemesis_tracking"][attackerName] = 0;
   
	self.pers["nemesis_tracking"][attackerName] += 1.5;

	if( self.pers["nemesis_name"] == "" || self.pers["nemesis_tracking"][attackerName] > self.pers["nemesis_tracking"][self.pers["nemesis_name"]] )
	{
		self.pers["nemesis_name"] = attackerName;
		self.pers["nemesis_rank"] = rank;
		self.pers["nemesis_rankIcon"] = prestige;
		self.pers["nemesis_xp"] = xp;
		self.pers["nemesis_xuid"] =xuid;
	}
	else if( isDefined( self.pers["nemesis_name"] ) && ( self.pers["nemesis_name"] == attackerName ) )
	{
		self.pers["nemesis_rank"] = rank;
		self.pers["nemesis_xp"] = xp;
	}
	
	//Nemesis Killcam - ( hopefully even with the wait it gets there with enough time not to cause a flicker)
	if( self.pers["nemesis_name"] == attackerName && self.pers["nemesis_tracking"][attackerName] >= 2 )
		self setClientUIVisibilityFlag( "killcam_nemesis", 1 );
	else
		self setClientUIVisibilityFlag( "killcam_nemesis", 0 );

	pixendevent();
}

default_isKillBoosting()
{
	return false;
}

giveKillStats( sMeansOfDeath, sWeapon, eVictim )
{
	self endon("disconnect");
	
	waittillframeend;

	if ( !GetDvarInt( #"xblive_privatematch" ) && self [[level.isKillBoosting]]() )	
	{
		return;
	}
		
	pixbeginevent("giveKillXP");
	
	self maps\mp\gametypes\_globallogic_score::incPersStat( "kills", 1, true, true );
	self.kills = self maps\mp\gametypes\_globallogic_score::getPersStat( "kills" );
	self maps\mp\gametypes\_globallogic_score::updatePersRatio( "kdratio", "kills", "deaths" );

	attacker = self;
	if ( sMeansOfDeath == "MOD_HEAD_SHOT" && !maps\mp\gametypes\_hardpoints::isKillstreakWeapon( sWeapon )  )
	{
		attacker thread incPersStat( "headshots", 1 , true, false );
		attacker.headshots = attacker.pers["headshots"];
	
		if ( !isdefined( eVictim.laststandparams ) ) 
		{
			attacker maps\mp\_medals::headshot( sWeapon );
		}
	
		attacker thread maps\mp\gametypes\_rank::giveRankXP( "headshot" );
	}
	attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill" );
	
	pixendevent();
}

incTotalKills( team )
{
	if ( level.teambased && (team == "allies" || team == "axis") )
	{
		game["totalKillsTeam"][team]++;				
	}	
	
	game["totalKills"]++;			
}

incItemStatByReference( reference, incValue, statName )
{
	if ( level.wagerMatch )
		return;
	
	itemIndex = maps\mp\gametypes\_rank::getItemIndex( reference );
	self incItemStatByIndex( itemIndex, incValue, statName );
	level thread maps\mp\gametypes\_persistence::updateGlobalCounterStats( reference, incValue, statName );
}

incItemStatByIndex( itemIndex, incValue, statName )
{
	if ( !incValue || !level.rankedMatch || level.wagerMatch )
	{
		return;
	}
	
	self maps\mp\gametypes\_persistence::checkWeaponMilestoneComplete( itemIndex, statName, incValue );
}
	
setAttachmentStat( name, incValue, statName )
{
	if ( !incValue || !level.rankedMatch || level.wagerMatch )
	{
		return;
	}
	
	isKill = false;

	if ( statName == "kills" )
	{
			isKill = true;
	}
	
	if ( isDefined( self.currentWeapon ) && ( isKill || statName == "shots" || statName == "hits" || statName == "headshots" ) )
	{
		if ( self.currentWeapon == name )
		{
			if ( !isDefined( self.currentAttachments ) )
			{
				return;
			}
			
			numAttachments = self.currentAttachments.size;
			
			if ( !numAttachments )
			{
				return;
			}
			
			for ( currentAttachment = 0; currentAttachment< numAttachments; currentAttachment++ )
			{
				attachmentName = self.currentAttachments[ currentAttachment ][ "name" ];
				
				if ( ( !isDefined( self.currentAttachments[ currentAttachment ][ "owned" ] ) ) || ( !self.currentAttachments[ currentAttachment ][ "owned" ] ) )
				{
					continue;
				}

				if ( isKill && ( self.currentAttachments[ currentAttachment ][ "point" ] == "top" ) && ( self playerADS() != 1 ) )
				{
					continue;	
				}
				if ( self.currentAttachments[ currentAttachment ][ "point" ] == "bottom" && attachmentname != "grip" )
				{
					continue;	
				}

				self maps\mp\gametypes\_persistence::checkGroupChallengeComplete( "Attachments", attachmentName, statName, incValue, "statValue", "currentMilestone", "attachment", "lifetime_" );
				self maps\mp\gametypes\_persistence::checkGroupChallengeComplete( "Attachments", attachmentName, statName, incValue, "challengeValue", "challengeTier", "attachment" );
			}
		}
	}
}

setWeaponStat( name, incValue, statName )
{
	if ( incValue && statName == "kills" && maps\mp\_medals::isMedal( name + "_kills" ) )
		self thread maps\mp\_medals::giveMedal( name + "_kills"  );

	level thread maps\mp\gametypes\_persistence::updateGlobalCounterStats( name, incValue, statName );

	if ( !incValue )
		return;
		
	if ( level.wagerMatch )
	{
		self maps\mp\gametypes\_wager::trackWagerWeaponUsage( name, incValue, statName );
		return;
	}
		
	if ( !level.rankedMatch )
	{
		return;
	}
	
	pixbeginevent("setWeaponStat");
	if ( isDefined( self.currentWeapon ) && ( self.currentWeapon == name ) )
	{
		weaponItemIndex = self.currWeaponItemIndex;
		setAttachmentStat( name, incValue, statName );
	}
	else
	{
		weaponItemIndex = getBaseWeaponItemIndex( name );
	}
	
	if ( weaponItemIndex )
	{
		contractsToProcess = self maps\mp\gametypes\_persistence::getContractsToProcess( "weapon", toLower( statName ) );
		if ( contractsToProcess.size )
			self maps\mp\gametypes\_persistence::processContracts( contractsToProcess, "weapon", statName, incValue, name );
		incItemStatByIndex( weaponItemIndex, incValue, statName );
	}
	pixendevent();
}

setInflictorStat( eInflictor, eAttacker, sWeapon )
{
	if ( !isDefined( eAttacker ) )
		return;

	if ( !isDefined( eInflictor ) )
	{
		eAttacker setWeaponStat( sWeapon, 1, "hits" );
		return;
	}

	if ( !isDefined( eInflictor.playerAffectedArray ) )
		eInflictor.playerAffectedArray = [];

	foundNewPlayer = true;
	for ( i = 0 ; i < eInflictor.playerAffectedArray.size ; i++ )
	{
		if ( eInflictor.playerAffectedArray[i] == self )
		{
			foundNewPlayer = false;
			break;
		}
	}

	if ( foundNewPlayer )
	{
		eInflictor.playerAffectedArray[eInflictor.playerAffectedArray.size] = self;
		if( sWeapon == "concussion_grenade_mp" || sWeapon == "tabun_gas_mp" )
		{
			eAttacker setWeaponStat( sWeapon, 1, "used" );
		}
		eAttacker setWeaponStat( sWeapon, 1, "hits" );
	}
}

threadedSetWeaponStatByName( name, incValue, statName )
{
	self endon("disconnect");
	waittillframeend;
	
	setWeaponStat( name, incValue, statName );
}

processAssist( killedplayer, damagedone )
{
	self endon("disconnect");
	killedplayer endon("disconnect");
	
	wait .05; // don't ever run on the same frame as the playerkilled callback.
	maps\mp\gametypes\_globallogic_utils::WaitTillSlowProcessAllowed();
	
	if ( self.pers["team"] != "axis" && self.pers["team"] != "allies" )
		return;
	
	if ( self.pers["team"] == killedplayer.pers["team"] )
		return;

	if ( !level.teambased )
		return;
	
	assist_level = "assist";
	
	assist_level_value = int( floor( damagedone / 25 ) );
	
	if ( assist_level_value > 0 )
	{
		if ( assist_level_value > 3 )
		{
			assist_level_value = 3;
		}
		assist_level = assist_level + "_" + ( assist_level_value * 25 );
	}
	
	self thread [[level.onXPEvent]]( assist_level );
	self thread maps\mp\_medals::assisted();
	self maps\mp\gametypes\_globallogic_score::incPersStat( "assists", 1 );
	self maps\mp\gametypes\_persistence::statAddWithGameType( "ASSISTS", 1 );

	self.assists = self  maps\mp\gametypes\_globallogic_score::getPersStat( "assists" );
	
	if( maps\mp\gametypes\_customClasses::isCustomGame() )
	{
		customAssistAmt = getDvarInt( "scr_custom_score_assist" );
		if( customAssistAmt != -1 ) // -1 is default scoring
		{
			_setPlayerScore( self, self.pers["score"] + customAssistAmt );
			onTeamScore( customAssistAmt, self.team, self, undefined );
			updateTeamScores( self.team );
		}
		else 
		{
			givePlayerScore( assist_level, self, killedplayer );
		}
	}
	else
	{
		givePlayerScore( assist_level, self, killedplayer );
	}
	self thread maps\mp\gametypes\_missions::playerAssist();
}


/#
xpRateThread()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );

	while ( level.inPrematchPeriod )
		wait ( 0.05 );

	for ( ;; )
	{
		wait ( 5.0 );
		if ( level.players[0].pers["team"] == "allies" || level.players[0].pers["team"] == "axis" )
			self maps\mp\gametypes\_rank::giveRankXP( "kill", int(min( GetDvarInt( #"scr_xprate" ), 50 )) );
	}
}
#/

logXPGains()
{
	if ( !isDefined( self.xpGains ) )
		return;

	xpTypes = getArrayKeys( self.xpGains );
	for ( index = 0; index < xpTypes.size; index++ )
	{
		gain = self.xpGains[xpTypes[index]];
		if ( !gain )
			continue;
			
		self logString( "xp " + xpTypes[index] + ": " + gain );
	}
}

