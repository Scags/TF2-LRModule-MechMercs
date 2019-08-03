#include <sourcemod>
#include <sdkhooks>
#include <morecolors>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2jailredux>

#pragma semicolon 1
#pragma newdecls required
#include "TF2JailRedux/stocks.inc"

#define PLUGIN_VERSION		"1.0.1"

#define RED 				2
#define BLU 				3
#define or 					||
#define and 				&&

public Plugin myinfo =
{
	name = "TF2Jail MM LR Module",
	author = "Scag/Ragenewb, all props to nergal",
	description = "Mechanized Mercenaries embedded as an LR for TF2Jail Redux",
	version = PLUGIN_VERSION,
	url = "https://github.com/Scags"
};

// I suck when it comes to naming these
methodmap JailTank < JBPlayer
{
	public JailTank( const int client )
	{
		return view_as< JailTank >(client);
	}
	public static JailTank OfUserId( const int id )
	{
		return view_as< JailTank >(GetClientOfUserId(id));
	}
	public static JailTank Of( const any thing )
	{
		return view_as< JailTank >(thing);
	}

	property TFClassType Class
	{
		public get()						{ return TF2_GetPlayerClass(this.index); }
		public set( const TFClassType i )	{ TF2_SetPlayerClass(this.index, i); }
	}

	property int iTeam
	{
		public get()						{ return GetClientTeam(this.index); }
	}
	property int iMaxHealth
	{
		public get()					{ return this.GetValue("iMaxHealth"); }
		public set( const int i )		{ this.SetValue("iMaxHealth", i); }
	}
	property int iType
	{
		public get()					{ return this.GetValue("iType"); }
		public set( const int i )		{ this.SetValue("iType", i); }
	}

	property bool bIsVehicle
	{
		public get()					{ return this.GetValue("bIsVehicle"); }
		public set( const bool i )		{ this.SetValue("bIsVehicle", i); }
	}
	property bool bHonkedHorn
	{
		public get()					{ return this.GetValue("bHonkedHorn"); }
		public set( const bool i )		{ this.SetValue("bHonkedHorn", i); }
	}

	property float flGas
	{
		public get()					{ return this.GetValue("flGas"); }
		public set( const float i )		{ this.SetValue("flGas", i); }
	}
	property float flSoundDelay
	{
		public get()					{ return this.GetValue("flSoundDelay"); }
		public set( const float i )		{ this.SetValue("flSoundDelay", i); }
	}
	property float flIdleSound
	{
		public get()					{ return this.GetValue("flIdleSound"); }
		public set( const float i )		{ this.SetValue("flIdleSound", i); }
	}

	public void Reset()
	{
		SetClientOverlay(this.index, "0");
		SetVariantString("");
		AcceptEntityInput(this.index, "SetCustomModel");
		StopSound(this.index, SNDCHAN_AUTO, "acvshtank/tankidle.mp3");
		StopSound(this.index, SNDCHAN_AUTO, "acvshtank/tankdrive.mp3");
		StopSound(this.index, SNDCHAN_AUTO, "armoredcar/idle.mp3");
		StopSound(this.index, SNDCHAN_AUTO, "armoredcar/driveloop.mp3");
		SetEntPropFloat(this.index, Prop_Send, "m_flModelScale", 1.0);
	}
	public void VehHelpPanel()
	{
		if (IsVoteInProgress())
			return;

		Panel panel = new Panel();
		char helpstr[512];
		switch (this.iType)
		{
			case 0:	helpstr = "Panzer 4:\nSMG turret + Rocket Cannon.\nRight Click: Rocket.\nMouse3/Attack3: Honk horn.";
			case 1:	helpstr = "Scout Car:\nSMG turret + 20mm Cannon.\nRight Click: 20mm Cannon.\nMouse3/Attack3: Honk horn.";
			case 2:	helpstr = "Ambulance:\nSMG turret\nArea of Effect Healing 20ft|6m\nMouse3/Attack3: Honk horn.";
			case 4:	helpstr = "King Panzer:\nSMG turret + Rocket Cannon.\nRight Click: Nuclear Rocket.\nMouse3/Attack3: Honk horn.";
			case 3:	helpstr = "Panzer II:\nSMG Turret + Howitzer Cannon.\nRight Click: Arcing, Hi-Explosive Rocket.\nMouse3/Attack3: Honk horn.";
			case 5:	helpstr = "Marder II Tank Marder 2:\nRocket Cannon.\nLeft Click: Rocket.\nMouse3/Attack3: Honk horn.";
		}
		panel.SetTitle(helpstr);
		panel.DrawItem("Exit");
		panel.Send(this.index, HintPanel, 30);
		delete panel;
	}
	public void ConvertToVehicle( const int id )
	{
		this.iType = id;
		this.bIsVehicle = true;
		this.VehHelpPanel();
		CreateTimer(0.1, Timer_MakePlayerVehicle, this.userid);
	}
};

