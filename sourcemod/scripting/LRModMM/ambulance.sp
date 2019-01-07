
//defines
#define AmbModel		"models/custom/tanks/ambulance.mdl" //thx to Friagram for saving teh day!
#define AmbModelPrefix		"models/custom/tanks/ambulance"

#define AMB_ACCELERATION	6.0
#define AMB_SPEEDMAX		400.0
#define AMB_SPEEDMAXREVERSE	350.0 //20 units slower than medic
#define AMB_INITSPEED		250.0

methodmap CAmbulance < CTank	/*you MUST inherit from CTank if u want roadkilling to work*/
{
	public CAmbulance (const int ind, bool uid=false)
	{
		return view_as< CAmbulance >( CTank(ind, uid) );
	}
	/*property int iPassengers
	{
		public get() {				//{ return RightClickAmmo[ this.index ]; } {
			int item; hFields[this.index].GetValue("iRockets", item);
			return item;
		}
		public set( const int val ) {		//{ RightClickAmmo[ this.index ] = val; } {
			hFields[this.index].SetValue("iRockets", val);
		}
	}*/

	public void Think ()
	{
		int client = this.index;
		if( !IsPlayerAlive(client) )
			return;

		int buttons = GetClientButtons(client);
		float vell[3];	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vell);
		float currtime = GetGameTime();
		
		if( (buttons & IN_FORWARD) and vell[0] != 0.0 and vell[1] != 0.0 ) {
			StopSound(client, SNDCHAN_AUTO, ArmCarIdle);

			this.flSpeed += AMB_ACCELERATION;
			if( this.flSpeed > AMB_SPEEDMAX )
				this.flSpeed = AMB_SPEEDMAX;

			if( this.flIdleSound != 0.0 )
				this.flIdleSound = 0.0;
			if( this.flSoundDelay < currtime ) {
				//strcopy(s, PLATFORM_MAX_PATH, ArmCarMove);
				EmitSoundToAll(ArmCarMove, client, SNDCHAN_AUTO);
				this.flSoundDelay = currtime+1.0;
			}
		}
		else if( (buttons & IN_BACK) and vell[0] != 0.0 and vell[1] != 0.0 ) {
			StopSound(client, SNDCHAN_AUTO, ArmCarIdle);

			this.flSpeed += AMB_ACCELERATION;
			if( this.flSpeed > AMB_SPEEDMAXREVERSE )
				this.flSpeed = AMB_SPEEDMAXREVERSE;
			
			if( this.flIdleSound != 0.0 )
				this.flIdleSound = 0.0;
			if( this.flSoundDelay < currtime ) {
				//strcopy(s, PLATFORM_MAX_PATH, ArmCarMove);
				EmitSoundToAll(ArmCarMove, client, SNDCHAN_AUTO);
				this.flSoundDelay = currtime+1.0;
			}
		}
		else {
			StopSound(client, SNDCHAN_AUTO, ArmCarMove);
			this.flGas += 0.001;

			if( this.flSoundDelay != 0.0 )
				this.flSoundDelay = 0.0;
			if( this.flIdleSound < currtime ) {
				//strcopy(s, PLATFORM_MAX_PATH, ArmCarIdle);
				EmitSoundToAll(ArmCarIdle, client, SNDCHAN_AUTO);
				this.flIdleSound = currtime+2.0;
			}
			this.flSpeed -= AMB_ACCELERATION;
			if( this.flSpeed < AMB_INITSPEED )
				this.flSpeed = AMB_INITSPEED;
		}

		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", this.flSpeed);

		//TF2_AddCondition(client, TFCond_MegaHeal, 0.1);
		/* prevent tanks from being airblasted and gives a team colored aura to allow teams to tell who's on what side */

		JailTank base;
		for( int i=MaxClients ; i ; --i ) {
			if( !IsClientInGame(i) )
				continue;
			
			if( !IsInRange(client, i, 250.0) )
				continue;
			
			if( GetClientTeam(i) != this.iTeam or i == client )
				continue;
			
			base = JailTank(i);
			if (!base.bIsVehicle)
				continue;
			
			int maxhp = base.iHealth+hAmbulance[ROCKETDMG].IntValue;
			if (maxhp > base.iMaxHealth) maxhp = base.iMaxHealth;
			base.iHealth = maxhp;

			TF2_AddCondition(i, TFCond_InHealRadius, 0.1);
		}
	}
	public void SetModel ()
	{
		SetVariantString(AmbModel);
		AcceptEntityInput(this.index, "SetCustomModel");
		SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
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
		Format( attribs, sizeof(attribs), "400 ; 1.0 ; 125 ; %i ; 326 ; 0.0 ; 252 ; 0.0 ; 25 ; 0.0 ; 53 ; 1 ; 59 ; 0.0 ; 60 ; 0.01 ; 68 ; %f", (1-maxhp), (this.Class == TFClass_Scout) ? -2.0 : -1.0 );

		int Turret = this.SpawnWeapon("tf_weapon_smg", 16, 1, 0, attribs);
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", Turret);
	}

};

public CAmbulance ToCAmbulance (JailTank veh)
{
	return view_as<CAmbulance> (veh);
}

public void AddAmbToDownloads ()
{
	char s[PLATFORM_MAX_PATH];
	//char extensionsb[][] = { ".vtf", ".vmt" };
	//char extensionsc[][] = { ".wav", ".mp3" };
	int i;
	PrecacheModel(AmbModel, true);
	for (i = 0; i < sizeof(extensions); i++) {
		Format(s, PLATFORM_MAX_PATH, "%s%s", AmbModelPrefix, extensions[i]);
		CheckDownload(s);
	}
}

public void AddAmbToMenu ( Menu& menu )
{
	menu.AddItem("3", "Ambulance");
}

