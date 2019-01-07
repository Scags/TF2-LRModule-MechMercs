
//defines
#define KingTankModel			"models/custom/tanks/tiger2.mdl" //thx to Friagram for saving teh day!
#define KingTankModelPrefix		"models/custom/tanks/tiger2"

methodmap CKingTank < CTank
{
	public CKingTank(const int client)
	{
		return view_as<CKingTank>( client );
	}
	public void Think ()
	{
		int client = this.index;
		if ( !IsPlayerAlive(client) )
			return;

		int buttons = GetClientButtons(client);
		float vell[3];	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vell);
		float currtime = GetGameTime();
		if ( (buttons & IN_FORWARD) and vell[0] != 0.0 and vell[1] != 0.0 )
		{
			StopSound(client, SNDCHAN_AUTO, TankIdle);

			this.flSpeed += hKingTank[ACCELERATION].FloatValue; /*simulates vehicular physics; not as good as Valve does with vehicle entities though*/
			if (this.flSpeed > hKingTank[SPEEDMAX].FloatValue)
				this.flSpeed = hKingTank[SPEEDMAX].FloatValue;

			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankMove);
				EmitSoundToAll(TankMove, client, SNDCHAN_AUTO, _, _, _, 80);
				this.flSoundDelay = currtime+31.0;
			}
		}
		else if ( (buttons & IN_BACK) and vell[0] != 0.0 and vell[1] != 0.0 )
		{
			StopSound(client, SNDCHAN_AUTO, TankIdle);

			this.flSpeed += hKingTank[ACCELERATION].FloatValue;
			if (this.flSpeed > hKingTank[SPEEDMAXREVERSE].FloatValue)
				this.flSpeed = hKingTank[SPEEDMAXREVERSE].FloatValue;
			
			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankMove);
				EmitSoundToAll(TankMove, client, SNDCHAN_AUTO, _, _, _, 80);
				this.flSoundDelay = currtime+31.0;
			}
		}
		else {
			StopSound(client, SNDCHAN_AUTO, TankMove);
			this.flGas += 0.001;

			if (this.flSoundDelay != 0.0)
				this.flSoundDelay = 0.0;
			if ( this.flIdleSound < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, TankIdle);
				EmitSoundToAll(TankIdle, client, SNDCHAN_AUTO, _, _, _, 80);
				this.flIdleSound = currtime+5.0;
			}
			this.flSpeed -= hKingTank[ACCELERATION].FloatValue;
			if (this.flSpeed < hKingTank[INITSPEED].FloatValue)
				this.flSpeed = hKingTank[INITSPEED].FloatValue;
		}

		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", this.flSpeed);

		if ( (buttons & IN_ATTACK2) and this.bIsVehicle ) //MOUSE2 Rocket firing mechanic
		{
			if ( this.flLastFire < currtime ) {
				float vPosition[3], vAngles[3], vVec[3];
				GetClientEyePosition(client, vPosition);
				GetClientEyeAngles(client, vAngles);

				vVec[0] = Cosine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[1] = Sine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[2] = -Sine( DegToRad(vAngles[0]) );

				vPosition[0] += vVec[0] * 100.0;
				vPosition[1] += vVec[1] * 100.0;
				vPosition[2] += vVec[2] * 100.0;
				bool crit = ( TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) or TF2_IsPlayerInCondition(client, TFCond_CritOnWin) );
				TE_SetupMuzzleFlash(vPosition, vAngles, 9.0, 1);
				TE_SendToAll();
				ShootRocket(client, crit, vPosition, vAngles, hRocketSpeed.FloatValue, hKingTank[ROCKETDMG].FloatValue, "");
				char s[PLATFORM_MAX_PATH];
				Format(s, PLATFORM_MAX_PATH, "%s%i.mp3", TankShoot, GetRandomInt(1, 3)); //sounds from Call of duty 1
				EmitSoundToAll(s, client, SNDCHAN_AUTO, _, _, _, 80);
				CreateTimer(1.0, Timer_ReloadTank, this.userid, TIMER_FLAG_NO_MAPCHANGE); //useless, only plays a 'reload' sound
				this.flLastFire = currtime + 4.0;

				float PunchVec[3] = {100.0, 0.0, 150.0};
				SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", PunchVec);
			}
		}
		//CreateTimer(0.1, Timer_TankCrush, client);
		//TF2_AddCondition(client, TFCond_MegaHeal, 0.2); /*prevent tanks from being airblasted and gives a team colored aura to allow teams to tell who's on what side */
	}
	public void SetModel ()
	{
		SetVariantString(KingTankModel);
		AcceptEntityInput(this.index, "SetCustomModel");
		SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		//SetEntPropFloat(this.index, Prop_Send, "m_flModelScale", 1.5);
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
		Format( attribs, sizeof(attribs), "521 ; 1.0 ; 400 ; 1.0 ; 125 ; %i ; 6 ; 0.5 ; 326 ; 0.0 ; 252 ; 0.0 ; 25 ; 0.0 ; 53 ; 1 ; 59 ; 0.0 ; 60 ; 0.01 ; 68 ; %f", (1-maxhp), (this.Class == TFClass_Scout) ? -2.0 : -1.0 );

		int Turret = this.SpawnWeapon("tf_weapon_smg", 16, 1, 0, attribs);
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", Turret);
		//SetClientOverlay( this.index, "effects/combine_binocoverlay" );
	}
};

public CKingTank ToCKingTank (JailTank veh)
{
	return view_as<CKingTank> (veh);
}

public void AddKingTankToDownloads ()
{
	char s[PLATFORM_MAX_PATH];
	//char extensionsc[][] = { ".wav", ".mp3" };
	int i;
	PrecacheModel(KingTankModel, true);
	for (i = 0; i < sizeof(extensions); i++) {
		Format(s, PLATFORM_MAX_PATH, "%s%s", KingTankModelPrefix, extensions[i]);
		CheckDownload(s);
	}
	for (i = 0; i < sizeof(extensionsb); i++) {
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/tiger2%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/tiger2_blue%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/tiger2_track%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/tiger_ii_track%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/tiger_ii_track_nm%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/e-75_blue%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/e-75_nm%s", extensionsb[i]);
		CheckDownload(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/tanks/e-75_red%s", extensionsb[i]);
		CheckDownload(s);
	}
}

public void AddKingTankToMenu ( Menu& menu )
{
	menu.AddItem("5", "King Panzer (Tiger II)");
}


