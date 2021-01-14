#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
init()
{
	level.classMap["smg_mp"] = "CLASS_SMG";
	level.classMap["cqb_mp"] = "CLASS_CQB";	
	level.classMap["assault_mp"] = "CLASS_ASSAULT";
	level.classMap["lmg_mp"] = "CLASS_LMG";
	level.classMap["sniper_mp"] = "CLASS_SNIPER";
	level.classMap["offline_class1_mp"] = "OFFLINE_CLASS1";
	level.classMap["offline_class2_mp"] = "OFFLINE_CLASS2";
	level.classMap["offline_class3_mp"] = "OFFLINE_CLASS3";
	level.classMap["offline_class4_mp"] = "OFFLINE_CLASS4";
	level.classMap["offline_class5_mp"] = "OFFLINE_CLASS5";
	level.classMap["offline_class6_mp"] = "OFFLINE_CLASS6";
	level.classMap["offline_class7_mp"] = "OFFLINE_CLASS7";
	level.classMap["offline_class8_mp"] = "OFFLINE_CLASS8";
	level.classMap["offline_class9_mp"] = "OFFLINE_CLASS9";
	level.classMap["offline_class10_mp"] = "OFFLINE_CLASS10";	
	
	
	
	
	
	level.classMap["custom1"] = "CLASS_CUSTOM1";
	level.classMap["custom2"] = "CLASS_CUSTOM2";
	level.classMap["custom3"] = "CLASS_CUSTOM3";
	level.classMap["custom4"] = "CLASS_CUSTOM4";
	level.classMap["custom5"] = "CLASS_CUSTOM5";
	level.classMap["prestige1"] = "CLASS_CUSTOM6";
	level.classMap["prestige2"] = "CLASS_CUSTOM7";
	level.classMap["prestige3"] = "CLASS_CUSTOM8";
	level.classMap["prestige4"] = "CLASS_CUSTOM9";
	level.classMap["prestige5"] = "CLASS_CUSTOM10";
	level.PrestigeNumber = 5;
	
	level.defaultClass = "CLASS_ASSAULT";
	
	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "weapon", "allowfrag" ) )
		level.weapons["frag"] = "frag_grenade_mp";
	else	
		level.weapons["frag"] = "";
	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "weapon", "allowsmoke" ) )
		level.weapons["smoke"] = "smoke_grenade_mp";
	else	
		level.weapons["smoke"] = "";
	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "weapon", "allowflash" ) )
		level.weapons["flash"] = "flash_grenade_mp";
	else	
		level.weapons["flash"] = "";
	level.weapons["concussion"] = "concussion_grenade_mp";
	
	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "weapon", "allowsatchel" ) )
		level.weapons["satchel_charge"] = "satchel_charge_mp";
	else	
		level.weapons["satchel_charge"] = "";
	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "weapon", "allowbetty" ) )
		level.weapons["betty"] = "mine_bouncing_betty_mp";
	else	
		level.weapons["betty"] = "";
	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "weapon", "allowrpgs" ) )
	{
		level.weapons["rpg"] = "rpg_mp";
	}
	else	
	{
		level.weapons["rpg"] = "";
	}
	
	create_class_exclusion_list();
	
	
	cac_init();	
	
	load_default_loadout( "CLASS_SMG", 210 );
	load_default_loadout( "CLASS_CQB", 230 );
	load_default_loadout( "CLASS_ASSAULT", 200 );	
	load_default_loadout( "CLASS_LMG", 220 );
	load_default_loadout( "CLASS_SNIPER", 240 );
	
	
	level.primary_weapon_array = [];
	level.side_arm_array = [];
	level.grenade_array = [];
	level.inventory_array = [];
	max_weapon_num = 99;
	for( i = 0; i < max_weapon_num; i++ )
	{
		if( !isdefined( level.tbl_weaponIDs[i] ) || level.tbl_weaponIDs[i]["group"] == "" )
			continue;
		if( !isdefined( level.tbl_weaponIDs[i] ) || level.tbl_weaponIDs[i]["reference"] == "" )
			continue;		
	
		
		weapon_type = level.tbl_weaponIDs[i]["group"]; 
		weapon = level.tbl_weaponIDs[i]["reference"]; 
		attachment = level.tbl_weaponIDs[i]["attachment"]; 
	
		weapon_class_register( weapon+"_mp", weapon_type );	
	
		if( isdefined( attachment ) && attachment != "" )
		{	
			attachment_tokens = strtok( attachment, " " );
			if( isdefined( attachment_tokens ) )
			{
				if( attachment_tokens.size == 0 )
					weapon_class_register( weapon+"_"+attachment+"_mp", weapon_type );	
				else
				{
					
					for( k = 0; k < attachment_tokens.size; k++ )
						weapon_class_register( weapon+"_"+attachment_tokens[k]+"_mp", weapon_type );
				}
			}
		}
	}
	
	precacheShader( "waypoint_bombsquad" );
	precacheShader( "waypoint_second_chance" );
	
	level thread onPlayerConnecting();
	
}
create_class_exclusion_list()
{
	currentDvar = 0;
	
	level.itemExclusions = [];
	
	while( GetDvarInt( "item_exclusion_" + currentDvar ) )
	{
		level.itemExclusions[ currentDvar ] = GetDvarInt( "item_exclusion_" + currentDvar );
		currentDvar++;
	}
	
	level.attachmentExclusions = [];
	
	currentDvar = 0;
	while( GetDvar( "attachment_exclusion_" + currentDvar ) !="" )
	{
		level.attachmentExclusions[ currentDvar ] = GetDvar( "attachment_exclusion_" + currentDvar );
		currentDvar++;
	}
}
is_item_excluded( itemIndex )
{
	numExclusions = level.itemExclusions.size;
	
	for ( exclusionIndex = 0; exclusionIndex < numExclusions; exclusionIndex++ )
	{
		if ( itemIndex == level.itemExclusions[ exclusionIndex ] )
		{
			return true;
		}
	}
	
	return false;
}
is_attachment_excluded( attachment )
{
	numExclusions = level.attachmentExclusions.size;
	
	for ( exclusionIndex = 0; exclusionIndex < numExclusions; exclusionIndex++ )
	{
		if ( attachment == level.attachmentExclusions[ exclusionIndex ] )
		{
			return true;
		}
	}
	
	return false;
}
load_default_loadout( class, stat_num )
{
		
		load_default_loadout_raw( "allies", class, stat_num );
		load_default_loadout_raw( "axis", class, stat_num );
}
get_item_count( itemReference )
{
	itemCount = int( tableLookup( "mp/statsTable.csv", level.cac_creference, itemReference, level.cac_ccount ) );
	if ( itemCount < 1 )
	{
		itemCount = 1;
	} 
	
	return itemCount;
}
getDefaultClassSlotWithExclusions( className, slotName )
{
	itemReference = GetDefaultClassSlot( className, slotName );
	
	itemIndex = int( tableLookup( "mp/statsTable.csv", level.cac_creference, itemReference, level.cac_numbering ) );
	
	if ( is_item_excluded( itemIndex ) )
	{
		itemReference = tableLookup( "mp/statsTable.csv", level.cac_numbering, 0, level.cac_creference );
	}
	
	return itemReference;
}
	
