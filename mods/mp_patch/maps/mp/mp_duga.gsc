#include maps\mp\_utility;
#include common_scripts\utility; 
#include maps\mp\_events;

main()
{
	///#
		//execdevgui( "devgui_mp_duga" );
	//#/
	
	//needs to be first for create fx
	maps\mp\mp_duga_fx::main();

	maps\mp\_load::main();

	maps\mp\mp_duga_amb::main();

	// If the team nationalites change in this file,
	// you must update the team nationality in the level's csc file as well!
	maps\mp\gametypes\_teamset_winterspecops::level_init();

	precachemodel("collision_geo_mc_8x560x190");
	precachemodel("collision_geo_mc_4x52x190");
	
	// enable new spawning system
	maps\mp\gametypes\_spawning::level_use_unified_spawning(true);

	if ( GetDvarInt( #"xblive_wagermatch" ) == 1 )
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_duga_wager"); 
	}
	else
	{
		maps\mp\_compass::setupMiniMap("compass_map_mp_duga"); 
	}
	
	//Increase sample size so as to resolve lighting issue
	SetDvar("sm_sunSampleSizeNear", ".5" );
	
	//Sets it up so my events go off at times based on the game time and score limit
	//level thread transformer_timer_init();
	///#
		//level thread devgui_duga();
	//#/

	glasses = GetStructArray( "glass_shatter_on_spawn", "targetname" );

	for ( i = 0; i < glasses.size; i++ )
	{
		RadiusDamage( glasses[i].origin, 64, 101, 100 ); 
	}

	// weapon collision to keep grenades from falling out of the map through a gap between the terrain and the wall.
	spawncollision("collision_geo_mc_8x560x190","collider",(462, -3840, -165), (0, 0, 0));
	spawncollision("collision_geo_mc_4x52x190","collider",(184, -3870, -164), (0, 270, 0));
	spawncollision("collision_geo_mc_4x52x190","collider",(184, -3922, -164), (0, 270, 0));
	spawncollision("collision_geo_mc_4x52x190","collider",(188, -3922, -169), (0, 270, 0));
}

//Sets it up so events can happen based on match time and score changes
transformer_timer_init()
{
	first_transformer_structs = getstructarray("transformer_struct","targetname");
	
	level._transformer_array = [];
	
	for( i=0; i < first_transformer_structs.size; i++)
	{
		current_struct = first_transformer_structs[i];
		level._transformer_array = add_to_array(level._transformer_array, current_struct);
			
		while(IsDefined(current_struct.target))
		{
			current_struct = getstruct(current_struct.target, "targetname");
			level._transformer_array = add_to_array(level._transformer_array, current_struct);	
		}
	}
	
	level waittill( "prematch_over" );
	
	
	if( (IsDefined(level.timelimit)) && (level.timelimit > 0))
	{
		//Electric transformers explode in pairs. The number of pairs is critical to determine how many 'events' we need.
		transformer_pairs = level._transformer_array.size / 2;
		total_seconds = level.timelimit * 60;
		//We want to space out the transformer pair explosion evenly thourought the match
		interval = total_seconds / transformer_pairs;
		
		//This creates events based on how many we need. The event sends a notify to duga.csc to set off explosions.
		for( i = total_seconds; i >= interval; i -= interval )
		{
		  println( "Seconds: " + i );
		  add_timed_event( int( i ), undefined, "go" );
		}
		
		//This event sets off with a tenth of a second left in the game. The duga.csc waits for the notify.
		add_timed_event( .1, undefined, "fin" );
	}
	//add_score_event( Int(level.scorelimit * .99), undefined, "final_boom" );
	//add_score_event( Int(level.scorelimit * 0.1),undefined, "next_boom" );
	//add_score_event( Int(level.scorelimit * 0.2),undefined, "next_boom" );
}

devgui_duga( cmd )
{
	
	for ( ;; )
	{
		wait( 0.5 );

		devgui_string = GetDvar( #"devgui_notify" );

		switch( devgui_string )
		{
			case "":
			break;
			
			case "transformer_explode1":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode2":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode3":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode4":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode5":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode6":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode7":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode8":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode9":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode10":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode11":
				level ClientNotify ("transformer_explode");
			break;
			
			case "transformer_explode12":
				level ClientNotify ("transformer_explode");
			break;
			
			//case "final_explode":
				//transformer_array[5] notify ("final_explode");
			//break;

			default:
				level notify( devgui_string );
			break;
		}

		SetDvar( "devgui_notify", "" );
	}
}
