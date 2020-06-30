
//defines
#define LightTankModel			"models/custom/tanks/panzer_short.mdl" // thx to Friagram for saving teh day!
#define LightTankModelPrefix		"models/custom/tanks/panzer_short"

methodmap CLightTank < CTank
{
	public CLightTank(const int client)
	{
		return view_as<CLightTank>( client );
	}

	public void PlaySpawnSound (const int number)
	{
		char sound[PLATFORM_MAX_PATH];
		Format(sound, PLATFORM_MAX_PATH, "%s%i.mp3", TankSpawn, number); // sounds from Company of Heroes 1
		EmitSoundToAll(sound, this.index, SNDCHAN_VOICE); EmitSoundToAll(sound, this.index, SNDCHAN_VOICE); EmitSoundToAll(sound, this.index, SNDCHAN_VOICE);
	}

	public void Think ()
	{
		if ( !IsPlayerAlive(this.index) )
			return;

		int buttons = GetClientButtons(this.index);
		float vell[3];	GetEntPropVector(this.index, Prop_Data, "m_vecAbsVelocity", vell);
		float currtime = GetGameTime();
		if ( (buttons & IN_FORWARD) and vell[0] != 0.0 and vell[1] != 0.0 )
		{
			StopSound(this.index, SNDCHAN_AUTO, TankIdle);

			this.flSpeed += hLightTank[ACCELERATION].FloatValue; /*simulates vehicular physics; not as good as Valve does with vehicle entities though*/
			if (this.flSpeed > hLightTank[INITSPEED].FloatValue)
				this.flSpeed = hLightTank[INITSPEED].FloatValue;

			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankMove);
				EmitSoundToAll(TankMove, this.index, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 110);
				this.flSoundDelay = currtime+27.745;
			}
		}
		else if ( (buttons & IN_BACK) and vell[0] != 0.0 and vell[1] != 0.0 )
		{
			StopSound(this.index, SNDCHAN_AUTO, TankIdle);

			this.flSpeed += hLightTank[ACCELERATION].FloatValue;
			if (this.flSpeed > hLightTank[SPEEDMAXREVERSE].FloatValue)
				this.flSpeed = hLightTank[SPEEDMAXREVERSE].FloatValue;
			
			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankMove);
				EmitSoundToAll(TankMove, this.index, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 110);
				this.flSoundDelay = currtime+27.745;
			}
		}
		else {
			StopSound(this.index, SNDCHAN_AUTO, TankMove);

			if (this.flSoundDelay != 0.0)
				this.flSoundDelay = 0.0;
			if ( this.flIdleSound < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankIdle);
				EmitSoundToAll(TankIdle, this.index, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 110);
				this.flIdleSound = currtime+4.475;
			}
			this.flSpeed -= hLightTank[ACCELERATION].FloatValue;
			if (this.flSpeed < hLightTank[INITSPEED].FloatValue)
				this.flSpeed = hLightTank[INITSPEED].FloatValue;
		}

		SetEntPropFloat(this.index, Prop_Send, "m_flMaxspeed", this.flSpeed);

		if ( (buttons & IN_ATTACK2) and this.bIsVehicle ) // MOUSE2 Rocket firing mechanic
		{
			if ( this.flLastFire < currtime ) {
				float vPosition[3], vAngles[3], vVec[3];
				GetClientEyePosition(this.index, vPosition);
				GetClientEyeAngles(this.index, vAngles);

				vVec[0] = Cosine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[1] = Sine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[2] = -Sine( DegToRad(vAngles[0]) );

				vPosition[0] += vVec[0] * 25.0;
				vPosition[1] += vVec[1] * 25.0;
				vPosition[2] += vVec[2] * 25.0;
				bool crit = ( TF2_IsPlayerInCondition(this.index, TFCond_Kritzkrieged) or TF2_IsPlayerInCondition(this.index, TFCond_CritOnWin) );
				TE_SetupMuzzleFlash(vPosition, vAngles, 9.0, 1);
				TE_SendToAll();
				int rocket = ShootRocket(this.index, crit, vPosition, vAngles, g_LR.GetParameterFloat("RocketSpeed", 4000.0)*0.3333, hLightTank[ROCKETDMG].FloatValue, "", true);
				if (rocket>MaxClients)
					SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon"));
				char s[PLATFORM_MAX_PATH];
				Format(s, PLATFORM_MAX_PATH, "%s%i.mp3", TankShoot, GetRandomInt(1, 3)); //sounds from Call of duty 1
				EmitSoundToAll(s, this.index, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 110);
				CreateTimer(1.0, Timer_ReloadTank, this.userid, TIMER_FLAG_NO_MAPCHANGE); //useless, only plays a 'reload' sound
				this.flLastFire = currtime + 4.0;

				float PunchVec[3] = {80.0, 0.0, 45.0};
				SetEntPropVector(this.index, Prop_Send, "m_vecPunchAngleVel", PunchVec);
			}
		}
		//CreateTimer(0.1, Timer_TankCrush, client);
		//TF2_AddCondition(this.index, TFCond_MegaHeal, 0.2); /*prevent tanks from being airblasted and gives a team colored aura to allow teams to tell who's on what side */
	}
	public void SetModel ()
	{
		SetVariantString(LightTankModel);
		AcceptEntityInput(this.index, "SetCustomModel");
		SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		//SetEntPropFloat(this.index, Prop_Send, "m_flModelScale", 1.25);
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
	}

	public void Equip ()
	{
		TF2_RemoveAllWeapons(this.index);
		int maxhp = GetEntProp(this.index, Prop_Data, "m_iMaxHealth");

		char attribs[128];
		Format( attribs, sizeof(attribs), "356 ; 1.0 ; 400 ; 1.0 ; 125 ; %i ; 326 ; 0.0 ; 252 ; 0.0 ; 25 ; 0.0 ; 53 ; 1 ; 59 ; 0.0 ; 60 ; 0.01 ; 99 ; 2.0 ; 68 ; %f", (1-maxhp), (this.Class == TFClass_Scout) ? -2.0 : -1.0 );

		int Turret = this.SpawnWeapon("tf_weapon_smg", 16, 1, 0, attribs);
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", Turret);
	}
};

public CLightTank ToCLightTank (JailTank veh)
{
	return view_as<CLightTank> (veh);
}

public void AddLightTankToDownloads ()
{
	char s[PLATFORM_MAX_PATH];
	//char extensionsb[][] = { ".vtf", ".vmt" };
	//char extensionsc[][] = { ".wav", ".mp3" };
	int i;
	PrecacheModel(LightTankModel, true);
	for (i = 0; i < sizeof(extensions); i++) {
		Format(s, PLATFORM_MAX_PATH, "%s%s", LightTankModelPrefix, extensions[i]);
		CheckDownload(s);
	}
}

public void AddLightTankToMenu ( Menu& menu )
{
	menu.AddItem("6", "Panzer III");
}