load_default_loadout_raw( team, class, stat_num )
{
	
	level.classWeapons[team][class][0] = getDefaultClassSlotWithExclusions( class, "primary" ) + "_mp";
	
	
	
	
	level.classSidearm[team][class] = getDefaultClassSlotWithExclusions( class, "secondary" ) + "_mp";
	
	
	primaryGrenadeRef = getDefaultClassSlotWithExclusions( class, "primarygrenade" );
	level.classGrenades[class]["primary"]["type"] = primaryGrenadeRef + "_mp";
	level.classGrenades[class]["primary"]["count"] = get_item_count( primaryGrenadeRef );
	
	secondaryGrenadeRef = getDefaultClassSlotWithExclusions( class, "specialgrenade" );
	level.classGrenades[class]["secondary"]["type"] = secondaryGrenadeRef + "_mp";
	level.classGrenades[class]["secondary"]["count"] = get_item_count( secondaryGrenadeRef );
	equipmentRef = getDefaultClassSlotWithExclusions( class, "equipment" );
	level.default_equipment[ class ][ "type" ] = equipmentRef + "_mp";
	level.default_equipment[ class ][ "count" ] = get_item_count( secondaryGrenadeRef );
	
	level.default_perk[class] = [];	
	if ( GetDvarInt( #"scr_game_perks" ) )
	{
		currentSpecialty = 0;
		for ( numSpecialties = 0; numSpecialties < 3; numSpecialties++ )
		{
			
			perkRef = getDefaultClassSlotWithExclusions( class, "specialty" + ( numSpecialties + 1 ) );
			
			if ( perkRef == "weapon_null" )
			{	
				level.default_perk[class][currentSpecialty] = "specialty_null";
			}
			else
			{
				specialty = level.perkReferenceToIndex[ perkRef ];
				
				specialties[currentSpecialty] = validatePerk( specialty, currentSpecialty );
				storeDefaultSpecialtyData( class, specialties[currentSpecialty] );
				level.default_perkIcon[class][ currentSpecialty ] = level.tbl_PerkData[ specialty ][ "reference_full" ];
				currentSpecialty++;
			}
		}
	}
	else
	{
		level.default_perk[class][0] = "specialty_null";
		level.default_perk[class][1] = "specialty_null";
	
		level.classGrenades[class]["primary"]["count"] = 1;
		level.classGrenades[class]["secondary"]["count"] = 1;
	}	
	
	level.classItem[team][class]["type"] = "";
	level.classItem[team][class]["count"] = 0;
	
	level.default_armor[class] = [];
	level.default_armor[class]["body"] = getDefaultClassSlotWithExclusions( class, "body" );
	level.default_armor[class]["head"] = getDefaultClassSlotWithExclusions( class, "head" );
	
}
			
weapon_class_register( weapon, weapon_type )
{
	if( isSubstr( "weapon_smg weapon_cqb weapon_assault weapon_lmg weapon_sniper weapon_shotgun weapon_launcher weapon_special", weapon_type ) )
		level.primary_weapon_array[weapon] = 1;	
	else if( isSubstr( "weapon_pistol", weapon_type ) )
		level.side_arm_array[weapon] = 1;
	else if( weapon_type == "weapon_grenade" )
		level.grenade_array[weapon] = 1;
	else if( weapon_type == "weapon_explosive" )
		level.inventory_array[weapon] = 1;
	else if( weapon_type == "weapon_rifle" ) 
		level.inventory_array[weapon] = 1;
	else
		assertex( false, "Weapon group info is missing from statsTable for: " + weapon_type );
}
cac_init()
{
	
	level.cac_size = 5;
	
	level.cac_max_item = 256;
	
	
	level.cac_numbering = 0;	
	level.cac_cstat = 1;		
	level.cac_cgroup = 2;		
	level.cac_cname = 3;		
	level.cac_creference = 4;	
	level.cac_ccount = 5;		
	level.cac_cimage = 6;		
	level.cac_cdesc = 7;		
	level.cac_cstring = 8;		
	level.cac_cint = 9;			
	level.cac_cunlock = 10;		
	level.cac_cint2 = 11;		
	level.cac_cost = 12; 
	level.cac_slot = 13; 
	level.cac_classified = 15;	
	
	for( i=0; i<13; i++ )
	{
		level.tbl_WeaponAttachment[i]["reference"] = tableLookup( "mp/attachmentTable.csv", 9, i, 4 );
	}
	
	level.tbl_weaponIDs = [];
	for( i = 0; i < level.cac_max_item; i++ )
	{
		itemRow = tableLookupRowNum( "mp/statsTable.csv", level.cac_numbering, i );
		
		if ( itemRow > -1 )
		{
			group_s = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cgroup );
			
			if ( isSubStr( group_s, "weapon_" ) )
			{
				reference_s = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_creference );
				if( reference_s != "" )
				{ 
					level.tbl_weaponIDs[i]["reference"] = reference_s;
					level.tbl_weaponIDs[i]["group"] = group_s;
					level.tbl_weaponIDs[i]["count"] = int( tableLookupColumnForRow( "mp/statstable.csv", itemRow, level.cac_ccount ) );
					level.tbl_weaponIDs[i]["attachment"] = tableLookupColumnForRow( "mp/statstable.csv", itemRow, level.cac_cstring );
					level.tbl_weaponIDs[i]["slot"] = tablelookup( "mp/statstable.csv", 0, i, level.cac_slot );	
					level.tbl_weaponIDs[i]["cost"] = tablelookup( "mp/statstable.csv", 0, i, level.cac_cost );	
					level.tbl_weaponIDs[i]["unlock_level"] = tablelookup( "mp/statstable.csv", 0, i, level.cac_cunlock );
					level.tbl_weaponIDs[i]["classified"] = int( tablelookup( "mp/statstable.csv", 0, i, level.cac_classified ) );
				}
			}
		}
	}
	
	for( i = 0; i < level.cac_max_item; i++ )
	{
		itemRow = tableLookupRowNum( "mp/statsTable.csv", level.cac_numbering, i );
		
		if ( itemRow > -1 )
		{
			group_s = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cgroup );
				
			if ( ( group_s == "body" ) || ( group_s == "head" ) )
			{
				if ( !isDefined( level.armor_index_start ) )
				{
					level.armor_index_start = i; 
					level.armor_index_end = i;
				}
				else if ( i > level.armor_index_end )
				{
					level.armor_index_end = i;
				}
				
				item = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_creference );
				if ( item != "" )
				{
					level.tbl_armor[i] = item;
				}
			}
		}
	}
	level.perkReferenceToIndex = [];
	
	level.perkNames = [];
	level.perkIcons = [];
	level.PerkData = [];
	
	level.allowedPerks[0] = [];
	level.allowedPerks[1] = [];
	level.allowedPerks[2] = [];
	level.allowedPerks[3] = [];
	
	for( i = 0; i < level.cac_max_item; i++ )
	{
		itemRow = tableLookupRowNum( "mp/statsTable.csv", level.cac_numbering, i );
		
		if ( itemRow > -1 )
		{
			group_s = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cgroup );
		
			if ( ( group_s == "specialty" ) || ( group_s == "deathstreak" ) )
			{
				reference_s = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_creference );
				
				if( reference_s != "" )
				{
					level.tbl_PerkData[i]["reference"] = reference_s;
					level.tbl_PerkData[i]["reference_full"] = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cimage );
					level.tbl_PerkData[i]["count"] = int( tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_ccount ) );
					level.tbl_PerkData[i]["cost"] = int( tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cost ) );
					level.tbl_PerkData[i]["group"] = group_s;
					level.tbl_PerkData[i]["name"] = tableLookupIString( "mp/statsTable.csv", level.cac_numbering, i, level.cac_cname );
					level.tbl_PerkData[i]["slot"] = tablelookup( "mp/statstable.csv", 0, i, level.cac_slot );	
					precacheString( level.tbl_PerkData[i]["name"] );
					
					level.perkReferenceToIndex[ level.tbl_PerkData[i]["reference"] ] = i;
					
					cost = int( tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cost ) );
		
					if( cost >= 0 )
					{
						if( level.tbl_PerkData[i]["group"] == "specialty" )
						{
							level.allowedPerks[0][ level.allowedPerks[0].size ] = i;
							level.allowedPerks[1][ level.allowedPerks[1].size ] = i;
							level.allowedPerks[2][ level.allowedPerks[2].size ] = i;
						}
						else if( level.tbl_PerkData[i]["group"] == "deathstreak" )
						{
							level.allowedPerks[3][ level.allowedPerks[3].size ] = i;
						}
					}
					
					level.perkNames[level.tbl_PerkData[i]["reference_full"]] = level.tbl_PerkData[i]["name"];
					level.perkIcons[level.tbl_PerkData[i]["reference_full"]] = level.tbl_PerkData[i]["reference_full"];
					precacheShader( level.perkIcons[level.tbl_PerkData[i]["reference_full"]] );
				}
			}
		}
	}
	
	killStreakReferenceToIndex = [];
	
	level.killStreakNames = [];
	level.killStreakIcons = [];
	level.KillStreakData = [];
	level.killStreakBaseValue = 202;
	
	level.allowedKillStreak[0] = [];
	level.allowedKillStreak[1] = [];
	level.allowedKillStreak[2] = [];
	level.allowedKillStreak[3] = [];
	level.allowedKillStreak[4] = [];
	for( i = 0; i < 5; i++ )
	{
		level.allowedKillStreak[i][0] = level.killStreakBaseValue; 
	}
	j = 1;
	
	level.killStreakBaseValue = undefined;
	level.totalKillStreaks = 0;
	
	for( i = 0; i < level.cac_max_item; i++ )
	{
		itemRow = tableLookupRowNum( "mp/statsTable.csv", level.cac_numbering, i );
		
		if ( itemRow > -1 )
		{
			group_s = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cgroup );
			
			if ( group_s == "killstreak" )
			{
				reference_s = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_creference );
				
				if( reference_s != "" )
				{
					if ( !isDefined( level.killStreakBaseValue ) )
					{
						level.killStreakBaseValue = i;
					}
					level.totalKillStreaks++;
					
					level.tbl_KillStreakData[i]["reference"] = reference_s;
					level.tbl_KillStreakData[i]["tableNumber"] = i ;
					level.tbl_KillStreakData[i]["icon"] = tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cimage );
					level.tbl_KillStreakData[i]["name"] = tableLookupIString( "mp/statsTable.csv", level.cac_numbering, i, level.cac_cname );
					precacheString( level.tbl_KillStreakData[i]["name"] );
	
					killStreakReferenceToIndex[ level.tbl_KillStreakData[i]["reference"] ] = i;
		
					cost = int( tableLookupColumnForRow( "mp/statsTable.csv", itemRow, level.cac_cost ) );
		
					if( cost >= 0 )
					{
						level.allowedKillStreak[0][j] = i;
						level.allowedKillStreak[1][j] = i;
						level.allowedKillStreak[2][j] = i;
						j++;
					}
					
					level.killStreakNames[level.tbl_KillStreakData[i]["reference"]] = level.tbl_KillStreakData[i]["name"];
					level.killStreakIcons[level.tbl_KillStreakData[i]["reference"]] = level.tbl_KillStreakData[i]["icon"];
					precacheShader( level.killStreakIcons[level.tbl_KillStreakData[i]["reference"]] );
					precacheShader( level.killStreakIcons[level.tbl_KillStreakData[i]["reference"]] + "_drop" );
				}
			}
		}
	}
}
getClassChoice( response )
{
	tokens = strtok( response, "," );
	
	assert( isDefined( level.classMap[tokens[0]] ) );
	
	return ( level.classMap[tokens[0]] );
}
getWeaponChoice( response )
{
	tokens = strtok( response, "," );
	if ( tokens.size > 1 )
		return int(tokens[1]);
	else
		return 0;
}
cac_getdata( )
{
	if ( isDefined( self.cac_initialized ) )
		return;
	
	getCacDataGroup( 0, 5 );
	
	if( level.onlineGame )
		getCacDataGroup( 5, 10 );
}
getLoadoutItemFromDDLStats( customClassNum, loadoutSlot )
{
	if ( customClassNum < 5 )
	{
		classBaseName = "customclass";
	}
	else
	{
		classBaseName = "prestigeclass";
		customClassNum = customClassNum - 5;
	}
	if ( !level.onlineGame )
	{
		return( self GetLoadoutItemFromProfile( classBaseName + ( customClassNum + 1 ), loadoutSlot ) );
	}
	
	itemIndex = ( self getdstat( "CacLoadouts", classBaseName + ( customClassNum + 1 ), loadoutSlot ) );
	
	if ( is_item_excluded( itemIndex ) && !is_warlord_perk( itemIndex ) )
	{
		return 0;
	}
	
	return itemIndex;
}
getAttachmentString( weaponNum, attachmentNum )
{
	attachmentString = GetItemAttachment( weaponNum, attachmentNum );
	
	if ( attachmentString != "none" && ( !is_attachment_excluded( attachmentString ) ) )
	{
		attachmentString = attachmentString + "_";
	}
	else
	{
		attachmentString = "";
	}
	
	return attachmentString;
}
getFullWeaponName( customClassNum, weaponSlot, attachmentsDisabled ) 
{
	assertex( ( ( weaponSlot == "primary" ) || ( weaponSlot == "secondary" ) ), "weaponSlot should be primary or secondary" );
	
	weaponName = "weapon_null";
	
	if ( ( weaponSlot == "primary" ) || ( weaponSlot == "secondary" ) )
	{
		weaponNum = getLoadoutItemFromDDLStats ( customClassNum, weaponSlot );
		
		if ( weaponSlot == "primary" )
		{
			weaponIndex = 3;
			assert( level.tbl_weaponIDs[weaponIndex]["reference"] == "m1911" );
			
			if ( weaponNum < 0 || !isDefined( level.tbl_weaponIDs[ weaponNum ] ) )
			{
					weaponNum = weaponIndex;
			}
		}
		
		if ( isDefined( level.tbl_weaponIDs[ weaponNum ] ) )
		{
			attachmenttop = getLoadoutItemFromDDLStats ( customClassNum, weaponSlot + "attachmenttop" );
			attachmentbottom = getLoadoutItemFromDDLStats ( customClassNum, weaponSlot + "attachmentbottom" );
			attachmenttrigger = getLoadoutItemFromDDLStats ( customClassNum, weaponSlot + "attachmenttrigger" );
			attachmentmuzzle = getLoadoutItemFromDDLStats ( customClassNum, weaponSlot + "attachmentmuzzle" );
			
			topName = getAttachmentString( weaponNum, attachmenttop );
			bottomName = getAttachmentString( weaponNum, attachmentbottom );
			triggerName = getAttachmentString( weaponNum, attachmenttrigger );
			muzzleName = getAttachmentString( weaponNum, attachmentmuzzle );
			
			weaponPrefix = level.tbl_weaponIDs[ weaponNum ][ "reference" ];
			
			if ( attachmentsDisabled )
			{
				weaponName = weaponPrefix + "_mp";
			}
			else if ( bottomName == "dw_" )
			{
				weaponName = weaponPrefix + bottomName + topName + triggerName + muzzleName + "mp";
			}
			else
			{
				weaponName = weaponPrefix + "_" + topName +	bottomName + triggerName + muzzleName + "mp";
			}
		}
	}
	
	return weaponName;
}
getKillStreakNum( killstreakName )
{
	if ( level.onlineGame )
	{
		return( self getdstat( "cacLoadouts", killstreakName ) );
	}
	else
	{
		return( self GetLoadoutItemFromProfile( "", killstreakName ) );
	}
}
setKillstreaks()
{
		killstreak1 = self getKillStreakNum( "killstreak1" );
		killstreak2 = self getKillStreakNum( "killstreak2" );
		killstreak3 = self getKillStreakNum( "killstreak3" );
		
		if( getDvarInt( "custom_killstreak_mode" ) == 2 )
		{
			killstreak1 = 0;
			killstreak2 = 0;
			killstreak3 = 0;
			if( getDvarInt( "custom_killstreak_1" ) )
			{
				killstreak1 = getDvarInt( "custom_killstreak_1" );
			}
			if( getDvarInt( "custom_killstreak_2" ) )
			{
				killstreak2 = getDvarInt( "custom_killstreak_2" );
			}
			if( getDvarInt( "custom_killstreak_3" ) )
			{
				killstreak3 = getDvarInt( "custom_killstreak_3" );
			}
		}
		
		killstreak1 = validateKillStreak( killstreak1, 0 );
		killstreak2 = validateKillStreak( killstreak2, 1 );
		killstreak3 = validateKillStreak( killstreak3, 2 );
		
		
		self.killstreak = [];
		
		assertex( isdefined( level.tbl_KillStreakData[killstreak1] ), "KillStreak #:"+killstreak1+"'s data is undefined" );
		self.killstreak[ 0 ] = level.tbl_KillStreakData[killstreak1]["reference"]; 
		assertex( isdefined( level.tbl_KillStreakData[killstreak2] ), "KillStreak #:"+killstreak2+"'s data is undefined" );
		self.killstreak[ 1 ] = level.tbl_KillStreakData[killstreak2]["reference"]; 
		assertex( isdefined( level.tbl_KillStreakData[killstreak3] ), "KillStreak #:"+killstreak3+"'s data is undefined" );
		self.killstreak[ 2 ] = level.tbl_KillStreakData[killstreak3]["reference"]; 
}
is_warlord_perk( itemIndex )
{
	
	if ( ( itemIndex == 168 ) || ( itemIndex == 169 ) )
	{
		return true;
	}
	else
	{
		return false;
	}
}
getCacDataGroup( cacRange, numClasses )
{
	for( i = cacRange; i < numClasses; i ++ )
	{
		primary_grenade = getLoadoutItemFromDDLStats ( i, "primarygrenade" );
		primary_num = getLoadoutItemFromDDLStats ( i, "primary" );
		specialty = [];
		specialty[0] = getLoadoutItemFromDDLStats ( i, "specialty1" );
		specialty[1] = getLoadoutItemFromDDLStats ( i, "specialty2" );
		specialty[2] = getLoadoutItemFromDDLStats ( i, "specialty3" );
		
		body = getLoadoutItemFromDDLStats( i, "body" );
		assert( body >= level.armor_index_start );
		assert( body <= level.armor_index_end );
		body = level.tbl_armor[ body ];
		assert( IsDefined( body ) );
		head = getLoadoutItemFromDDLStats( i, "head" );
		assert( head >= level.armor_index_start );
		assert( head <= level.armor_index_end );
		head = level.tbl_armor[ head ];
		assert( IsDefined( head ) );
		
		special_grenade = getLoadoutItemFromDDLStats ( i, "specialgrenade" );
		
		equipment = getLoadoutItemFromDDLStats ( i, "equipment" );
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		self.custom_class[i]["primary_grenades"] = level.tbl_weaponIDs[primary_grenade]["reference"]+"_mp"; 
		self.custom_class[i]["primary_grenades_count"] = level.tbl_weaponIDs[primary_grenade]["count"]; 
		
		
		self.custom_class[i]["equipment_slot"] = level.tbl_weaponIDs[equipment]["reference"]+"_mp";
		self.custom_class[i]["equipment_slot_count"] = level.tbl_weaponIDs[equipment]["count"];
		attachmentsDisabled = false;
		
		for ( j = 0; j < specialty.size; j++ )
		{
			if ( is_warlord_perk( specialty[ j ] ) && is_item_excluded( specialty[ j ] ) )
			{
				attachmentsDisabled = true;
				specialty[ j ] = 0;
			}
			specialty[j] = validatePerk( specialty[j], j, i );
		}
		
		classbonus = getLoadoutItemFromDDLStats( i, "classbonus" );
		
		
		
		
		
		
		
		
		
		
		
		specialIndex = 70;
		assert( level.tbl_weaponIDs[specialIndex]["reference"] == "concussion_grenade" ); 
		if ( !isDefined( level.tbl_weaponIDs[special_grenade] ) )
			special_grenade = specialIndex;
		specialGrenadeType = level.tbl_weaponIDs[special_grenade]["reference"];
		
		if ( specialGrenadeType != "weapon_null" )
		{
			if ( specialGrenadeType != "willy_pete" && specialGrenadeType != "concussion_grenade" && specialGrenadeType != "flash_grenade" && specialGrenadeType != "nightingale" && specialGrenadeType != "tabun_gas" )
			{
				iprintln( "^1Warning: (" + self.name + ") special grenade " + special_grenade + " is invalid. Setting to concussion grenade." );
				special_grenade = specialIndex;
			}
			
			for( j = 0; j < specialty.size; j++ )
			{
				if ( specialGrenadeType == "smoke_grenade" && level.tbl_PerkData[specialty[j]]["reference_full"] == "specialty_specialgrenade" )
				{
					iprintln( "^1Warning: (" + self.name + ") smoke grenade may not be used with extra special grenades. Setting to concussion grenade." );
					special_grenade = specialIndex;
				}
			}
		}
		
		self.custom_class[i]["primary"] = getFullWeaponName( i, "primary", attachmentsDisabled );
		self.custom_class[i]["secondary"] = getFullWeaponName( i, "secondary", attachmentsDisabled );
		
		
		self.custom_class[i]["specialties"] = [];
		for ( j = 0; j < specialty.size; j++ )
		{
			storeSpecialtyData( self, i, specialty[j] );
		}
		self.custom_class[i]["classbonus"] = classbonus;
		
		self.custom_class[i]["special_grenade"] = level.tbl_weaponIDs[special_grenade]["reference"]+"_mp"; 
		self.custom_class[i]["special_grenade_count"] = level.tbl_weaponIDs[special_grenade]["count"]; 
		
		
		self.custom_class[i]["body"] = body;
		self.custom_class[i]["head"] = head;
		
		self.custom_class[i]["player_render_options"]    = self calcPlayerOptions( i );
		self.custom_class[i]["primary_weapon_options"]   = self calcWeaponOptions( i, 0 );
		self.custom_class[i]["secondary_weapon_options"] = self calcWeaponOptions( i, 1 );
		self.cac_initialized = true;
		
	}
}
storeDefaultSpecialtyData( className, specialty )
{
	if ( !IsArray( specialty ) )
	{
		t = specialty;
		specialty = [];
		specialty[0] = t;
	}
	
	for ( i = 0; i < specialty.size; i++ )
	{
		index = level.default_perk[className].size;
		
		if ( IsString( specialty[i] ) )
		{
			level.default_perk[className][index] = specialty[i];
		}
		else
		{
			level.default_perk[className][index] = level.tbl_PerkData[specialty[i]]["reference_full"];
		}
	}
}
storeSpecialtyData( player, class_index, specialty )
{
	if ( !IsArray( specialty ) )
	{
		t = specialty;
		specialty = [];
		specialty[0] = t;
	}
	
	for ( i = 0; i < specialty.size; i++ )
	{
		index = player.custom_class[class_index]["specialties"].size;
		
		player.custom_class[class_index]["specialties"][index] = SpawnStruct();
		if ( IsString( specialty[i] ) )
		{
			player.custom_class[class_index]["specialties"][index].name			= specialty[i];
			player.custom_class[class_index]["specialties"][index].weaponref	= undefined;
			player.custom_class[class_index]["specialties"][index].count		= 0;
			player.custom_class[class_index]["specialties"][index].group		= "specialty";
		}
		else
		{
			player.custom_class[class_index]["specialties"][index].name			= level.tbl_PerkData[specialty[i]]["reference_full"]; 
			player.custom_class[class_index]["specialties"][index].weaponref	= level.tbl_PerkData[specialty[i]]["reference"]; 
			player.custom_class[class_index]["specialties"][index].count		= level.tbl_PerkData[specialty[i]]["count"]; 
			player.custom_class[class_index]["specialties"][index].group		= level.tbl_PerkData[specialty[i]]["group"]; 
		}
	}
}
isPerkGroup( perkName )
{
	return ( IsDefined( perkName ) && IsString( perkName ) );
}
getSlotForPerk( perkIndex )
{
	for ( i = 0; i < level.allowedPerks.size; i++ )
	{
		for ( j = 0; j < level.allowedPerks[i].size; j++ )
		{
			if ( IsDefined( level.allowedPerks[i][j] ) && level.allowedPerks[i][j] == perkIndex )
			{
				return i;
			}
		}
	}
	return 0;
}
setPerkIcon( classNum, specialtyNumber, perkIndex )
{
	if ( classNum < 0 )
	{
		return;
	}
	
	
	if ( !IsDefined( self.custom_class[classNum]["specialty" + specialtyNumber] ) )
	{
		self.custom_class[classNum]["specialty" + specialtyNumber] = level.tbl_PerkData[ perkIndex ][ "reference_full" ];
	}
}
validatePerkGroup( perkGroup, perkIndex, classNum )
{
	perks = StrTok( perkGroup, "|" );
	if ( !isdefined( level.specialtyToPerkIndex ) )
	{
		level.specialtyToPerkIndex = [];
	}
		
	
	if ( ( isDefined( level.tbl_PerkData[ perkIndex ]["count"] ) ) && ( level.tbl_PerkData[ perkIndex ]["count"] == 0 ) )
	{
		for ( i = 0; i < perks.size; i++ )
		{
			if ( !isDefined( level.specialtyToPerkIndex[ perks[ i ] ] ) )
			{
				level.specialtyToPerkIndex[ perks[ i ] ] = perkIndex;
			}
			else
			{
				assert( level.specialtyToPerkIndex[ perks[ i ] ] == perkIndex );
			}
		}
	}
	
	return perks;
}
validatePerk( perkIndex, perkSlotIndex, classNum, group )
{
	if ( !IsDefined( group ) )
	{
		group = false;
	}
	
	if ( !isDefined( classNum ) )
	{
		classnum = -1; 
	}
	
	perkGroup = undefined;
	specialtyNumber = perkSlotIndex + 1;
	
	if ( IsDefined( level.tbl_PerkData[ perkIndex ] ) )
	{
		perkGroup = level.tbl_PerkData[ perkIndex ][ "reference" ];
	}
	
	if ( isPerkGroup( perkGroup ) )
	{
		setPerkIcon( classNum, specialtyNumber, perkIndex );
		return validatePerkGroup( perkGroup, perkIndex, classNum );
	}
	
	perkIndex = level.perkReferenceToIndex[ "specialty_null" ];
	perks = [];
	perks[0] = "specialty_null";
	setPerkIcon( classNum, specialtyNumber, perkIndex );
	return perks;
}
validateKillStreak( killStreakIndex, killStreakSlotIndex )
{
	for ( i = 0; i < level.allowedKillStreak[ killStreakSlotIndex ].size; i++ )
	{
		if ( killStreakIndex == level.allowedKillStreak[ killStreakSlotIndex ][ i ] )
			return ( killStreakIndex );
	}
	return level.killStreakBaseValue;
}
logClassChoice( class, primaryWeapon, specialType, perks )
{
	if ( class == self.lastClass )
		return;
	self logstring( "choseclass: " + class + " weapon: " + primaryWeapon + " special: " + specialType );		
	for( i=0; i<perks.size; i++ )
		self logstring( "perk" + i + ": " + perks[i] );
	
	self.lastClass = class;
}
get_specialtydata( class_num, specialty, specialty_num )
{
	cac_reference	= specialty.name;
	cac_weaponref	= specialty.weaponref;	
	cac_group		= specialty.group;
	cac_count		= specialty.count;
		
	assertex( isdefined( cac_group ), "Missing "+specialty.name+"'s group name" );
	
	
	if( cac_reference == "specialty_twogrenades" && GetDvarInt( #"scr_game_perks" ) )
	{
		self.custom_class[class_num]["grenades_count"] = 2;
		self.custom_class[class_num]["specialgrenades_count"] = 3;
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	if ( cac_group == "specialty" )
	{
		self.specialty[self.specialty.size] = cac_reference;
	}
}
reset_specialty_slots( class_num )
{
	self.specialty = [];		
	self.custom_class[class_num]["inventory"] = "";
	self.custom_class[class_num]["inventory_count"] = 0;
	self.custom_class[class_num]["inventory_group"] = "";
	self.custom_class[class_num]["grenades"] = ""; 
	self.custom_class[class_num]["grenades_count"] = 0;
	self.custom_class[class_num]["grenades_group"] = "";
	self.custom_class[class_num]["specialgrenades"] = "";
	self.custom_class[class_num]["specialgrenades_count"] = 0;
	self.custom_class[class_num]["specialgrenades_group"] = "";
}
blackboxClassChoice( primary, secondary, grenades, specialgrenades, equipment )
{
	spawnid = getplayerspawnid( self );
	bbPrint( "mploadouts: spawnid %d body %s head %s primary %s secondary %s grenade %s special %s equipment %s",
			spawnid,
			self.cac_body_type,
			self.cac_head_type,
			primary,
			secondary,
			grenades,
			specialgrenades,
			equipment
		   );
	for ( i = 0; i < self.killstreak.size; i++ )
	{
		bbPrint( "mpkillstreaks: spawnid %d name %s", spawnid, self.killstreak[i] );
	}
	perks = self GetPerks();
	for ( i = 0; i < perks.size; i++ )
	{
		bbPrint( "mpspecialties: spawnid %d name %s", spawnid, perks[i] );
	}
}
giveKillStreaks()
{
		if ( !isDefined( self.killstreak ) || !isDefined( self.killstreak[ 0 ] ) || !isDefined( self.killstreak[ 1 ] ) || !isDefined( self.killstreak[ 2 ] ) )
		{
			setKillstreaks();
		}
		
		assert( isDefined( self.killstreak[ 0 ] ) && isDefined( self.killstreak[ 1 ] ) && isDefined( self.killstreak[ 2 ] ) );
}
getFullCustomWeaponName( customClassNum, weaponSlot ) 
{
	assertex( ( ( weaponSlot == "primary" ) || ( weaponSlot == "secondary" ) ), "weaponSlot should be primary or secondary" );
	
	weaponName = "weapon_null";
	
	if ( ( weaponSlot == "primary" ) || ( weaponSlot == "secondary" ) )
	{
		weaponNum = getCustomClassLoadoutItem ( customClassNum, weaponSlot );
		
		if ( weaponSlot == "primary" )
		{
			weaponIndex = 3;
			assert( level.tbl_weaponIDs[weaponIndex]["reference"] == "m1911" );
			
			if ( weaponNum < 0 || !isDefined( level.tbl_weaponIDs[ weaponNum ] ) )
			{
					weaponNum = weaponIndex;
			}
		}
		
		if ( isDefined( level.tbl_weaponIDs[ weaponNum ] ) )
		{
			attachmenttop = getCustomClassLoadoutItem ( customClassNum, weaponSlot + "attachmenttop" );
			attachmentbottom = getCustomClassLoadoutItem ( customClassNum, weaponSlot + "attachmentbottom" );
			attachmenttrigger = getCustomClassLoadoutItem ( customClassNum, weaponSlot + "attachmenttrigger" );
			attachmentmuzzle = getCustomClassLoadoutItem ( customClassNum, weaponSlot + "attachmentmuzzle" );
		
			topName = getAttachmentString( weaponNum, attachmenttop );
			bottomName = getAttachmentString( weaponNum, attachmentbottom );
			triggerName = getAttachmentString( weaponNum, attachmenttrigger );
			muzzleName = getAttachmentString( weaponNum, attachmentmuzzle );
			
			weaponPrefix = level.tbl_weaponIDs[ weaponNum ][ "reference" ];
			
			if ( bottomName == "dw_" )
			{
				weaponName = weaponPrefix + bottomName + topName + triggerName + muzzleName + "mp";
			}
			else
			{
				weaponName = weaponPrefix + "_" + topName +	bottomName + triggerName + muzzleName + "mp";
			}
		}
	}
	
	return weaponName;
}
loadCustomGameModeClasses( team, class )
{
	if( isSubstr( class, "CLASS_CUSTOM" ) || isSubstr(class, "CLASS_PRESTIGE") )
	{
		
		class_num = int( class[class.size-1] )-1;
		if( -1 == class_num )
			class_num = 9;
	}
	else
	{
		switch( class )
		{
		case "CLASS_SMG":
			class_num = 0;
			break;
		case "CLASS_CQB":
			class_num = 1;
			break;
		case "CLASS_ASSAULT":
			class_num = 2;
			break;
		case "CLASS_LMG":
			class_num = 3;
			break;
		default:
			class_num = 4;
			break;
		}
	}
	
	assert( class_num >= 0 && class_num < 10 );
	for( i = 0; i < 10; i ++ )
	{
		primary_grenade = getCustomClassLoadoutItem ( i, "primarygrenade" );
		primary_num = getCustomClassLoadoutItem ( i, "primary" );
		specialty = [];
		specialty[0] = getCustomClassLoadoutItem ( i, "specialty1" );
		specialty[1] = getCustomClassLoadoutItem ( i, "specialty2" );
		specialty[2] = getCustomClassLoadoutItem ( i, "specialty3" );
		
		body = getCustomClassLoadoutItem( i, "body" );
		body = level.tbl_armor[ body ];
		assert( IsDefined( body ) );
		head = getCustomClassLoadoutItem( i, "head" );
		head = level.tbl_armor[ head ];
		assert( IsDefined( head ) );
		
		special_grenade = getCustomClassLoadoutItem ( i, "specialgrenade" );
		
		equipment = getCustomClassLoadoutItem ( i, "equipment" );
		
		self.custom_class[i]["player_render_options"]    = self calcPlayerOptions( i );
		self.custom_class[i]["primary_weapon_options"]   = self calcWeaponOptions( i, 0 );
		self.custom_class[i]["secondary_weapon_options"] = self calcWeaponOptions( i, 1 );
		
		self.custom_class[i]["primary_grenades"] = level.tbl_weaponIDs[primary_grenade]["reference"]+"_mp"; 
		self.custom_class[i]["primary_grenades_count"] = 1; 
		
		self.custom_class[i]["equipment_slot"] = level.tbl_weaponIDs[equipment]["reference"]+"_mp";
		self.custom_class[i]["equipment_slot_count"] = level.tbl_weaponIDs[equipment]["count"];
		for ( j = 0; j < specialty.size; j++ )
		{
			specialty[j] = validatePerk( specialty[j], j, i );
		}
		
		classbonus = getCustomClassLoadoutItem( i, "classbonus" );
		specialIndex = 70;
		assert( level.tbl_weaponIDs[specialIndex]["reference"] == "concussion_grenade" ); 
		if ( !isDefined( level.tbl_weaponIDs[special_grenade] ) )
			special_grenade = specialIndex;
		specialGrenadeType = level.tbl_weaponIDs[special_grenade]["reference"];
		
		if ( specialGrenadeType != "weapon_null" )
		{
			if ( specialGrenadeType != "willy_pete" && specialGrenadeType != "concussion_grenade" && specialGrenadeType != "flash_grenade" && specialGrenadeType != "nightingale" && specialGrenadeType != "tabun_gas" )
			{
				iprintln( "^1Warning: (" + self.name + ") special grenade " + special_grenade + " is invalid. Setting to concussion grenade." );
				special_grenade = specialIndex;
			}
			
			for( j = 0; j < specialty.size; j++ )
			{
				if ( specialGrenadeType == "smoke_grenade" && level.tbl_PerkData[specialty[j]]["reference_full"] == "specialty_specialgrenade" )
				{
					iprintln( "^1Warning: (" + self.name + ") smoke grenade may not be used with extra special grenades. Setting to concussion grenade." );
					special_grenade = specialIndex;
				}
			}
		}
		
		self.custom_class[i]["primary"] = getFullCustomWeaponName( i, "primary" );
		self.custom_class[i]["secondary"] = getFullCustomWeaponName( i, "secondary" );
		
		
		self.custom_class[i]["specialties"] = [];
		for ( j = 0; j < specialty.size; j++ )
		{
			storeSpecialtyData( self, i, specialty[j] );
		}
		self.custom_class[i]["classbonus"] = classbonus;
		
		self.custom_class[i]["special_grenade"] = level.tbl_weaponIDs[special_grenade]["reference"]+"_mp"; 
		self.custom_class[i]["special_grenade_count"] = level.tbl_weaponIDs[special_grenade]["count"]; 
		
		
		self.custom_class[i]["body"] = body;
		self.custom_class[i]["head"] = head;
		
		self.cac_initialized = true;
		
		self.custom_class[i]["health"] = getCustomClassModifier( i, "health" );
		self.custom_class[i]["healthRegeneration"] = getCustomClassModifier( i, "healthRegeneration" );
		self.custom_class[i]["healthVampirism"] = getCustomClassModifier( i, "healthVampirism" );
		self.custom_class[i]["movementSpeed"] = getCustomClassModifier( i, "movementSpeed" );
		self.custom_class[i]["movementSprintSpeed"] = getCustomClassModifier( i, "movementSprintSpeed" );
		self.custom_class[i]["damage"] = getCustomClassModifier( i, "damage" );
		self.custom_class[i]["damageExplosive"] = getCustomClassModifier( i, "damageExplosive" );
	}						  	
							  	
	return class_num;		  
}			
applyCustomClassModifiers()
{
	self maps\mp\gametypes\_customClasses::setMovementSpeedModifier();
	newHealth = self maps\mp\gametypes\_customClasses::getModifiedHealth();
	if( newHealth != 100 )
	{
		self.maxhealth = newHealth;
		self.health = self.maxhealth;
	}
}
getRandomValidCustomClass( team, class )
{
	classList = [];
	for( i=0; i < 10; i++ )
	{
		classTeam = getcustomclassmodifier( i, "team" );
		active = getcustomclassmodifier( i, "active" );
		
		if( active > 0 && ( classTeam == 1 || ( classTeam == 2 && team == "axis" ) || ( classTeam == 3 && team == "allies" ) ) )
		{
			classList[ classList.size ] = "CLASS_CUSTOM" + (i+1);
		}
	}
	return array_randomize( classList )[0];
}
listWeaponAttachments( weaponName, player )
{
	if ( isSubStr( weaponName, "dw_mp" ) )
	{
		attachments = [];
		
		attachments[ 0 ] = [];
		attachments[ 0 ] [ "name" ] = "dw";
		attachments[ 0 ] [ "point" ] = "muzzle";
		
		if ( isDefined( player ) )
		{
			if ( player getDstat( "purchasedAttachments", "dw" ) )
			{
				attachments[ 0 ][ "owned" ] = true;
			}
		}		
		
		return attachments;
	}
	
	subStrings = strtok( weaponName, "_" );
	
	numSubStrings = subStrings.size;
	
	numAttachments = 0;
	
	attachments = [];
	
	for ( currString = 0; currString < numSubStrings; currString++ )
	{		
		attachPoint = tableLookup( "mp/attachmenttable.csv", 4, subStrings[ currString ], 1 );
		if ( attachPoint == "" )
		{
			continue;	
		}
		
		attachments[ numAttachments ] = [];
		attachments[ numAttachments ] [ "name" ] = subStrings[ currString ];
		attachments[ numAttachments ] [ "point" ] = attachPoint;
			
		if ( isDefined( player ) )
		{
			if ( player getDstat( "purchasedAttachments", subStrings[ currString ] ) )
			{
				attachments[ numAttachments ][ "owned" ] = true;
			}
		}
		
		numAttachments++;
	}
	
	return attachments;
}
initStaticWeaponsTime()
{
	self.staticWeaponsStartTime = getTime();
}
initWeaponAttachments( weaponName )
{
	if ( self is_bot() )
	{
		return;
	}
	
	self.currentWeaponStartTime = getTime();
	
	self.currentWeapon = weaponName;
	
	self.currWeaponItemIndex = getBaseWeaponItemIndex( weaponName );
	
	self.currentAttachments = listWeaponAttachments( weaponName, self );
}
isEquipmentAllowed( equipment )
{
	if ( GetDvarInt( #"scr_disable_equipment" ) )
		return false;
	
	if( equipment == "" )
		return false;
	if ( equipment == "weapon_null_mp" )
		return false;
		
	if ( equipment == "camera_spike_mp" && self IsSplitScreen() )
		return false;
		
	if ( equipment == level.tacticalInsertionWeapon && level.disable_tacinsert )
		return false;
	
	return true;
}
							  	
giveLoadout( team, class )	  
{
	pixbeginevent("giveLoadout");
	
	self takeAllWeapons();	  	
	
	
	
	primaryIndex = 0;
	
	
	self.specialty = [];
	self.killstreak = [];
	
	primaryWeapon = undefined;
	
	self notify( "give_map" );
	
	self GiveWeapon( "knife_mp" );
	if ( self maps\mp\gametypes\_copycat::copycat_in_use() )
	{
		self maps\mp\gametypes\_copycat::copycat_give_loadout();
	}
	else if( ( isSubstr( class, "CLASS_CUSTOM" ) || isSubstr(class, "CLASS_PRESTIGE") || maps\mp\gametypes\_customClasses::isUsingCustomGameModeClasses() ) )
	{	
		pixbeginevent("custom class");
		
		
		if( !( maps\mp\gametypes\_customClasses::isUsingCustomGameModeClasses() ) )
		{
			self cac_getdata();
			
			class_num = int( class[class.size-1] )-1;
			
			if( -1 == class_num )
				class_num = 9;
		}
		else
		{
			if( self is_bot() )
			{
				class = getRandomValidCustomClass( team, class );
				self setClass( class );
			}
			class_num = self loadCustomGameModeClasses( team, class );
		}
		self.class_num = class_num;
		
		assertex( isdefined( self.custom_class[class_num]["primary"] ), "Custom class "+class_num+": primary weapon setting missing" );
		assertex( isdefined( self.custom_class[class_num]["secondary"] ), "Custom class "+class_num+": secondary weapon setting missing" );
		
		
		self reset_specialty_slots( class_num );
		
		
		self.custom_class[class_num]["grenades"] = self.custom_class[class_num]["primary_grenades"];
		self.custom_class[class_num]["grenades_count"] = self.custom_class[class_num]["primary_grenades_count"];
		self.custom_class[class_num]["specialgrenades"] = self.custom_class[class_num]["special_grenade"];
		self.custom_class[class_num]["specialgrenades_count"] = self.custom_class[class_num]["special_grenade_count"];
		self.custom_class[class_num]["equipment"] = self.custom_class[class_num]["equipment_slot"];
		self.custom_class[class_num]["equipment_count"] = self.custom_class[class_num]["equipment_slot_count"];
		for ( i = 0; i < self.custom_class[class_num]["specialties"].size; i++ )
		{
			self get_specialtydata( class_num, self.custom_class[class_num]["specialties"][i], i );
		}
		
		
		self register_perks();
		
		giveKillStreaks();
		
		classbonus_data = tableLookup( "mp/classBonusTable.csv", 0, self.custom_class[class_num]["classbonus"], 1 );
		specialties = StrTok( classbonus_data, "|" );
		for ( i = 0; i < specialties.size; i++ )
		{
			self SetPerk( specialties[i] );
		}
		
		
		
		if ( isDefined( self.pers["weapon"] ) && self.pers["weapon"] != "none" )
			weapon = self.pers["weapon"];
		else
			weapon = self.custom_class[class_num]["primary"];
		
		primaryAttachmentsAllowed = true;
		
		if ( GetDvarInt( #"scr_disable_attachments" ) ) 
		{
			primaryAttachmentsAllowed = false;
		}
		else if ( GetDvarInt( #"scr_game_perks" ) == false )
		{
			classPrimaryAttachments = listWeaponAttachments( weapon, self );
			if ( classPrimaryAttachments.size > 1 ) 
			{
				primaryAttachmentsAllowed = false;			
			}
		}
			
		if ( primaryAttachmentsAllowed == false )
		{
			weaponNum = getLoadoutItemFromDDLStats( class_num, "primary" );
			weapon = level.tbl_weaponIDs[ weaponNum ][ "reference" ] + "_mp";
		}
		
		sidearm = self.custom_class[class_num]["secondary"];
		if ( GetDvarInt( #"scr_disable_attachments" ) )
		{
			weaponNum = getLoadoutItemFromDDLStats( class_num, "secondary" );
			sidearm = level.tbl_weaponIDs[ weaponNum ][ "reference" ] + "_mp";
		}
		
		self GiveWeapon( sidearm, 0, int( self.custom_class[class_num]["secondary_weapon_options"] ) );
		if ( self cac_hasSpecialty( "specialty_extraammo" ) )
			self giveMaxAmmo( sidearm );
		
		if( maps\mp\gametypes\_weapons::isPistol( sidearm ) )
			self setSpawnWeapon( sidearm );
			
		
		primaryWeapon = weapon;
		
		assertex( isdefined( self.custom_class[class_num]["primary_weapon_options"] ), "Player's weapon options is not defined, it should be at least initialized to 0" );
		primaryTokens = strtok( primaryWeapon, "_" );
		self.pers["primaryWeapon"] = primaryTokens[0];
		
		self GiveWeapon( weapon, 0, int( self.custom_class[class_num]["primary_weapon_options"] ) );
		self SetPlayerRenderOptions( int( self.custom_class[class_num]["player_render_options"] ) );
		
		if ( self cac_hasSpecialty( "specialty_extraammo" ) )
			self giveMaxAmmo( weapon );
			
		self setSpawnWeapon( weapon );
		
		secondaryWeapon = self.custom_class[class_num]["inventory"];
		if ( secondaryWeapon != "" )
		{
			self GiveWeapon( secondaryWeapon );
			
			self setWeaponAmmoOverall( secondaryWeapon, self.custom_class[class_num]["inventory_count"] );
			
			self SetActionSlot( 3, "weapon", secondaryWeapon );
			self SetActionSlot( 4, "" );
		}
		else
		{
			self SetActionSlot( 3, "altMode" );
			self SetActionSlot( 4, "" );
		}
		
		
		grenadeTypePrimary = self.custom_class[class_num]["grenades"]; 
		if ( grenadeTypePrimary != "" && grenadeTypePrimary != "weapon_null_mp" )
		{
			grenadeCount = self.custom_class[class_num]["grenades_count"]; 
	
			self GiveWeapon( grenadeTypePrimary );
			self SetWeaponAmmoClip( grenadeTypePrimary, grenadeCount );
			self SwitchToOffhand( grenadeTypePrimary );
			isFrag = self setOffhandPrimaryClass( grenadeTypePrimary );
			if( isFrag != "frag" )
			{
				self GiveWeapon( level.weapons["frag"] );
				self SetWeaponAmmoClip( level.weapons["frag"], 0 );
			}
		}
		else
		{
			self GiveWeapon( level.weapons["frag"] );
			self SetWeaponAmmoClip( level.weapons["frag"], 0 );
		}
		
		
		grenadeTypeSecondary = self.custom_class[class_num]["specialgrenades"]; 
		if ( grenadeTypeSecondary != "" && grenadeTypeSecondary != "weapon_null_mp")
		{
			grenadeCount = self.custom_class[class_num]["specialgrenades_count"]; 
	
			self setOffhandSecondaryClass( grenadeTypeSecondary );
			
			self giveWeapon( grenadeTypeSecondary );
			self SetWeaponAmmoClip( grenadeTypeSecondary, grenadeCount );
		}
		
		equipment_weapon = self.custom_class[class_num]["equipment"];
		
		if ( isEquipmentAllowed( equipment_weapon ) )
		{
			self GiveWeapon( equipment_weapon );
			
			self setWeaponAmmoOverall( equipment_weapon, self.custom_class[class_num]["equipment_count"] );
			
			self SetActionSlot( 1, "weapon", equipment_weapon );
		}
		self.cac_body_type = self.custom_class[ class_num ][ "body" ];
		self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
		self.cac_hat_type = "none";
		self maps\mp\gametypes\_armor::set_player_model();
		self initStaticWeaponsTime();
		
		self thread initWeaponAttachments( primaryWeapon );
		self thread blackboxClassChoice( primaryWeapon, sidearm, grenadeTypePrimary, grenadeTypeSecondary, equipment_weapon );
	}
	else if ( self is_bot() )
	{
		pixbeginevent("bot");
		self maps\mp\gametypes\_bot::bot_give_loadout();
		pixendevent(); 
	}
	else
	{			
		pixbeginevent("default class");
		
				
		
		assertex( isdefined(self.pers["class"]), "Player during spawn and loadout got no class!" );
		selected_class = self.pers["class"];
		
		
		
		specialty_size = level.default_perk[selected_class].size;
		
		
		
		
		for( i = 0; i < specialty_size; i++ )
		{
			if( isdefined( level.default_perk[selected_class][i] ) && level.default_perk[selected_class][i] != "" )
				self.specialty[self.specialty.size] = level.default_perk[selected_class][i];
		}
		assertex( isdefined( self.specialty ) && self.specialty.size > 0, "Default class: " + self.pers["class"] + " is missing specialties " );
		
		
		self register_perks();
		giveKillStreaks();
		
		if ( isdefined( self.pers["primary"] ) )
		{
			primaryIndex = self.pers["primary"];
		}
		
		
		
		if ( isDefined( self.pers["weapon"] ) && self.pers["weapon"] != "none" )
		{
			weapon = self.pers["weapon"];
		}
		else
		{
			weapon = level.classWeapons[team][class][primaryIndex];
		}
		
		
		sidearm = level.classSidearm[team][class];
		
		if ( sidearm != "" && sidearm != "weapon_null_mp" )
		{
			println( "^5GiveWeapon( " + sidearm + " ) -- sidearm" );
			self GiveWeapon( sidearm );
			if ( self cac_hasSpecialty( "specialty_extraammo" ) )
				self giveMaxAmmo( sidearm );
			
			if( maps\mp\gametypes\_weapons::isPistol( sidearm ) )
				self setSpawnWeapon( sidearm );
		}
		
		primaryWeapon = weapon;
		primaryTokens = strtok( primaryWeapon, "_" );
		self.pers["primaryWeapon"] = primaryTokens[0];
		
		
		
	
		println( "^5GiveWeapon( " + weapon + " ) -- weapon" );
		self GiveWeapon( weapon );
		if( self cac_hasSpecialty( "specialty_extraammo" ) )
			self giveMaxAmmo( weapon );
			
		self setSpawnWeapon( weapon );
			
			
			self SetActionSlot( 3, "altMode" );
			self SetActionSlot( 4, "" );
		
		grenadeTypePrimary = level.classGrenades[class]["primary"]["type"];
		
		if ( grenadeTypePrimary != "" && grenadeTypePrimary != "weapon_null_mp" )
		{
			grenadeCount = level.classGrenades[class]["primary"]["count"];
	
println( "^5GiveWeapon( " + grenadeTypePrimary + " ) -- grenadeTypePrimary" );
			self GiveWeapon( grenadeTypePrimary );
			self SetWeaponAmmoClip( grenadeTypePrimary, grenadeCount );
			self SwitchToOffhand( grenadeTypePrimary );
		}
		
		grenadeTypeSecondary = level.classGrenades[class]["secondary"]["type"];
		
		if ( grenadeTypeSecondary != "" && grenadeTypeSecondary != "weapon_null_mp" )
		{
			grenadeCount = level.classGrenades[class]["secondary"]["count"];
	
			self setOffhandSecondaryClass( grenadeTypeSecondary );
println( "^5GiveWeapon( " + grenadeTypeSecondary + " ) -- grneadeTypeSecondary" );
			self giveWeapon( grenadeTypeSecondary );
			self SetWeaponAmmoClip( grenadeTypeSecondary, grenadeCount );
		}
		
		equipment_weapon = level.default_equipment[ class ][ "type" ];
		if ( isEquipmentAllowed( equipment_weapon ) )
		{
			self GiveWeapon( equipment_weapon );
			
			self setWeaponAmmoOverall( equipment_weapon, level.default_equipment[ class ][ "count" ] );
			
			self SetActionSlot( 1, "weapon", equipment_weapon );
		}
		self.cac_body_type = level.default_armor[class]["body"];
		self.cac_head_type = self maps\mp\gametypes\_armor::get_default_head();
		self.cac_hat_type = "none";
		
		self maps\mp\gametypes\_armor::set_player_model();
		self initStaticWeaponsTime();
		
		self thread initWeaponAttachments( primaryWeapon );
		self thread blackboxClassChoice( primaryWeapon, sidearm, grenadeTypePrimary, grenadeTypeSecondary, equipment_weapon );
		pixendevent(); 
	}
	if( maps\mp\gametypes\_customClasses::isUsingCustomGameModeClasses() )
	{
		self applyCustomClassModifiers();
	}
	if( isDefined( self.movementSpeedModifier ) )
	{
		self setMoveSpeedScale( self.movementSpeedModifier * self getMoveSpeedScale() );
	}
	if ( isDefined( level.giveCustomLoadout ) )
	{
		spawnWeapon = self [[level.giveCustomLoadout]]();
		if ( IsDefined( spawnWeapon ) )
			self thread initWeaponAttachments( spawnWeapon );
	}
	
	
	self cac_selector();
	
	pixendevent();
}
setWeaponAmmoOverall( weaponname, amount )
{
	if ( isWeaponClipOnly( weaponname ) )
	{
		self setWeaponAmmoClip( weaponname, amount );
	}
	else
	{
		self setWeaponAmmoClip( weaponname, amount );
		diff = amount - self getWeaponAmmoClip( weaponname );
		assert( diff >= 0 );
		self setWeaponAmmoStock( weaponname, diff );
	}
}
onPlayerConnecting()
{
	for(;;)
	{
		level waittill( "connecting", player );
		if ( !level.oldschool )
		{
		if ( !isDefined( player.pers["class"] ) )
		{
			player.pers["class"] = "";
	}
			player.class = player.pers["class"];
			player.lastClass = "";
		}
		player.detectExplosives = false;
		player.bombSquadIcons = [];
		player.bombSquadIds = [];	
		player.reviveIcons = [];
		player.reviveIds = [];
	}
}
fadeAway( waitDelay, fadeDelay )
{
	wait waitDelay;
	
	self fadeOverTime( fadeDelay );
	self.alpha = 0;
}
setClass( newClass )
{
	self.curClass = newClass;
}
initPerkDvars()
{
	level.cac_armorpiercing_data = cac_get_dvar_int( "perk_armorpiercing", "40" ) / 100;
	level.cac_bulletdamage_data = cac_get_dvar_int( "perk_bulletDamage", "35" );		
	level.cac_fireproof_data = cac_get_dvar_int( "perk_fireproof", "95" );				
	level.cac_armorvest_data = cac_get_dvar_int( "perk_armorVest", "80" );				
	level.cac_explosivedamage_data = cac_get_dvar_int( "perk_explosiveDamage", "25" );	
	level.cac_flakjacket_data = cac_get_dvar_int( "perk_flakJacket", "35" );			
	level.cac_flakjacket_hardcore_data = cac_get_dvar_int( "perk_flakJacket_hardcore", "9" );	
}
cac_selector()
{
	self thread maps\mp\_tacticalinsertion::postLoadout();
	
	perks = self.specialty;
	self.detectExplosives = false;
	for( i=0; i<perks.size; i++ )
	{
		perk = perks[i];
		
		if( perk == "specialty_detectexplosive" )
			self.detectExplosives = true;
	}
	
	maps\mp\gametypes\_weaponobjects::setupBombSquad();
	
	
	
		self.canreviveothers = true;
		maps\mp\_laststand::setupRevive();
	
}
	
register_perks()
{
	perks = self.specialty;
	self clearPerks();
	for( i=0; i<perks.size; i++ )
	{
		perk = perks[i];
		
		
		if ( perk == "specialty_null" || isSubStr( perk, "specialty_weapon_" ) || perk == "weapon_null" )
			continue;
			
		if ( !GetDvarInt( #"scr_game_perks" ) )
			continue;
			
		self setPerk( perk );
	}
	
	
}
cac_get_dvar_int( dvar, def )
{
	return int( cac_get_dvar( dvar, def ) );
}
cac_get_dvar( dvar, def )
{
	if ( getdvar( dvar ) != "" )
	{
		return getdvarfloat( dvar );
	}
	else
	{
		setdvar( dvar, def );
		return def;
	}
}
cac_hasSpecialty( perk_reference )
{
	return_value = self hasPerk( perk_reference );

	if (!isDefined(return_value))
		return false;
		
	return return_value;
	
	
}
cac_modified_vehicle_damage( victim, attacker, damage, meansofdeath, weapon, inflictor )
{
	
	if( !isdefined( victim) || !isdefined( attacker ) || !isplayer( attacker ) )
		return damage;
	if( !isdefined( damage ) || !isdefined( meansofdeath ) || !isdefined( weapon ) )
		return damage;
	old_damage = damage;
	final_damage = damage;
	
	
	if( attacker cac_hasSpecialty( "specialty_bulletdamage" ) && isPrimaryDamage( meansofdeath ) )
	
	
	
	{
		final_damage = damage*(100+level.cac_bulletdamage_data)/100;
		
	}
	else if( attacker cac_hasSpecialty( "specialty_explosivedamage" ) && isPlayerExplosiveWeapon( weapon, meansofdeath )  )
	{
		final_damage = damage*(100+level.cac_explosivedamage_data)/100;
		
	}
	else
	{
		final_damage = old_damage;
	}	
	
	
	
	
	
	return int( final_damage );
}
cac_modified_damage( victim, attacker, damage, meansofdeath, weapon, inflictor, hitloc )
{
	
	if( !isdefined( victim) || !isdefined( attacker ) || !isplayer( attacker ) || !isplayer( victim ) )
		return damage;
	if( !isdefined( damage ) || !isdefined( meansofdeath ) )
		return damage;
	if( meansofdeath == "" )
		return damage;
	if( !IsDefined(hitloc) || hitloc == "" )
		hitloc = "torso_upper";
		
	old_damage = damage;
	final_damage = damage;
	
	
	
	
	
	
	
	
	
	
	if( ( isplayer( attacker ) && attacker cac_hasSpecialty( "specialty_bulletdamage" ) ) && isPrimaryDamage( meansofdeath ) )
	{
		
		if( isdefined( victim ) && isPlayer( victim ) && victim cac_hasSpecialty( "specialty_armorvest" ) && !isHeadDamage( hitloc ) )
		{
			final_damage = old_damage;
			
		}
		else
		{
			final_damage = damage*(100+level.cac_bulletdamage_data)/100;
			
		}
	}
	else if( victim cac_hasSpecialty( "specialty_armorvest" ) && isPrimaryDamage( meansofdeath ) && !isHeadDamage( hitloc ) )
	{	
		
		final_damage = damage*(level.cac_armorvest_data *.01);
		
	}
	else if ( victim cac_hasSpecialty ("specialty_fireproof") && isFireDamage( weapon, meansofdeath ) )
	{
		level.cac_fireproof_data = cac_get_dvar_int( "perk_fireproof", level.cac_fireproof_data );
		
		final_damage = damage*((100-level.cac_fireproof_data)/100);
		
	}
	else if( attacker cac_hasSpecialty( "specialty_explosivedamage" ) && isPlayerExplosiveWeapon( weapon, meansofdeath ) )
	{
		final_damage = damage*(100+level.cac_explosivedamage_data)/100;
		
	}
	else if (victim cac_hasSpecialty( "specialty_flakjacket" ) && ( !isdefined( inflictor.stucktoplayer ) || inflictor.stucktoplayer != victim ) && meansofdeath != "MOD_PROJECTILE"  && weapon != "briefcase_bomb_mp" && weapon != "tabun_gas_mp" && weapon != "concussion_grenade_mp" && weapon != "flash_grenade_mp" && weapon != "willy_pete_mp" )
	{
		if ( isExplosiveDamage( meansofdeath, weapon ) || isSubStr( weapon, "explodable_barrel" ) || isSubStr( weapon, "destructible_car" ))
		{
			
			level.cac_flakjacket_data = cac_get_dvar_int( "perk_flakJacket", level.cac_flakjacket_data );
			if( level.hardcoreMode )
			{
				level.cac_flakjacket_data = cac_get_dvar_int( "perk_flakJacket_hardcore", level.cac_flakjacket_hardcore_data );
			}
			
			if ( isdefined( attacker ) && isplayer( attacker) )
			{
				if ( level.teambased )
				{
					if ( attacker.team != victim.team )
					{
						victim thread maps\mp\_properks::flakjacketProtected();
					}
				}
				else
				{
					if ( attacker != victim )
					{
						victim thread maps\mp\_properks::flakjacketProtected();
					}
				}
			}
			final_damage = int( old_damage * ( level.cac_flakjacket_data / 100 ) );
			
		}		
	}
	else
	{	
		final_damage = old_damage;
	}
	if ( GetDvar( #"scr_disable_cac_2" ) == "" )
	{
		final_damage = victim maps\mp\gametypes\_armor::get_armor_damage( meansofdeath, weapon, hitloc, final_damage );
	}
	
	
	
	
	
	
	return int( final_damage );
}
isExplosiveDamage( meansofdeath, weapon )
{
	explosivedamage = "MOD_GRENADE MOD_GRENADE_SPLASH MOD_PROJECTILE_SPLASH MOD_EXPLOSIVE";
			
	if( isSubstr( explosivedamage, meansofdeath ) )
		return true;
	return false;
}
isPrimaryDamage( meansofdeath )
{
	
	if( meansofdeath == "MOD_RIFLE_BULLET" || meansofdeath == "MOD_PISTOL_BULLET" )
		return true;
	return false;
}
isFireDamage( weapon, meansofdeath )
{
	if ( ( isSubStr( weapon, "flame" ) || isSubStr( weapon, "napalmblob_" ) || isSubStr( weapon, "napalm_" ) ) && ( meansofdeath == "MOD_BURNED" || meansofdeath == "MOD_GRENADE" || meansofdeath == "MOD_GRENADE_SPLASH" ) )
		return true;
	if( GetSubStr( weapon, 0, 3 ) == "ft_" )
		return true;
	return false;
}
isPlayerExplosiveWeapon( weapon, meansofdeath )
{
	if ( !isExplosiveDamage( meansofdeath, weapon ) )
		return false;
		
	if ( weapon == "artillery_mp" || weapon == "airstrike_mp" || weapon == "napalm_mp" || weapon == "mortar_mp" || weapon == "hind_ffar_mp" || weapon == "cobra_ffar_mp" )
		return false;
	
	
	if ( issubstr(weapon, "turret" ) )
		return false;
	
	return true;
}
isHeadDamage( hitloc )
{
	return ( hitloc == "helmet" || hitloc == "head" || hitloc == "neck" );
} 
