
//defines
#define ArmCarModel		"models/custom/daimler/daimler.mdl"	// Thx to Friagram for saving teh day! Credit goes to daimler for model!
#define ArmCarModelPrefix	"models/custom/daimler/daimler"
#define ArmCarShoot		"armoredcar/cannon.mp3"
#define ArmCarSpawn		"armoredcar/spawn"
#define ArmCarMove		"armoredcar/driveloop.mp3"
#define ArmCarIdle		"armoredcar/idle.mp3"

methodmap CArmCar < CTank
{
	public CArmCar (const int client)
	{
		return view_as<CArmCar>( client );
	}
	
	property int iCannonClipsize
	{
		public get() { return this.GetValue("iCannonClipsize"); }
		public set( const int i ) { this.SetValue("iCannonClipsize", i); }
	}

	public void PlaySpawnSound (const int number)
	{
		char sound[PLATFORM_MAX_PATH];
		Format(sound, PLATFORM_MAX_PATH, "%s%i.mp3", ArmCarSpawn, number); //sounds from Company of Heroes 1
		EmitSoundToAll(sound, this.index, SNDCHAN_VOICE); EmitSoundToAll(sound, this.index, SNDCHAN_VOICE); EmitSoundToAll(sound, this.index, SNDCHAN_VOICE);
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
			StopSound(client, SNDCHAN_AUTO, ArmCarIdle);

			this.flSpeed += hArmoredCar[ACCELERATION].FloatValue; /*simulates vehicular physics; not as good as Valve does with vehicle entities though*/
			if (this.flSpeed > hArmoredCar[SPEEDMAX].FloatValue)
				this.flSpeed = hArmoredCar[SPEEDMAX].FloatValue;

			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, ArmCarMove);
				EmitSoundToAll(ArmCarMove, client, SNDCHAN_AUTO);
				this.flSoundDelay = currtime+1.0;
			}
		}
		else if ( (buttons & IN_BACK) and vell[0] != 0.0 and vell[1] != 0.0 )
		{
			StopSound(client, SNDCHAN_AUTO, ArmCarIdle);

			this.flSpeed += hArmoredCar[ACCELERATION].FloatValue;

			if (this.flSpeed > hArmoredCar[SPEEDMAXREVERSE].FloatValue)
				this.flSpeed = hArmoredCar[SPEEDMAXREVERSE].FloatValue;

			if (this.flIdleSound != 0.0)
				this.flIdleSound = 0.0;
			if ( this.flSoundDelay < currtime ) {
				//strcopy(snd, PLATFORM_MAX_PATH, ArmCarMove);
				EmitSoundToAll(ArmCarMove, client, SNDCHAN_AUTO);
				this.flSoundDelay = currtime+1.0;
			}
		}
		else {
			StopSound(client, SNDCHAN_AUTO, ArmCarMove);
			
			if (this.flSoundDelay != 0.0)
				this.flSoundDelay = 0.0;

			if (this.flIdleSound < currtime) {
				//strcopy(snd, PLATFORM_MAX_PATH, ArmCarIdle);
				EmitSoundToAll(ArmCarIdle, client, SNDCHAN_AUTO);
				this.flIdleSound = currtime+2.0;
			}
			this.flSpeed -= hArmoredCar[ACCELERATION].FloatValue;
			if (this.flSpeed < hArmoredCar[INITSPEED].FloatValue)
				this.flSpeed = hArmoredCar[INITSPEED].FloatValue;
		}

		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", this.flSpeed);

		if( (buttons & IN_ATTACK2) and this.bIsVehicle ) {	// MOUSE2 20mm Hitscan Cannon
			if( this.flLastFire < currtime ) {
				if( this.iCannonClipsize <= 0 ) {
					this.flLastFire = currtime + 1.3;
					SetPawnTimer(_ReloadCannon, 1.0, this);
					EmitSoundToAll("weapons/flaregun_worldreload.wav", client, SNDCHAN_AUTO);
					EmitSoundToAll("weapons/flaregun_worldreload.wav", client, SNDCHAN_AUTO);
					return;
				}
				float vPosition[3], vAngles[3], vVec[3];
				GetClientEyePosition(client, vPosition);
				GetClientEyeAngles(client, vAngles);
				
				vVec[0] = Cosine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[1] = Sine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
				vVec[2] = -Sine( DegToRad(vAngles[0]) );
				
				vPosition[0] += vVec[0] * 40.0;
				vPosition[1] += vVec[1] * 40.0;
				vPosition[2] += vVec[2] * 40.0;
				vPosition[2] += 3.0;
				
				float RandAngle = GetRandomFloat(0.0, 360.0); // Handle's 20mm Cannon accuracy
				float RandMagnitudeX = (GetRandomInt(0, 250) / 100.0), RandMagnitudeY = (GetRandomInt(0, 250) / 100.0);
				
				vAngles[0] += (RandMagnitudeX)*Cosine(RandAngle) * (GetRandomInt(0, 1) == 1 ? -1 : 1);
				vAngles[1] += (RandMagnitudeY)*Sine(RandAngle) * (GetRandomInt(0, 1) == 1 ? -1 : 1);

				int beamcolor[4];
				switch( this.iTeam ) {
					case 2: { beamcolor[0] = 190; beamcolor[1] = 59; beamcolor[2] = 59; }
					case 3: { beamcolor[0] = 71; beamcolor[1] = 102; beamcolor[2] = 190; }
				}
				beamcolor[3] = 255;

				TR_TraceRayFilter( vPosition, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client );
				float endpos[3]; TR_GetEndPosition(endpos);

				TE_SetupBeamPoints( vPosition, endpos, PrecacheModel("sprites/laser.vmt", true), PrecacheModel("sprites/laser.vmt", true), 1, 1, 1.0, 8.0, 8.0, 5, 2.0, beamcolor, 0 );
				TE_SendToAll();
				
				TE_SetupMuzzleFlash(vPosition, vAngles, 5.0, 1);
				TE_SendToAll();

				if ( TR_DidHit() ) {
					int target = TR_GetEntityIndex();
					int dmgflag = DMG_DIRECT;
					float dmg = hArmoredCar[ROCKETDMG].FloatValue;
					if ( IsClientValid(target) and target != client and GetClientTeam(target) != this.iTeam )
					{
						if ( TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) or TF2_IsPlayerInCondition(client, TFCond_CritOnWin) )
						{
							dmgflag |= DMG_CRIT;
						}
						SDKHooks_TakeDamage( target, client, client, dmg, dmgflag );
					}
					else if ( target > MaxClients and IsValidEntity(target) and GetEntProp(target, Prop_Data, "m_iTeamNum") != this.iTeam)
						SDKHooks_TakeDamage( target, client, client, dmg, dmgflag);
				}
				EmitSoundToAll(ArmCarShoot, client, SNDCHAN_AUTO); EmitSoundToAll(ArmCarShoot, client, SNDCHAN_AUTO); EmitSoundToAll(ArmCarShoot, client, SNDCHAN_AUTO);
				// Sounds from Company of Heroes 1
				this.flLastFire = currtime + 0.4;
				this.iCannonClipsize -= 1;
				
				float PunchVec[3] = {40.0, 0.0, 30.0};
				SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", PunchVec);
			}
		}
		// Stop airblast from pushing vehicles
		//TF2_AddCondition(client, TFCond_MegaHeal, 0.2);
	}
	public void SetModel ()
	{
		SetVariantString(ArmCarModel);
		AcceptEntityInput(this.index, "SetCustomModel");
		SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		//SetEntPropFloat(this.index, Prop_Send, "m_flModelScale", 1.25);
	}

	public void Death ()
	{
		StopSound(this.index, SNDCHAN_AUTO, ArmCarIdle);
		StopSound(this.index, SNDCHAN_AUTO, ArmCarMove);

		char sound[PLATFORM_MAX_PATH];
		Format(sound, PLATFORM_MAX_PATH, "%s%i.mp3", TankDeath, GetRandomInt(1, 2)); //sounds from Call of Duty 1
		EmitSoundToAll(sound, this.index, SNDCHAN_AUTO);
		AttachParticle(this.index, "buildingdamage_dispenser_fire1", 1.0);
		this.flIdleSound = 0.0;
		this.flSoundDelay = 0.0;
	}

	public void Equip ()
	{
		TF2_RemoveAllWeapons(this.index);
		int maxhp = GetEntProp(this.index, Prop_Data, "m_iMaxHealth");

		char attribs[128];
		Format( attribs, sizeof(attribs), "400 ; 1.0 ; 125 ; %i ; 326 ; 0.0 ; 252 ; 0.0 ; 25 ; 0.0 ; 53 ; 1 ; 59 ; 0.0 ; 60 ; 0.01 ; 100 ; 0.01 ; 68 ; %f", (1-maxhp), (this.Class == TFClass_Scout) ? -2.0 : -1.0 );
		int Turret = this.SpawnWeapon("tf_weapon_smg", 16, 1, 0, attribs);
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", Turret);
		this.iCannonClipsize = 5;
	}

};