enum
{	// Tank specific cvars
	ACCELERATION,
	SPEEDMAX,
	SPEEDMAXREVERSE,
	INITSPEED,
	HEALTH,
	ROCKETDMG
};

ConVar
	hAmbulance[ROCKETDMG+1],	// HEALAMT
	hArmoredCar[ROCKETDMG+1],
	hDestroyer[ROCKETDMG+1],
	hKingTank[ROCKETDMG+1],
	hLightTank[ROCKETDMG+1],
	hTank[ROCKETDMG+1],
	hRocketSpeed,
	hConvertOnSpawn,
	hCrushDmg,
	hTimeLeft,
	hPickCount,
	hDisableMuting,
	hTeamBansCVar
;

int
	iTeamBansCVar
;

bool
	bDisabled
;

JBGameMode
	gamemode
;

#define CHECK() 				if (gamemode.iLRType != TF2JailRedux_LRIndex()) return

#include "LRModMM/handler.sp"

public void OnPluginStart()
{
	RegConsoleCmd("sm_mmclasshelp",	ClassInfoCmd);
	RegConsoleCmd("sm_mmclassinfo",	ClassInfoCmd);

	RegAdminCmd("sm_forcevehicle", ForcePlayerVehicle, ADMFLAG_KICK);

	CreateConVar("jbmm_version", PLUGIN_VERSION, "Mechanized Mercenaries Version (Do not touch)", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	hAmbulance[ACCELERATION] = CreateConVar("sm_jbmm_ambulance_acceleration", "6", "Amublance acceleration.", FCVAR_NOTIFY, true, 0.1);
	hArmoredCar[ACCELERATION] = CreateConVar("sm_jbmm_armcar_acceleration", "8", "Armored Car acceleration.", FCVAR_NOTIFY, true, 0.1);
	hDestroyer[ACCELERATION] = CreateConVar("sm_jbmm_destroyer_acceleration", "5", "Marder 2 acceleration.", FCVAR_NOTIFY, true, 0.1);
	hKingTank[ACCELERATION] = CreateConVar("sm_jbmm_kingtank_acceleration", "2", "King Panzer acceleration.", FCVAR_NOTIFY, true, 0.1);
	hLightTank[ACCELERATION] = CreateConVar("sm_jbmm_lighttank_acceleration", "5", "Panzer 3 acceleration.", FCVAR_NOTIFY, true, 0.1);
	hTank[ACCELERATION] = CreateConVar("sm_jbmm_tank_acceleration", "3", "Panzer 4 acceleration.", FCVAR_NOTIFY, true, 0.1);

	hAmbulance[SPEEDMAX] = CreateConVar("sm_jbmm_ambulance_speedmax", "400", "Ambulance max speed.", FCVAR_NOTIFY, true, 0.1);
	hArmoredCar[SPEEDMAX] = CreateConVar("sm_jbmm_armcar_speedmax", "330", "Armored Car max speed.", FCVAR_NOTIFY, true, 0.1);
	hDestroyer[SPEEDMAX] = CreateConVar("sm_jbmm_destroyer_speedmax", "270", "Marder 2 max speed.", FCVAR_NOTIFY, true, 0.1);
	hKingTank[SPEEDMAX] = CreateConVar("sm_jbmm_kingtank_speedmax", "150", "King Panzer max speed.", FCVAR_NOTIFY, true, 0.1);
	hLightTank[SPEEDMAX] = CreateConVar("sm_jbmm_lighttank_speedmax", "250", "Panzer 3 max speed.", FCVAR_NOTIFY, true, 0.1);
	hTank[SPEEDMAX] = CreateConVar("sm_jbmm_tank_speedmax", "200", "Panzer 4 max speed.", FCVAR_NOTIFY, true, 0.1);

	hAmbulance[SPEEDMAXREVERSE] = CreateConVar("sm_jbmm_ambulance_speedmax_r", "350", "Ambulance max speed in reverse.", FCVAR_NOTIFY, true, 0.1);
	hArmoredCar[SPEEDMAXREVERSE] = CreateConVar("sm_jbmm_armcar_speedmax_r", "300", "Armored Car max speed in reverse.", FCVAR_NOTIFY, true, 0.1);
	hDestroyer[SPEEDMAXREVERSE] = CreateConVar("sm_jbmm_destroyer_speedmax_r", "240", "Marder 2 max speed in reverse,", FCVAR_NOTIFY, true, 0.1);
	hKingTank[SPEEDMAXREVERSE] = CreateConVar("sm_jbmm_kingtank_speedmax_r", "130", "King Panzer max speed in reverse.", FCVAR_NOTIFY, true, 0.1);
	hLightTank[SPEEDMAXREVERSE] = CreateConVar("sm_jbmm_lighttank_speedmax_r", "220", "Panzer 3 max speed in reverse.", FCVAR_NOTIFY, true, 0.1);
	hTank[SPEEDMAXREVERSE] = CreateConVar("sm_jbmm_tank_speedmax_r", "180", "Panzer 4 max speed in reverse.", FCVAR_NOTIFY, true, 0.1);

	hAmbulance[INITSPEED] = CreateConVar("sm_jbmm_ambulance_initspeed", "250", "Ambulance initialization speed.", FCVAR_NOTIFY, true, 0.1);
	hArmoredCar[INITSPEED] = CreateConVar("sm_jbmm_armcar_initspeed", "200", "Armored Car initialization speed.", FCVAR_NOTIFY, true, 0.1);
	hDestroyer[INITSPEED] = CreateConVar("sm_jbmm_destroyer_initspeed", "50", "Marder 2 initialization speed,", FCVAR_NOTIFY, true, 0.1);
	hKingTank[INITSPEED] = CreateConVar("sm_jbmm_kingtank_initspeed", "20", "King Panzer initialization speed.", FCVAR_NOTIFY, true, 0.1);
	hLightTank[INITSPEED] = CreateConVar("sm_jbmm_lighttank_initspeed", "60", "Panzer 3 initialization speed.", FCVAR_NOTIFY, true, 0.1);
	hTank[INITSPEED] = CreateConVar("sm_jbmm_tank_initspeed", "40", "Panzer 4 initialization speed.", FCVAR_NOTIFY, true, 0.1);

	hAmbulance[HEALTH] = CreateConVar("sm_jbmm_ambulance_health", "400", "Ambulance max health.", FCVAR_NOTIFY, true, 1.0);
	hArmoredCar[HEALTH] = CreateConVar("sm_jbmm_armcar_health", "600", "Armored Car max health.", FCVAR_NOTIFY, true, 1.0);
	hDestroyer[HEALTH] = CreateConVar("sm_jbmm_destroyer_health", "500", "Marder 2 max health,", FCVAR_NOTIFY, true, 1.0);
	hKingTank[HEALTH] = CreateConVar("sm_jbmm_kingtank_health", "2000", "King Panzer max health.", FCVAR_NOTIFY, true, 1.0);
	hLightTank[HEALTH] = CreateConVar("sm_jbmm_lighttank_health", "750", "Panzer 3 max health.", FCVAR_NOTIFY, true, 1.0);
	hTank[HEALTH] = CreateConVar("sm_jbmm_tank_health", "1000", "Panzer 4 max health.", FCVAR_NOTIFY, true, 1.0);

	hAmbulance[ROCKETDMG] = CreateConVar("sm_jbmm_ambulance_heal_amount", "5", "Ambulance healing amount per tick (0.1 seconds).", FCVAR_NOTIFY, true, 1.0);
	hArmoredCar[ROCKETDMG] = CreateConVar("sm_jbmm_armcar_gundmg", "40", "How much damage the Armored Car's 20mm cannon deals.", FCVAR_NOTIFY, true, 1.0);
	hDestroyer[ROCKETDMG] = CreateConVar("sm_jbmm_destroyer_rocketdmg", "1000", "How much damage the Marder 2's rocket deals,", FCVAR_NOTIFY, true, 1.0);
	hKingTank[ROCKETDMG] = CreateConVar("sm_jbmm_kingtank_rocketdmg", "150", "How much damage the King Panzer's rocket deals.", FCVAR_NOTIFY, true, 1.0);
	hLightTank[ROCKETDMG] = CreateConVar("sm_jbmm_lighttank_rocketdmg", "80", "How much damage the Panzer 3's rocket deals.", FCVAR_NOTIFY, true, 1.0);
	hTank[ROCKETDMG] = CreateConVar("sm_jbmm_tank_rocketdmg", "100", "How much damage the Panzer 4's rocket deals.", FCVAR_NOTIFY, true, 1.0);

	hCrushDmg = CreateConVar("sm_jbmm_crushdmg", "5.0", "Crush Damage done by Vehicles while they're moving", FCVAR_NOTIFY, true, 0.0);
	hRocketSpeed = CreateConVar("sm_jbmm_rocket_speed", "4000", "How fast tank rockets travel.", FCVAR_NOTIFY, true, 1.0);
	hConvertOnSpawn = CreateConVar("sm_jbmm_spawn_convert", "0", "Convert players to vehicles when/if they spawn in midround?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hTimeLeft = CreateConVar("sm_jbmm_round_time", "600", "Round time during a MM round IF a time limit is enabled in core plugin.", FCVAR_NOTIFY, true, 0.0);
	hDisableMuting = CreateConVar("sm_jbmm_disable_muting", "0", "Disable plugin muting during this last request?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hPickCount = CreateConVar("sm_jbmm_pickcount", "5", "Maximum number of times this LR can be picked in a single map. 0 for no limit", FCVAR_NOTIFY, true, 0.0);

	AutoExecConfig(true, "LRModuleMM");

	LoadTranslations("tf2jail_redux.phrases");
}

public void OnAllPluginsLoaded()
{
	TF2JailRedux_RegisterPlugin();
	gamemode = new JBGameMode();
	hTeamBansCVar = FindConVar("sm_jbans_ignore_midround");

	JB_Hook(OnHudShow, 					fwdOnHudShow);
	JB_Hook(OnLRPicked, 				fwdOnLRPicked);
	JB_Hook(OnPanelAdd,					fwdOnPanelAdd);
	JB_Hook(OnMenuAdd, 					fwdOnMenuAdd);
	JB_Hook(OnDownloads, 				fwdOnDownloads);
	JB_Hook(OnRoundStart, 				fwdOnRoundStart);
	JB_Hook(OnRoundStartPlayer, 		fwdOnRoundStartPlayer);
	JB_Hook(OnRoundEnd, 				fwdOnRoundEnd);
	JB_Hook(OnRoundEndPlayer, 			fwdOnRoundEndPlayer);
	JB_Hook(OnRedThink, 				fwdOnThink);
	JB_Hook(OnBlueThink, 				fwdOnThink);
	JB_Hook(OnClientTouch, 				fwdOnClientTouch);
	JB_Hook(OnPlayerSpawned, 			fwdOnPlayerSpawned);
	JB_Hook(OnPlayerDied, 				fwdOnPlayerDied);
	JB_Hook(OnTimeLeft, 				fwdOnTimeLeft);
	JB_Hook(OnPlayerPreppedPre, 		fwdOnPlayerPreppedPre);
	JB_Hook(OnHurtPlayer, 				fwdOnHurtPlayer);
	JB_Hook(OnTakeDamage, 				fwdOnTakeDamage);
	JB_Hook(OnClientInduction, 			fwdOnClientInduction);
	JB_Hook(OnVariableReset, 			fwdOnVariableReset);
	JB_Hook(OnTimeEnd, 					fwdOnTimeEnd);
	JB_Hook(OnPlayMusic, 				fwdOnPlayMusic);
	JB_Hook(OnShouldAutobalance, 		fwdOnShouldAutobalance);
	JB_Hook(OnSetWardenLock, 			fwdOnSetWardenLock);
}

public void OnPluginEnd()
{
	if (LibraryExists("TF2Jail_Redux"))
		TF2JailRedux_UnRegisterPlugin();
}

public void OnLibraryRemoved(const char[] name)
{
	if (!strcmp(name, "TF2Jail_Redux", false))
		bDisabled = true;
	else if (!strcmp(name, "TF2JailRedux_TeamBans", false))
		hTeamBansCVar = null;
}

public void OnLibraryAdded(const char[] name)
{
	if (!strcmp(name, "TF2Jail_Redux", false) && bDisabled)
	{
		OnAllPluginsLoaded();
		bDisabled = false;
	}
	else if (!strcmp(name, "TF2JailRedux_TeamBans", false))
		hTeamBansCVar = FindConVar("sm_jbans_ignore_midround");
}

public void fwdOnClientInduction(const JBPlayer player)
{
	JailTank base = JailTank.Of(player);
	base.iType = -1;
 	base.iHealth = 0;
	base.bIsVehicle = false;
	base.bHonkedHorn = false;
	base.flSpeed = 0.0;
	base.flSoundDelay = 0.0;
	base.flIdleSound = 0.0;
	ToCTank(base).flLastFire = 0.0;
}

public void fwdOnClientTouch(const JBPlayer player, const JBPlayer touched)
{
	CHECK();

	JailTank base = JailTank.Of(player), victim = JailTank.Of(touched);

	// make sure noot to damage players just because enemies stand on them.
	if( base.bIsVehicle and !victim.bIsVehicle )
		ManageOnTouchPlayer(base, victim); // in handler.sp
}

public void fwdOnThink(const JBPlayer player)
{
	CHECK();

	JailTank base = JailTank.Of(player);
	if (base.bIsVehicle)
	{
		ManageVehicleThink(base);
		SetEntityHealth(base.index, base.iHealth);
	}
}

public Action Timer_MakePlayerVehicle(Handle timer, any userid)
{

	int client = GetClientOfUserId(userid);
	if( client and IsClientInGame(client) ) {
		JailTank player = JailTank(client);
		ManageHealth(player);			// in handler.sp
		ManageVehicleTransition(player);	// in handler.sp
		//SetEntPropEnt(player.index, Prop_Send, "m_hVehicle", player.index);
		//SetVariantString("1");
		//AcceptEntityInput(client, "SetForcedTauntCam");
	}
	return Plugin_Continue;
}

public Action Timer_VehicleDeath(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if( client and IsClientInGame(client) ) {
		JailTank player = JailTank(client);
		if( player.iHealth <= 0 )
			player.iHealth = 0; // ded, k!big soup rice
		ManageVehicleDeath(player); // in handler.sp Powerup
	}
	return Plugin_Continue;
}

public Action ClassInfoCmd (int client, int args)
{
	JailTank(client).VehHelpPanel();
	return Plugin_Handled;
}

public int MenuHandler_GoTank(Menu menu, MenuAction action, int client, int select)
{
	if( IsClientObserver(client) )
		return;
	
	char info1[16]; menu.GetItem(select, info1, sizeof(info1));
	if( action == MenuAction_Select ) {
		JailTank player = JailTank(client);
		player.iType = StringToInt(info1);
	}
	else if( action == MenuAction_End )
		delete menu;
}

public bool TraceFilterIgnorePlayers(int entity, int contentsMask, any client)
{
	return( !(entity and entity <= MaxClients) );
}

public Action fwdOnTakeDamage(const JBPlayer victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	CHECK() Plugin_Continue;

	JailTank vehAttacker = JailTank(attacker);
	JailTank vehVictim = JailTank.Of(victim);

	if (vehVictim.bIsVehicle)	// in handler.sp
		return ManageOnVehicleTakeDamage(vehVictim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
	
	if (damagetype & DMG_CRIT)
		return Plugin_Continue; //this prevents damage fall off applying to crits
	
	if (!(0 < attacker <= MaxClients))
		return Plugin_Continue;
	
	if (vehAttacker.bIsVehicle)	// in handler.sp
		return ManageOnVehicleDealDamage(vehVictim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);

	return Plugin_Continue;
}

public void RemoveEnt(const int ref)
{
	int ent = EntRefToEntIndex(ref);
	if( ent && IsValidEntity(ent) )
		RemoveEntity(ent);
}

public int HintPanel(Menu menu, MenuAction action, int client, int select)
{
	return;
}

public void fwdOnDownloads()
{
	ManageDownloads();
}

public void fwdOnHudShow(char strHud[128])
{
	CHECK();

	strcopy(strHud, 128, "Mechanized Mercenaries");
}

public Action fwdOnLRPicked(const JBPlayer Player, const int selection, ArrayList arrLRS)
{
	if (selection == TF2JailRedux_LRIndex())
		CPrintToChatAll("%t %N has chosen {default}Mechanized Mercenaries{burlywood} as their last request.", "Plugin Tag", Player.index);
	return Plugin_Continue;
}

public void fwdOnPanelAdd(const int index, char name[64])
{
	if (index == TF2JailRedux_LRIndex())
		strcopy(name, sizeof(name), "Mechanized Mercenaries - War Thunder who?");
}

public void fwdOnMenuAdd(const int index, int &max, char strName[64])
{
	if (index != TF2JailRedux_LRIndex())
		return;

	max = hPickCount.IntValue;
	strcopy(strName, sizeof(strName), "Mechanized Mercenaries");
}

public void fwdOnTimeLeft(int &time)
{
	CHECK();

	time = hTimeLeft.IntValue;
}

public void fwdOnRoundStart(Event event)
{
	CHECK();

	if (hTeamBansCVar && !hTeamBansCVar.BoolValue)
	{
		hTeamBansCVar.SetBool(true);
		iTeamBansCVar = 1;
	}

	gamemode.bDisableCriticals = true;
	gamemode.bIgnoreRebels = true;
	gamemode.bDisableMuting = hDisableMuting.BoolValue;
	gamemode.bIsWarday = true;
	gamemode.bIsWardenLocked = true;
	gamemode.EvenTeams();

	EmitSoundToAll(VehicleHorns[GetRandomInt(0, sizeof(VehicleHorns)-1)]);
}

public void fwdOnRoundStartPlayer(const JBPlayer player)
{
	CHECK();

	JailTank.Of(player).ConvertToVehicle(GetRandomInt(0, Destroyer));
}

public void fwdOnRoundEnd(Event event)
{
	CHECK();

	if (hTeamBansCVar && iTeamBansCVar)
	{
		hTeamBansCVar.SetBool(false);
		iTeamBansCVar = 0;
	}
}

public void fwdOnRoundEndPlayer(const JBPlayer player, Event event)
{
	CHECK();
	JailTank.Of(player).Reset();
}

public Action fwdOnTimeEnd()
{
	CHECK() Plugin_Continue;

	int players[2];
	int i;
	for (i = MaxClients; i; --i)
		if (IsClientInGame(i) && IsPlayerAlive(i))
			++players[GetClientTeam(i)-2];

	if (players[0] > players[1])
		ForceTeamWin(RED);
	else if (players[1] > players[0])
		ForceTeamWin(BLU);
	else	// Draw, nobody wins
	{
		i = CreateEntityByName("game_round_win");
		if (i != -1)
		{
			SetVariantInt(0);
			AcceptEntityInput(i, "SetTeam");
			AcceptEntityInput(i, "RoundWin");
		}
		else ServerCommand("sm_slay @all");
	}
	return Plugin_Handled;
}

public void fwdOnPlayerSpawned(const JBPlayer player, Event event)
{
	CHECK();
	if (hConvertOnSpawn.BoolValue)
		JailTank.Of(player).ConvertToVehicle(GetRandomInt(0, Destroyer));
}

public Action fwdOnPlayerPreppedPre(const JBPlayer player)
{
	CHECK() Plugin_Continue;

	if (JailTank.Of(player).bIsVehicle)
		return Plugin_Handled;
	return Plugin_Continue;
}

public void fwdOnPlayerDied(const JBPlayer player, Event event)
{
	CHECK();

	JailTank base = JailTank.Of(player);
	if (base.bIsVehicle)
	{
		CreateTimer(0.1, Timer_VehicleDeath, base.userid);
		ManageVehicleDeath(base);
	}
}

public void fwdOnHurtPlayer(const JBPlayer victim, const JBPlayer attacker, Event event)
{
	CHECK();

	JailTank base = JailTank.Of(victim);
	if (base.bIsVehicle)
		base.iHealth -= event.GetInt("damageamount");
}

public void fwdOnVariableReset(const JBPlayer player)
{
	JailTank base = JailTank.Of(player);
	base.iType = -1;
 	base.iHealth = 0;
	base.bIsVehicle = false;
	base.bHonkedHorn = false;
	base.flSpeed = 0.0;
	base.flSoundDelay = 0.0;
	base.flIdleSound = 0.0;
	ToCTank(base).flLastFire = 0.0;
}

public Action fwdOnPlayMusic(char song[PLATFORM_MAX_PATH], float &time)
{
	CHECK() Plugin_Continue;

	if (IsSoundPrecached(MechMercsTheme))
	{
		strcopy(song, sizeof(song), MechMercsTheme);
		time = 130.0;
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action fwdOnShouldAutobalance()
{
	if (gamemode.iLRPresetType == TF2JailRedux_LRIndex())
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action ForcePlayerVehicle(int client, int args)
{
	CHECK() Plugin_Handled;

	if( args < 2 ) {
		ReplyToCommand(client, "%t Usage: sm_forcevehicle <player/target> <vehicle id>", "Plugin Tag");
		return Plugin_Handled;
	}
	char name[32]; GetCmdArg( 1, name, sizeof(name) );

	char number[4]; GetCmdArg( 2, number, sizeof(number) );
	int type = StringToInt(number);

	if( type < 0 or type > 255 )
		type = -1;

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if( (target_count = ProcessTargetString(name, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0 ) {
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	JailTank veh;
	for( int i=0 ; i<target_count ; ++i ) {
		if( !IsValidClient(target_list[i], false) )
			continue;
		
		veh = JailTank(target_list[i]);
		veh.bIsVehicle = true;
		veh.ConvertToVehicle(type);
		veh.VehHelpPanel();
				
		CPrintToChat(veh.index, "%t An Admin has forced you on a Vehicle", "Admin Tag");
		CPrintToChat(client, "%t You've forced %N onto a Vehicle", "Admin Tag", target_list[i]);
	}
	return Plugin_Handled;
}

public Action fwdOnSetWardenLock(const bool status)
{
	CHECK() Plugin_Continue;

	return !status ? Plugin_Handled : Plugin_Continue;
}