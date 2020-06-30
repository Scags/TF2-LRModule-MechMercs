#include <sourcemod>
#include <sdkhooks>
#include <morecolors>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2jailredux>

#pragma semicolon 1
#pragma newdecls required
#include "TF2JailRedux/stocks.inc"

#define PLUGIN_VERSION		"1.0.2"

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
		public get()					{ return this.GetProp("iMaxHealth"); }
		public set( const int i )		{ this.SetProp("iMaxHealth", i); }
	}
	property int iType
	{
		public get()					{ return this.GetProp("iType"); }
		public set( const int i )		{ this.SetProp("iType", i); }
	}

	property bool bIsVehicle
	{
		public get()					{ return this.GetProp("bIsVehicle"); }
		public set( const bool i )		{ this.SetProp("bIsVehicle", i); }
	}
	property bool bHonkedHorn
	{
		public get()					{ return this.GetProp("bHonkedHorn"); }
		public set( const bool i )		{ this.SetProp("bHonkedHorn", i); }
	}

	property float flGas
	{
		public get()					{ return this.GetPropFloat("flGas"); }
		public set( const float i )		{ this.SetPropFloat("flGas", i); }
	}
	property float flSoundDelay
	{
		public get()					{ return this.GetPropFloat("flSoundDelay"); }
		public set( const float i )		{ this.SetPropFloat("flSoundDelay", i); }
	}
	property float flIdleSound
	{
		public get()					{ return this.GetPropFloat("flIdleSound"); }
		public set( const float i )		{ this.SetPropFloat("flIdleSound", i); }
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
		SetClientOverlay(this.index, "effects/combine_binocoverlay");
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
	hTeamBansCVar
;

int
	iTeamBansCVar
;

bool
	bDisabled = true
;

JBGameMode
	gamemode
;

LastRequest
	g_LR
;

#define CHECK() 				if (g_LR == null || g_LR != JBGameMode_GetCurrentLR()) return
#define CHECK_ACT(%1) 			if (g_LR == null || g_LR != JBGameMode_GetCurrentLR()) return %1

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

	AutoExecConfig(true, "LRModuleMM");

	LoadTranslations("tf2jail_redux.phrases");
}

