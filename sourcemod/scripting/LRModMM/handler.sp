
#include "LRModMM/vehicles.sp"

enum /*Vehicles*/ {	/* When you add custom vehicles, add to the anonymous enum as the vehicle's ID */
	Tank = 0,
	ArmoredCar = 1,
	Ambulance = 2,
	PanzerIII = 3,
	KingPanzer = 4,
	Destroyer = 5
};

char VehicleHorns[][] = {
	"acvshtank/awooga.mp3",
	"acvshtank/dukesofhazzard.mp3",
	"acvshtank/lacucaracha.mp3",
	"acvshtank/twohonks.mp3"
};

#define MechMercsTheme 		"acvshtank/theme.mp3"

public void ManageDownloads()
{
	AddTankToDownloads();
	AddArmCarToDownloads();
	AddAmbToDownloads();
	AddKingTankToDownloads();
	AddLightTankToDownloads();
	AddDestroyerToDownloads();

	char s[PLATFORM_MAX_PATH];
	int i;
	for( i=1 ; i<6 ; i++ ) {
		Format(s, PLATFORM_MAX_PATH, "weapons/fx/rics/ric%i.wav", i);
		PrecacheSound(s, true);
	}
	PrecacheSound("ui/item_store_add_to_cart.wav", true);
	PrecacheSound("weapons/wrench_hit_build_success1.wav", true);
	PrecacheSound("weapons/wrench_hit_build_success2.wav", true);
	PrecacheSound("weapons/wrench_hit_build_fail.wav", true);
	PrecacheSound("weapons/flaregun_worldreload.wav", true);
	
	for( i=0 ; i<sizeof(VehicleHorns) ; i++) {
		PrecacheSound(VehicleHorns[i], true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", VehicleHorns[i]);
		CheckDownload(s);
	}
	if (FileExists("sound/" ... MechMercsTheme))
	{
		PrecacheSound(MechMercsTheme);
		AddFileToDownloadsTable("sound/" ... MechMercsTheme);
	}
}
public void ManageHealth(const JailTank base)
{
	switch( base.iType ) {
		case -1: {}
		case Tank: {
			CTank tanker = ToCTank(base);
			tanker.iHealth = tanker.iMaxHealth = hTank[HEALTH].IntValue; /* tank's are armored vehicles, give them 4x the normal health */
			tanker.PlaySpawnSound(GetRandomInt(1, 3));
		}
		case ArmoredCar: {
			CArmCar car = ToCArmCar(base);
			car.iHealth = car.iMaxHealth = hArmoredCar[HEALTH].IntValue; /* car's aren't well armored vehicles, give them 2x+150 normal health */
			car.PlaySpawnSound(GetRandomInt(1, 3));
		}
		case Ambulance: {
			CAmbulance amb = ToCAmbulance(base);
			amb.iHealth = amb.iMaxHealth = hAmbulance[HEALTH].IntValue; /* ambulance isn't armored or armed, give 2x normal hp */
		}
		case KingPanzer: {
			CKingTank king = ToCKingTank(base);
			king.iHealth = king.iMaxHealth = hKingTank[HEALTH].IntValue; /* KING PANZER! give them 20x the normal health */
			king.PlaySpawnSound(GetRandomInt(1, 3));
		}
		case PanzerIII: {
			CLightTank pnzr3 = ToCLightTank(base);
			pnzr3.iHealth = pnzr3.iMaxHealth = hLightTank[HEALTH].IntValue;
			pnzr3.PlaySpawnSound(GetRandomInt(1, 3));
		}
		case Destroyer: {
			CDestroyer dest = ToCDestroyer(base);
			dest.iHealth = dest.iMaxHealth = hDestroyer[HEALTH].IntValue;
		}
	}
	SetEntityHealth(base.index, base.iHealth);
}

public void ManageConnect(const int client)
{
	CTank(client).flLastFire = 0.0;
}

public void ManageOnTouchPlayer(const JailTank base, const JailTank victim)
{
	switch( base.iType ) {
		case -1: {}
		case Tank, ArmoredCar, Ambulance, KingPanzer, PanzerIII, Destroyer: {
			if( GetEntPropEnt(victim.index, Prop_Send, "m_hGroundEntity") == base.index ) // If human/vehicle on vehicle, ignore.
				return;

			if( GetEntPropEnt(base.index, Prop_Send, "m_hGroundEntity") == victim.index ) // Vehicle is standing on player, kill them!
				SDKHooks_TakeDamage(victim.index, base.index, base.index, hCrushDmg.FloatValue*5.0, DMG_VEHICLE);

			//int buttons = GetClientButtons(base.index);

			float vecShoveDir[3];	GetEntPropVector(base.index, Prop_Data, "m_vecAbsVelocity", vecShoveDir);
			if( vecShoveDir[0] != 0.0 and vecShoveDir[1] != 0.0 ) {
				float entitypos[3];	GetEntPropVector(base.index, Prop_Data, "m_vecAbsOrigin", entitypos);
				float targetpos[3];	GetEntPropVector(victim.index, Prop_Data, "m_vecAbsOrigin", targetpos);

				float vecTargetDir[3]; SubtractVectors(entitypos, targetpos, vecTargetDir);
				NormalizeVector(vecShoveDir, vecShoveDir);
				NormalizeVector(vecTargetDir, vecTargetDir);
				
				if( GetVectorDotProduct(vecShoveDir, vecTargetDir) <= 0 )
					SDKHooks_TakeDamage(victim.index, base.index, base.index, hCrushDmg.FloatValue, DMG_VEHICLE);
			}
		}
	}
}



/*
for buildings, it's unnecessary to do vector math because it's impossible to build things on players and there's no prospect that buildings will ever be on top of vehicles. tl;dr - Buildings are stationary, just hurt them when touched.
*/

public void ManageOnTouchBuilding(const JailTank base, const int building)
{
	switch( base.iType ) {
		case -1: {}
		case Tank, ArmoredCar, Ambulance, KingPanzer, PanzerIII, Destroyer: {
			SDKHooks_TakeDamage( building, base.index, base.index, hCrushDmg.FloatValue/2.0, DMG_VEHICLE);
			//SetVariantInt( RoundToCeil(CrushDmg.FloatValue)/2 );
			//AcceptEntityInput(building, "RemoveHealth");
		}
	}
}

public void ManageVehicleThink(const JailTank base)
{
	int wep = GetActiveWep(base.index);
	if (wep != -1)
		SetWeaponAmmo(wep, 200);

	switch( base.iType ) {
		case -1: {}
		case Tank:		ToCTank(base).Think();
		case ArmoredCar:	ToCArmCar(base).Think();
		case Ambulance:		ToCAmbulance(base).Think();
		case KingPanzer:	ToCKingTank(base).Think();
		case PanzerIII:		ToCLightTank(base).Think();
		case Destroyer:		ToCDestroyer(base).Think();
	}
}

public void ManageVehicleModels(const JailTank base)
{
	switch( base.iType ) {
		case -1: {}
		case Tank:		ToCTank(base).SetModel();
		case ArmoredCar:	ToCArmCar(base).SetModel();
		case Ambulance:		ToCAmbulance(base).SetModel();
		case KingPanzer:	ToCKingTank(base).SetModel();
		case PanzerIII:		ToCLightTank(base).SetModel();
		case Destroyer:		ToCDestroyer(base).SetModel();
	}
}

public void ManageVehicleDeath(const JailTank base)
{
	switch( base.iType ) {
		case -1: {}
		case Tank:		ToCTank(base).Death();
		case ArmoredCar:	ToCArmCar(base).Death();
		case Ambulance:		ToCAmbulance(base).Death();
		case KingPanzer:	ToCKingTank(base).Death();
		case PanzerIII:		ToCLightTank(base).Death();
		case Destroyer:		ToCDestroyer(base).Death();
	}
}

public void ManageVehicleTransition(const JailTank base) /* whatever stuff needs initializing should be done here */
{
	switch( base.iType ) {
		case -1: {}
		case Tank: {
			CTank tanker = ToCTank(base);
			tanker.SetModel();
			tanker.Equip();
		}
		case ArmoredCar: {
			CArmCar car = ToCArmCar(base);
			car.SetModel();
			car.Equip();
		}
		case Ambulance: {
			CAmbulance heal = ToCAmbulance(base);
			heal.SetModel();
			heal.Equip();
		}
		case KingPanzer: {
			CKingTank king = ToCKingTank(base);
			king.SetModel();
			king.Equip();
		}
		case PanzerIII: {
			CLightTank pnzr3 = ToCLightTank(base);
			pnzr3.SetModel();
			pnzr3.Equip();
		}
		case Destroyer: {
			CDestroyer marder = ToCDestroyer(base);
			marder.SetModel();
			marder.Equip();
		}
	}
	if( base.bIsVehicle ) {
		int ent = -1;
		while( (ent = FindEntityByClassname(ent, "tf_wearable*")) != -1 ) {
			if( GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == base.index )
				AcceptEntityInput(ent, "kill");
		}
	}
	SetClientOverlay(base.index, "effects/combine_binocoverlay");
}

public Action ManageOnVehicleTakeDamage(const JailTank victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	char classname [64], strEntname [32];

	if (IsValidEdict(inflictor))
		GetEntityClassname(inflictor, strEntname, sizeof(strEntname));
	if (IsValidEdict(weapon))
		GetEdictClassname(weapon, classname, sizeof(classname));
	
	int tanker = victim.index;

	switch ( victim.iType ) {
		case -1: {}
		case Tank, ArmoredCar, Ambulance, KingPanzer, PanzerIII, Destroyer: {
			if (tanker == attacker) {	// vehicles shouldn't be able to hurt themselves
				damage *= 0.0;
				return Plugin_Changed;
			}
			if ( (attacker > MaxClients or attacker <= 0) and !(damagetype & DMG_FALL) ) {	// if null attacker, just kill the vehicle outright
				//TF2_IgnitePlayer(tanker, attacker);
				CreateTimer(0.1, Timer_VehicleDeath, victim.userid);
				return Plugin_Continue;
			}
			
			if( damagetype & (DMG_BULLET|DMG_CLUB|DMG_SLASH) ) {
				TE_SetupArmorRicochet(damagePosition, NULL_VECTOR);
				TE_SendToAll();
				char sound[PLATFORM_MAX_PATH]; Format( sound, PLATFORM_MAX_PATH, "weapons/fx/rics/ric%i.wav", GetRandomInt(1, 5) );
				EmitSoundToAll(sound, tanker); EmitSoundToAll(sound, tanker);
			}
			
			if ( damage > 100.0 and !strcmp(classname, "tf_weapon_knife", false) ) {	// Vehicles shouldn't die from a single backstab
				damage = 50.0/6.0;	// backstab calc will result this to 100 dmg. 
				TF2_AddCondition(victim.index, TFCond_MarkedForDeath, 15.0, inflictor);
				return Plugin_Changed;
			}
			
			if( TF2_IsPlayerInCondition(victim.index, TFCond_MarkedForDeath) )
				damage *= 2.0;
			
			if( TF2_IsPlayerInCondition(victim.index, TFCond_Jarated) )
				damage *= 1.25;

			if ( damagetype & DMG_CRIT ) {	// Vehicles don't take crits, think of them as Building Human hybrids.
				damage /= 3.0;
				return Plugin_Changed;
			}

//			if ( !damagecustom and TF2_IsPlayerInCondition(tanker, TFCond_Taunting) and TF2_IsPlayerInCondition(attacker, TFCond_Taunting) )
//			{
//				damage = victim.iHealth+0.1;	// Rock Paper Scissors patch. RPS damagecustom ID is 0
//				return Plugin_Changed;
//			}
				

			/* vehicles are weak to explosives but not to bullets and fire */
			/*{
				if ( !strcmp(strEntname, "tf_projectile_rocket", false)
					or !strcmp(classname, "tf_weapon_grenadelauncher", false)
					or !strcmp(classname, "tf_weapon_pipebomblauncher", false)
					or !strcmp(classname, "tf_weapon_cannon", false)
					or !strcmp(classname, "tf_weapon_particle_cannon", false)
					or !strcmp(strEntname, "tf_projectile_sentryrocket", false)
					or !strcmp(strEntname, "env_explosion", false) )
				{
					damage *= 2.0;
				}
				else if ( !strcmp(classname, "tf_weapon_flamethrower", false) )
					damage *= 0.2;
				else if ( weapon == GetPlayerWeaponSlot(attacker, 2) )
					damage *= 0.5;
				else {
					TE_SetupArmorRicochet(damagePosition, NULL_VECTOR);
					TE_SendToAll();
					char sound[PLATFORM_MAX_PATH]; Format( sound, PLATFORM_MAX_PATH, "weapons/fx/rics/ric%i.wav", GetRandomInt(1, 5) );
					EmitSoundToAll(sound, tanker); EmitSoundToAll(sound, tanker);
					damage *= 0.2;
				}
				return Plugin_Changed;
			}*/
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action ManageOnVehicleDealDamage(const JailTank victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	/*float Pos[3]; GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Pos);	// Spot of attacker
	float Pos2[3]; GetEntPropVector(victim.index, Prop_Send, "m_vecOrigin", Pos2);	// Spot of victim
	float dist = GetVectorDistance(Pos, Pos2, false);				// Calculate dist between target and attacker
	char classname[64], strEntname[32];

	if( IsValidEdict(inflictor) )
		GetEntityClassname(inflictor, strEntname, sizeof(strEntname));
	if( IsValidEdict(weapon) )
		GetEdictClassname(weapon, classname, sizeof(classname));
	*/
	switch( JailTank(attacker).iType ) {
		case -1: {}
		case Tank, ArmoredCar, Ambulance, KingPanzer, PanzerIII, Destroyer: {
			if( victim.index != attacker and victim.iTeam != GetClientTeam(attacker) ) {
				// void damage fall off
				/*if ( !strcmp(strEntname, "tf_projectile_rocket", false) ) {
					if (dist > 966.0)
						dist = 966.0;
					if (dist < 409.6)
						dist = 409.6;
					damage *= dist/512.0;
					return Plugin_Changed;
				}
				if ( !strcmp(classname, "tf_weapon_smg", false) ) {
					if (dist > 1024.0)
						dist = 1024.0;
					if (dist < 341.33)
						dist = 341.33;
					damage *= dist/512.0;
					return Plugin_Changed;
				}*/
			}
		}
	}
	return Plugin_Continue;
}

public void ManageVehicleKillPlayer(const JailTank attacker, const JailTank victim, Event event) //to lazy to code this better lol
{
	int dmgbits = event.GetInt("damagebits");
	if (dmgbits & DMG_VEHICLE) {
		event.SetString("weapon_logclassname", "vehicle_crush");
		event.SetString("weapon", "mantreads");
		//event.SetInt("customkill", TF_CUSTOM_TRIGGER_HURT);
		//event.SetInt("playerpenetratecount", 0);

		char s[PLATFORM_MAX_PATH];
		strcopy(s, PLATFORM_MAX_PATH, TankCrush);
		EmitSoundToAll(s, attacker.index);
	}
	if (dmgbits & DMG_DIRECT) {	// For armored car
		event.SetString("weapon_logclassname", "20mm_cannon");
		event.SetString("weapon", "detonator");
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	CHECK() Plugin_Continue;

	JailTank player = JailTank(client);
	int vehflags = GetEntityFlags(client);

/*
	This controls the angularity of how treads function in real life.
	Tanks should NOT be able to strafe left or right like a crab.
	force the left and right buttons to instead turn player angles and nullify the velocity of strafing.
*/
	if( player.bIsVehicle and !IsFakeClient(client) ) {
		switch( player.iType ) {
			case ArmoredCar, Ambulance, Destroyer: {
				if( (buttons & IN_MOVELEFT) and (vehflags & FL_ONGROUND) ) {
					angles[1] += 10.0;
					vel[1] = 1.0;
					TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
					return Plugin_Changed;
				}
				if( (buttons & IN_MOVERIGHT) and (vehflags & FL_ONGROUND) ) {
					angles[1] -= 10.0;
					vel[1] = 1.0;
					TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
					return Plugin_Changed;
				}
			}
			case Tank,PanzerIII: {
				if( (buttons & IN_MOVELEFT) and (vehflags & FL_ONGROUND) ) {
					angles[1] += 7.0;
					vel[1] = 1.0;
					TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
					return Plugin_Changed;
				}
				if( (buttons & IN_MOVERIGHT) and (vehflags & FL_ONGROUND) ) {
					angles[1] -= 7.0;
					vel[1] = 1.0;
					TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
					return Plugin_Changed;
				}
			}
			case KingPanzer: {
				if( (buttons & IN_MOVELEFT) and (vehflags & FL_ONGROUND) ) {
					angles[1] += 4.0;
					vel[1] = 1.0;
					TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
					return Plugin_Changed;
				}
				if( (buttons & IN_MOVERIGHT) and (vehflags & FL_ONGROUND) ) {
					angles[1] -= 4.0;
					vel[1] = 1.0;
					TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
					return Plugin_Changed;
				}
			}
		}
		// novelty horn honking! It's the small details that really add to a mod :)
		if( (buttons & IN_ATTACK3) and player.iType > -1 ) {
			if (player.bHonkedHorn)
				return Plugin_Continue;
			else {
				player.bHonkedHorn = true;
				EmitSoundToAll(VehicleHorns[GetRandomInt(0, sizeof(VehicleHorns)-1)], client);
				SetPawnTimer(_ResetHorn, 4.0, player);
			}
		}
		// Vehicles shouldn't be able to duck
		if( (buttons & IN_DUCK) and (vehflags & FL_ONGROUND) ) {
			buttons &= ~IN_DUCK;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
public void _ResetHorn(const JailTank client)
{
	if( IsClientValid(client.index) )
		client.bHonkedHorn = false;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	JailTank player = JailTank(client);
	if( !player.bIsVehicle )
		return;

	switch( condition ) {
		case TFCond_Bleeding, TFCond_OnFire, TFCond_Gas, TFCond_Jarated, TFCond_Ubercharged: {	/* vehicles shouldn't bleed or be flammable */
			TF2_RemoveCondition(client, condition);
			SetClientOverlay(client, "effects/combine_binocoverlay");
			return;
		}
	}
}
