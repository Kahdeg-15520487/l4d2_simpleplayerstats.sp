/**
* Simple Player Statistics
* 
* Copyright (C) 2019 
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License 
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/*
* -------------------------------------------------
* Change Log
* -------------------------------------------------
* 
* 1.0.0-alpha - 6/1/2019
*  - Initial Release
*
* 1.0.1-alpha - 6/4/2019
* - Bug Fix: Extra stats item from player rank panel does not execute when selected
* - Bug Fix: Error 'Client index is invalid' thrown during player initialization
* - Verify if steamid is valid for ShowInGamePlayerRanks
* - Bug Fix: Views in the database were hardcoded to query from 'playerstats' database. This will not work for those who use a different database name.
* - Added console command 'sm_hidestats'. Allow players to hide their extra stats from others.
* - Bug Fix: Fixed wrong parameter count for Notify().
*/

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
//#include <smlib>

#pragma semicolon 1
#pragma newdecls required

#define DEBUG

#define PLUGIN_AUTHOR "tank cat"
#define PLUGIN_VERSION "1.4.0"

#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_VALID_HUMAN(%1)		(IS_VALID_CLIENT(%1) && IsClientConnected(%1) && !IsFakeClient(%1))
#define IS_SPECTATOR(%1)        (GetClientTeam(%1) == TEAM_SPECTATOR)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == TEAM_SURVIVOR)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == TEAM_INFECTED)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_VALID_SPECTATOR(%1)  (IS_VALID_INGAME(%1) && IS_SPECTATOR(%1))
#define IS_SURVIVOR_ALIVE(%1)   (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1)   (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))
#define IS_HUMAN_SURVIVOR(%1)   (IS_VALID_HUMAN(%1) && IS_SURVIVOR(%1))
#define IS_HUMAN_INFECTED(%1)   (IS_VALID_HUMAN(%1) && IS_INFECTED(%1))

#define MAX_CLIENTS MaxClients

#define CONFIG_FILE "playerstats.cfg"

#define STATS_DISPLAY_TYPE_POINTS 1
#define STATS_DISPLAY_TYPE_AMOUNT 2
#define STATS_DISPLAY_TYPE_BOTH 3

#define CLASS_SMG 0
#define CLASS_SHOTGUN 1
#define CLASS_RIFLE 2
#define CLASS_MELEE 3
#define CLASS_DEAGLE 4
#define CLASS_SNIPER 5

//Player general information
#define STATS_STEAM_ID "steam_id"
#define STATS_LAST_KNOWN_ALIAS "last_known_alias"
#define STATS_LAST_JOIN_DATE "last_join_date"
#define STATS_RANK "rank_num"
#define STATS_CREATE_DATE "create_date"
#define STATS_TOTAL_POINTS "total_points"

//Player in-game statistics
#define STATS_SURVIVOR_REVIVED "survivor_revived"
#define STATS_SURVIVOR_HEALED "survivor_healed"
#define STATS_SURVIVOR_DEFIBED "survivor_defibed"
#define STATS_SURVIVOR_DEATH "survivor_death"
#define STATS_SURVIVOR_INCAPPED "survivor_incapped"
#define STATS_SURVIVOR_FRIENDLYFIRE "survivor_ff"
#define STATS_SURVIVOR_TITLE "survivor_tittle"

#define STATS_WEAPON_CLASS "weapon_class"
#define STATS_WEAPON_SPECIAL "weapon_special"
#define STATS_WEAPON_RIFLE "weapon_rifle"
#define STATS_WEAPON_SMG "weapon_smg"
#define STATS_WEAPON_SNIPER "weapon_sniper"
#define STATS_WEAPON_SHOTGUN "weapon_shotgun"
#define STATS_WEAPON_MELEE "weapon_melee"
#define STATS_WEAPON_DEAGLE "weapon_deagle"

#define STATS_INFECTED_KILLED "infected_killed"
#define STATS_INFECTED_HEADSHOT "infected_headshot"

#define STATS_BOOMER_KILLED "boomer_killed"
#define STATS_BOOMER_KILLED_CLEAN "boomer_killed_clean"

#define STATS_CHARGER_KILLED "charger_killed"
#define STATS_CHARGER_PUMMELED "charger_pummeled"

#define STATS_HUNTER_KILLED "hunter_killed"
#define STATS_HUNTER_POUNCED "hunter_pounced"
#define STATS_HUNTER_SHOVED "hunter_shoved"

#define STATS_JOCKEY_KILLED "jockey_killed"
#define STATS_JOCKEY_POUNCED "jockey_pounced"
#define STATS_JOCKEY_SHOVED "jockey_shoved"
#define STATS_JOCKEY_RIDED "jockey_rided"

#define STATS_SMOKER_KILLED "smoker_killed"
#define STATS_SMOKER_CHOKED "smoker_choked"
#define STATS_SMOKER_TONGUE_SLASHED "smoker_tongue_slashed"

#define STATS_SPITTER_KILLED "spitter_killed"

#define STATS_WITCH_KILLED "witch_killed"
#define STATS_WITCH_KILLED_1SHOT "witch_killed_1shot"
#define STATS_WITCH_HARASSED "witch_harassed"

#define STATS_TANK_KILLED "tank_killed"
#define STATS_TANK_MELEE "tank_melee"
#define STATS_CAR_ALARMED "car_alarm"

#define ZC_COMMON       "infected"
#define ZC_SMOKER       "smoker"
#define ZC_BOOMER       "boomer"
#define ZC_HUNTER       "hunter"
#define ZC_JOCKEY       "jockey"
#define ZC_CHARGER      "charger"
#define ZC_WITCH        "witch"
#define ZC_TANK         8

#define DEFAULT_POINT_MODIFIER 1.0
#define DEFAULT_PLUGIN_TAG "PSTATS"
#define DEFAULT_TITLE_STAT_PANEL_PLAYER "Player Stats"
#define DEFAULT_TITLE_STAT_PANEL_TOPN "Top {top_player_count} Players"
#define DEFAULT_TITLE_STAT_PANEL_INGAME "Player In-Game Ranks"
#define DEFAULT_TITLE_STAT_PANEL_EXTRAS "Additional Stats"

#define DEFAULT_CONFIG_ANNOUNCE_FORMAT "Player '{last_known_alias}' ({steam_id}) has joined the game (Rank: {i:rank_num}, Points: {f:total_points})"
#define DEFAULT_TOP_PLAYERS 10
#define DEFAULT_MIN_TOP_PLAYERS 10
#define DEFAULT_MAX_TOP_PLAYERS 50

#define GAMEINFO_SERVER_NAME "server_name"
#define MAX_STEAMAUTH_LENGTH 21

Database g_hDatabase = null;
StringMap g_mStatModifiers;
StringMap g_mPlayersInitialized;

//Prepared statements
DBStatement g_hQueryRecordExists = null;

bool g_bPlayerInitialized[MAXPLAYERS + 1] = false;
bool g_bInitializing[MAXPLAYERS + 1] = false;
bool g_bShowingRankPanel[MAXPLAYERS + 1] = false;
//need this flag below to allow us to know if the player has viewed his rank on join. 
//we do not need to keep displaying his/her rank everytime he/she changes teams.
bool g_bPlayerRankShown[MAXPLAYERS + 1] = true;
char g_ConfigPath[PLATFORM_MAX_PATH];
char g_SQLHost[255];
char g_SQLDb[255];
char g_SQLUser[255];
char g_SQLPass[255];

char g_StatPanelTitlePlayer[255];
char g_StatPanelTitleTopN[255];
char g_StatPanelTitleInGame[255];
char g_StatPanelTitleExtras[255];

char g_ConfigAnnounceFormat[512];
char g_SelSteamIds[MAXPLAYERS + 1][MAX_STEAMAUTH_LENGTH];
bool g_bSkillDetectLoaded = false;
ConVar g_bDebug;
ConVar g_bEnabled;
ConVar g_iStatsMenuTimeout;
ConVar g_iStatsMaxTopPlayers;
ConVar g_iStatsDisplayType;
ConVar g_sServerName;
ConVar g_bShowRankOnConnect;
ConVar g_bConnectAnnounceEnabled;

char g_sBasicStats[][128] = {
	
	STATS_SURVIVOR_DEATH, 
	STATS_SURVIVOR_HEALED, 
	STATS_SURVIVOR_DEFIBED, 
	STATS_SURVIVOR_REVIVED, 
	STATS_SURVIVOR_INCAPPED, 
	STATS_SURVIVOR_FRIENDLYFIRE, 
	
	STATS_WEAPON_CLASS, 
	STATS_WEAPON_SPECIAL, 
	STATS_WEAPON_RIFLE, 
	STATS_WEAPON_SMG, 
	STATS_WEAPON_SNIPER, 
	STATS_WEAPON_SHOTGUN, 
	STATS_WEAPON_MELEE, 
	STATS_WEAPON_DEAGLE, 
	
	STATS_INFECTED_KILLED, 
	STATS_INFECTED_HEADSHOT, 
	
	STATS_BOOMER_KILLED, 
	STATS_BOOMER_KILLED_CLEAN, 
	
	STATS_CHARGER_KILLED, 
	STATS_CHARGER_PUMMELED, 
	
	STATS_HUNTER_KILLED, 
	STATS_HUNTER_POUNCED, 
	STATS_HUNTER_SHOVED, 
	
	STATS_JOCKEY_KILLED, 
	STATS_JOCKEY_POUNCED, 
	STATS_JOCKEY_SHOVED, 
	STATS_JOCKEY_RIDED, 
	
	STATS_SMOKER_KILLED, 
	STATS_SMOKER_CHOKED, 
	STATS_SMOKER_TONGUE_SLASHED, 
	
	STATS_SPITTER_KILLED, 
	
	STATS_WITCH_KILLED, 
	STATS_WITCH_KILLED_1SHOT, 
	STATS_WITCH_HARASSED, 
	
	STATS_TANK_KILLED, 
	STATS_TANK_MELEE, 
	
	STATS_CAR_ALARMED, 
};

public Plugin myinfo = 
{
	name = "Simple Player Statistics", 
	author = PLUGIN_AUTHOR, 
	description = "Tracks kills, deaths and other special skills", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/Kahdeg-15520487/l4d2_simpleplayerstats.sp"
};

/**
* Called when the plugin is fully initialized and all known external references are resolved. This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
* If any run-time error is thrown during this callback, the plugin will be marked as failed.
*/
public void OnPluginStart()
{
	//Make sure we are on left 4 dead 2!
	if (GetEngineVersion() != Engine_Left4Dead2) {
		SetFailState("This plugin only supports left 4 dead 2!");
		return;
	}
	
	BuildPath(Path_SM, g_ConfigPath, sizeof(g_ConfigPath), "configs/%s", CONFIG_FILE);
	
	char defaultTopPlayerStr[32];
	IntToString(DEFAULT_TOP_PLAYERS, defaultTopPlayerStr, sizeof(defaultTopPlayerStr));
	
	CreateConVar("pstats_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_bEnabled = CreateConVar("pstats_enabled", "1", "Enable/Disable tracking", _, true, 0.0, true, 1.0);
	g_bDebug = CreateConVar("pstats_debug_enabled", "0", "Enable debug messages", _, true, 0.0, true, 1.0);
	g_iStatsMenuTimeout = CreateConVar("pstats_menu_timeout", "5", "The timeout value for the player stats panel", _, true, 3.0, true, 9999.0);
	g_iStatsMaxTopPlayers = CreateConVar("pstats_max_top_players", defaultTopPlayerStr, "The max top N players to display", _, true, float(DEFAULT_MIN_TOP_PLAYERS), true, float(DEFAULT_MAX_TOP_PLAYERS));
	g_iStatsDisplayType = CreateConVar("pstats_display_type", "2", "1 = Display points, 2 = Display the quantity, 3 = Both points and quantity", _, true, 1.0, true, 3.0);
	g_bShowRankOnConnect = CreateConVar("pstats_show_rank_onjoin", "0", "If set, player rank will be displayed to the user on every map change", _, true, 0.0, true, 1.0);
	g_bConnectAnnounceEnabled = CreateConVar("pstats_cannounce_enabled", "0", "If set, connect announce will be displayed to chat when a player joins", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d2_simpleplayerstats");
	
	g_sServerName = FindConVar("hostname");
	g_mStatModifiers = new StringMap();
	g_mPlayersInitialized = new StringMap();
	
	LoadConfigData();
	
	if (!InitDatabase()) {
		Error("Could not connect to the database. Please check your database configuration file and make sure everything is configured correctly.");
		SetFailState("Could not connect to the database");
	}
	
	RegConsoleCmd("sm_rank", Command_ShowRank, "Display the current stats & ranking of the requesting player. A panel will be displayed to the player.");
	RegConsoleCmd("sm_top", Command_ShowTopPlayers, "Display the top N players. A menu panel will be displayed to the requesting player");
	RegConsoleCmd("sm_ranks", Command_ShowTopPlayersInGame, "Display the ranks of the players currently playing in the server. A menu panel will be displayed to the requesting player.");
	RegConsoleCmd("sm_hidestats", Command_HideExtraFromPublic, "If set by the player, extra stats will not be shown to the public (e.g. via top 10 panel)");
	RegConsoleCmd("sm_wiperank", Command_WipeRank, "If set by the player, extra stats will not be shown to the public (e.g. via top 10 panel)");
	RegAdminCmd("sm_pstats_reload", Command_ReloadConfig, ADMFLAG_ROOT, "Reloads plugin configuration. This is useful if you have modified the playerstats.cfg file. This command also synchronizes the modifier values set from the configuration file to the database.");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	//HookEvent("infected_death", Event_InfectedDeath, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_incapacitated", Event_PlayerIncapped, EventHookMode_Post);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Post);
	HookEvent("defibrillator_used", Event_DefibSuccess, EventHookMode_Post);
	HookEvent("revive_success", Event_ReviveSuccess, EventHookMode_Post);
	HookEvent("friendly_fire", Event_FriendlyFire, EventHookMode_Post);
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	HookEvent("boomer_exploded", Event_BoomerExploded, EventHookMode_Post);
	HookEvent("charger_killed", Event_ChargerKilled, EventHookMode_Post);
	HookEvent("hunter_headshot", Event_HunterKilled, EventHookMode_Post);
	HookEvent("jockey_killed", Event_JockeyKilled, EventHookMode_Post);
	//HookEvent("smoker_killed", Event_SmokerKilled, EventHookMode_Post);
	HookEvent("spitter_killed", Event_SpitterKilled, EventHookMode_Post);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
	HookEvent("tank_killed", Event_TankKilled, EventHookMode_Post);
	
	HookEvent("pounce_stopped", Event_HunterShoved, EventHookMode_Post);
	HookEvent("jockey_ride_end", Event_JockeyShoved, EventHookMode_Post);
	
	HookEvent("witch_harasser_set", Event_WitchHarrassed, EventHookMode_Post);
	
	HookEvent("triggered_car_alarm", Event_CarAlarmed, EventHookMode_Post);
	
	//Perform one time initialization when the player first connects to the server (shouldn't be called on map change)
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Post);
	//Note: We use this event instead of OnClientDisconnect because this event does not get fired on map change.
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Post);
	HookEvent("player_transitioned", Event_PlayerTransitioned, EventHookMode_Post);
	HookEvent("bot_player_replace", Event_PlayerReplaceBot, EventHookMode_Post);
}

