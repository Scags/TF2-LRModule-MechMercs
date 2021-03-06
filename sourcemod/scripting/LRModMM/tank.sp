
//defines
#define TankModel			"models/custom/tanks/panzer.mdl" //thx to Friagram for saving teh day!
#define TankModelPrefix			"models/custom/tanks/panzer"

#define TankShoot			"acvshtank/fire"
#define TankDeath			"acvshtank/dead"
#define TankSpawn			"acvshtank/spawn"
#define TankReload			"acvshtank/reload.mp3"
#define TankCrush			"acvshtank/vehicle_hit_person.mp3"
#define TankMove			"acvshtank/tankdrive.mp3"
#define TankIdle			"acvshtank/tankidle.mp3"


methodmap CTank < JailTank
{
	public CTank(const int client)
	{
		return view_as< CTank >( client );
	}

	property float flLastFire
	{
		public get() { return this.GetPropFloat("flLastFire"); }
		public set( const float i ) { this.SetPropFloat("flLastFire", i); }
	}

	public void PlaySpawnSound (const int number)
	{
		char sound[PLATFORM_MAX_PATH];
		Format(sound, PLATFORM_MAX_PATH, "%s%i.mp3", TankSpawn, number); //sounds from Company of Heroes 1
		EmitSoundToAll(sound, this.index, SNDCHAN_VOICE); EmitSoundToAll(sound, this.index, SNDCHAN_VOICE); EmitSoundToAll(sound, this.index, SNDCHAN_VOICE);
	}

	public void Think ()
	{
		int player = this.index;
		if ( !IsPlayerAlive(player) )
			return;

		int buttons = GetClientButtons(player);
		float vell[3];	GetEntPropVector(player, Prop_Data, "m_vecAbsVelocity", vell);
		float currtime = GetGameTime();
		if ( (buttons & IN_FORWARD) and vell[0] != 0.0 and vell[1] != 0.0 )
		{
			StopSound(player, SNDCHAN_AUTO, TankIdle);

			this.flSpeed += hTank[ACCELERATION].FloatValue; /*simulates vehicular physics; not as good as Valve does with vehicle entities though*/
			if (this.flSpeed > hTank[SPEEDMAX].FloatValue)
				this.flSpeed = hTank[SPEEDMAX].FloatValue;

			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankMove);
				EmitSoundToAll(TankMove, player, SNDCHAN_AUTO);
				this.flSoundDelay = currtime+31.0;
			}
		}
		else if ( (buttons & IN_BACK) and vell[0] != 0.0 and vell[1] != 0.0 )
		{
			StopSound(player, SNDCHAN_AUTO, TankIdle);

			this.flSpeed += hTank[ACCELERATION].FloatValue;
			if (this.flSpeed > hTank[SPEEDMAXREVERSE].FloatValue)
				this.flSpeed = hTank[SPEEDMAXREVERSE].FloatValue;
			
			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankMove);
				EmitSoundToAll(TankMove, player, SNDCHAN_AUTO);
				this.flSoundDelay = currtime+31.0;
			}
		}
		else {
			StopSound(player, SNDCHAN_AUTO, TankMove);

			if (this.flSoundDelay != 0.0)
				this.flSoundDelay = 0.0;
			if ( this.flIdleSound < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankIdle);
				EmitSoundToAll(TankIdle, player, SNDCHAN_AUTO);
				this.flIdleSound = currtime+5.0;
			}
			this.flSpeed -= hTank[ACCELERATION].FloatValue;
			if (this.flSpeed < hTank[INITSPEED].FloatValue)
				this.flSpeed = hTank[INITSPEED].FloatValue;
		}

		SetEntPropFloat(player, Prop_Send, "m_flMaxspeed", this.flSpeed);

		if ( (buttons & IN_ATTACK2) and this.bIsVehicle ) //MOUSE2 Rocket firing mechanic
		{
			if ( this.flLastFire < currtime ) {
				float vPosition[3], vAngles[3], vVec[3];
				GetClientEyePosition(player, vPosition);
				GetClientEyeAngles(player, vAngles);

				vVec[0] = Cosine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[1] = Sine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[2] = -Sine( DegToRad(vAngles[0]) );

				vPosition[0] += vVec[0] * 50.0;
				vPosition[1] += vVec[1] * 50.0;
				vPosition[2] += vVec[2] * 50.0;
				bool crit = ( TF2_IsPlayerInCondition(player, TFCond_Kritzkrieged) or TF2_IsPlayerInCondition(player, TFCond_CritOnWin) );
				TE_SetupMuzzleFlash(vPosition, vAngles, 9.0, 1);
				TE_SendToAll();
				ShootRocket(player, crit, vPosition, vAngles, g_LR.GetParameterFloat("RocketSpeed", 4000.0), hTank[ROCKETDMG].FloatValue, "");
				char s[PLATFORM_MAX_PATH];
				Format(s, PLATFORM_MAX_PATH, "%s%i.mp3", TankShoot, GetRandomInt(1, 3)); //sounds from Call of duty 1
				EmitSoundToAll(s, player, SNDCHAN_AUTO);
				CreateTimer(1.0, Timer_ReloadTank, this.userid, TIMER_FLAG_NO_MAPCHANGE); //useless, only plays a 'reload' sound
				this.flLastFire = currtime + 4.0;
				
				float PunchVec[3] = {100.0, 0.0, 90.0};
				SetEntPropVector(player, Prop_Send, "m_vecPunchAngleVel", PunchVec);
			}
		}
		//CreateTimer(0.1, Timer_TankCrush, client);
		//TF2_AddCondition(player, TFCond_MegaHeal, 0.2); /*prevent tanks from being airblasted and gives a team colored aura to allow teams to tell who's on what side */
	}
	public void SetModel ()
	{
		SetVariantString(TankModel);
		AcceptEntityInput(this.index, "SetCustomModel");
		SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		//SetEntPropFloat(this.index, Prop_Send, "m_flModelScale", 1.25);
	}

	public void Death ()
	{
		StopSound(this.index, SNDCHAN_AUTO, TankIdle);
		StopSound(this.index, SNDCHAN_AUTO, TankMove);

		char sound[PLATFORM_MAX_PATH];
		Format(sound, PLATFORM_MAX_PATH, "%s%i.mp3", TankDeath, GetRandomInt(1, 2)); // Sounds from Call of Duty 1
		EmitSoundToAll(sound, this.index, SNDCHAN_AUTO);
		AttachParticle(this.index, "buildingdamage_dispenser_fire1", 1.0);
		SetClientOverlay(this.index, "0");
		this.flIdleSound = 0.0;
		this.flSoundDelay = 0.0;
	}

	public void Equip ()
	{
		TF2_RemoveAllWeapons(this.index);
		int maxhp = GetEntProp(this.index, Prop_Data, "m_iMaxHealth");
		char attribs[128];
		Format( attribs, sizeof(attribs), "400 ; 1.0 ; 125 ; %i ; 6 ; 0.5 ; 326 ; 0.0 ; 252 ; 0.0 ; 25 ; 0.0 ; 53 ; 1 ; 59 ; 0.0 ; 60 ; 0.01 ; 68 ; %f", (1-maxhp), (this.Class == TFClass_Scout) ? -2.0 : -1.0 );

		int Turret = this.SpawnWeapon("tf_weapon_smg", 16, 1, 0, attribs);
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", Turret);
	}
};

