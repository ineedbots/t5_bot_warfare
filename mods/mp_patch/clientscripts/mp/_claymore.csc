#include clientscripts\mp\_utility;
#include clientscripts\mp\_rewindobjects;

init( localClientNum )
{
	level._effect["fx_claymore_laser"] = loadfx( "weapon/claymore/fx_claymore_laser" );
}

spawned( localClientNum )
{
	self endon( "entityshutdown" );

	self waittill_dobj(localClientNum);

	while( true )
	{
		if( IsDefined( self.stunned ) && self.stunned )
		{
			wait( 0.1 );
			continue;
		}


		self.claymoreLaserFXId = PlayFXOnTag( localClientNum, level._effect["fx_claymore_laser"], self, "tag_fx" );

		self waittill( "stunned" );
		stopfx(localClientNum, self.claymoreLaserFXId);

	}
}