/**
* Called when all plugins have been loaded
*/
public void OnAllPluginsLoaded() {
	g_bSkillDetectLoaded = LibraryExists("skill_detect");
	Debug("OnAllPluginsLoaded()");
}

/**
* Called when a plugin/library has been removed/unloaded
*/
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "skill_detect")) {
		g_bSkillDetectLoaded = false;
		Debug("Skill detect plugin unloaded");
	}
}

/**
* Called when a plugin/library has been added/reloaded
*/
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "skill_detect")) {
		g_bSkillDetectLoaded = true;
		Debug("Skill detect plugin loaded");
	}
}

/**
* Called when the map has loaded, servercfgfile (server.cfg) has been executed, and all plugin configs are done executing. 
* This is the best place to initialize plugin functions which are based on cvar data.
*/
public void OnConfigsExecuted() {
	Debug("Loading config file: %s", g_ConfigPath);
	
	//Load and parse the config file
	if (!LoadConfigData()) {
		SetFailState("Problem loading/reading config file: %s", g_ConfigPath);
		return;
	}
	
	//Determine if whether we should automatically sync the values of the cached modifier entries
	if (GetStatModifierCount() == 0) {
		FlushStatModifiersToDb();
	}
	
	//If the plugin has been reloaded, we re-initialize the players herer. 
	//This does not apply during map transition
	if (GetHumanPlayerCount() > 0) {
		Debug("OnConfigsExecuted() :: Initializing players");
		InitializePlayers();
	}
	else {
		Debug("OnConfigsExecuted() :: Skipped player initialization. No available players or players have not connected yet.");
	}
}

/**
* Called when a client receives an auth ID. The state of a client's authorization as an admin is not guaranteed here. 
* Use OnClientPostAdminCheck() if you need a client's admin status.
* This is called by bots, but the ID will be "BOT".
*/
public void OnClientAuthorized(int client, const char[] auth) {
	//Ignore bots
	if (!IS_VALID_HUMAN(client))
		return;
	Debug("OnClientAuthorized(%N) = %s", client, auth);
	if (!isInitialized(client)) {
		InitializePlayer(client, true);
	} else {
		Debug("OnClientAuthorized :: Client '%N' has already been initialized. Skipping initialization", client);
	}
}

/**
* Called once a client successfully connects. This callback is paired with OnClientDisconnect.
*/
public void OnClientConnected(int client) {
	if (!IS_VALID_HUMAN(client))
		return;
	Debug("OnClientConnected(%N)", client);
}

/**
* Called when a client is entering the game.
* Whether a client has a steamid is undefined until OnClientAuthorized is called, which may occur either before or after OnClientPutInServer. 
* Similarly, use OnClientPostAdminCheck() if you need to verify whether connecting players are admins.
* GetClientCount() will include clients as they are passed through this function, as clients are already in game at this point.
*/
public void OnClientPutInServer(int client) {
	if (!IS_VALID_HUMAN(client))
		return;
	Debug("OnClientPutInServer(%N)", client);
}

/**
* Called once a client is authorized and fully in-game, and after all post-connection authorizations have been performed.
* This callback is guaranteed to occur on all clients, and always after each OnClientPutInServer() call.
*/
public void OnClientPostAdminCheck(int client) {
	if (!IS_VALID_HUMAN(client))
		return;
	Debug("OnClientPostAdminCheck(%N = %i)", client, client);
	//Just in-case, need to check if initialized since we are going to retrieve stats info from the player
	if (!isInitialized(client)) {
		Debug("Player has not yet been initialized. Skipping connect announce for '%N'", client);
		return;
	}
	PlayerConnectAnnounce(client);
}

/**
* Called when a client is disconnecting from the server. 
*  Note: This will also be called when server is changing levels
*/
public void OnClientDisconnect(int client) {
	if (!IS_VALID_HUMAN(client))
		return;
	
	Debug("OnClientDisconnect(%N) :: Resetting flags for client.", client);
	g_bInitializing[client] = false;
}

/**
* Called when the map is loaded.
*/
public void OnMapStart() {
	Debug("================================= OnMapStart =================================");
	ResetShowPlayerRankFlags();
}

/**
* Called right before a map ends.
*/
public void OnMapEnd() {
	if (HasNextMap()) {
		Debug("================================= OnMapEnd ================================= (CHANGING LEVELS)");
	} else {
		Debug("================================= OnMapEnd ================================= (NOT CHANGING LEVEL)");
	}
}

/**
* Callback for sm_hidestats command
*/
public Action Command_HideExtraFromPublic(int client, int args) {
	if (client != 0 && !IS_VALID_HUMAN(client)) {
		Debug("Client %i not valid", client);
		return Plugin_Handled;
	}
	
	if (args >= 1) {
		char arg[255];
		GetCmdArg(1, arg, sizeof(arg));
		
		//if (!String_IsNumeric(arg)) {
		//Notify(client, "Usage: sm_hidestats <1 = Hide, 0 = Unhide>");
		//return Plugin_Handled;
		//}
		
		char steamId[MAX_STEAMAUTH_LENGTH];
		if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId))) {
			Notify(client, "Could not process your request at this time. If the issue persists, please contact your administrator (Reason: Invalid Steam ID)");
			return Plugin_Handled;
		}
		
		HideStats(steamId, StringToInt(arg) > 0, client);
	} else {
		Notify(client, "Usage: sm_hidestats <1 = Hide, 0 = Unhide>");
	}
	
	return Plugin_Handled;
}

void HideStats(const char[] steamId, bool hide, int client = -1) {
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	char query[128];
	Format(query, sizeof(query), "UPDATE STATS_PLAYERS SET hide_extra_stats = %i WHERE steam_id = '%s'", (hide) ? 1 : 0, qSteamId);
	
	DataPack pack = new DataPack();
	pack.WriteString(steamId);
	pack.WriteCell(client);
	pack.WriteCell(hide);
	
	g_hDatabase.Query(TQ_HideStats, query, pack);
}

public void TQ_HideStats(Database db, DBResultSet results, const char[] error, DataPack pack) {
	if (results == null) {
		Error("TQ_HideStats :: Query failed (Reason: %s)", error);
		return;
	}
	
	pack.Reset();
	char steamId[MAX_STEAMAUTH_LENGTH];
	pack.ReadString(steamId, sizeof(steamId));
	int clientId = pack.ReadCell();
	bool hide = pack.ReadCell();
	
	if (results.AffectedRows >= 0) {
		if (hide) {
			Notify(clientId, "Your extra stats should now be hidden from public viewing");
		} else {
			Notify(clientId, "Your extra stats should now be visible to anyone");
		}
	}
}

public Action Command_WipeRank(int client, int args) {
	
	if (client != 0 && !IS_VALID_HUMAN(client)) {
		Debug("Client %i not valid", client);
		return Plugin_Handled;
	}
	
	//check if sync argument was provided
	if (args == 1) {
		char arg[255];
		GetCmdArg(1, arg, sizeof(arg));
		if (StrEqual(arg, "yes")) {
			char steamId[MAX_STEAMAUTH_LENGTH];
			if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId))) {
				Notify(client, "Could not process your request at this time. If the issue persists, please contact your administrator (Reason: Invalid Steam ID)");
				return Plugin_Handled;
			}
			
			PrintToConsole(client, "Wiping player record of '%s'", steamId);
			WipePlayerRecord(steamId, client);
			return Plugin_Handled;
		}
		
	}
	PrintToConsole(client, "Usage: sm_wiperank yes");
	
	return Plugin_Handled;
}

/**
* Reset the stats of the specified player. This will NOT delete a player record.
*/
void WipePlayerRecord(const char[] steamId, int client = -1) {
	if (StringBlank(steamId)) {
		return;
	}
	
	Debug("Resetting player record of steam id %s", steamId);
	
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	int bufferSize = (ComputeBufferSize(g_sBasicStats, sizeof(g_sBasicStats))) * 5;
	char[] fields = new char[bufferSize];
	
	for (int i = 0; i < sizeof(g_sBasicStats); i++) {
		char tmp[128];
		FormatEx(tmp, sizeof(tmp), "%s = 0,", g_sBasicStats[i]);
		StrCat(fields, bufferSize, tmp);
	}
	
	//remove last comma
	strcopy(fields, strlen(fields), fields);
	
	bufferSize *= 2 + 1;
	char[] query = new char[bufferSize];
	
	Format(query, bufferSize, "UPDATE STATS_PLAYERS SET %s WHERE steam_id = '%s'", fields, qSteamId);
	
	DataPack pack = new DataPack();
	pack.WriteString(steamId);
	pack.WriteCell(client);
	
	g_hDatabase.Query(TQ_WipePlayerRecord, query, pack);
}

public void TQ_WipePlayerRecord(Database db, DBResultSet results, const char[] error, DataPack pack) {
	if (results == null) {
		Error("TQ_WipePlayerRecord :: Query failed (Reason: %s)", error);
		return;
	}
	
	pack.Reset();
	char steamId[MAX_STEAMAUTH_LENGTH];
	pack.ReadString(steamId, sizeof(steamId));
	int client = pack.ReadCell();
	
	if (results.AffectedRows > 0) {
		PrintToConsole(client, "Record has been wiped clean for steam id '%s'", steamId);
	} else {
		PrintToConsole(client, "No affected records after wipe attempt to '%s'", steamId);
	}
	
	delete pack;
}

/**
* Computes the sum of the length of each element on the multi-dimensional character array
*/
stock int ComputeBufferSize(const char[][] arr, int size) {
	int len = 0;
	for (int i = 0; i < size; i++) {
		len += strlen(arr[i]);
	}
	return len;
}

/**
* Callback for sm_pstats_reload command
*/
public Action Command_ReloadConfig(int client, int args) {
	if (PluginDisabled()) {
		Debug("Client %N tried to execute command but player stats is currently disabled.", client);
		return Plugin_Handled;
	}
	
	bool sync = false;
	
	//check if sync argument was provided
	if (args >= 1) {
		char arg[255];
		GetCmdArg(1, arg, sizeof(arg));
		TrimString(arg);
		
		if (StrEqual("sync", arg)) {
			sync = true;
		} else {
			Notify(client, "Usage: sm_pstats_reload <sync>");
			return Plugin_Handled;
		}
	}
	
	if (!LoadConfigData()) {
		LogAction(client, -1, "Failed to reload plugin configuration file");
		SetFailState("Problem loading/reading config file: %s", g_ConfigPath);
		return Plugin_Handled;
	}
	
	//If sync is specified, flush the cached entries to the database
	if (sync) {
		if (!ExtrasEnabled()) {
			Notify(client, "Note: Extra statistics are excluded from this operation since the feature is disabled.");
		}
		FlushStatModifiersToDb();
	}
	
	LogAction(client, -1, "Plugin configuration reloaded successfully");
	Notify(client, "Plugin configuration reloaded successfully");
	
	if (DebugEnabled()) {
		PlayerConnectAnnounce(client);
	}
	return Plugin_Handled;
}

/**
* Flushes the cached stat modifiers (entries that have been recently read from the config file) into the database
*/
public void FlushStatModifiersToDb() {
	if (g_mStatModifiers == null || g_mStatModifiers.Size == 0) {
		Debug("FlushStatModifiersToDb :: No cached entries available. Perhaps the config file was not loaded?");
		return;
	}
	
	StringMapSnapshot keys = g_mStatModifiers.Snapshot();
	
	for (int i = 0; i < keys.Length; i++) {
		int bufferSize = keys.KeyBufferSize(i);
		char[] keyName = new char[bufferSize];
		keys.GetKey(i, keyName, bufferSize);
		
		float value = DEFAULT_POINT_MODIFIER;
		if (g_mStatModifiers.GetValue(keyName, value)) {
			SyncStatModifiers(keyName, value);
		}
	}
}

/**
* Load/Reload the plugin configuration file
*
* @param forceSync If true, the stat modifiers read from the config file will be synchronized to the database.
*/
bool LoadConfigData() {
	KeyValues kv = new KeyValues("PlayerStats");
	
	if (!kv.ImportFromFile(g_ConfigPath)) {
		return false;
	}
	
	//Re-initialize the modifier map
	if (g_mStatModifiers == null) {
		Debug("Re-initializing map");
		g_mStatModifiers = new StringMap();
	}
	
	Info("Parsing configuration file: %s", g_ConfigPath);
	
	Debug("Processing Stat Modifiers");
	if (kv.JumpToKey("StatModifiers", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				char key[255];
				float value;
				kv.GetSectionName(key, sizeof(key));
				value = kv.GetFloat(NULL_STRING, DEFAULT_POINT_MODIFIER);
				
				Debug("> Caching modifier: %s = %f", key, value);
				g_mStatModifiers.SetValue(key, value, true);
			}
			while (kv.GotoNextKey(false));
		}
		kv.GoBack();
	} else {
		Error("Missing config key 'StatModifiers'");
		delete kv;
		return false;
	}
	kv.GoBack();
	
	Debug("Cached a total of %d stat modifiers", g_mStatModifiers.Size);
	
	Debug("Processing Stat Panel Configuration");
	if (!kv.JumpToKey("StatPanels"))
	{
		Error("Missing config key 'PlayerRankPanel'");
		delete kv;
		return false;
	}
	
	//Player rank panel
	kv.GetString("title_rank_player", g_StatPanelTitlePlayer, sizeof(g_StatPanelTitlePlayer));
	
	if (strcmp(g_StatPanelTitlePlayer, "", false) == 0) {
		Debug("Config 'title_rank_player' is empty. Using default");
		FormatEx(g_StatPanelTitlePlayer, sizeof(g_StatPanelTitlePlayer), DEFAULT_TITLE_STAT_PANEL_PLAYER);
	}
	
	//Top N rank panel
	kv.GetString("title_rank_topn", g_StatPanelTitleTopN, sizeof(g_StatPanelTitleTopN));
	
	if (strcmp(g_StatPanelTitleTopN, "", false) == 0) {
		Debug("Config 'title_rank_topn' is empty. Using default");
		FormatEx(g_StatPanelTitleTopN, sizeof(g_StatPanelTitleTopN), DEFAULT_TITLE_STAT_PANEL_TOPN);
	}
	
	//In-Game players rank panel
	kv.GetString("title_rank_ingame", g_StatPanelTitleInGame, sizeof(g_StatPanelTitleInGame));
	
	if (strcmp(g_StatPanelTitleInGame, "", false) == 0) {
		Debug("Config 'title_rank_ingame' is empty. Using default");
		FormatEx(g_StatPanelTitleInGame, sizeof(g_StatPanelTitleInGame), DEFAULT_TITLE_STAT_PANEL_INGAME);
	}
	
	kv.GetString("title_rank_extras", g_StatPanelTitleExtras, sizeof(g_StatPanelTitleExtras));
	if (strcmp(g_StatPanelTitleExtras, "", false) == 0) {
		Debug("Config 'title_rank_extras' is empty. Using default");
		FormatEx(g_StatPanelTitleExtras, sizeof(g_StatPanelTitleExtras), DEFAULT_TITLE_STAT_PANEL_EXTRAS);
	}
	
	Debug("> Parsed title : Stat Panel Title (Player) = %s", g_StatPanelTitlePlayer);
	Debug("> Parsed title : Stat Panel Title (Top N) = %s", g_StatPanelTitleTopN);
	Debug("> Parsed title : Stat Panel Title (In-Game) = %s", g_StatPanelTitleInGame);
	Debug("> Parsed title : Stat Panel Title (Extras) = %s", g_StatPanelTitleExtras);
	
	kv.GoBack();
	
	Debug("Processing Connect Announce");
	if (!kv.JumpToKey("ConnectAnnounce")) {
		Error("Missing config key 'ConnectAnnounce'");
		delete kv;
		return false;
	}
	
	kv.GetString("format", g_ConfigAnnounceFormat, sizeof(g_ConfigAnnounceFormat));
	
	if (strcmp(g_ConfigAnnounceFormat, "", false) == 0) {
		Debug("> Connect announce format is empty. Using default");
		FormatEx(g_ConfigAnnounceFormat, sizeof(g_ConfigAnnounceFormat), DEFAULT_CONFIG_ANNOUNCE_FORMAT);
	}
	
	Debug("> Parsed connect announce format : Connect Announce Format = %s", g_ConfigAnnounceFormat);
	
	kv.GoBack();
	
	Debug("Processing SQL Configuration");
	if (!kv.JumpToKey("SQL"))
	{
		Error("Missing config key 'SQL'");
		delete kv;
		return false;
	}
	//SQL server config
	kv.GetString("host", g_SQLHost, sizeof(g_SQLHost));
	kv.GetString("database", g_SQLDb, sizeof(g_SQLDb));
	kv.GetString("user", g_SQLUser, sizeof(g_SQLUser));
	kv.GetString("pass", g_SQLPass, sizeof(g_SQLPass));
	
	kv.GoBack();
	
	delete kv;
	return true;
}