public CArmCar ToCArmCar(JailTank veh)
{
	return view_as<CArmCar> (veh);
}

public void AddArmCarToDownloads()
{
	char s[PLATFORM_MAX_PATH];
	//char extensionsc[][] = { ".wav", ".mp3" };

	AddFileToDownloadsTable("sound/armoredcar/driveloop.mp3");
	AddFileToDownloadsTable("sound/armoredcar/cannon.mp3");
	AddFileToDownloadsTable("sound/armoredcar/idle.mp3");

	int i;
	PrecacheModel(ArmCarModel, true);
	for (i = 0; i < sizeof(extensions); i++)
	{
		Format(s, PLATFORM_MAX_PATH, "%s%s", ArmCarModelPrefix, extensions[i]);
		if (FileExists(s, true))
			AddFileToDownloadsTable(s);
	}
	for (i = 0; i < sizeof(extensionsb); i++)
	{
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/daimler/daimler%s", extensionsb[i]);
		if (FileExists(s, true))
			AddFileToDownloadsTable(s);
		Format(s, PLATFORM_MAX_PATH, "materials/models/custom/daimler/daimler_blue%s", extensionsb[i]);
		if (FileExists(s, true))
			AddFileToDownloadsTable(s);
	}
	PrecacheSound(ArmCarShoot, true);
	Format(s, PLATFORM_MAX_PATH, "sound/%s", ArmCarShoot);
	if (FileExists(s, true))
		AddFileToDownloadsTable(s);

	for (i = 1; i < 4; i++) {
		Format(s, PLATFORM_MAX_PATH, "%s%i.mp3", ArmCarSpawn, i);
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		if (FileExists(s, true))
			AddFileToDownloadsTable(s);
	}
	PrecacheSound(ArmCarMove, true);
	PrecacheSound(ArmCarIdle, true);
}

public void AddArmCarToMenu( Menu& menu )
{
	menu.AddItem("2", "Armored Car");
}
public void _ReloadCannon(const CArmCar car)
{
	car.iCannonClipsize += 5;
}