public CTank ToCTank (JailTank veh)
{
	return view_as<CTank> (veh);
}

public void AddTankToDownloads ()
{
	char s[PLATFORM_MAX_PATH];
	//char extensionsc[][] = { ".wav", ".mp3" };
	int i;
	PrecacheModel(TankModel, true);
	for (i = 0; i < sizeof(extensions); ++i) {
		Format(s, PLATFORM_MAX_PATH, "%s%s", TankModelPrefix, extensions[i]);
		CheckDownload(s);
	}
	for (i = 0; i < sizeof(extensionsb); ++i) {
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/panzer%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/panzer_blue%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/panzer_track%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/pziv_ausfg%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/pziv_ausfg_nm%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/pziv_ausfg_red%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/hummel_track%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/hummel_track_nm%s", extensionsb[i]);
		CheckDownload(s);
	}
	for (i = 1; i < 4; ++i) {
		if (i < 3) {
			Format(s, PLATFORM_MAX_PATH, "%s%i.mp3", TankDeath, i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
		}
		Format(s, PLATFORM_MAX_PATH, "%s%i.mp3", TankShoot, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);

		Format(s, PLATFORM_MAX_PATH, "%s%i.mp3", TankSpawn, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);
	}
	AddFileToDownloadsTable("sound/acvshtank/reload.mp3");
	AddFileToDownloadsTable("sound/acvshtank/vehicle_hit_person.mp3");
	AddFileToDownloadsTable("sound/acvshtank/tankidle.mp3");
	AddFileToDownloadsTable("sound/acvshtank/tankdrive.mp3");
	PrecacheSound(TankReload, true);
	PrecacheSound(TankCrush, true);
	PrecacheSound(TankMove, true);
	PrecacheSound(TankIdle, true);
}

public void AddTankToMenu ( Menu& menu )
{
	menu.AddItem("0", "Panzer IV");
}

public Action Timer_ReloadTank (Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);
	CTank tanker = CTank(client);
	if (!tanker.bIsVehicle)
		return Plugin_Continue;

	if (client and IsClientInGame(client)) {
		//char s[PLATFORM_MAX_PATH];
		//strcopy(s, PLATFORM_MAX_PATH, TankReload);
		EmitSoundToAll(TankReload, client, SNDCHAN_AUTO);
	}
	return Plugin_Continue;
}