/**
* Check if a record of a player exists
*
* @parm The steam id of the player to check. In'STEAM_*'format.
*/
public bool PlayerRecordExists(const char[] steamId) {
	int count = 0;
	
	if (g_hQueryRecordExists == null) {
		char error[255];
		g_hQueryRecordExists = SQL_PrepareQuery(g_hDatabase, "SELECT COUNT(1) FROM STATS_PLAYERS s WHERE s.steam_id = ? LIMIT 1", error, sizeof(error));
		if (g_hQueryRecordExists == null) {
			Error("PlayerRecordExists :: Unable to prepare sql query (Reason: %s)", error);
			return false;
		}
	}
	
	SQL_BindParamString(g_hQueryRecordExists, 0, steamId, false);
	
	if (!SQL_Execute(g_hQueryRecordExists)) {
		Error("Unable to execute query for PlayerRecordExists");
		return false;
	}
	
	if (SQL_FetchRow(g_hQueryRecordExists)) {
		count = SQL_FetchInt(g_hQueryRecordExists, 0);
	}
	
	return count > 0;
}

/**
* Queries the database for the number of stat modifiers in the database
*/
public int GetStatModifierCount() {
	int count = 0;
	DBResultSet query = SQL_Query(g_hDatabase, "SELECT COUNT(1) FROM STATS_SKILLS");
	if (query == null) {
		char error[255];
		SQL_GetError(g_hDatabase, error, sizeof(error));
		Error("GetStatModifierCount :: Failed to query table count (Reason: %s)", error);
		return -1;
	}
	else {
		if (query.FetchRow()) {
			count = query.FetchInt(0);
			Debug("Got total stat modifier count in table: %i", count);
		}
		delete query;
		
		query = SQL_Query(g_hDatabase, "SELECT * FROM STATS_SKILLS");
		if (query == null) {
			char error[255];
			SQL_GetError(g_hDatabase, error, sizeof(error));
			Error("GetStatModifierCount :: Failed to query table count (Reason: %s)", error);
			return -1;
		}
		else {
			while (query.FetchRow()) {
				int nameFieldId = -1;
				int modFieldId = -1;
				if (query.FieldNameToNum("name", nameFieldId) && nameFieldId >= 0
					 && query.FieldNameToNum("modifier", modFieldId) && modFieldId >= 0) {
					char name[255];
					query.FetchString(nameFieldId, name, 255);
					float mod = query.FetchFloat(modFieldId);
					g_mStatModifiers.SetValue(name, mod);
				}
			}
		}
	}
	return count;
}

/**
* Synchronizes (Insert or Update) the statistic key/value into the STATS_SKILLS database table
*/
public void SyncStatModifiers(const char[] key, float value) {
	if (StringBlank(key)) {
		Debug("No key specified. Skipping sync");
		return;
	}
	
	int len = strlen(key) * 2 + 1;
	char[] qKey = new char[len];
	if (!g_hDatabase.Escape(key, qKey, len)) {
		Debug("Could not escape string '%s'", key);
		return;
	}
	
	char query[512];
	FormatEx(query, sizeof(query), "INSERT INTO STATS_SKILLS (name, modifier, update_date) VALUES ('%s', %f, current_timestamp()) ON DUPLICATE KEY UPDATE modifier = %f, update_date = current_timestamp()", qKey, value, value);
	
	DataPack pack = new DataPack();
	pack.WriteString(key);
	pack.WriteFloat(value);
	
	g_hDatabase.Query(TQ_SyncStatModifiers, query, pack);
}

/**
* SQL Callback for SyncStatModifiers
*/
public void TQ_SyncStatModifiers(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		Error("TQ_SyncStatModifiers :: Query failed (Reason: %s)", error);
		return;
	}
	
	DataPack pack = data;
	char name[255];
	float modifier;
	
	pack.Reset();
	pack.ReadString(name, sizeof(name));
	modifier = pack.ReadFloat();
	
	if (results.AffectedRows > 0) {
		Info("Synchronized cached entry to DB (%s = %.2f)", name, modifier);
	} else {
		Info("Nothing was synced (%s = %.2f)", name, modifier);
	}
}

public Action Event_PlayerReplaceBot(Event event, const char[] name, bool dontBroadcast) {
	int botId = event.GetInt("bot");
	int userId = event.GetInt("player");
	
	int botClientId = GetClientOfUserId(botId);
	int clientId = GetClientOfUserId(userId);
	
	Debug("Player %N has replaced bot %N", clientId, botClientId);
	
	return Plugin_Continue;
}

public Action Event_PlayerTransitioned(Event event, const char[] name, bool dontBroadcast) {
	int userId = event.GetInt("userid");
	int clientId = GetClientOfUserId(userId);
	Debug("Player has transitioned to first person view = %N", clientId);
	
	if (IS_VALID_HUMAN(clientId) && ShowRankOnConnect() && !PlayerRankShown(clientId)) {
		char steamId[MAX_STEAMAUTH_LENGTH];
		if (GetClientAuthId(clientId, AuthId_Steam2, steamId, sizeof(steamId))) {
			ShowPlayerRankPanel(clientId, steamId);
			SetPlayerRankShownFlag(clientId);
		} else {
			Error("Event_PlayerTransitioned :: Could not obtain steam id of client %N", clientId);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast) {
	char playerName[MAX_NAME_LENGTH];
	char steamId[MAX_STEAMAUTH_LENGTH];
	char ipAddress[16];
	
	event.GetString("name", playerName, sizeof(playerName));
	event.GetString("networkid", steamId, sizeof(steamId));
	event.GetString("address", ipAddress, sizeof(ipAddress));
	int slot = event.GetInt("index");
	int userid = event.GetInt("userid");
	bool isBot = event.GetBool("bot");
	
	if (!isBot) {
		int client = GetClientOfUserId(userid);
		Debug("\n\nPLAYER_CONNECT_EVENT :: Name = %s, Steam ID: %s, IP: %s, Slot: %i, User ID: %i, Is Bot: %i, Client ID: %i\n\n", playerName, steamId, ipAddress, slot, userid, isBot, client);
		if (PlayerRecordExists(steamId)) {
			Info("Found existing record for player '%s' (%s)", playerName, steamId);
		} else {
			Debug("\n\nNo player record found for %s (%s)", playerName, steamId);
		}
		
		//InitializePlayer(client, true);
	}
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	char reason[512];
	char playerName[MAX_NAME_LENGTH];
	char networkId[255];
	
	int userId = event.GetInt("userid");
	int clientId = GetClientOfUserId(userId);
	
	event.GetString("name", playerName, sizeof(playerName));
	event.GetString("reason", reason, sizeof(reason));
	event.GetString("networkid", networkId, sizeof(networkId));
	int isBot = event.GetInt("bot");
	
	if (!IS_VALID_CLIENT(clientId) || IsFakeClient(clientId))
		return Plugin_Continue;
	
	Debug("(EVENT => %s): name = %s, reason = %s, id = %s, isBot = %i, clientid = %i", name, playerName, reason, networkId, isBot, clientId);
	Debug("Resetting client flags for player %N", clientId);
	
	g_bPlayerInitialized[clientId] = false;
	
	UnsetPlayerRankShownFlag(clientId);
	
	return Plugin_Continue;
}

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast) {
	Debug("================================= MAP TRANSITION =================================");
}

/**
* Called when the plugin is about to be unloaded.
* It is not necessary to close any handles or remove hooks in this function. SourceMod guarantees that plugin shutdown automatically and correctly releases all resources.
*/
public void OnPluginEnd() {
	Debug("================================= OnPluginEnd =================================");
}

/**
* Check if player has been initialized (existing record in database)
*
* @return true if the player record has been initialized
*/
public bool isInitialized(int client) {
	return g_bPlayerInitialized[client];
}

/**
* Function to check if we are on the final level of the versus campaign
*
* @return true if the current map is the final map of the versus campaign
*/
stock bool IsFinalMap()
{
	return (FindEntityByClassname(-1, "info_changelevel") == -1
		 && FindEntityByClassname(-1, "trigger_changelevel") == -1);
}

/**
* Function to check if we still have a next level after the current
* 
* @return true if we still have next map after the current
*/
stock bool HasNextMap()
{
	return (FindEntityByClassname(-1, "info_changelevel") >= 0
		 || FindEntityByClassname(-1, "trigger_changelevel") >= 0);
}

/**
* Callback for sm_topig command
*/
public Action Command_ShowTopPlayersInGame(int client, int args) {
	if (PluginDisabled()) {
		Notify(client, "Cannot execute command. Player stats is currently disabled.");
		return Plugin_Handled;
	}
	ShowInGamePlayerRanks(client);
	return Plugin_Handled;
}

/**
* Display a panel showing the statistics and rank of the players in-game
*
* @param client The requesting client index
*/
public void ShowInGamePlayerRanks(int client) {
	if (!IS_VALID_CLIENT(client) || IsFakeClient(client)) {
		Debug("ShowInGamePlayerRanks :: Skipping show stats. Not a valid client (%i)", client);
		return;
	}
	
	char steamId[MAX_STEAMAUTH_LENGTH];
	if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId))) {
		Error("ShowInGamePlayerRanks :: Could not retrieve a valid steam id for '%N'", client);
		return;
	}
	
	char steamIds[256];
	int count = GetInGamePlayerSteamIds(steamIds, sizeof(steamIds));
	
	if (count == 0) {
		Debug("ShowInGamePlayerRanks :: No players available to query");
		return;
	}
	
	Debug("Steam Ids = %s", steamIds);
	
	char query[512];
	
	FormatEx(query, sizeof(query), "SELECT * from STATS_VW_PLAYER_RANKS s WHERE s.steam_id IN (%s) ORDER BY rank_num LIMIT 8", steamIds);
	
	Debug("ShowInGamePlayerRanks :: Executing query: %s", query);
	
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(count);
	g_hDatabase.Query(TQ_ShowInGamePlayerRanks, query, pack);
}

/**
* SQL Callback for 'ShowInGamePlayerRanks' Command
*/
public void TQ_ShowInGamePlayerRanks(Database db, DBResultSet results, const char[] error, any data) {
	DataPack pack = data;
	StringMap map = new StringMap();
	
	pack.Reset();
	int clientId = pack.ReadCell();
	//int playerCount = pack.ReadCell();
	
	//Verify that the player is still connected to the server
	if (!IS_VALID_HUMAN(clientId)) {
		Error("TQ_ShowInGamePlayerRanks :: Client id %i is no longer valid (Player has probably left the server before the completion of this request)", clientId);
		delete pack;
		delete map;
		return;
	}
	
	char msg[255];
	Menu menu = new Menu(TopInGameRanksMenuHandler);
	menu.ExitButton = true;
	menu.SetTitle(g_StatPanelTitleInGame);
	
	while (results.FetchRow()) {
		ExtractPlayerStats(results, map);
		
		char steamId[MAX_STEAMAUTH_LENGTH];
		char lastKnownAlias[255];
		int rankNum;
		
		map.GetString(STATS_STEAM_ID, steamId, sizeof(steamId));
		map.GetString(STATS_LAST_KNOWN_ALIAS, lastKnownAlias, sizeof(lastKnownAlias));
		map.GetValue(STATS_RANK, rankNum);
		
		Debug("> Player: %s", lastKnownAlias);
		Format(msg, sizeof(msg), "%s (Rank %d)", lastKnownAlias, rankNum);
		menu.AddItem(steamId, msg);
		
		delete map;
		map = new StringMap();
	}
	
	menu.Display(clientId, g_iStatsMenuTimeout.IntValue);
	
	delete pack;
	delete map;
}

/**
* Callback for TQ_ShowInGamePlayerRanks menu
*/
public int TopInGameRanksMenuHandler(Menu menu, MenuAction action, int clientId, int idIndex) {
	//Verify that the player is still connected to the server
	/*if (!IS_VALID_HUMAN(clientId)) {
		Error("TopInGameRanksMenuHandler :: Client id %i is no longer valid (Player has probably left the server before the completion of this request)", clientId);
		delete menu;
		return;
	}*/
	
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char steamId[MAX_STEAMAUTH_LENGTH];
		bool found = menu.GetItem(idIndex, steamId, sizeof(steamId));
		
		if (found) {
			ShowPlayerRankPanel(clientId, steamId);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		Debug("Client %N's menu was cancelled.  Reason: %d", clientId, idIndex);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/**
* Builds a comma delimited string of steam ids of each player who is currently in-game and associated with a team (survivor or infected). 
* Spectators or players with invalid steam id are ignored. Note: The buffer should be big enough to contain at least 8 steam id strings (at least 256).
*/
public int GetInGamePlayerSteamIds(char[] buffer, int size) {
	if (size < 171) {
		Error("GetInGamePlayerSteamIds :: Buffer size is too small (%i). Should be > 170", size);
		return 0;
	}
	int count = 0;
	char steamId[MAX_STEAMAUTH_LENGTH];
	char tmp[128];
	
	int humanCount = GetHumanPlayerCount(false);
	
	for (int i = 1; i <= MAX_CLIENTS; i++) {
		if (IS_VALID_HUMAN(i) && (IS_VALID_SURVIVOR(i) || IS_VALID_INFECTED(i))) {
			//yeah, do not ignore retvals
			if (GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId))) {
				if ((count + 1) >= humanCount) {
					FormatEx(tmp, sizeof(tmp), "'%s'", steamId);
				} else {
					FormatEx(tmp, sizeof(tmp), "'%s',", steamId);
				}
				Debug("GetInGamePlayerSteamIds :: Adding: %s", tmp);
				StrCat(buffer, size, tmp);
				count++;
			}
		}
	}
	return count;
}

