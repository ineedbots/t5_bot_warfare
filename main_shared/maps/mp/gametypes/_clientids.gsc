init()
{
	level.clientid = 0;
	level thread onPlayerConnect();
}
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		player.clientid = level.clientid;
		level.clientid++;	
	}
} 