public void OnPluginEnd()
{
	if (LibraryExists("TF2Jail_Redux") && g_LR != null)
	{
		g_LR.Destroy();
		g_LR = null;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (!strcmp(name, "TF2Jail_Redux", false) && bDisabled)
	{
		InitSubPlugin();
		bDisabled = false;
	}
	else if (!strcmp(name, "TF2JailRedux_TeamBans", false))
		hTeamBansCVar = FindConVar("sm_jbans_ignore_midround");
}

public void InitSubPlugin()
{
	gamemode = new JBGameMode();
#pragma unused gamemode

	hTeamBansCVar = FindConVar("sm_jbans_ignore_midround");

	g_LR = LastRequest.CreateFromConfig("Mechanized Mercenaries");

	if (g_LR == null)		// If it's her first time, set the mood
	{
		g_LR = LastRequest.Create("Mechanized Mercenaries");

		g_LR.SetDescription("Turn everyone into tanks!");
		g_LR.SetAnnounceMessage("{default}{NAME}{burlywood} has selected {default}Mechanized Mercenaries{burlywood} as their last request.");

		g_LR.SetParameterNum("Disabled", 0);
		g_LR.SetParameterNum("OpenCells", 1);
		g_LR.SetParameterNum("TimerStatus", 1);
		g_LR.SetParameterNum("TimerTime", 300);
		g_LR.SetParameterNum("LockWarden", 1);
		g_LR.SetParameterNum("UsesPerMap", 3);
		g_LR.SetParameterNum("IsWarday", 1);
		g_LR.SetParameterNum("NoMuting", 1);
		g_LR.SetParameterNum("DisableMedic", 1);
		g_LR.SetParameterNum("EnableCriticals", 0);
		g_LR.SetParameterNum("IgnoreRebels", 1);
		g_LR.SetParameterNum("VoidFreekills", 1);
		g_LR.SetParameterNum("AllowWeapons", 1);
		g_LR.SetParameterNum("BalanceTeams", 1);

		g_LR.SetParameterNum("CrushDamage", 5);
		g_LR.SetParameterNum("RocketSpeed", 4000);
		g_LR.SetParameterNum("ConvertOnSpawn", 0);

		g_LR.SetMusicStatus(true);
		g_LR.SetMusicFileName(MechMercsTheme);
		g_LR.SetMusicTime(130.0);
		// Keeping everything else as a cvar, yea fuck that lmao

		g_LR.ExportToConfig(.create = true, .createonly = true);
	}

	JB_Hook(OnDownloads, 				fwdOnDownloads);
	g_LR.AddHook(OnLRActivate, 			fwdOnRoundStart);
	g_LR.AddHook(OnLRActivatePlayer, 	fwdOnRoundStartPlayer);
	g_LR.AddHook(OnRoundEnd, 			fwdOnRoundEnd);
	g_LR.AddHook(OnRoundEndPlayer, 		fwdOnRoundEndPlayer);
	g_LR.AddHook(OnRedThink, 			fwdOnThink);
	g_LR.AddHook(OnBlueThink, 			fwdOnThink);
	g_LR.AddHook(OnPlayerTouch, 		fwdOnClientTouch);
	g_LR.AddHook(OnPlayerSpawned, 		fwdOnPlayerSpawned);
	g_LR.AddHook(OnPlayerDied, 			fwdOnPlayerDied);
	g_LR.AddHook(OnPlayerPrepped, 		fwdOnPlayerPrepped);
	g_LR.AddHook(OnPlayerHurt, 			fwdOnHurtPlayer);
	g_LR.AddHook(OnTakeDamage, 			fwdOnTakeDamage);
	g_LR.AddHook(OnClientInduction, 	fwdOnClientInduction);
	g_LR.AddHook(OnVariableReset, 		fwdOnVariableReset);
	g_LR.AddHook(OnTimeEnd, 			fwdOnTimeEnd);
//	g_LR.AddHook(OnPlayMusic, 			fwdOnPlayMusic);
//	g_LR.AddHook(OnShouldAutobalance, 	fwdOnShouldAutobalance);
//	g_LR.AddHook(OnSetWardenLock, 		fwdOnSetWardenLock);

	bDisabled = false;
}

public void fwdOnClientInduction(LastRequest lr, const JBPlayer player)
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

public void fwdOnClientTouch(LastRequest lr, const JBPlayer player, const JBPlayer touched)
{
	JailTank base = JailTank.Of(player), victim = JailTank.Of(touched);

	// make sure noot to damage players just because enemies stand on them.
	if( base.bIsVehicle and !victim.bIsVehicle )
		ManageOnTouchPlayer(base, victim); // in handler.sp
}

public void fwdOnThink(LastRequest lr, const JBPlayer player)
{
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

public Action fwdOnTakeDamage(LastRequest lr, const JBPlayer victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
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

public void fwdOnRoundStart(LastRequest lr)
{
	if (hTeamBansCVar && !hTeamBansCVar.BoolValue)
	{
		hTeamBansCVar.SetBool(true);
		iTeamBansCVar = 1;
	}

	EmitSoundToAll(VehicleHorns[GetRandomInt(0, sizeof(VehicleHorns)-1)]);
}

public void fwdOnRoundStartPlayer(LastRequest lr, const JBPlayer player)
{
	JailTank.Of(player).ConvertToVehicle(GetRandomInt(0, Destroyer));
}

public void fwdOnRoundEnd(LastRequest lr, Event event)
{
	if (hTeamBansCVar && iTeamBansCVar)
	{
		hTeamBansCVar.SetBool(false);
		iTeamBansCVar = 0;
	}
}

public void fwdOnRoundEndPlayer(LastRequest lr, const JBPlayer player, Event event)
{
	JailTank.Of(player).Reset();
}

public Action fwdOnTimeEnd(LastRequest lr)
{
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

public void fwdOnPlayerSpawned(LastRequest lr, const JBPlayer player, Event event)
{
	if (lr.GetParameterNum("ConvertOnSpawn", 0))
		JailTank.Of(player).ConvertToVehicle(GetRandomInt(0, Destroyer));
}

public Action fwdOnPlayerPrepped(LastRequest lr, const JBPlayer player)
{
	if (JailTank.Of(player).bIsVehicle)
		return Plugin_Handled;
	return Plugin_Continue;
}

public void fwdOnPlayerDied(LastRequest lr, const JBPlayer player, Event event)
{
	JailTank base = JailTank.Of(player);
	if (base.bIsVehicle)
	{
		CreateTimer(0.1, Timer_VehicleDeath, base.userid);
		ManageVehicleDeath(base);
	}
}

// TODO; use SDKHook_GetMaxHealth for this instead!
public void fwdOnHurtPlayer(LastRequest lr, const JBPlayer victim, const JBPlayer attacker, Event event)
{
	JailTank base = JailTank.Of(victim);
	if (base.bIsVehicle)
		base.iHealth -= event.GetInt("damageamount");
}

public void fwdOnVariableReset(LastRequest lr, const JBPlayer player)
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

public Action ForcePlayerVehicle(int client, int args)
{
	CHECK_ACT(Plugin_Handled);

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

public Action fwdOnSetWardenLock(LastRequest lr, const bool status)
{
	return !status ? Plugin_Handled : Plugin_Continue;
}

public bool TraceRayDontHitSelf(int ent, int mask, any data)
{
	return ent != data;
}