/**
* Callback method for the sm_top console command
*/
public Action Command_ShowTopPlayers(int client, int args) {
	if (PluginDisabled()) {
		Notify(client, "Cannot execute command. Player stats is currently disabled.");
		return Plugin_Handled;
	}
	
	int maxPlayers = (g_iStatsMaxTopPlayers.IntValue <= 0) ? DEFAULT_MAX_TOP_PLAYERS : g_iStatsMaxTopPlayers.IntValue;
	
	if (args >= 1) {
		
		char arg[255];
		GetCmdArg(1, arg, sizeof(arg));
		
		if (!String_IsNumeric(arg)) {
			Notify(client, "Argument must be numeric: %s", arg);
			return Plugin_Handled;
		}
		
		//TrimString(arg, arg, sizeof(arg));
		TrimString(arg);
		
		maxPlayers = StringToInt(arg);
		
		//Check bounds
		if (maxPlayers < DEFAULT_MIN_TOP_PLAYERS) {
			maxPlayers = DEFAULT_MIN_TOP_PLAYERS;
		}
		if (maxPlayers > DEFAULT_MAX_TOP_PLAYERS)
			maxPlayers = DEFAULT_MAX_TOP_PLAYERS;
	}
	
	Debug("Displaying top %i players", maxPlayers);
	ShowTopPlayersRankPanel(client, maxPlayers);
	
	return Plugin_Handled;
}

/**
* Display the Player Rank Panel to the target user
*
* @param client The target client index
* @param max The maximum number of players to be displayed on the rank panel. Note: The upper and lower limits are capped between DEFAULT_MIN_TOP_PLAYERS and DEFAULT_MAX_TOP_PLAYERS.
*/
void ShowTopPlayersRankPanel(int client, int max = DEFAULT_MAX_TOP_PLAYERS) {
	if (!IS_VALID_CLIENT(client) || IsFakeClient(client)) {
		Debug("Skipping show stats. Not a valid client");
		return;
	}
	
	char steamId[MAX_STEAMAUTH_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	int maxRows = (max <= 0) ? ((g_iStatsMaxTopPlayers.IntValue <= 0) ? DEFAULT_MAX_TOP_PLAYERS : g_iStatsMaxTopPlayers.IntValue) : max;
	
	char query[512];
	
	FormatEx(query, sizeof(query), "select * from STATS_VW_PLAYER_RANKS s LIMIT %i", maxRows);
	
	Debug("ShowTopPlayersRankPanel :: Executing query: %s", query);
	
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(maxRows);
	
	g_hDatabase.Query(TQ_ShowTopPlayers, query, pack);
}

/**
* SQL Callback for Show Top Players Command
*/
public void TQ_ShowTopPlayers(Database db, DBResultSet results, const char[] error, DataPack pack) {
	pack.Reset();
	int clientId = pack.ReadCell();
	int maxRows = pack.ReadCell();
	
	//Verify that the player is still connected to the server
	if (!IS_VALID_HUMAN(clientId)) {
		Error("TQ_ShowTopPlayers :: Client id %i is no longer valid (Player has probably left the server before the completion of this request)", clientId);
		delete pack;
		return;
	}
	
	StringMap map = new StringMap();
	
	Debug("Displaying Total of %i entries", maxRows);
	
	char msg[255];
	Menu menu = new Menu(TopPlayerStatsMenuHandler);
	menu.ExitButton = true;
	
	FormatEx(msg, sizeof(msg), "%s", g_StatPanelTitleTopN);
	
	char maxRowsStr[32];
	IntToString(maxRows, maxRowsStr, sizeof(maxRowsStr));
	ReplaceString(msg, sizeof(msg), "{top_player_count}", maxRowsStr);
	menu.SetTitle(msg);
	
	while (results.FetchRow()) {
		ExtractPlayerStats(results, map);
		
		char steamId[MAX_STEAMAUTH_LENGTH];
		char lastKnownAlias[MAX_NAME_LENGTH];
		int rankNum;
		
		map.GetString(STATS_STEAM_ID, steamId, sizeof(steamId));
		map.GetString(STATS_LAST_KNOWN_ALIAS, lastKnownAlias, sizeof(lastKnownAlias));
		map.GetValue(STATS_RANK, rankNum);
		
		Debug("> Player: %s", lastKnownAlias);
		Format(msg, sizeof(msg), "%s (Rank %d)", lastKnownAlias, rankNum);
		menu.AddItem(steamId, msg);
		
		delete map;
		map = new StringMap();
	}
	
	menu.Display(clientId, g_iStatsMenuTimeout.IntValue);
	
	delete pack;
	delete map;
}

public int TopPlayerStatsMenuHandler(Menu menu, MenuAction action, int clientId, int idIndex)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char steamId[MAX_STEAMAUTH_LENGTH];
		bool found = menu.GetItem(idIndex, steamId, sizeof(steamId));
		
		if (found) {
			ShowPlayerRankPanel(clientId, steamId);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		Debug("Client %N's menu was cancelled.  Reason: %d", clientId, idIndex);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/**
* Callback method for the command show rank
*/
public Action Command_ShowRank(int client, int args) {
	if (PluginDisabled()) {
		Notify(client, "Cannot execute command. Player stats is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!IS_VALID_HUMAN(client)) {
		Error("Client '%N' is not valid. Skipping show rank", client);
		return Plugin_Handled;
	}
	
	char steamId[MAX_STEAMAUTH_LENGTH];
	if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId))) {
		Error("Unable to retrieve a valid steam id from client %N", client);
	}
	ShowPlayerRankPanel(client, steamId);
	return Plugin_Handled;
}

/**
* Display the rank/stats panel to the requesting player
*/
public void ShowPlayerRankPanel(int client, const char[] steamId) {
	if (!IS_VALID_HUMAN(client)) {
		Debug("Skipping display of rank panel for client %i. Not a valid human player", client);
		return;
	}
	
	//Check if a request is already in progress
	if (g_bShowingRankPanel[client]) {
		if (IS_VALID_HUMAN(client)) {
			Notify(client, "Your request is already being processed");
			return;
		}
	}
	
	if (!isInitialized(client)) {
		Debug("ShowPlayerRankPanel :: Client %N is not yet initialized", client);
		return;
	}
	
	char clientSteamId[MAX_STEAMAUTH_LENGTH];
	
	if (GetClientAuthId(client, AuthId_Steam2, clientSteamId, sizeof(clientSteamId)) && StrEqual(clientSteamId, steamId)) {
		Info("Player '%N' is viewing his own rank", client);
	} else {
		Info("Player '%N' is viewing the rank of steam id '%s'", client, steamId);
	}
	
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	char query[512];
	
	FormatEx(query, sizeof(query), "select * from STATS_VW_PLAYER_RANKS s WHERE s.steam_id = '%s'", qSteamId);
	
	Debug("ShowPlayerRankPanel :: Executing Query: %s", query);
	
	g_bShowingRankPanel[client] = true;
	
	DataPack pack = new DataPack();
	pack.WriteString(steamId);
	pack.WriteCell(client);
	
	g_hDatabase.Query(TQ_ShowPlayerRankPanel, query, pack);
}

/**
* SQL Callback for Player Rank/Stats Panel.
*/
public void TQ_ShowPlayerRankPanel(Database db, DBResultSet results, const char[] error, DataPack pack) {
	pack.Reset();
	char selSteamId[MAX_STEAMAUTH_LENGTH];
	pack.ReadString(selSteamId, sizeof(selSteamId));
	int clientId = pack.ReadCell();
	
	//Verify that the player is still connected to the server
	if (!IS_VALID_HUMAN(clientId)) {
		Debug("TQ_ShowPlayerRankPanel :: Client id %i is no longer valid (Player has probably left the server before the completion of this request)", clientId);
		g_bShowingRankPanel[clientId] = false;
		delete pack;
		return;
	}
	
	if (results == null) {
		Error("TQ_ShowPlayerRankPanel :: Query failed (Reason: %s)", error);
		g_bShowingRankPanel[clientId] = false;
	} else if (results.RowCount > 0) {
		StringMap map = new StringMap();
		
		if (results.FetchRow()) {
			//Extract basic stats
			ExtractPlayerStats(results, map);
			
			char steamId[MAX_STEAMAUTH_LENGTH];
			char createDate[255];
			char lastJoinDate[255];
			
			//Retrieve general info
			map.GetString(STATS_STEAM_ID, steamId, sizeof(steamId));
			map.GetString(STATS_LAST_JOIN_DATE, lastJoinDate, sizeof(lastJoinDate));
			map.GetString(STATS_CREATE_DATE, createDate, sizeof(createDate));
			
			char msg[255];
			Panel panel = new Panel();
			if (!StringBlank(g_StatPanelTitlePlayer)) {
				panel.SetTitle(g_StatPanelTitlePlayer);
			}
			
			PanelDrawStatLineBreak(panel);
			
			PanelDrawStatLabelStr(panel, "Name", STATS_LAST_KNOWN_ALIAS, map, "\"", "\"");
			PanelDrawStatLabelInt(panel, "Rank", STATS_RANK, map, "#");
			PanelDrawStatLabelFloat(panel, "Points", STATS_TOTAL_POINTS, map);
			
			PanelDrawStatLineBreak(panel);
			
			PanelDrawStatItem(panel, "Stat");
			
			PanelDrawStat(panel, "Death", STATS_SURVIVOR_DEATH, map);
			PanelDrawStat(panel, "Revived", STATS_SURVIVOR_REVIVED, map);
			PanelDrawStat(panel, "Healed", STATS_SURVIVOR_HEALED, map);
			PanelDrawStat(panel, "Defibed", STATS_SURVIVOR_DEFIBED, map);
			PanelDrawStatLabelStr(panel, "Class", STATS_WEAPON_CLASS, map);
			//TODO
			//PanelDrawStatLabelStr(panel, "Title", STATS_SURVIVOR_TITLE, map);
			
			PanelDrawStatItem(panel, "Killed");
			
			PanelDrawStat(panel, "Common", STATS_INFECTED_KILLED, map);
			PanelDrawStat(panel, "Boomer", STATS_BOOMER_KILLED, map);
			PanelDrawStat(panel, "Charger", STATS_CHARGER_KILLED, map);
			PanelDrawStat(panel, "Hunter", STATS_HUNTER_KILLED, map);
			PanelDrawStat(panel, "Jockey", STATS_JOCKEY_KILLED, map);
			PanelDrawStat(panel, "Smoker", STATS_SMOKER_KILLED, map);
			PanelDrawStat(panel, "Witch", STATS_WITCH_KILLED, map);
			PanelDrawStat(panel, "Tank", STATS_TANK_KILLED, map);
			
			
			PanelDrawStatLineBreak(panel); //line-break
			
			//If extra stats are enabled, display the menu item
			//Extra stats will be shown to the requesting player if
			// - The target player did not opt out extra stats from public viewing
			// - The requesting player is viewing his own
			// - The requesting player is an admin
			if (IsSamePlayer(clientId, selSteamId) || Client_IsAdmin(clientId)) {
				Format(msg, sizeof(msg), "More Stats");
				panel.DrawItem(msg, ITEMDRAW_DEFAULT);
				
				//Since there is no way to pass the steam id to the menu handler callback, 
				//we store the steam id to a global variable instead.. :/
				
				//Copy data to global variable
				strcopy(g_SelSteamIds[clientId], sizeof(g_SelSteamIds[]), selSteamId);
				
				Debug("TQ_ShowPlayerRankPanel :: Updated client %N's player selection = %s", clientId, g_SelSteamIds[clientId]);
			}
			
			panel.Send(clientId, PlayerStatsMenuHandler, g_iStatsMenuTimeout.IntValue);
		}
		
		delete map;
	} else {
		Debug("TQ_ShowPlayerRankPanel :: No record was fetched for client %N. Possibly deleted from the database?", clientId);
		ResetInitializeFlags(clientId);
	}
	g_bShowingRankPanel[clientId] = false;
}

public bool IsSamePlayer(int client, const char[] steamId) {
	return client == Client_FindBySteamId(steamId);
}

/**
* Menu Callback Handler for Show Player Rank panel
*/
public int PlayerStatsMenuHandler(Menu menu, MenuAction action, int client, int selectedIndex)
{
	//Verify that the player is still connected to the server
	if (!IS_VALID_HUMAN(client)) {
		Debug("PlayerStatsMenuHandler :: Client id %i is no longer valid (Player has probably left the server before the completion of this request)", client);
		delete menu;
		return;
	}
	
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		if (selectedIndex != 3) {
			Debug("Clearing selected steam id");
			strcopy(g_SelSteamIds[client], sizeof(g_SelSteamIds[]), "");
			return;
		}
		
		if (StringBlank(g_SelSteamIds[client])) {
			Error("PlayerStatsMenuHandler :: Unable to retrieve the selected steam id");
			delete menu;
			return;
		}
		
		Debug("Showing the extra stats panel to %N", client);
		ShowExtraStatsPanel(client, g_SelSteamIds[client]);
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		Debug("PlayerStatsMenuHandler :: Client %d's menu was cancelled.", client, selectedIndex);
		//strcopy(g_SelSteamIds[client], sizeof(g_SelSteamIds[]), "");
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		Debug("PlayerStatsMenuHandler :: Cleaning up resources");
		strcopy(g_SelSteamIds[client], sizeof(g_SelSteamIds[]), "");
		delete menu;
	}
}

/**
* Display the extra statistics panel to the requesting user. Request is ignored if the feature is disabled.
*/
public void ShowExtraStatsPanel(int client, const char[] steamId) {
	if (!ExtrasEnabled()) {
		Error("Extra stats are currently disabled");
		return;
	}
	
	if (!IS_VALID_HUMAN(client)) {
		Debug("Skipping display of extra stats panel for client %i. Not a valid human player", client);
		return;
	}
	
	char clientSteamId[MAX_STEAMAUTH_LENGTH];
	
	if (GetClientAuthId(client, AuthId_Steam2, clientSteamId, sizeof(clientSteamId)) && StrEqual(clientSteamId, steamId)) {
		Info("Player '%N' is viewing his extra stats", client);
	} else {
		Info("Player '%N' is viewing the extra stats of steam id '%s'", client, steamId);
	}
	
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	char query[512];
	FormatEx(query, sizeof(query), "select * from STATS_VW_PLAYER_RANKS s WHERE s.steam_id = '%s'", qSteamId);
	
	g_hDatabase.Query(TQ_ShowExtraStatsPanel, query, client);
}

public void BuildGameInfoMap(StringMap & map) {
	if (map == null)
		return;
	
	char serverName[MAX_NAME_LENGTH];
	GetServerName(serverName, sizeof(serverName));
	
	//Set server name
	map.SetString(GAMEINFO_SERVER_NAME, serverName);
}

