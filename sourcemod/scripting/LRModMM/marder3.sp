
//defines
#define DestroyerModel			"models/custom/tanks/marder3.mdl" //thx to Friagram for saving teh day!
#define DestroyerModelPrefix		"models/custom/tanks/marder3"

methodmap CDestroyer < CTank
{
	public CDestroyer(const int client)
	{
		return view_as<CDestroyer>( client );
	}

	/*public void PlaySpawnSound (const int number)
	{
		char sound[PLATFORM_MAX_PATH];
		Format(sound, PLATFORM_MAX_PATH, "%s%i.mp3", TankSpawn, number); //sounds from Company of Heroes 1
		EmitSoundToAll(sound, this.index, SNDCHAN_VOICE); EmitSoundToAll(sound, this.index, SNDCHAN_VOICE); EmitSoundToAll(sound, this.index, SNDCHAN_VOICE);
	}*/

	public void Think ()
	{
		if ( !IsPlayerAlive(this.index) )
			return;

		int buttons = GetClientButtons(this.index);
		float vell[3];	GetEntPropVector(this.index, Prop_Data, "m_vecAbsVelocity", vell);
		float currtime = GetGameTime();
		if ( (buttons & IN_FORWARD) and vell[0] != 0.0 and vell[1] != 0.0 ) {
			StopSound(this.index, SNDCHAN_AUTO, TankIdle);

			this.flSpeed += hDestroyer[ACCELERATION].FloatValue; /*simulates vehicular physics; not as good as Valve does with vehicle entities though*/
			if (this.flSpeed > hDestroyer[SPEEDMAX].FloatValue)
				this.flSpeed = hDestroyer[SPEEDMAX].FloatValue;

			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankMove);
				EmitSoundToAll(TankMove, this.index, SNDCHAN_AUTO);
				this.flSoundDelay = currtime+31.0;
			}
		}
		else if ( (buttons & IN_BACK) and vell[0] != 0.0 and vell[1] != 0.0 ) {
			StopSound(this.index, SNDCHAN_AUTO, TankIdle);

			this.flSpeed += hDestroyer[ACCELERATION].FloatValue;
			if (this.flSpeed > hDestroyer[SPEEDMAXREVERSE].FloatValue)
				this.flSpeed = hDestroyer[SPEEDMAXREVERSE].FloatValue;
			
			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankMove);
				EmitSoundToAll(TankMove, this.index, SNDCHAN_AUTO);
				this.flSoundDelay = currtime+31.0;
			}
		}
		else {
			StopSound(this.index, SNDCHAN_AUTO, TankMove);

			if (this.flSoundDelay != 0.0)
				this.flSoundDelay = 0.0;
			if ( this.flIdleSound < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankIdle);
				EmitSoundToAll(TankIdle, this.index, SNDCHAN_AUTO);
				this.flIdleSound = currtime+5.0;
			}
			this.flSpeed -= hDestroyer[ACCELERATION].FloatValue;
			if (this.flSpeed < hDestroyer[INITSPEED].FloatValue)
				this.flSpeed = hDestroyer[INITSPEED].FloatValue;
		}

		SetEntPropFloat(this.index, Prop_Send, "m_flMaxspeed", this.flSpeed);

		/*
		if ( (buttons & IN_ATTACK2) and this.bIsVehicle ) //MOUSE2 Rocket firing mechanic
		{
			if ( this.flLastFire < currtime ) {
				float vPosition[3], vAngles[3], vVec[3];
				GetClientEyePosition(this.index, vPosition);
				GetClientEyeAngles(this.index, vAngles);

				vVec[0] = Cosine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[1] = Sine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[2] = -Sine( DegToRad(vAngles[0]) );

				vPosition[0] += vVec[0] * 50.0;
				vPosition[1] += vVec[1] * 50.0;
				vPosition[2] += vVec[2] * 50.0;
				bool crit = ( TF2_IsPlayerInCondition(this.index, TFCond_Kritzkrieged) or TF2_IsPlayerInCondition(this.index, TFCond_CritOnWin) );
				TE_SetupMuzzleFlash(vPosition, vAngles, 9.0, 1);
				TE_SendToAll();
				ShootRocket(this.index, crit, vPosition, vAngles, DESTROYER_SPEED, DESTROYER_DMG, "");
				Format(snd, PLATFORM_MAX_PATH, "%s%i.mp3", TankShoot, GetRandomInt(1, 3)); //sounds from Call of duty 1
				EmitSoundToAll(snd, this.index, SNDCHAN_AUTO);
				CreateTimer(1.0, Timer_ReloadTank, this.userid, TIMER_FLAG_NO_MAPCHANGE); //useless, only plays a 'reload' sound
				CreateTimer(4.0, Timer_ReloadTank, this.userid, TIMER_FLAG_NO_MAPCHANGE);
				this.flLastFire = currtime + 8.0;

				float PunchVec[3] = {80.0, 0.0, 45.0};
				SetEntPropVector(this.index, Prop_Send, "m_vecPunchAngleVel", PunchVec);
			}
		}
		CreateTimer(0.1, Timer_TankCrush, client);
		TF2_AddCondition(this.index, TFCond_MegaHeal, 0.2);
		*/
		/*prevent tanks from being airblasted and gives a team colored aura to allow teams to tell who's on what side */
	}
	public void SetModel ()
	{
		SetVariantString(DestroyerModel);
		AcceptEntityInput(this.index, "SetCustomModel");
		//SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		SetEntProp(this.index, Prop_Send, "m_bCustomModelRotates", 1); 
		//SetEntPropFloat(this.index, Prop_Send, "m_flModelScale", 1.25);
	}
	public void Equip ()
	{
		TF2_RemoveAllWeapons(this.index);
		int maxhp = GetEntProp(this.index, Prop_Data, "m_iMaxHealth");

		char attribs[150];
		Format( attribs, sizeof(attribs), "125 ; %i ; 400 ; 1.0 ; 326 ; 0.0 ; 252 ; 0.0 ; 37 ; 0.0 ; 53 ; 1 ; 59 ; 0.0 ; 60 ; 0.01 ; 100 ; 0.2 ; 5 ; 3.0 ; 2 ; %f ; 103 ; 3.636 ; 68 ; %f", (1-maxhp), (hDestroyer[ROCKETDMG].FloatValue/263.157), (this.Class == TFClass_Scout) ? -2.0 : -1.0 );

		int Turret = this.SpawnWeapon("tf_weapon_rocketlauncher_directhit", 127, 1, 0, attribs);
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", Turret);
		this.SetWepInvis(0);
	}
	public void Death ()
	{
		StopSound(this.index, SNDCHAN_AUTO, TankIdle);
		StopSound(this.index, SNDCHAN_AUTO, TankMove);

		char sound[PLATFORM_MAX_PATH];
		Format(sound, PLATFORM_MAX_PATH, "%s%i.mp3", TankDeath, GetRandomInt(1, 2)); //sounds from Call of Duty 1
		EmitSoundToAll(sound, this.index, SNDCHAN_AUTO);
		AttachParticle(this.index, "buildingdamage_dispenser_fire1", 1.0);
		SetClientOverlay(this.index, "0");
		this.flIdleSound = 0.0;
		this.flSoundDelay = 0.0;
		SetEntProp(this.index, Prop_Send, "m_bCustomModelRotates", 0); 
	}
};

public CDestroyer ToCDestroyer (JailTank veh)
{
	return view_as<CDestroyer> (veh);
}

public void AddDestroyerToDownloads ()
{
	char s[PLATFORM_MAX_PATH];
	//char extensionsc[][] = { ".wav", ".mp3" };
	int i;
	PrecacheModel(DestroyerModel, true);
	for (i = 0; i < sizeof(extensions); i++) {
		Format(s, PLATFORM_MAX_PATH, "%s%s", DestroyerModelPrefix, extensions[i]);
		CheckDownload(s);
	}
	for (i = 0; i < sizeof(extensionsb); i++) {
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/marder3%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/marder3_blue%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/marder3_track%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/hetzer_track%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/hetzer_track_nm%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/marder_iii_blue%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/marder_iii_nm%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/marder_iii_red%s", extensionsb[i]);
		CheckDownload(s);
	}
}

public void AddDestroyerToMenu ( Menu& menu )
{
	menu.AddItem("7", "Marder III Tank Destroyer");
}