/**
* SQL Callback for Extra Player Rank/Stats Panel.
*/
public void TQ_ShowExtraStatsPanel(Database db, DBResultSet results, const char[] error, int client) {
	//Verify that the player is still connected to the server
	if (!IS_VALID_HUMAN(client)) {
		Error("TQ_ShowExtraStatsPanel :: Client id %i is no longer valid (Player has probably left the server before the completion of this request)", client);
		return;
	}
	
	if (results == null) {
		Error("TQ_ShowExtraStatsPanel :: Query failed! %s", error);
	} else if (results.RowCount > 0) {
		
		StringMap map = new StringMap();
		
		if (results.FetchRow()) {
			
			//Extract and store to map
			ExtractPlayerStats(results, map);
			
			Panel panel = new Panel();
			
			panel.SetTitle(g_StatPanelTitleExtras);
			
			PanelDrawStatLineBreak(panel);
			
			PanelDrawStatLabelStr(panel, "Name", STATS_LAST_KNOWN_ALIAS, map, "\"", "\"");
			
			PanelDrawStatLineBreak(panel);
			
			PanelDrawStatItem(panel, "Class");
			
			//#define STATS_WEAPON_SPECIAL "weapon_special"
			//#define STATS_WEAPON_RIFLE "weapon_rifle"
			//#define STATS_WEAPON_SMG "weapon_smg"
			//#define STATS_WEAPON_SNIPER "weapon_sniper"
			//#define STATS_WEAPON_SHOTGUN "weapon_shotgun"
			//#define STATS_WEAPON_MELEE "weapon_melee"
			//#define STATS_WEAPON_DEAGLE "weapon_deagle"
			
			//PanelDrawStat(panel, "Class", STATS_WEAPON_CLASS, map);
			PanelDrawStatLabelStr(panel, "Class", STATS_WEAPON_CLASS, map);
			PanelDrawStat(panel, "Rifle kill", STATS_WEAPON_RIFLE, map);
			PanelDrawStat(panel, "Shotgun kill", STATS_WEAPON_SHOTGUN, map);
			PanelDrawStat(panel, "Melee kill", STATS_WEAPON_MELEE, map);
			PanelDrawStat(panel, "Sniper kill", STATS_WEAPON_SNIPER, map);
			PanelDrawStat(panel, "Smg kill", STATS_WEAPON_SMG, map);
			PanelDrawStat(panel, "Deagle kill", STATS_WEAPON_DEAGLE, map);
			PanelDrawStat(panel, "Special kill", STATS_WEAPON_SPECIAL, map);
			
			PanelDrawStatItem(panel, "Special");
			
			PanelDrawStat(panel, "Boomer killed without bile", STATS_BOOMER_KILLED_CLEAN, map);
			PanelDrawStat(panel, "Hunter shoved", STATS_HUNTER_SHOVED, map);
			PanelDrawStat(panel, "Jockey shoved", STATS_JOCKEY_SHOVED, map);
			PanelDrawStat(panel, "Total jockey ride time", STATS_JOCKEY_RIDED, map);
			PanelDrawStat(panel, "Smoker tongue slashed", STATS_SMOKER_TONGUE_SLASHED, map);
			PanelDrawStat(panel, "Witch crowned", STATS_WITCH_KILLED_1SHOT, map);
			PanelDrawStat(panel, "Melee hit tank", STATS_TANK_MELEE, map);
			
			PanelDrawStatLineBreak(panel);
			
			PanelDrawStatItem(panel, "Back");
			
			panel.Send(client, ShowExtraStatsMenuHandler, g_iStatsMenuTimeout.IntValue);
			
			Debug("TQ_ShowExtraStatsPanel :: Successfully extracted all values");
		}
		
		delete map;
	}
}

/**
* Menu Callback Handler for ShowExtraStatsPanel panel
*/
public int ShowExtraStatsMenuHandler(Menu menu, MenuAction action, int client, int selectedIndex) {
	//Verify that the player is still connected to the server
	if (!IS_VALID_HUMAN(client)) {
		Error("ShowExtraStatsMenuHandler :: Client id %i is no longer valid (Player has probably left the server before the completion of this request)", client);
		return;
	}
	
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		Debug("ShowExtraStatsMenuHandler :: Item selected: %i", selectedIndex);
		
		//Go Back
		if (selectedIndex == 3) {
			ShowPlayerRankPanel(client, g_SelSteamIds[client]);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		Debug("ShowExtraStatsMenuHandler :: Client %d's menu was cancelled.", client, selectedIndex);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		Debug("Menu has ended");
		delete menu;
		strcopy(g_SelSteamIds[client], sizeof(g_SelSteamIds[]), "");
	}
}

/**
* Retrieve the modifier/multiplier value for the requested stat key
*/
public float GetStatModifier(const char[] statKey) {
	if (g_mStatModifiers == null) {
		Error("GetStatMultiplier :: The modifier map has not yet been initialized. Using default.");
		return DEFAULT_POINT_MODIFIER;
	}
	float modifier = DEFAULT_POINT_MODIFIER;
	if (!g_mStatModifiers.GetValue(statKey, modifier)) {
		Error("GetStatMultiplier :: Could not retrieve stat modifier for '%s'. Using default.", statKey);
	}
	Debug("Using modifier for '%s' = %.2f", statKey, modifier);
	return modifier;
}

/**
* Utility function to draw a stat item to a panel. Points are automatically computed by this method using the cached modifiers. 
*/
public void PanelDrawStat(Panel & panel, const char[] label, const char[] statKey, StringMap & map) {
	int amount = 0;
	char msg[64];
	
	//extract value
	if (!map.GetValue(statKey, amount)) {
		Error("Could not retrieve value for stat '%s' from the map", statKey);
		Format(msg, sizeof(msg), " ☼ %s (N/A)", label);
		panel.DrawText(msg);
		return;
	}
	
	int displayType = g_iStatsDisplayType.IntValue;
	
	float points = amount * GetStatModifier(statKey);
	
	//display both points and amount	
	if (displayType == STATS_DISPLAY_TYPE_BOTH) {
		Format(msg, sizeof(msg), "☼ %s (%i, %.2f)", label, amount, points);
	}
	//display points
	else if (displayType == STATS_DISPLAY_TYPE_POINTS) {
		Format(msg, sizeof(msg), "☼ %s (%.2f)", label, points);
	}
	//display amount
	else {
		Format(msg, sizeof(msg), "☼ %s (%i)", label, amount);
	}
	panel.DrawText(msg);
}

void PanelDrawStatLabelStr(Panel & panel, const char[] label, const char[] statKey, StringMap & map, const char[] valPrefix = "", const char[] valPostfix = "") {
	char msg[255];
	char valueStr[255];
	if (!map.GetString(statKey, valueStr, sizeof(valueStr))) {
		Error("PanelDrawStatLabelStr :: Key '%s' does not exist", statKey);
		return;
	}
	FormatEx(msg, sizeof(msg), "%s: %s%s%s", label, valPrefix, valueStr, valPostfix);
	panel.DrawText(msg);
}

void PanelDrawStatLabelInt(Panel & panel, const char[] label, const char[] statKey, StringMap & map, const char[] valPrefix = "", const char[] valPostfix = "") {
	char msg[255];
	int value;
	if (!map.GetValue(statKey, value)) {
		Error("PanelDrawStatLabelInt :: Key '%s' does not exist", statKey);
		return;
	}
	FormatEx(msg, sizeof(msg), "%s: %s%i%s", label, valPrefix, value, valPostfix);
	panel.DrawText(msg);
}

void PanelDrawStatLabelFloat(Panel & panel, const char[] label, const char[] statKey, StringMap & map, const char[] valPrefix = "", const char[] valPostfix = "") {
	char msg[255];
	float value;
	if (!map.GetValue(statKey, value)) {
		Error("PanelDrawStatLabelFloat :: Key '%s' does not exist", statKey);
		return;
	}
	FormatEx(msg, sizeof(msg), "%s: %s%.2f%s", label, valPrefix, value, valPostfix);
	panel.DrawText(msg);
}

void PanelDrawStatLineBreak(Panel & panel) {
	if (panel == null)
		return;
	panel.DrawText(" "); //line-break
}

void PanelDrawStatItem(Panel & panel, const char[] name, const char[] valPrefix = "", const char[] valPostfix = "") {
	char msg[255];
	Format(msg, sizeof(msg), "%s%s%s", valPrefix, name, valPostfix);
	panel.DrawItem(name, ITEMDRAW_DEFAULT);
}

/**
* Helper function for extracting a single row of player statistic from the result set and store it on a map
* 
* @return true if the extraction was succesful from the result set, otherwise false if the extraction failed.
*/
public void ExtractPlayerStats(DBResultSet & results, StringMap & map) {
	if (results == null || map == null) {
		Debug("ExtractPlayerStats :: results or map is null");
		return;
	}
	
	FetchStrFieldToMap(results, STATS_STEAM_ID, map);
	FetchStrFieldToMap(results, STATS_LAST_KNOWN_ALIAS, map);
	FetchStrFieldToMap(results, STATS_LAST_JOIN_DATE, map);
	FetchFloatFieldToMap(results, STATS_TOTAL_POINTS, map);
	FetchIntFieldToMap(results, STATS_RANK, map);
	
	FetchIntFieldToMap(results, STATS_SURVIVOR_DEATH, map);
	FetchIntFieldToMap(results, STATS_SURVIVOR_REVIVED, map);
	FetchIntFieldToMap(results, STATS_SURVIVOR_HEALED, map);
	FetchIntFieldToMap(results, STATS_SURVIVOR_DEFIBED, map);
	FetchIntFieldToMap(results, STATS_SURVIVOR_INCAPPED, map);
	FetchIntFieldToMap(results, STATS_SURVIVOR_FRIENDLYFIRE, map);
	
	
	//STATS_WEAPON_CLASS
	/*
#define STATS_WEAPON_SPECIAL "weapon_special"
#define STATS_WEAPON_RIFLE "weapon_rifle"
#define STATS_WEAPON_SMG "weapon_smg"
#define STATS_WEAPON_SNIPER "weapon_sniper"
#define STATS_WEAPON_SHOTGUN "weapon_shotgun"
#define STATS_WEAPON_MELEE "weapon_melee"
#define STATS_WEAPON_DEAGLE "weapon_deagle"
	*/
	
	int special = GetIntField(results, STATS_WEAPON_SPECIAL);
	int melee = GetIntField(results, STATS_WEAPON_MELEE);
	int deagle = GetIntField(results, STATS_WEAPON_DEAGLE);
	int rifle = GetIntField(results, STATS_WEAPON_RIFLE);
	int shotgun = GetIntField(results, STATS_WEAPON_SHOTGUN);
	int smg = GetIntField(results, STATS_WEAPON_SMG);
	int sniper = GetIntField(results, STATS_WEAPON_SNIPER);
	
	if (special > melee && special > deagle && special > rifle && special > shotgun && special > smg && special > sniper) {
		SetStrFieldToMap("Specialist", STATS_WEAPON_CLASS, map);
	}
	else if (melee > special && melee > deagle && melee > rifle && melee > shotgun && melee > smg && melee > sniper) {
		SetStrFieldToMap("Brawler", STATS_WEAPON_CLASS, map);
	}
	else if (deagle > special && deagle > melee && deagle > rifle && deagle > shotgun && deagle > smg && deagle > sniper) {
		SetStrFieldToMap("Cowboy", STATS_WEAPON_CLASS, map);
	}
	else if (rifle > special && rifle > melee && rifle > deagle && rifle > shotgun && rifle > smg && rifle > sniper) {
		SetStrFieldToMap("Rifler", STATS_WEAPON_CLASS, map);
	}
	else if (shotgun > special && shotgun > melee && shotgun > deagle && shotgun > rifle && shotgun > smg && shotgun > sniper) {
		SetStrFieldToMap("Supporter", STATS_WEAPON_CLASS, map);
	}
	else if (smg > special && smg > melee && smg > deagle && smg > rifle && smg > shotgun && smg > sniper) {
		SetStrFieldToMap("Run'n'Gun", STATS_WEAPON_CLASS, map);
	}
	else if (sniper > special && sniper > melee && sniper > deagle && sniper > rifle && sniper > shotgun && sniper > smg) {
		SetStrFieldToMap("Markman", STATS_WEAPON_CLASS, map);
	}
	else {
		SetStrFieldToMap("Balancer", STATS_WEAPON_CLASS, map);
	}
	
	FetchIntFieldToMap(results, STATS_WEAPON_SPECIAL, map);
	FetchIntFieldToMap(results, STATS_WEAPON_RIFLE, map);
	FetchIntFieldToMap(results, STATS_WEAPON_SMG, map);
	FetchIntFieldToMap(results, STATS_WEAPON_SNIPER, map);
	FetchIntFieldToMap(results, STATS_WEAPON_SHOTGUN, map);
	FetchIntFieldToMap(results, STATS_WEAPON_MELEE, map);
	FetchIntFieldToMap(results, STATS_WEAPON_DEAGLE, map);
	
	FetchIntFieldToMap(results, STATS_INFECTED_KILLED, map);
	FetchIntFieldToMap(results, STATS_INFECTED_HEADSHOT, map);
	
	FetchIntFieldToMap(results, STATS_BOOMER_KILLED, map);
	FetchIntFieldToMap(results, STATS_BOOMER_KILLED_CLEAN, map);
	
	FetchIntFieldToMap(results, STATS_CHARGER_KILLED, map);
	FetchIntFieldToMap(results, STATS_CHARGER_PUMMELED, map);
	
	FetchIntFieldToMap(results, STATS_HUNTER_KILLED, map);
	FetchIntFieldToMap(results, STATS_HUNTER_POUNCED, map);
	FetchIntFieldToMap(results, STATS_HUNTER_SHOVED, map);
	
	FetchIntFieldToMap(results, STATS_JOCKEY_KILLED, map);
	FetchIntFieldToMap(results, STATS_JOCKEY_POUNCED, map);
	FetchIntFieldToMap(results, STATS_JOCKEY_SHOVED, map);
	FetchIntFieldToMap(results, STATS_JOCKEY_RIDED, map);
	
	FetchIntFieldToMap(results, STATS_SMOKER_KILLED, map);
	FetchIntFieldToMap(results, STATS_SMOKER_CHOKED, map);
	FetchIntFieldToMap(results, STATS_SMOKER_TONGUE_SLASHED, map);
	
	FetchIntFieldToMap(results, STATS_SPITTER_KILLED, map);
	
	FetchIntFieldToMap(results, STATS_WITCH_KILLED, map);
	FetchIntFieldToMap(results, STATS_WITCH_KILLED_1SHOT, map);
	FetchIntFieldToMap(results, STATS_WITCH_HARASSED, map);
	
	FetchIntFieldToMap(results, STATS_TANK_KILLED, map);
	FetchIntFieldToMap(results, STATS_TANK_MELEE, map);
	
	FetchStrFieldToMap(results, STATS_CREATE_DATE, map);
}

/**
* Convenience function to fetch a string field from a resultset and store it's value into a StringMap instance
*/
public bool SetStrFieldToMap(const char[] str, const char[] field, StringMap & map) {
	if (StringBlank(str) || map == null || StringBlank(field)) {
		return false;
	}
	
	map.SetString(field, str, true);
	return true;
}

public int GetIntField(DBResultSet & results, const char[] field) {
	if (results == null || StringBlank(field)) {
		return false;
	}
	
	int fieldId = -1;
	if (results.FieldNameToNum(field, fieldId) && fieldId >= 0) {
		return results.FetchInt(fieldId);
	}
	return -1;
}

/**
* Convenience function to fetch a string field from a resultset and store it's value into a StringMap instance
*/
public bool FetchStrFieldToMap(DBResultSet & results, const char[] field, StringMap & map) {
	if (results == null || map == null || StringBlank(field)) {
		return false;
	}
	
	int fieldId = -1;
	if (results.FieldNameToNum(field, fieldId) && fieldId >= 0) {
		char value[255];
		results.FetchString(fieldId, value, sizeof(value));
		map.SetString(field, value, true);
		return true;
	}
	return false;
}

/**
* Convenience function to fetch a float field from a resultset and store it's value into a StringMap instance
*/
public bool FetchFloatFieldToMap(DBResultSet & results, const char[] field, StringMap & map) {
	if (results == null || map == null || StringBlank(field)) {
		return false;
	}
	
	int fieldId = -1;
	if (results.FieldNameToNum(field, fieldId) && fieldId >= 0) {
		float value = results.FetchFloat(fieldId);
		map.SetValue(field, value, true);
		return true;
	}
	return false;
}

/**
* Convenience function to fetch an integer field from a resultset and store it's value into a StringMap instance
*/
public bool FetchIntFieldToMap(DBResultSet & results, const char[] field, StringMap & map) {
	if (results == null || map == null || StringBlank(field)) {
		return false;
	}
	
	int fieldId = -1;
	if (results.FieldNameToNum(field, fieldId) && fieldId >= 0) {
		int value = results.FetchInt(fieldId);
		map.SetValue(field, value, true);
		return true;
	}
	return false;
}

/**
* Returns the number of human players currently in the server (including spectators)
*/
int GetHumanPlayerCount(bool includeSpec = true, int excludeClient = -1) {
	int count = 0;
	for (int i = 1; i <= MAX_CLIENTS; i++) {
		if (excludeClient >= 1 && i == excludeClient)
			continue;
		if (includeSpec) {
			if (IS_VALID_HUMAN(i))
				count++;
		} else {
			if (IS_VALID_HUMAN(i) && (IS_VALID_SURVIVOR(i) || IS_VALID_INFECTED(i)))
				count++;
		}
	}
	return count;
}

/**
* Iterates and initialize all available players on the server
*/
public void InitializePlayers() {
	for (int i = 1; i <= MAX_CLIENTS; i++)
	{
		if (IS_VALID_HUMAN(i))
		{
			if (IsClientConnected(i) && isInitialized(i)) {
				Debug("Client '%N' is already initialized. Skipping process.", i);
				continue;
			}
			Debug("%i) Initialize %N", i, i);
			InitializePlayer(i, false);
		}
	}
}

/**
* Initialize a player record if not yet existing
*
* @param client The client index to initialize
*/
public void InitializePlayer(int client, bool updateJoinDateIfExists) {
	Debug("Initializing Client %N", client);
	
	if (!IS_VALID_CLIENT(client) || IsFakeClient(client)) {
		Debug("InitializePlayer :: Client index %i is not valid. Skipping Initialization", client);
		return;
	}
	
	if (g_bInitializing[client]) {
		Debug("InitializePlayer :: Initialization for '%N' is already in-progress. Please wait.", client);
		return;
	}
	
	char steamId[MAX_STEAMAUTH_LENGTH];
	if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId))) {
		ResetInitializeFlags(client);
		Error("Could not initialize player '%N'. Invalid steam id (%s)", client, steamId);
		return;
	}
	
	char name[255];
	GetClientName(client, name, sizeof(name));
	
	//unnecessary? 
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	len = strlen(name) * 2 + 1;
	char[] qName = new char[len];
	SQL_EscapeString(g_hDatabase, name, qName, len);
	
	char query[512];
	
	if (updateJoinDateIfExists) {
		Debug("InitializePlayer :: Join date will be updated for %N", client);
		FormatEx(query, sizeof(query), "INSERT INTO STATS_PLAYERS (steam_id, last_known_alias, last_join_date) VALUES ('%s', '%s', CURRENT_TIMESTAMP()) ON DUPLICATE KEY UPDATE last_join_date = CURRENT_TIMESTAMP(), last_known_alias = '%s'", qSteamId, qName, qName);
	}
	else {
		Debug("InitializePlayer :: Join date will NOT be updated for %N", client);
		FormatEx(query, sizeof(query), "INSERT INTO STATS_PLAYERS (steam_id, last_known_alias, last_join_date) VALUES ('%s', '%s', CURRENT_TIMESTAMP()) ON DUPLICATE KEY UPDATE last_known_alias = '%s'", qSteamId, qName, qName);
	}
	
	g_bInitializing[client] = true;
	g_hDatabase.Query(TQ_InitializePlayer, query, client);
}

public void ResetInitializeFlags(int client) {
	if (!IS_VALID_HUMAN(client)) {
		Debug("ResetInitializeFlags :: Client index %i no longer valid.");
		return;
	}
	Debug("Resetting init flags for client %N", client);
	g_bPlayerInitialized[client] = false;
	g_bInitializing[client] = false;
}

public void InitializePlayerById(const char[] name, const char[] steamId, bool updateJoinDateIfExists) {
	Debug("Initializing Player %s (%s)", name, steamId);
	
	//unnecessary? 
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	len = strlen(name) * 2 + 1;
	char[] qName = new char[len];
	SQL_EscapeString(g_hDatabase, name, qName, len);
	
	char query[512];
	
	if (updateJoinDateIfExists) {
		Debug("InitializePlayerById :: Join date will be updated for %s", name);
		FormatEx(query, sizeof(query), "INSERT INTO STATS_PLAYERS (steam_id, last_known_alias, last_join_date) VALUES ('%s', '%s', CURRENT_TIMESTAMP()) ON DUPLICATE KEY UPDATE last_join_date = CURRENT_TIMESTAMP(), last_known_alias = '%s'", qSteamId, qName, qName);
	}
	else {
		Debug("InitializePlayerById :: Join date will NOT be updated for %s", name);
		FormatEx(query, sizeof(query), "INSERT INTO STATS_PLAYERS (steam_id, last_known_alias, last_join_date) VALUES ('%s', '%s', CURRENT_TIMESTAMP()) ON DUPLICATE KEY UPDATE last_known_alias = '%s'", qSteamId, qName, qName);
	}
	
	DataPack pack = new DataPack();
	pack.WriteString(name);
	pack.WriteString(steamId);
	
	//g_bInitializing[client] = true;
	g_hDatabase.Query(TQ_InitializePlayerBySteamId, query, pack);
}

/**
* SQL Callback for InitializePlayer threaded query
*/
public void TQ_InitializePlayerBySteamId(Database db, DBResultSet results, const char[] error, DataPack pack) {
	
	char name[MAX_NAME_LENGTH];
	char steamId[MAX_STEAMAUTH_LENGTH];
	
	pack.Reset();
	pack.ReadString(name, sizeof(name));
	pack.ReadString(steamId, sizeof(steamId));
	
	if (results == null) {
		Error("TQ_InitializePlayerBySteamId :: Query failed (Reason: %s)", error);
		//g_bPlayerInitialized[client] = false;
		//g_bInitializing[client] = false;
		return;
	}
	
	if (results.AffectedRows == 0) {
		Debug("TQ_InitializePlayerBySteamId :: Nothing was updated for player %s (%s)", name, steamId);
	}
	else if (results.AffectedRows == 1) {
		Debug("TQ_InitializePlayerBySteamId :: Player %s (%s) has been initialized for the first time", name, steamId);
	}
	else if (results.AffectedRows > 1) {
		Debug("TQ_InitializePlayerBySteamId :: Existing record has been updated for player %s (%s)", name, steamId);
	}
	
	//g_bPlayerInitialized[client] = true;
	//g_bInitializing[client] = false;
	
	g_mPlayersInitialized.SetValue(steamId, true);
	
	Debug("Player %s (%s) successfully initialized", name, steamId);
}

/**
* SQL Callback for InitializePlayer threaded query
*/
public void TQ_InitializePlayer(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;
	
	if (!IS_VALID_CLIENT(client) || !IsClientConnected(client)) {
		Debug("TQ_InitializePlayer :: Client index '%i' is not valid or not connected. Skipping initialization", client);
		ResetInitializeFlags(client);
		return;
	}
	
	if (results == null) {
		Error("TQ_InitializePlayer :: Query failed (Reason: %s)", error);
		ResetInitializeFlags(client);
		return;
	}
	
	if (results.AffectedRows == 0) {
		Debug("TQ_InitializePlayer :: Nothing was updated for player %N", client);
	}
	else if (results.AffectedRows == 1) {
		Debug("TQ_InitializePlayer :: Player %N has been initialized for the first time", client);
	}
	else if (results.AffectedRows > 1) {
		Debug("TQ_InitializePlayer :: Existing record has been updated for player %N", client);
	}
	
	g_bPlayerInitialized[client] = true;
	g_bInitializing[client] = false;
	
	Debug("Player '%N' successfully initialized", client);
}

/**
* Connect to the database
* 
* @return true if the connection is successful
*/
bool DbConnect(bool force = false)
{
	if (g_hDatabase != INVALID_HANDLE) {
		if (!force) {
			Debug("DbConnect() :: Already connected to the database, skipping.");
			return true;
		}
		delete g_hDatabase;
	}
	
	char error[512];
	//g_hDatabase = SQL_Connect(DB_CONFIG_NAME, true, error, sizeof(error));
	
	Handle kv = new KeyValues("Databases");
	KvSetString(kv, "driver", "mysql");
	KvSetString(kv, "host", g_SQLHost);
	KvSetString(kv, "database", g_SQLDb);
	KvSetString(kv, "user", g_SQLUser);
	KvSetString(kv, "pass", g_SQLPass);
	g_hDatabase = SQL_ConnectCustom(kv, error, sizeof(error), false);
	
	if (g_hDatabase != INVALID_HANDLE) {
		LogMessage("Connected to the database: %s", g_SQLDb);
		return true;
	} else {
		Error("Failed to connect to database: %s", error);
	}
	
	return false;
}

/**
* Initialize database (create tables/indices etc)
*
* @return true if the initialization is successfull
*/
public bool InitDatabase() {
	if (!DbConnect()) {
		Error("InitDatabase :: Unable to retrieve database handle");
		return false;
	}
	return true;
}

/**
* Method to trigger the Player Connect Announcement in Chat
*/
public void PlayerConnectAnnounce(int client) {
	
	if (PluginDisabled() || !CAnnounceEnabled()) {
		Debug("Skipping connect announce for client '%N'. Either plugin has been disabled (pstats_enabled = 0) or Connect Announce Feature is.", client);
		return;
	}
	
	if (!IS_VALID_CLIENT(client) || IsFakeClient(client) || !IsClientAuthorized(client)) {
		Debug("PlayerConnectAnnounce() :: Skipping connect announce for %N", client);
		return;
	}
	
	char steamId[MAX_STEAMAUTH_LENGTH];
	if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId))) {
		Error("PlayerConnectAnnounce :: Unable to retrieve steam id for client %N", client);
		return;
	}
	
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	char query[512];
	FormatEx(query, sizeof(query), "select * from STATS_VW_PLAYER_RANKS s WHERE s.steam_id = '%s'", qSteamId);
	
	Debug("Executing Query: %s", query);
	
	g_hDatabase.Query(TQ_PlayerConnectAnnounce, query, client);
}

/**
* SQL callback for the Player Connect Announcement
*/
public void TQ_PlayerConnectAnnounce(Database db, DBResultSet results, const char[] error, any data) {
	
	/* Make sure the client didn't disconnect while the thread was running */
	if (!IS_VALID_CLIENT(data)) {
		Debug("Client '%i' is not a valid client index, skipping display stats", data);
		return;
	}
	
	if (results == null) {
		Error("TQ_PlayerConnectAnnounce :: Query failed (Reason: %s)", error);
	} else if (results.RowCount > 0) {
		
		StringMap map = new StringMap();
		
		if (results.FetchRow()) {
			
			//Extract results to map
			ExtractPlayerStats(results, map);
			
			char steamId[MAX_STEAMAUTH_LENGTH];
			char lastKnownAlias[MAX_NAME_LENGTH];
			char createDate[255];
			char lastJoinDate[255];
			float totalPoints;
			int rankNum;
			int survivorsIncapped;
			int infectedKilled;
			int infectedHeadshot;
			
			map.GetString(STATS_STEAM_ID, steamId, sizeof(steamId));
			map.GetString(STATS_LAST_KNOWN_ALIAS, lastKnownAlias, sizeof(lastKnownAlias));
			map.GetString(STATS_LAST_JOIN_DATE, lastJoinDate, sizeof(lastJoinDate));
			map.GetString(STATS_CREATE_DATE, createDate, sizeof(createDate));
			map.GetValue(STATS_TOTAL_POINTS, totalPoints);
			map.GetValue(STATS_RANK, rankNum);
			map.GetValue(STATS_SURVIVOR_INCAPPED, survivorsIncapped);
			map.GetValue(STATS_INFECTED_KILLED, infectedKilled);
			map.GetValue(STATS_INFECTED_HEADSHOT, infectedHeadshot);
			
			char tmpMsg[255];
			
			//parse stats
			ParseKeywordsWithMap(g_ConfigAnnounceFormat, tmpMsg, sizeof(tmpMsg), map);
			
			Debug("PARSE RESULT = %s", tmpMsg);
			
			//Client_PrintToChatAll(true, tmpMsg);
			PrintToChatAll(tmpMsg);
			
			Debug("'%N' has joined the game (Id: %s, Points: %f, Rank: %i, Last Known Alias: %s)", data, steamId, totalPoints, rankNum, lastKnownAlias);
		}
		
		delete map;
	}
}

/**
* Parse keywords within the text and replace with values associated in the map
* 
* @param text The text to parse
* @param buffer The buffer to store the output
* @param size The size of the output buffer
* @param map The StringMap containing the key/value pairs that will be used for the lookup and replacement
*/
public void ParseKeywordsWithMap(const char[] text, char[] buffer, int size, StringMap & map) {
	Debug("======================================================= PARSE START =======================================================");
	
	Debug("Parsing stats string : \"%s\"", text);
	
	StringMapSnapshot keys = map.Snapshot();
	
	//Copy content
	FormatEx(buffer, size, "%s", g_ConfigAnnounceFormat);
	
	//iterate through all available keys in the map
	for (int i = 0; i < keys.Length; i++) {
		int bufferSize = keys.KeyBufferSize(i);
		char[] keyName = new char[bufferSize];
		keys.GetKey(i, keyName, bufferSize);
		
		int searchKeySize = bufferSize + 32;
		
		//There are probably simpler and more effective ways on doing this but i'm too lazy :)
		
		//Standard search key
		char[] searchKey = new char[searchKeySize];
		FormatEx(searchKey, searchKeySize, "{%s}", keyName);
		
		//Float search key
		char[] searchKeyFloat = new char[searchKeySize];
		FormatEx(searchKeyFloat, searchKeySize, "{f:%s}", keyName);
		
		//Int search key
		char[] searchKeyInt = new char[searchKeySize];
		FormatEx(searchKeyInt, searchKeySize, "{i:%s}", keyName);
		
		//Date search key
		char[] searchKeyDate = new char[searchKeySize];
		FormatEx(searchKeyDate, searchKeySize, "{d:%s}", keyName);
		
		char[] sKey = new char[searchKeySize];
		
		int pos = -1;
		
		char valueStr[128];
		
		bool found = false;
		
		//If we find the key, then replace it with the actual value
		if ((pos = StrContains(g_ConfigAnnounceFormat, searchKey, false)) > -1) {
			//Try extract string		
			map.GetString(keyName, valueStr, sizeof(valueStr));
			Debug("(%i: %s) Key '%s' FOUND at position %i (value = %s, type = string)", i, keyName, searchKey, pos, valueStr);
			FormatEx(sKey, searchKeySize, searchKey);
			found = true;
		} else if ((pos = StrContains(g_ConfigAnnounceFormat, searchKeyFloat, false)) > -1) {
			float valueFloat;
			map.GetValue(keyName, valueFloat);
			FormatEx(valueStr, sizeof(valueStr), "%.2f", valueFloat);
			FormatEx(sKey, searchKeySize, searchKeyFloat);
			Debug("(%i: %s) Key '%s' FOUND at position %i (value = %s, type = float)", i, keyName, sKey, pos, valueStr);
			found = true;
		} else if ((pos = StrContains(g_ConfigAnnounceFormat, searchKeyInt, false)) > -1) {
			int valueInt;
			map.GetValue(keyName, valueInt);
			FormatEx(valueStr, sizeof(valueStr), "%i", valueInt);
			FormatEx(sKey, searchKeySize, searchKeyInt);
			Debug("(%i: %s) Key '%s' FOUND at position %i (value = %s, type = integer)", i, keyName, sKey, pos, valueStr);
			found = true;
		}
		else if ((pos = StrContains(g_ConfigAnnounceFormat, searchKeyDate, false)) > -1) {
			map.GetString(keyName, valueStr, sizeof(valueStr));
			FormatEx(sKey, searchKeySize, searchKeyDate);
			//FormatTime(valueStr, sizeof(valueStr), NULL_STRING, valueInt);
			Debug("(%i: %s) Key '%s' FOUND at position %i (value = %s, type = date)", i, keyName, sKey, pos, valueStr);
			found = true;
		}
		else {
			Debug("(%i: %s) Key '%s' NOT FOUND", i, keyName, searchKey);
			Format(valueStr, sizeof(valueStr), "N/A");
		}
		
		if (!found) {
			continue;
		}
		//Perform the replacement
		//Debug("\tReplacing key '%s' with value '%s'", sKey, valueStr);
		ReplaceString(buffer, size, sKey, valueStr, false);
	}
	
	Debug("======================================================= PARSE END =======================================================");
}

public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	Debug("================================== OnRoundStart ==================================");
	return Plugin_Continue;
}

public Action Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	Debug("================================== OnRoundEnd ==================================");
	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
	char playerName[MAX_NAME_LENGTH];
	int userId = event.GetInt("userid");
	int clientId = GetClientOfUserId(userId);
	int newTeamId = event.GetInt("team");
	int oldTeamId = event.GetInt("oldteam");
	bool disconnect = event.GetBool("disconnect");
	bool isBot = event.GetBool("isbot");
	event.GetString("name", playerName, sizeof(playerName));
	
	//Only display the rank panel if the player has completed transitioning to a team
	if (IS_VALID_CLIENT(clientId) && !isBot && !disconnect) {
		Debug("Player %N has joined a team (old team = %i, new team = %i, disconnect = %i, bot = %i)", clientId, oldTeamId, newTeamId, disconnect, isBot);
		if (ShowRankOnConnect() && !PlayerRankShown(clientId) && IS_VALID_HUMAN(clientId)) {
			char steamId[MAX_STEAMAUTH_LENGTH];
			if (GetClientAuthId(clientId, AuthId_Steam2, steamId, sizeof(steamId))) {
				Debug("Displaying player rank to user %N", clientId);
				ShowPlayerRankPanel(clientId, steamId);
				SetPlayerRankShownFlag(clientId);
			} else {
				Error("Could not obtain steam id of client %N", clientId);
			}
		} else {
			Debug("Will not display player rank panel to client %N", clientId);
		}
	}
	
	return Plugin_Continue;
}

void ResetShowPlayerRankFlags() {
	Debug("Resetting Player Rank Shown Flags");
	for (int i = 0; i < sizeof(g_bPlayerRankShown); i++) {
		UnsetPlayerRankShownFlag(i);
	}
}

bool PlayerRankShown(int clientId) {
	return g_bPlayerRankShown[clientId];
}

void SetPlayerRankShownFlag(int clientId) {
	if (!IS_VALID_HUMAN(clientId))
		return;
	Debug("Setting Player Rank Shown Flags for client %N", clientId);
	g_bPlayerRankShown[clientId] = true;
}

void UnsetPlayerRankShownFlag(int clientId) {
	//Debug("> Unsetting Player Rank Shown Flag for Client Index: %i", clientId);
	g_bPlayerRankShown[clientId] = false;
}

/**
* Callback for player_incapped event. Records basic stats only.
*/
public Action Event_PlayerIncapped(Event event, const char[] name, bool dontBroadcast) {
	int victimId = event.GetInt("userid");
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	int victimClientId = GetClientOfUserId(victimId);
	
	if (!IS_HUMAN_INFECTED(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!IS_HUMAN_SURVIVOR(victimClientId)) {
		Debug("Skipping stat update '%s' for %N. Victim is a bot", STATS_SURVIVOR_INCAPPED, attackerClientId);
		return Plugin_Continue;
	}
	
	UpdateStat(victimClientId, STATS_SURVIVOR_INCAPPED, 1);
	
	return Plugin_Continue;
}

public Action Event_HunterShoved(Event event, const char[] name, bool dontBroadcast) {
	
	int shoverId = event.GetInt("userid");
	int shoverClientId = GetClientOfUserId(shoverId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(shoverClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(shoverClientId, STATS_HUNTER_SHOVED, 1);
	
	return Plugin_Continue;
}

public Action Event_JockeyShoved(Event event, const char[] name, bool dontBroadcast) {
	
	int shoverId = event.GetInt("rescuer");
	int shoverClientId = GetClientOfUserId(shoverId);
	float duration = event.GetFloat("ride_length");
	//PrintToChatAll("%d | %f", shoverId, duration);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(shoverClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	PrintToChatAll("jockey reg");
	UpdateStat(shoverClientId, STATS_JOCKEY_SHOVED, 1);
	UpdateStat(shoverClientId, STATS_JOCKEY_RIDED, RoundFloat(duration));
	
	return Plugin_Continue;
}

public Action Event_CarAlarmed(Event event, const char[] name, bool dontBroadcast) {
	
	int alarmerId = event.GetInt("userid");
	int alarmerClientId = GetClientOfUserId(alarmerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(alarmerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(alarmerClientId, STATS_CAR_ALARMED, 1);
	
	return Plugin_Continue;
}

/**
* Callback for witch harrass events. Records basic stats only
*/
public Action Event_WitchHarrassed(Event event, const char[] name, bool dontBroadcast) {
	
	int harrasserId = event.GetInt("userid");
	int harrasserClientId = GetClientOfUserId(harrasserId);
	bool first = event.GetBool("first");
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(harrasserClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	if (first) {
		UpdateStat(harrasserClientId, STATS_WITCH_HARASSED, 1);
	}
	
	return Plugin_Continue;
}

/**
* Callback for witch death events. Records basic stats only
*/
public Action Event_WitchKilled(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("userid");
	int attackerClientId = GetClientOfUserId(attackerId);
	//int witchId = event.GetInt("witchid");
	bool oneShot = event.GetBool("oneshot");
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	char weaponName[255];
	GetClientWeapon(attackerClientId, weaponName, 255);
	
	UpdateStat(attackerClientId, STATS_WITCH_KILLED, 1);
	if (oneShot) {
		UpdateStat(attackerClientId, STATS_WITCH_KILLED_1SHOT, 1);
	}
	UpdateWeaponStat(attackerClientId, weaponName);
	
	return Plugin_Continue;
}

/**
* Callback for hunter death events.
*/
public Action Event_HunterKilled(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("userid");
	int attackerClientId = GetClientOfUserId(attackerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(attackerClientId, STATS_HUNTER_KILLED, 1);
	
	return Plugin_Continue;
}

/**
* Callback for boomer death events.
*/
public Action Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	bool clean = event.GetBool("splashedbile");
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(attackerClientId, STATS_BOOMER_KILLED, 1);
	if (clean) {
		UpdateStat(attackerClientId, STATS_BOOMER_KILLED_CLEAN, 1);
	}
	
	return Plugin_Continue;
}

/**
* Callback for charger death events.
*/
public Action Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(attackerClientId, STATS_CHARGER_KILLED, 1);
	
	return Plugin_Continue;
}

/**
* Callback for jockey death events.
*/
public Action Event_JockeyKilled(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(attackerClientId, STATS_JOCKEY_KILLED, 1);
	
	return Plugin_Continue;
}

/**
* Callback for smoker death events.
*/
public Action Event_SmokerKilled(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(attackerClientId, STATS_SMOKER_KILLED, 1);
	
	return Plugin_Continue;
}

/**
* Callback for spitter death events.
*/
public Action Event_SpitterKilled(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(attackerClientId, STATS_SPITTER_KILLED, 1);
	
	return Plugin_Continue;
}

/**
* Callback for hunter death events.
*/
public Action Event_TankKilled(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(attackerClientId, STATS_TANK_KILLED, 1);
	
	return Plugin_Continue;
}

public Action Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast) {
	/*
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	bool attackerIsBot = event.GetBool("attackerisbot");
	if (IS_VALID_CLIENT(attackerClientId) && !attackerIsBot) {
		if (!AllowCollectStats())
			return Plugin_Continue;
		
		//survivor killed infected
		if (IS_VALID_SURVIVOR(attackerClientId)) {

			char weaponName[255];
			GetClientWeapon(attackerClientId, weaponName, 255);
			//Debug(weaponName);
		}
	}
	*/
	return Plugin_Continue;
}

public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast) {
	int healerId = event.GetInt("userid");
	int healerClientId = GetClientOfUserId(healerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(healerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(healerClientId, STATS_SURVIVOR_REVIVED, 1);
	
	return Plugin_Continue;
}

public Action Event_DefibSuccess(Event event, const char[] name, bool dontBroadcast) {
	int healerId = event.GetInt("userid");
	int healerClientId = GetClientOfUserId(healerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(healerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(healerClientId, STATS_SURVIVOR_DEFIBED, 1);
	
	return Plugin_Continue;
}

public Action Event_HealSuccess(Event event, const char[] name, bool dontBroadcast) {
	int healerId = event.GetInt("userid");
	int healerClientId = GetClientOfUserId(healerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(healerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(healerClientId, STATS_SURVIVOR_HEALED, 1);
	
	return Plugin_Continue;
}

public Action Event_FriendlyFire(Event event, const char[] name, bool dontBroadcast) {
	int attackerId = event.GetInt("guilty");
	int attackerClientId = GetClientOfUserId(attackerId);
	
	//We will only process valid human survivor players
	if (!IS_HUMAN_SURVIVOR(attackerClientId)) {
		return Plugin_Continue;
	}
	
	if (!AllowCollectStats()) {
		return Plugin_Continue;
	}
	
	UpdateStat(attackerClientId, STATS_SURVIVOR_FRIENDLYFIRE, 1);
	
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int victimId = event.GetInt("userid");
	int victimClientId = GetClientOfUserId(victimId);
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	bool attackerIsBot = event.GetBool("attackerisbot");
	
	if (IS_VALID_CLIENT(attackerClientId) && !attackerIsBot) {
		if (!AllowCollectStats())
			return Plugin_Continue;
		
		//survivor killed infected
		if (IS_VALID_SURVIVOR(attackerClientId)) {
			
			char victimname[255];
			event.GetString("victimname", victimname, 255);
			
			if (!StrEqual(victimname, ZC_COMMON, false)) {
				int zClass = GetEntProp(victimClientId, Prop_Send, "m_zombieClass");
				
				char weaponName[255];
				event.GetString("weapon", weaponName, 255);
				
				if (zClass == ZC_TANK && StrEqual(weaponName, "melee", false)) {
					Debug("melee tank");
					UpdateStat(attackerClientId, STATS_TANK_MELEE, 1);
				}
			}
		}
	}
	return Plugin_Continue;
}

/**
* Callback for player_death event. This records basic stats only (kills and headshots).
*/
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victimId = event.GetInt("userid");
	int victimClientId = GetClientOfUserId(victimId);
	int attackerId = event.GetInt("attacker");
	int attackerClientId = GetClientOfUserId(attackerId);
	bool headshot = event.GetBool("headshot");
	bool attackerIsBot = event.GetBool("attackerisbot");
	
	//#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
	//#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == TEAM_SURVIVOR)
	if (IS_VALID_CLIENT(attackerClientId) && !attackerIsBot) {
		if (!AllowCollectStats())
			return Plugin_Continue;
		
		//survivor killed infected
		if (IS_VALID_SURVIVOR(attackerClientId)) {
			
			char victimname[255];
			event.GetString("victimname", victimname, 255);
			
			if (!StrEqual(victimname, ZC_COMMON, false)) {
				//int zClass = GetEntProp(victimClientId, Prop_Send, "m_zombieClass");
				
				if (StrEqual(victimname, ZC_HUNTER, false)) {
					UpdateStat(attackerClientId, STATS_HUNTER_KILLED, 1);
				}
				else if (StrEqual(victimname, ZC_SMOKER, false)) {
					UpdateStat(attackerClientId, STATS_SMOKER_KILLED, 1);
				}
			}
			else {
				if (headshot) {
					UpdateStat(attackerClientId, STATS_INFECTED_HEADSHOT, 1);
				}
				UpdateStat(attackerClientId, STATS_INFECTED_KILLED, 1);
			}
			
			char weaponName[255];
			GetClientWeapon(attackerClientId, weaponName, 255);
			//Debug(weaponName);
			UpdateWeaponStat(attackerClientId, weaponName);
		}
		//infected killed survivor
		else if (IS_VALID_SURVIVOR(victimClientId)) {
			UpdateStat(victimClientId, STATS_SURVIVOR_DEATH, 1);
		} //ignore the rest
	}
	return Plugin_Continue;
}

void UpdateWeaponStat(int client, const char[] weaponName) {
	//#define STATS_WEAPON_SPECIAL "weapon_special"
	//#define STATS_WEAPON_RIFLE "weapon_rifle"
	//#define STATS_WEAPON_SMG "weapon_smg"
	//#define STATS_WEAPON_SNIPER "weapon_sniper"
	//#define STATS_WEAPON_SHOTGUN "weapon_shotgun"
	//#define STATS_WEAPON_MELEE "weapon_melee"
	//#define STATS_WEAPON_DEAGLE "weapon_deagle"
	
	/*
	special
	weapon_grenade_launcher
	weapon_rifle_m60
	
	melee
	weapon_chainsaw
	weapon_melee
	
	deagle
	weapon_pistol_magnum
	
	rifle
	weapon_rifle
	weapon_rifle_ak47
	weapon_rifle_desert
	weapon_rifle_sg552
	
	shotgun
	weapon_pumpshotgun
	weapon_shotgun_chrome
	weapon_autoshotgun
	weapon_shotgun_spas
	
	smg
	weapon_smg
	weapon_smg_mp5
	weapon_smg_silenced
	
	sniper
	weapon_sniper_awp
	weapon_sniper_military
	weapon_sniper_scout
	weapon_hunting_rifle
	*/
	
	//special
	if (StrEqual(weaponName, "weapon_grenade_launcher") || StrEqual(weaponName, "weapon_rifle_m60")) {
		UpdateStat(client, STATS_WEAPON_SPECIAL, 1);
	}
	
	//melee
	if (StrEqual(weaponName, "weapon_chainsaw") || StrEqual(weaponName, "weapon_melee")) {
		UpdateStat(client, STATS_WEAPON_MELEE, 1);
	}
	
	//deagle
	if (StrEqual(weaponName, "weapon_pistol_magnum")) {
		UpdateStat(client, STATS_WEAPON_DEAGLE, 1);
	}
	
	//rifle
	if (StrEqual(weaponName, "weapon_rifle") || StrEqual(weaponName, "weapon_rifle_ak47") || StrEqual(weaponName, "weapon_rifle_desert") || StrEqual(weaponName, "weapon_rifle_sg552")) {
		UpdateStat(client, STATS_WEAPON_RIFLE, 1);
	}
	
	//shotgun
	if (StrEqual(weaponName, "weapon_pumpshotgun") || StrEqual(weaponName, "weapon_shotgun_chrome") || StrEqual(weaponName, "weapon_autoshotgun") || StrEqual(weaponName, "weapon_shotgun_spas")) {
		UpdateStat(client, STATS_WEAPON_SHOTGUN, 1);
	}
	
	//smg
	if (StrEqual(weaponName, "weapon_smg") || StrEqual(weaponName, "weapon_smg_mp5") || StrEqual(weaponName, "weapon_smg_silenced")) {
		UpdateStat(client, STATS_WEAPON_SMG, 1);
	}
	
	//sniper
	if (StrEqual(weaponName, "weapon_sniper_awp") || StrEqual(weaponName, "weapon_sniper_military") || StrEqual(weaponName, "weapon_sniper_scout") || StrEqual(weaponName, "weapon_hunting_rifle")) {
		UpdateStat(client, STATS_WEAPON_SNIPER, 1);
	}
}

/**
* Utility function for updating the stat field of the player
*/
void UpdateStat(int client, const char[] column, int amount = 1, int victim = -1) {
	if (!AllowCollectStats()) {
		return;
	}
	
	if (!IS_VALID_HUMAN(client)) {
		Error("Skipping update stat '%s'. Client is not valid: %N", column, client);
		return;
	}
	
	if (!isInitialized(client)) {
		Error("Skipping update stat '%s'. Client is not initialized %N", column, client);
		return;
	}
	
	char steamId[MAX_STEAMAUTH_LENGTH];
	if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId))) {
		Error("UpdateStat :: Invalid steam id for %N = %s. Skipping stat update '%s'", client, steamId, column);
		return;
	}
	
	char name[255];
	GetClientName(client, name, sizeof(name));
	
	int len = strlen(steamId) * 2 + 1;
	char[] qSteamId = new char[len];
	SQL_EscapeString(g_hDatabase, steamId, qSteamId, len);
	
	len = strlen(column) * 2 + 1;
	char[] qColumnName = new char[len];
	SQL_EscapeString(g_hDatabase, column, qColumnName, len);
	
	len = strlen(name) * 2 + 1;
	char[] qName = new char[len];
	SQL_EscapeString(g_hDatabase, name, qName, len);
	
	char query[255];
	FormatEx(query, sizeof(query), "UPDATE STATS_PLAYERS SET %s = %s + %i, last_known_alias = '%s' WHERE steam_id = '%s'", qColumnName, qColumnName, amount, qName, qSteamId);
	
	DataPack pack = new DataPack();
	pack.WriteString(column);
	pack.WriteCell(client);
	pack.WriteCell(amount);
	pack.WriteCell(victim);
	
	g_hDatabase.Query(TQ_UpdateStat, query, pack);
	
	//PrintToChatAll("%s stat %s", qName, qColumnName);
	
	//ShowPlayerRankPanel(client, steamId);
}

public void TQ_UpdateStat(Database db, DBResultSet results, const char[] error, DataPack pack) {
	if (results == null) {
		Error("TQ_UpdateStat :: Query failed (Reason: %s)", error);
		return;
	}
	
	char column[128];
	
	pack.Reset();
	pack.ReadString(column, sizeof(column));
	int clientId = pack.ReadCell();
	int count = pack.ReadCell();
	int victimId = pack.ReadCell();
	
	float modifier = GetStatModifier(column);
	float points = count * modifier;
	
	if (results.AffectedRows > 0) {
		if (IS_VALID_CLIENT(victimId)) {
			Debug("Stat '%s' updated for %N (Count: %i, Multiplier: %.2f, Points: %.2f, Victim: %N)", column, clientId, count, modifier, points, victimId);
		} else {
			Debug("Stat '%s' updated for %N (Count: %i, Multiplier: %.2f, Points: %.2f, Victim: N/A)", column, clientId, count, modifier, points);
		}
	}
	else {
		if (IS_VALID_CLIENT(victimId)) {
			Debug("Stat '%s' not updated for %N (Count: %i, Multiplier: %.2f, Points: %.2f, Victim: %N)", column, clientId, count, modifier, points, victimId);
		} else {
			Debug("Stat '%s' not updated for %N (Count: %i, Multiplier: %.2f, Points: %.2f, Victim: N/A)", column, clientId, count, modifier, points);
		}
	}
	
	delete pack;
}

public void PrintSqlVersion() {
	DBResultSet tmpQuery = SQL_Query(g_hDatabase, "select VERSION()");
	if (tmpQuery == null)
	{
		char error[255];
		SQL_GetError(g_hDatabase, error, sizeof(error));
		Debug("Failed to query (error: %s)", error);
	}
	else
	{
		if (SQL_FetchRow(tmpQuery)) {
			char version[255];
			SQL_FetchString(tmpQuery, 0, version, sizeof(version));
			Debug("SQL DB VERSION: %s", version);
		}
		/* Free the Handle */
		delete tmpQuery;
	}
}

/**
* Get the current name/hostname of the server
*/
public void GetServerName(char[] buffer, int size) {
	g_sServerName.GetString(buffer, size);
}

/**
* Checks if the stat key belongs to the basic stats group
*/
public bool IsBasicStat(const char[] name) {
	for (int i = 0; i < sizeof(g_sBasicStats); i++) {
		if (StrEqual(g_sBasicStats[i], name, false)) {
			return true;
		}
	}
	return false;
}

/**
* Checks if the plugin should collect/record statistics.
*
* This will return false if:
* - Cvar 'pstats_enabled' is 0
* - Cvar 'pstats_versus_exclusive' is 1 and game mode is not versus
*/
public bool AllowCollectStats() {
	//Check if plugin is enabled
	if (PluginDisabled()) {
		Debug("Player stats is currently disabled. Stats will not be recorded");
		return false;
	}
	
	return true;
}

/**
* Checks if the skill detect plugin is loaded
*/
public bool SkillDetectLoaded() {
	return g_bSkillDetectLoaded;
}

/**
* Checks if extra special stats should be recorded too :)
*/
public bool ExtrasEnabled() {
	return true;
}

/**
* Check if connect announce is enabled
*/
public bool CAnnounceEnabled() {
	return g_bConnectAnnounceEnabled.BoolValue;
}

/**
* Check if the plugin is in disabled state.
*/
public bool PluginDisabled() {
	return !g_bEnabled.BoolValue;
}

/**
* Checks if the plugin is in debug mode
*/
public bool DebugEnabled() {
	return g_bDebug.BoolValue;
}

/**
* Check if we should show the player rank to the user when he/she connects to the server
*/
public bool ShowRankOnConnect() {
	return g_bShowRankOnConnect.BoolValue;
}

/**
* Check if the string is blank
*/
stock bool StringBlank(const char[] text) {
	int len = strlen(text);
	char[] tmp = new char[len];
	strcopy(tmp, len, text);
	TrimString(tmp);
	return StrEqual(tmp, "");
}

/**
* Print and log plugin error messages. Error messages will also be printed to chat for admins in the server.
*/
public void Error(const char[] format, any...)
{
	int len = strlen(format) + 255;
	char[] formattedString = new char[len];
	VFormat(formattedString, len, format, 2);
	
	len = len + 8;
	char[] debugMessage = new char[len];
	Format(debugMessage, len, "[ERROR] %s", formattedString);
	
	PrintToServer(debugMessage);
	LogError(debugMessage);
	
	//Display error messages to root admins if debug is enabled
	for (int i = 1; i <= MAX_CLIENTS; i++) {
		if (IS_VALID_HUMAN(i) && Client_HasAdminFlags(i, ADMFLAG_ROOT)) {
			PrintToConsole(i, debugMessage);
			if (!DebugEnabled())
				continue;
			//Client_PrintToChat(i, true, "{R}[ERROR]{N} %s", formattedString);
			PrintToChat(i, "{R}[ERROR]{N} %s", formattedString);
		}
	}
}

/**
* Print and log plugin notify messages to the client
*/
public void Notify(int client, const char[] format, any...)
{
	int len = strlen(format) + 255;
	char[] formattedString = new char[len];
	VFormat(formattedString, len, format, 3);
	
	len = len + 8;
	char[] debugMessage = new char[len];
	
	if (client == 0) {
		Format(debugMessage, len, "[%s] %s", DEFAULT_PLUGIN_TAG, formattedString);
		PrintToServer(debugMessage);
	} else if (client > 0 && IS_VALID_HUMAN(client)) {
		Format(debugMessage, len, "{N}[{L}%s{N}] {O}%s", DEFAULT_PLUGIN_TAG, formattedString);
		//Client_PrintToChat(client, true, "%s", debugMessage);
		PrintToChat(client, "%s", debugMessage);
	} else {
		return;
	}
	
	LogAction(client, -1, debugMessage);
	
	//Display info messages to root admins
	for (int i = 1; i <= MAX_CLIENTS; i++) {
		if (IS_VALID_HUMAN(i) && Client_HasAdminFlags(i, ADMFLAG_ROOT)) {
			PrintToConsole(i, debugMessage);
		}
	}
}

/**
* Print and log plugin info messages
*/
public void Info(const char[] format, any...)
{
	int len = strlen(format) + 255;
	char[] formattedString = new char[len];
	VFormat(formattedString, len, format, 2);
	
	len = len + 8;
	char[] debugMessage = new char[len];
	Format(debugMessage, len, "[INFO] %s", formattedString);
	
	PrintToServer(debugMessage);
	LogMessage(debugMessage);
	
	//Display info messages to root admins
	for (int i = 1; i <= MAX_CLIENTS; i++) {
		if (IS_VALID_HUMAN(i) && Client_HasAdminFlags(i, ADMFLAG_ROOT)) {
			PrintToConsole(i, debugMessage);
		}
	}
}

/**
* Print and log plugin debug messages. This does not display messages when debug mode is disabled.
*/
public void Debug(const char[] format, any...)
{
	#if defined DEBUG
	if (!DebugEnabled()) {
		return;
	}
	
	int len = strlen(format) + 255;
	char[] formattedString = new char[len];
	VFormat(formattedString, len, format, 2);
	
	len = len + 8;
	char[] debugMessage = new char[len];
	Format(debugMessage, len, "[DEBUG] %s", formattedString);
	
	PrintToServer(debugMessage);
	LogMessage(debugMessage);
	
	//Display debug messages to root admins
	for (int i = 1; i <= MAX_CLIENTS; i++) {
		if (IS_VALID_HUMAN(i) && Client_HasAdminFlags(i, ADMFLAG_ROOT))
			PrintToConsole(i, debugMessage);
	}
	#endif
}



/**
 * Checks if the string is numeric.
 * This correctly handles + - . in the String.
 *
 * @param str				String to check.
 * @return					True if the String is numeric, false otherwise..
 */
public bool String_IsNumeric(const char[] str)
{
	int x = 0;
	int dotsFound = 0;
	int numbersFound = 0;
	
	if (str[x] == '+' || str[x] == '-') {
		x++;
	}
	
	while (str[x] != '\0') {
		
		if (IsCharNumeric(str[x])) {
			numbersFound++;
		}
		else if (str[x] == '.') {
			dotsFound++;
			
			if (dotsFound > 1) {
				return false;
			}
		}
		else {
			return false;
		}
		
		x++;
	}
	
	if (!numbersFound) {
		return false;
	}
	
	return true;
}

/**
 * Checks if string str starts with subString.
 *
 *
 * @param str				String to check
 * @param subString			Sub-String to check in str
 * @return					True if str starts with subString, false otherwise.
 */
public bool String_StartsWith(const char[] str, const char[] subString)
{
	int n = 0;
	while (subString[n] != '\0') {
		
		if (str[n] == '\0' || str[n] != subString[n]) {
			return false;
		}
		
		n++;
	}
	
	return true;
}

/**
 * Checks whether the client is a generic admin.
 *
 * @param				Client Index.
 * @return				True if the client is a generic admin, false otheriwse.
 */
public bool Client_IsAdmin(int client)
{
	AdminId adminId = GetUserAdmin(client);
	
	if (adminId == INVALID_ADMIN_ID) {
		return false;
	}
	
	return GetAdminFlag(adminId, Admin_Generic);
}

/**
 * Checks whether a client has certain admin flags
 *
 * @param				Client Index.
 * @return				True if the client has the admin flags, false otherwise.
 */
bool Client_HasAdminFlags(int client, int flags = ADMFLAG_GENERIC)
{
	AdminId adminId = GetUserAdmin(client);
	
	if (adminId == INVALID_ADMIN_ID) {
		return false;
	}
	
	return (GetAdminFlags(adminId, Access_Effective) & flags);
}


/**
* Finds a player by his SteamID
*
* @param auth			SteamID to search for
* @return				Client Index or -1
*/
public int Client_FindBySteamId(const char[] auth)
{
	char clientAuth[MAX_STEAMAUTH_LENGTH];
	for (int client = 1; client <= MaxClients; client++) {
		if (!IsClientAuthorized(client)) {
			continue;
		}
		
		GetClientAuthId(client, AuthId_Steam2, clientAuth, sizeof(clientAuth));
		
		if (StrEqual(auth, clientAuth)) {
			return client;
		}
	}
	
	return -1;
}
