// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                  // Force strict semicolon mode.
#pragma newdecls required

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <multicolors>

#include <tfdb>

// *********************************************************************************
// CONSTANTS 
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME             "[TF2] Dodgeball"
#define PLUGIN_AUTHOR           "Damizean, edited by x07x08 with features from YADBP 1.4.2 & Redux"
#define PLUGIN_VERSION          "1.6.0"
#define PLUGIN_CONTACT          "https://github.com/x07x08/TF2-Dodgeball-Modified"

// ---- Flags and types constants --------------------------------------------------
enum Musics
{
    Music_RoundStart,
    Music_RoundWin,
    Music_RoundLose,
    Music_Gameplay,
    SizeOfMusicsArray
}

enum ParticleAttachmentType
{
    PATTACH_ABSORIGIN = 0,    // Create at absorigin, but don't follow
    PATTACH_ABSORIGIN_FOLLOW, // Create at absorigin, and update to follow the entity
    PATTACH_CUSTOMORIGIN,     // Create at a custom origin, but don't follow
    PATTACH_POINT,            // Create on attachment point, but don't follow
    PATTACH_POINT_FOLLOW,     // Create on attachment point, and update to follow the entity
    PATTACH_WORLDORIGIN,      // Used for control points that don't attach to an entity
    PATTACH_ROOTBONE_FOLLOW   // Create at the root bone of the entity, and update to follow
};

// *********************************************************************************
// VARIABLES
// *********************************************************************************

// -----<<< Cvars >>>-----
ConVar g_hCvarEnabled;
ConVar g_hCvarEnableCfgFile;
ConVar g_hCvarDisableCfgFile;
ConVar g_hCvarStealPreventionNumber;
ConVar g_hCvarStealPreventionDamage;
ConVar g_hCvarStealDistance;
ConVar g_hCvarDelayPrevention;
ConVar g_hCvarDelayPreventionTime;
ConVar g_hCvarDelayPreventionSpeedup;
ConVar g_hCvarNoTargetRedirectDamage;

// -----<<< Gameplay >>>-----
bool   g_bEnabled;                // Is the plugin enabled?
bool   g_bRoundStarted;           // Has the round started?
int    g_iRoundCount;             // Current round count since map start
int    g_iRocketsFired;           // No. of rockets fired since round start
Handle g_hLogicTimer;             // Logic timer
float  g_fNextSpawnTime;          // Time at wich the next rocket will be able to spawn
int    g_iLastDeadTeam;           // The team of the last dead client. If none, it's a random team.
int    g_iLastDeadClient;         // The last dead client. If none, it's a random client.
int    g_iPlayerCount;
float  g_fTickModifier;
float  g_fStealDistance = 48.0;
int    g_iEmptyModel;
bool   g_bClientHideTrails [MAXPLAYERS + 1];
bool   g_bClientHideSprites[MAXPLAYERS + 1];
int    g_iLastStealer;

eRocketSteal bStealArray[MAXPLAYERS + 1];

// -----<<< Configuration >>>-----
bool g_bMusicEnabled;
bool g_bMusic[view_as<int>(SizeOfMusicsArray)];
char g_strMusic[view_as<int>(SizeOfMusicsArray)][PLATFORM_MAX_PATH];
bool g_bUseWebPlayer;
char g_strWebPlayerUrl[256];

// -----<<< Structures >>>-----
// Rockets
bool        g_bRocketIsValid            [MAX_ROCKETS];
int         g_iRocketEntity             [MAX_ROCKETS];
int         g_iRocketFakeEntity         [MAX_ROCKETS];
int         g_iRocketRedCriticalEntity  [MAX_ROCKETS];
int         g_iRocketBluCriticalEntity  [MAX_ROCKETS];
int         g_iRocketTarget             [MAX_ROCKETS];
int         g_iRocketClass              [MAX_ROCKETS];
RocketFlags g_iRocketFlags              [MAX_ROCKETS];
float       g_fRocketSpeed              [MAX_ROCKETS];
float       g_fRocketMphSpeed           [MAX_ROCKETS];
float       g_fRocketDirection          [MAX_ROCKETS][3];
int         g_iRocketDeflections        [MAX_ROCKETS];
int         g_iRocketAltDeflections     [MAX_ROCKETS];
int         g_iRocketEventDeflections   [MAX_ROCKETS];
float       g_fRocketLastDeflectionTime [MAX_ROCKETS];
float       g_fRocketLastBeepTime       [MAX_ROCKETS];
bool        g_bIsRocketBouncing         [MAX_ROCKETS];
bool        g_bIsRocketStolen           [MAX_ROCKETS];
bool        g_bPreventingDelay          [MAX_ROCKETS];
float       g_fLastSpawnTime            [MAX_ROCKETS];
bool        g_bIsRocketDraggable        [MAX_ROCKETS];
int         g_iRocketBounces            [MAX_ROCKETS];
int         g_iRocketCount;

// Classes
char           g_strRocketClassName           [MAX_ROCKET_CLASSES][16];
char           g_strRocketClassLongName       [MAX_ROCKET_CLASSES][32];
BehaviourTypes g_iRocketClassBehaviour        [MAX_ROCKET_CLASSES];
char           g_strRocketClassModel          [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassTrail          [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassSprite         [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassSpriteColor    [MAX_ROCKET_CLASSES][16];
float          g_fRocketClassSpriteLifetime   [MAX_ROCKET_CLASSES];
float          g_fRocketClassSpriteStartWidth [MAX_ROCKET_CLASSES];
float          g_fRocketClassSpriteEndWidth   [MAX_ROCKET_CLASSES];
RocketFlags    g_iRocketClassFlags            [MAX_ROCKET_CLASSES];
float          g_fRocketClassBeepInterval     [MAX_ROCKET_CLASSES];
char           g_strRocketClassSpawnSound     [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassBeepSound      [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassAlertSound     [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
float          g_fRocketClassCritChance       [MAX_ROCKET_CLASSES];
float          g_fRocketClassDamage           [MAX_ROCKET_CLASSES];
float          g_fRocketClassDamageIncrement  [MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeed            [MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeedIncrement   [MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeedLimit       [MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRate         [MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRateIncrement[MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRateLimit    [MAX_ROCKET_CLASSES];
float          g_fRocketClassElevationRate    [MAX_ROCKET_CLASSES];
float          g_fRocketClassElevationLimit   [MAX_ROCKET_CLASSES];
float          g_fRocketClassRocketsModifier  [MAX_ROCKET_CLASSES];
float          g_fRocketClassPlayerModifier   [MAX_ROCKET_CLASSES];
float          g_fRocketClassControlDelay     [MAX_ROCKET_CLASSES];
float          g_fRocketClassDragTimeMin      [MAX_ROCKET_CLASSES];
float          g_fRocketClassDragTimeMax      [MAX_ROCKET_CLASSES];
float          g_fRocketClassTargetWeight     [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnSpawn      [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnDeflect    [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnKill       [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnExplode    [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnNoTarget   [MAX_ROCKET_CLASSES];
float          g_fSavedParameters             [MAX_ROCKET_CLASSES][10]; // Should have used an enum
RocketFlags    g_iSavedRocketClassFlags       [MAX_ROCKET_CLASSES];
int            g_iRocketClassMaxBounces       [MAX_ROCKET_CLASSES];
int            g_iRocketClassSavedMaxBounces  [MAX_ROCKET_CLASSES];
float          g_fRocketClassBounceScale      [MAX_ROCKET_CLASSES];
StringMap      g_hRocketClassTrie;
int            g_iRocketClassCount;

// Spawner classes
char      g_strSpawnersName        [MAX_SPAWNER_CLASSES][32];
int       g_iSpawnersMaxRockets    [MAX_SPAWNER_CLASSES];
float     g_fSpawnersInterval      [MAX_SPAWNER_CLASSES];
ArrayList g_hSpawnersChancesTable  [MAX_SPAWNER_CLASSES];
ArrayList g_hSavedChancesTable     [MAX_SPAWNER_CLASSES];
StringMap g_hSpawnersTrie;
int       g_iSpawnersCount;

// Array containing the spawn points for the Red team, and
// their associated spawner class.
int g_iCurrentRedSpawn;
int g_iSpawnPointsRedCount;
int g_iSpawnPointsRedClass  [MAX_SPAWN_POINTS];
int g_iSpawnPointsRedEntity [MAX_SPAWN_POINTS];

// Array containing the spawn points for the Blu team, and
// their associated spawner class.
int g_iCurrentBluSpawn;
int g_iSpawnPointsBluCount;
int g_iSpawnPointsBluClass  [MAX_SPAWN_POINTS];
int g_iSpawnPointsBluEntity [MAX_SPAWN_POINTS];

// The default spawner class.
int g_iDefaultRedSpawner;
int g_iDefaultBluSpawner;

// -----<<< Forward handles >>>-----
Handle g_hForwardOnRocketCreated;
Handle g_hForwardOnRocketCreatedPre;
Handle g_hForwardOnRocketAltDeflect;
Handle g_hForwardOnRocketDeflect;
Handle g_hForwardOnRocketDeflectPre;
Handle g_hForwardOnRocketSteal;
Handle g_hForwardOnRocketNoTarget;
Handle g_hForwardOnRocketDelay;
Handle g_hForwardOnRocketBounce;
Handle g_hForwardOnRocketBouncePre;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

// *********************************************************************************
// METHODS
// *********************************************************************************

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public void OnPluginStart()
{
    char strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf")) SetFailState("This plugin is only for Team Fortress 2.");
    
    LoadTranslations("tfdb.phrases.txt");
    
    CreateConVar("tf_dodgeball_version", PLUGIN_VERSION, PLUGIN_NAME, _);
    g_hCvarEnabled = CreateConVar("tf_dodgeball_enabled", "1", "Enable Dodgeball on TFDB maps?", _, true, 0.0, true, 1.0);
    g_hCvarEnableCfgFile = CreateConVar("tf_dodgeball_enablecfg", "sourcemod/dodgeball_enable.cfg", "Config file to execute when enabling the Dodgeball game mode.");
    g_hCvarDisableCfgFile = CreateConVar("tf_dodgeball_disablecfg", "sourcemod/dodgeball_disable.cfg", "Config file to execute when disabling the Dodgeball game mode.");
    g_hCvarStealPreventionNumber = CreateConVar("tf_dodgeball_sp_number", "3", "How many steals before you get slayed?", _, true, 0.0, false);
    g_hCvarStealPreventionDamage = CreateConVar("tf_dodgeball_sp_damage", "0", "Reduce all damage on stolen rockets?", _, true, 0.0, true, 1.0);
    g_hCvarStealDistance = CreateConVar("tf_dodgeball_sp_distance", "48.0", "The distance between players for a steal to register.", _, true, 0.0, false);
    g_hCvarDelayPrevention = CreateConVar("tf_dodgeball_delay_prevention", "1", "Enable delay prevention?", _, true, 0.0, true, 1.0);
    g_hCvarDelayPreventionTime = CreateConVar("tf_dodgeball_dp_time", "5", "How much time (in seconds) before delay prevention activates?", _, true, 0.0, false);
    g_hCvarDelayPreventionSpeedup = CreateConVar("tf_dodgeball_dp_speedup", "100", "How much speed (in hammer units per second) should the rocket gain when delayed?", _, true, 0.0, false);
    g_hCvarNoTargetRedirectDamage = CreateConVar("tf_dodgeball_redirect_damage", "1", "Reduce all damage when a rocket has an invalid target?", _, true, 0.0, true, 1.0);
    
    g_hCvarStealDistance.AddChangeHook(tf2dodgeball_cvarhook);
    
    g_hRocketClassTrie = new StringMap();
    g_hSpawnersTrie = new StringMap();
    g_fTickModifier = 0.1 / GetTickInterval();
    
    RegisterCommands();
}

/* AskPluginLoad2()
**
** Registers the plugin's fake natives.
** -------------------------------------------------------------------------- */
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] strError, int iErrMax)
{
	CreateNative("TFDB_IsValidRocket", Native_IsValidRocket);
	CreateNative("TFDB_FindRocketByEntity", Native_FindRocketByEntity);
	
	CreateNative("TFDB_IsDodgeballEnabled", Native_IsDodgeballEnabled);
	
	CreateNative("TFDB_GetRocketEntity", Native_GetRocketEntity);
	
	CreateNative("TFDB_GetRocketFlags", Native_GetRocketFlags);
	CreateNative("TFDB_SetRocketFlags", Native_SetRocketFlags);
	
	CreateNative("TFDB_GetRocketTarget", Native_GetRocketTarget);
	CreateNative("TFDB_SetRocketTarget", Native_SetRocketTarget);
	
	CreateNative("TFDB_GetRocketEventDeflections", Native_GetRocketEventDeflections);
	CreateNative("TFDB_SetRocketEventDeflections", Native_SetRocketEventDeflections);
	
	CreateNative("TFDB_GetRocketAltDeflections", Native_GetRocketAltDeflections);
	CreateNative("TFDB_SetRocketAltDeflections", Native_SetRocketAltDeflections);
	
	CreateNative("TFDB_GetRocketDeflections", Native_GetRocketDeflections);
	CreateNative("TFDB_SetRocketDeflections", Native_SetRocketDeflections);
	
	CreateNative("TFDB_GetRocketClass", Native_GetRocketClass);
	CreateNative("TFDB_SetRocketClass", Native_SetRocketClass);
	
	CreateNative("TFDB_GetRocketClassCount", Native_GetRocketClassCount);
	
	CreateNative("TFDB_GetRocketClassBehaviour", Native_GetRocketClassBehaviour);
	CreateNative("TFDB_SetRocketClassBehaviour", Native_SetRocketClassBehaviour);
	
	CreateNative("TFDB_GetRocketClassFlags", Native_GetRocketClassFlags);
	CreateNative("TFDB_SetRocketClassFlags", Native_SetRocketClassFlags);
	
	CreateNative("TFDB_GetRocketClassDamage", Native_GetRocketClassDamage);
	CreateNative("TFDB_SetRocketClassDamage", Native_SetRocketClassDamage);
	
	CreateNative("TFDB_GetRocketClassDamageIncrement", Native_GetRocketClassDamageIncrement);
	CreateNative("TFDB_SetRocketClassDamageIncrement", Native_SetRocketClassDamageIncrement);
	
	CreateNative("TFDB_GetRocketClassSpeed", Native_GetRocketClassSpeed);
	CreateNative("TFDB_SetRocketClassSpeed", Native_SetRocketClassSpeed);
	
	CreateNative("TFDB_GetRocketClassSpeedIncrement", Native_GetRocketClassSpeedIncrement);
	CreateNative("TFDB_SetRocketClassSpeedIncrement", Native_SetRocketClassSpeedIncrement);
	
	CreateNative("TFDB_GetRocketClassSpeedLimit", Native_GetRocketClassSpeedLimit);
	CreateNative("TFDB_SetRocketClassSpeedLimit", Native_SetRocketClassSpeedLimit);
	
	CreateNative("TFDB_GetRocketClassTurnRate", Native_GetRocketClassTurnRate);
	CreateNative("TFDB_SetRocketClassTurnRate", Native_SetRocketClassTurnRate);
	
	CreateNative("TFDB_GetRocketClassTurnRateIncrement", Native_GetRocketClassTurnRateIncrement);
	CreateNative("TFDB_SetRocketClassTurnRateIncrement", Native_SetRocketClassTurnRateIncrement);
	
	CreateNative("TFDB_GetRocketClassTurnRateLimit", Native_GetRocketClassTurnRateLimit);
	CreateNative("TFDB_SetRocketClassTurnRateLimit", Native_SetRocketClassTurnRateLimit);
	
	CreateNative("TFDB_GetRocketClassElevationRate", Native_GetRocketClassElevationRate);
	CreateNative("TFDB_SetRocketClassElevationRate", Native_SetRocketClassElevationRate);
	
	CreateNative("TFDB_GetRocketClassElevationLimit", Native_GetRocketClassElevationLimit);
	CreateNative("TFDB_SetRocketClassElevationLimit", Native_SetRocketClassElevationLimit);
	
	CreateNative("TFDB_GetRocketClassRocketsModifier", Native_GetRocketClassRocketsModifier);
	CreateNative("TFDB_SetRocketClassRocketsModifier", Native_SetRocketClassRocketsModifier);
	
	CreateNative("TFDB_GetRocketClassPlayerModifier", Native_GetRocketClassPlayerModifier);
	CreateNative("TFDB_SetRocketClassPlayerModifier", Native_SetRocketClassPlayerModifier);
	
	CreateNative("TFDB_GetRocketClassControlDelay", Native_GetRocketClassControlDelay);
	CreateNative("TFDB_SetRocketClassControlDelay", Native_SetRocketClassControlDelay);
	
	CreateNative("TFDB_GetRocketClassDragTimeMin", Native_GetRocketClassDragTimeMin);
	CreateNative("TFDB_SetRocketClassDragTimeMin", Native_SetRocketClassDragTimeMin);
	
	CreateNative("TFDB_GetRocketClassDragTimeMax", Native_GetRocketClassDragTimeMax);
	CreateNative("TFDB_SetRocketClassDragTimeMax", Native_SetRocketClassDragTimeMax);
	
	CreateNative("TFDB_SetRocketClassCount", Native_SetRocketClassCount);
	
	CreateNative("TFDB_SetRocketEntity", Native_SetRocketEntity);
	
	CreateNative("TFDB_GetSavedParameters", Native_GetSavedParameters);
	CreateNative("TFDB_SetSavedParameters", Native_SetSavedParameters);
	
	CreateNative("TFDB_GetSavedRocketClassFlags", Native_GetSavedRocketClassFlags);
	CreateNative("TFDB_SetSavedRocketClassFlags", Native_SetSavedRocketClassFlags);
	
	CreateNative("TFDB_GetRocketClassMaxBounces", Native_GetRocketClassMaxBounces);
	CreateNative("TFDB_SetRocketClassMaxBounces", Native_SetRocketClassMaxBounces);
	
	CreateNative("TFDB_GetRocketClassSavedMaxBounces", Native_GetRocketClassSavedMaxBounces);
	CreateNative("TFDB_SetRocketClassSavedMaxBounces", Native_SetRocketClassSavedMaxBounces);
	
	CreateNative("TFDB_GetSpawnersName", Native_GetSpawnersName);
	CreateNative("TFDB_SetSpawnersName", Native_SetSpawnersName);
	
	CreateNative("TFDB_GetSpawnersMaxRockets", Native_GetSpawnersMaxRockets);
	CreateNative("TFDB_SetSpawnersMaxRockets", Native_SetSpawnersMaxRockets);
	
	CreateNative("TFDB_GetSpawnersInterval", Native_GetSpawnersInterval);
	CreateNative("TFDB_SetSpawnersInterval", Native_SetSpawnersInterval);
	
	CreateNative("TFDB_GetSpawnersChancesTable", Native_GetSpawnersChancesTable);
	CreateNative("TFDB_SetSpawnersChancesTable", Native_SetSpawnersChancesTable);
	
	CreateNative("TFDB_GetSavedChancesTable", Native_GetSavedChancesTable);
	CreateNative("TFDB_SetSavedChancesTable", Native_SetSavedChancesTable);
	
	CreateNative("TFDB_GetSpawnersCount", Native_GetSpawnersCount);
	CreateNative("TFDB_SetSpawnersCount", Native_SetSpawnersCount);
	
	CreateNative("TFDB_GetCurrentRedSpawn", Native_GetCurrentRedSpawn);
	CreateNative("TFDB_SetCurrentRedSpawn", Native_SetCurrentRedSpawn);
	
	CreateNative("TFDB_GetSpawnPointsRedCount", Native_GetSpawnPointsRedCount);
	CreateNative("TFDB_SetSpawnPointsRedCount", Native_SetSpawnPointsRedCount);
	
	CreateNative("TFDB_GetSpawnPointsRedClass", Native_GetSpawnPointsRedClass);
	CreateNative("TFDB_SetSpawnPointsRedClass", Native_SetSpawnPointsRedClass);
	
	CreateNative("TFDB_GetSpawnPointsRedEntity", Native_GetSpawnPointsRedEntity);
	CreateNative("TFDB_SetSpawnPointsRedEntity", Native_SetSpawnPointsRedEntity);
	
	CreateNative("TFDB_GetCurrentBluSpawn", Native_GetCurrentBluSpawn);
	CreateNative("TFDB_SetCurrentBluSpawn", Native_SetCurrentBluSpawn);
	
	CreateNative("TFDB_GetSpawnPointsBluCount", Native_GetSpawnPointsBluCount);
	CreateNative("TFDB_SetSpawnPointsBluCount", Native_SetSpawnPointsBluCount);
	
	CreateNative("TFDB_GetSpawnPointsBluClass", Native_GetSpawnPointsBluClass);
	CreateNative("TFDB_SetSpawnPointsBluClass", Native_SetSpawnPointsBluClass);
	
	CreateNative("TFDB_GetSpawnPointsBluEntity", Native_GetSpawnPointsBluEntity);
	CreateNative("TFDB_SetSpawnPointsBluEntity", Native_SetSpawnPointsBluEntity);
	
	CreateNative("TFDB_GetRoundStarted", Native_GetRoundStarted);
	CreateNative("TFDB_GetRoundCount", Native_GetRoundCount);
	
	CreateNative("TFDB_GetRocketsFired", Native_GetRocketsFired);
	
	CreateNative("TFDB_GetNextSpawnTime", Native_GetNextSpawnTime);
	CreateNative("TFDB_SetNextSpawnTime", Native_SetNextSpawnTime);
	
	CreateNative("TFDB_GetLastDeadTeam", Native_GetLastDeadTeam);
	CreateNative("TFDB_GetLastDeadClient", Native_GetLastDeadClient);
	CreateNative("TFDB_GetLastStealer", Native_GetLastStealer);
	
	CreateNative("TFDB_GetRocketFakeEntity", Native_GetRocketFakeEntity);
	CreateNative("TFDB_SetRocketFakeEntity", Native_SetRocketFakeEntity);
	
	CreateNative("TFDB_GetRocketSpeed", Native_GetRocketSpeed);
	CreateNative("TFDB_SetRocketSpeed", Native_SetRocketSpeed);
	
	CreateNative("TFDB_GetRocketMphSpeed", Native_GetRocketMphSpeed);
	CreateNative("TFDB_SetRocketMphSpeed", Native_SetRocketMphSpeed);
	
	CreateNative("TFDB_GetRocketDirection", Native_GetRocketDirection);
	CreateNative("TFDB_SetRocketDirection", Native_SetRocketDirection);
	
	CreateNative("TFDB_GetRocketLastDeflectionTime", Native_GetRocketLastDeflectionTime);
	
	CreateNative("TFDB_GetRocketCount", Native_GetRocketCount);
	
	CreateNative("TFDB_GetIsRocketBouncing", Native_GetIsRocketBouncing);
	CreateNative("TFDB_SetIsRocketBouncing", Native_SetIsRocketBouncing);
	
	CreateNative("TFDB_GetIsRocketStolen", Native_GetIsRocketStolen);
	
	CreateNative("TFDB_GetPreventingDelay", Native_GetPreventingDelay);
	
	CreateNative("TFDB_GetIsRocketDraggable", Native_GetIsRocketDraggable);
	CreateNative("TFDB_SetIsRocketDraggable", Native_SetIsRocketDraggable);
	
	CreateNative("TFDB_GetRocketBounces", Native_GetRocketBounces);
	CreateNative("TFDB_SetRocketBounces", Native_SetRocketBounces);
	
	CreateNative("TFDB_GetRocketClassName", Native_GetRocketClassName);
	CreateNative("TFDB_SetRocketClassName", Native_SetRocketClassName);
	
	CreateNative("TFDB_GetRocketClassLongName", Native_GetRocketClassLongName);
	CreateNative("TFDB_SetRocketClassLongName", Native_SetRocketClassLongName);
	
	CreateNative("TFDB_GetRocketClassModel", Native_GetRocketClassModel);
	CreateNative("TFDB_SetRocketClassModel", Native_SetRocketClassModel);
	
	CreateNative("TFDB_GetRocketClassTrail", Native_GetRocketClassTrail);
	CreateNative("TFDB_SetRocketClassTrail", Native_SetRocketClassTrail);
	
	CreateNative("TFDB_GetRocketClassSprite", Native_GetRocketClassSprite);
	CreateNative("TFDB_SetRocketClassSprite", Native_SetRocketClassSprite);
	
	CreateNative("TFDB_GetRocketClassSpriteColor", Native_GetRocketClassSpriteColor);
	CreateNative("TFDB_SetRocketClassSpriteColor", Native_SetRocketClassSpriteColor);
	
	CreateNative("TFDB_GetRocketClassSpriteLifetime", Native_GetRocketClassSpriteLifetime);
	CreateNative("TFDB_SetRocketClassSpriteLifetime", Native_SetRocketClassSpriteLifetime);
	
	CreateNative("TFDB_GetRocketClassSpriteStartWidth", Native_GetRocketClassSpriteStartWidth);
	CreateNative("TFDB_SetRocketClassSpriteStartWidth", Native_SetRocketClassSpriteStartWidth);
	
	CreateNative("TFDB_GetRocketClassSpriteEndWidth", Native_GetRocketClassSpriteEndWidth);
	CreateNative("TFDB_SetRocketClassSpriteEndWidth", Native_SetRocketClassSpriteEndWidth);
	
	CreateNative("TFDB_GetRocketClassBeepInterval", Native_GetRocketClassBeepInterval);
	CreateNative("TFDB_SetRocketClassBeepInterval", Native_SetRocketClassBeepInterval);
	
	CreateNative("TFDB_GetRocketClassSpawnSound", Native_GetRocketClassSpawnSound);
	CreateNative("TFDB_SetRocketClassSpawnSound", Native_SetRocketClassSpawnSound);
	
	CreateNative("TFDB_GetRocketClassBeepSound", Native_GetRocketClassBeepSound);
	CreateNative("TFDB_SetRocketClassBeepSound", Native_SetRocketClassBeepSound);
	
	CreateNative("TFDB_GetRocketClassAlertSound", Native_GetRocketClassAlertSound);
	CreateNative("TFDB_SetRocketClassAlertSound", Native_SetRocketClassAlertSound);
	
	CreateNative("TFDB_GetRocketClassCritChance", Native_GetRocketClassCritChance);
	CreateNative("TFDB_SetRocketClassCritChance", Native_SetRocketClassCritChance);
	
	CreateNative("TFDB_GetRocketClassTargetWeight", Native_GetRocketClassTargetWeight);
	CreateNative("TFDB_SetRocketClassTargetWeight", Native_SetRocketClassTargetWeight);
	
	CreateNative("TFDB_GetRocketClassCmdsOnSpawn", Native_GetRocketClassCmdsOnSpawn);
	CreateNative("TFDB_SetRocketClassCmdsOnSpawn", Native_SetRocketClassCmdsOnSpawn);
	
	CreateNative("TFDB_GetRocketClassCmdsOnDeflect", Native_GetRocketClassCmdsOnDeflect);
	CreateNative("TFDB_SetRocketClassCmdsOnDeflect", Native_SetRocketClassCmdsOnDeflect);
	
	CreateNative("TFDB_GetRocketClassCmdsOnKill", Native_GetRocketClassCmdsOnKill);
	CreateNative("TFDB_SetRocketClassCmdsOnKill", Native_SetRocketClassCmdsOnKill);
	
	CreateNative("TFDB_GetRocketClassCmdsOnExplode", Native_GetRocketClassCmdsOnExplode);
	CreateNative("TFDB_SetRocketClassCmdsOnExplode", Native_SetRocketClassCmdsOnExplode);
	
	CreateNative("TFDB_GetRocketClassCmdsOnNoTarget", Native_GetRocketClassCmdsOnNoTarget);
	CreateNative("TFDB_SetRocketClassCmdsOnNoTarget", Native_SetRocketClassCmdsOnNoTarget);
	
	CreateNative("TFDB_GetRocketClassBounceScale", Native_GetRocketClassBounceScale);
	CreateNative("TFDB_SetRocketClassBounceScale", Native_SetRocketClassBounceScale);
	
	CreateNative("TFDB_CreateRocket", Native_CreateRocket);
	CreateNative("TFDB_DestroyRocket", Native_DestroyRocket);
	CreateNative("TFDB_DestroyRockets", Native_DestroyRockets);
	CreateNative("TFDB_DestroyRocketClasses", Native_DestroyRocketClasses);
	CreateNative("TFDB_DestroySpawners", Native_DestroySpawners);
	CreateNative("TFDB_ParseConfigurations", Native_ParseConfigurations);
	CreateNative("TFDB_PopulateSpawnPoints", Native_PopulateSpawnPoints);
	CreateNative("TFDB_HomingRocketThink", Native_HomingRocketThink);
	CreateNative("TFDB_RocketOtherThink", Native_RocketOtherThink);
	CreateNative("TFDB_RocketLegacyThink", Native_RocketLegacyThink);
	
	SetupForwards();
	
	RegPluginLibrary("tfdb");
	
	return APLRes_Success;
}

/* SetupForwards()
**
** Registers the plugin's forwards.
** -------------------------------------------------------------------------- */
void SetupForwards()
{
	// Rocket index, rocket entity
	g_hForwardOnRocketCreated = CreateGlobalForward("TFDB_OnRocketCreated", ET_Ignore, Param_Cell, Param_Cell);
	// Rocket index, rocket class, rocket flags
	g_hForwardOnRocketCreatedPre = CreateGlobalForward("TFDB_OnRocketCreatedPre", ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef);
	// Rocket index, rocket entity, rocket owner
	g_hForwardOnRocketAltDeflect = CreateGlobalForward("TFDB_OnRocketAltDeflect", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	// Rocket index, rocket entity, rocket owner
	g_hForwardOnRocketDeflect = CreateGlobalForward("TFDB_OnRocketDeflect", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	// Rocket index, rocket entity, rocket owner, rocket target
	g_hForwardOnRocketDeflectPre = CreateGlobalForward("TFDB_OnRocketDeflectPre", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
	// Rocket index, stealer, rocket target, stolen rockets count
	g_hForwardOnRocketSteal = CreateGlobalForward("TFDB_OnRocketSteal", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	// Rocket index, rocket target, previous target
	g_hForwardOnRocketNoTarget = CreateGlobalForward("TFDB_OnRocketNoTarget", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	// Rocket index, delayer
	g_hForwardOnRocketDelay = CreateGlobalForward("TFDB_OnRocketDelay", ET_Ignore, Param_Cell, Param_Cell);
	// Rocket index, rocket entity
	g_hForwardOnRocketBounce = CreateGlobalForward("TFDB_OnRocketBounce", ET_Ignore, Param_Cell, Param_Cell);
	// Rocket index, rocket entity, angles, velocity
	g_hForwardOnRocketBouncePre = CreateGlobalForward("TFDB_OnRocketBouncePre", ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array);
}

/* OnConfigsExecuted()
**
** When all the configuration files have been executed, try to enable the
** Dodgeball.
** -------------------------------------------------------------------------- */
public void OnConfigsExecuted()
{
    if (g_hCvarEnabled.BoolValue && IsDodgeBallMap())
    {
        EnableDodgeBall();
    }
}

/* OnMapEnd()
**
** When the map ends, disable DodgeBall.
** -------------------------------------------------------------------------- */
public void OnMapEnd()
{
    DisableDodgeBall();
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**     __  ___                                                  __ 
**    /  |/  /___ _____  ____ _____ ____  ____ ___  ___  ____  / /_
**   / /|_/ / __ `/ __ \/ __ `/ __ `/ _ \/ __ `__ \/ _ \/ __ \/ __/
**  / /  / / /_/ / / / / /_/ / /_/ /  __/ / / / / /  __/ / / / /_  
** /_/  /_/\__,_/_/ /_/\__,_/\__, /\___/_/ /_/ /_/\___/_/ /_/\__/  
**                          /____/                                 
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

//   ___                       _ 
//  / __|___ _ _  ___ _ _ __ _| |
// | (_ / -_) ' \/ -_) '_/ _` | |
//  \___\___|_||_\___|_| \__,_|_|

/* IsDodgeBallMap()
**
** Checks if the current map is a dodgeball map.
** -------------------------------------------------------------------------- */
bool IsDodgeBallMap()
{
    char strMap[64];
    GetCurrentMap(strMap, sizeof(strMap));
    return StrContains(strMap, "tfdb_", false) == 0;
}

/* EnableDodgeBall()
**
** Enables and hooks all the required events.
** -------------------------------------------------------------------------- */
void EnableDodgeBall()
{
    if (g_bEnabled == false)
    {
        // Parse configuration files
        char strMapName[64]; GetCurrentMap(strMapName, sizeof(strMapName));
        char strMapFile[PLATFORM_MAX_PATH]; FormatEx(strMapFile, sizeof(strMapFile), "%s.cfg", strMapName);
        ParseConfigurations();
        ParseConfigurations(strMapFile);
        
        // Check if we have all the required information
        if (g_iRocketClassCount == 0)   SetFailState("No rocket class defined.");
        if (g_iSpawnersCount == 0)      SetFailState("No spawner class defined.");
        if (g_iDefaultRedSpawner == -1) SetFailState("No spawner class definition for the Red spawners exists in the config file.");
        if (g_iDefaultBluSpawner == -1) SetFailState("No spawner class definition for the Blu spawners exists in the config file.");
        
        // Hook events and info_target outputs.
        HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
        HookEvent("arena_round_start", OnSetupFinished, EventHookMode_PostNoCopy); // teamplay_setup_finished will not fire on maps that lack team_round_timer
        HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
        HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
        HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
        HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
        HookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);
        HookEvent("object_deflected", OnObjectDeflected);
        
        g_iEmptyModel = PrecacheModel("models/empty.mdl", true);
        PrecacheParticleSystem("rockettrail_fire"); // Why isn't this particle already precached?
        
        AddMultiTargetFilter("@stealer", MLTargetFilterStealer, "last stealer", false);
        AddMultiTargetFilter("@!stealer", MLTargetFilterStealer, "non last stealer", false); // Sounds weird not gonna lie
        
        // Precache sounds
        PrecacheSound(SOUND_DEFAULT_SPAWN, true);
        PrecacheSound(SOUND_DEFAULT_BEEP, true);
        PrecacheSound(SOUND_DEFAULT_ALERT, true);
        PrecacheSound(SOUND_DEFAULT_SPEEDUP, true);
        if (g_bMusicEnabled == true)
        {
            if (g_bMusic[Music_RoundStart]) PrecacheSoundEx(g_strMusic[Music_RoundStart], true, true);
            if (g_bMusic[Music_RoundWin])   PrecacheSoundEx(g_strMusic[Music_RoundWin], true, true);
            if (g_bMusic[Music_RoundLose])  PrecacheSoundEx(g_strMusic[Music_RoundLose], true, true);
            if (g_bMusic[Music_Gameplay])   PrecacheSoundEx(g_strMusic[Music_Gameplay], true, true);
        }
        
        // Precache particles
        PrecacheParticle(PARTICLE_NUKE_1);
        PrecacheParticle(PARTICLE_NUKE_2);
        PrecacheParticle(PARTICLE_NUKE_3);
        PrecacheParticle(PARTICLE_NUKE_4);
        PrecacheParticle(PARTICLE_NUKE_5);
        PrecacheParticle(PARTICLE_NUKE_COLLUMN);
        
        // Precache rocket resources
        for (int i = 0; i < g_iRocketClassCount; i++)
        {
            RocketFlags iFlags = g_iRocketClassFlags[i];
            if (TestFlags(iFlags, RocketFlag_CustomModel))      PrecacheModelEx(g_strRocketClassModel[i], true, true);
            if (TestFlags(iFlags, RocketFlag_CustomSpawnSound)) PrecacheSoundEx(g_strRocketClassSpawnSound[i], true, true);
            if (TestFlags(iFlags, RocketFlag_CustomBeepSound))  PrecacheSoundEx(g_strRocketClassBeepSound[i], true, true);
            if (TestFlags(iFlags, RocketFlag_CustomAlertSound)) PrecacheSoundEx(g_strRocketClassAlertSound[i], true, true);
            if (TestFlags(iFlags, RocketFlag_CustomTrail))      PrecacheParticleSystem(g_strRocketClassTrail[i]);
            if (TestFlags(iFlags, RocketFlag_CustomSprite))     PrecacheTrail(g_strRocketClassSprite[i]);
        }
        
        // Execute enable config file
        char strCfgFile[64]; g_hCvarEnableCfgFile.GetString(strCfgFile, sizeof(strCfgFile));
        ServerCommand("exec \"%s\"", strCfgFile);
        
        // Done.
        g_bEnabled        = true;
        g_bRoundStarted   = false;
        g_iRoundCount     = 0;
    }
}

/* DisableDodgeBall()
**
** Disables all hooks and frees arrays.
** -------------------------------------------------------------------------- */
void DisableDodgeBall()
{
    if (g_bEnabled == true)
    {
        // Clean up everything
        DestroyRockets();
        DestroyRocketClasses();
        DestroySpawners();
        if (g_hLogicTimer != null) KillTimer(g_hLogicTimer);
        g_hLogicTimer = null;
        
        // Disable music
        g_bMusic[Music_RoundStart] =
        g_bMusic[Music_RoundWin]   = 
        g_bMusic[Music_RoundLose]  = 
        g_bMusic[Music_Gameplay]   = false;
        
        // Unhook events and info_target outputs;
        UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
        UnhookEvent("arena_round_start", OnSetupFinished, EventHookMode_PostNoCopy);
        UnhookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
        UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
        UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
        UnhookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
        UnhookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);
        UnhookEvent("object_deflected", OnObjectDeflected);
        
        RemoveMultiTargetFilter("@stealer", MLTargetFilterStealer);
        RemoveMultiTargetFilter("@!stealer", MLTargetFilterStealer);
        
        // Execute enable config file
        char strCfgFile[64]; g_hCvarDisableCfgFile.GetString(strCfgFile, sizeof(strCfgFile));
        ServerCommand("exec \"%s\"", strCfgFile);
        
        // Done.
        g_bEnabled        = false;
        g_bRoundStarted   = false;
        g_iRoundCount     = 0;
    }
    
}

public void OnClientDisconnect(int iClient)
{
	bStealArray[iClient].stoleRocket = false;
	bStealArray[iClient].rocketsStolen = 0;
	
	if (iClient == g_iLastDeadClient)
	{
		g_iLastDeadClient = 0;
	}
	
	if (iClient == g_iLastStealer)
	{
		g_iLastStealer = 0;
	}
	
	g_bClientHideTrails [iClient] = false;
	g_bClientHideSprites[iClient] = false;
}

//   ___                     _           
//  / __|__ _ _ __  ___ _ __| |__ _ _  _ 
// | (_ / _` | '  \/ -_) '_ \ / _` | || |
//  \___\__,_|_|_|_\___| .__/_\__,_|\_, |
//                     |_|          |__/ 

/* OnRoundStart()
**
** At round start, do something?
** -------------------------------------------------------------------------- */
public void OnRoundStart(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (g_bMusic[Music_RoundStart])
    {
        EmitSoundToAll(g_strMusic[Music_RoundStart]);
    }
    
    for (int i = 0; i <= MaxClients; i++)
    {
        bStealArray[i].stoleRocket = false;
        bStealArray[i].rocketsStolen = 0;
    }
}

/* OnSetupFinished()
**
** When the setup finishes, populate the spawn points arrays and create the
** Dodgeball game logic timer.
** -------------------------------------------------------------------------- */
public void OnSetupFinished(Event hEvent, char[] strEventName, bool bDontBroadcast)
{   
    if ((g_bEnabled == true) && (BothTeamsPlaying() == true))
    {
        PopulateSpawnPoints();
        
        if (g_iLastDeadTeam == 0) g_iLastDeadTeam = GetURandomIntRange(view_as<int>(TFTeam_Red), view_as<int>(TFTeam_Blue));
        if (!IsValidClient(g_iLastDeadClient)) g_iLastDeadClient = 0;
        
        g_hLogicTimer      = CreateTimer(FPS_LOGIC_INTERVAL, OnDodgeBallGameFrame, _, TIMER_REPEAT);
        g_iPlayerCount     = CountAlivePlayers();
        g_iRocketsFired    = 0;
        g_iCurrentRedSpawn = 0;
        g_iCurrentBluSpawn = 0;
        g_fNextSpawnTime   = GetGameTime();
        g_bRoundStarted    = true;
        g_iRoundCount++;
    }
}

/* OnRoundEnd()
**
** At round end, stop the Dodgeball game logic timer and destroy the remaining
** rockets.
** -------------------------------------------------------------------------- */
public void OnRoundEnd(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (g_hLogicTimer != null)
    {
        KillTimer(g_hLogicTimer);
        g_hLogicTimer = null;
    }
    
    if (g_bMusicEnabled == true)
    {
        if (g_bUseWebPlayer)
        {
            for (int iClient = 1; iClient <= MaxClients; iClient++)
            {
                if (IsValidClient(iClient))
                {
                    ShowHiddenMOTDPanel(iClient, "MusicPlayerStop", "http://0.0.0.0/");
                }
            }
        }
        else if (g_bMusic[Music_Gameplay])
        {
            StopSoundToAll(SNDCHAN_MUSIC, g_strMusic[Music_Gameplay]);
        }
    }
    
    DestroyRockets();
    g_bRoundStarted = false;
}

/* OnPlayerSpawn()
**
** When the player spawns, force class to Pyro.
** -------------------------------------------------------------------------- */
public void OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if (!IsValidClient(iClient)) return;
    
    TFClassType iClass = TF2_GetPlayerClass(iClient);
    if (!(iClass == TFClass_Pyro || iClass == TFClass_Unknown))
    {
        TF2_SetPlayerClass(iClient, TFClass_Pyro, false, true);
        TF2_RespawnPlayer(iClient);
    }
}

/* OnPlayerDeath()
**
** When the player dies, set the last dead team to determine the next
** rocket's team.
** -------------------------------------------------------------------------- */
public void OnPlayerDeath(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (g_bRoundStarted == false) return;
    int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
    int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
    
    if (!IsValidClient(iAttacker))
    {
        iAttacker = 0;
    }
    
    if (IsValidClient(iVictim))
    {
        bStealArray[iVictim].stoleRocket = false;
        bStealArray[iVictim].rocketsStolen = 0;
        
        g_iLastDeadClient = iVictim;
        g_iLastDeadTeam = GetClientTeam(iVictim);
        
        int iInflictor = hEvent.GetInt("inflictor_entindex");
        int iIndex = FindRocketByEntity(iInflictor);
        
        if (iIndex != -1)
        {
            int iClass = g_iRocketClass[iIndex];
            int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
            float fSpeed = g_fRocketSpeed[iIndex];
            float fMphSpeed = g_fRocketMphSpeed[iIndex];
            int iDeflections = g_iRocketDeflections[iIndex];
            
            if ((g_iRocketFlags[iIndex] & RocketFlag_OnExplodeCmd) && !(g_iRocketFlags[iIndex] & RocketFlag_Exploded))
            {
                ExecuteCommands(g_hRocketClassCmdsOnExplode[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections, fMphSpeed);
                g_iRocketFlags[iIndex] |= RocketFlag_Exploded;
            }
            
            if (TestFlags(g_iRocketFlags[iIndex], RocketFlag_OnKillCmd))
                ExecuteCommands(g_hRocketClassCmdsOnKill[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections, fMphSpeed);
        }
    }
    
    SetRandomSeed(view_as<int>(GetGameTime()));
}

/* OnPlayerInventory()
**
** Make sure the client only has the flamethrower equipped.
** -------------------------------------------------------------------------- */
public void OnPlayerInventory(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if (!IsValidClient(iClient)) return;
    
    for (int iSlot = 1; iSlot < 5; iSlot++)
    {
        int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
        if (iEntity != -1) RemoveEdict(iEntity);
    }
}

/* OnPlayerRunCmd()
**
** Block flamethrower's Mouse1 attack.
** -------------------------------------------------------------------------- */
public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
    if (g_bEnabled == true) iButtons &= ~IN_ATTACK;
    return Plugin_Continue;
}

/* OnBroadcastAudio()
**
** Replaces the broadcasted audio for our custom music files.
** -------------------------------------------------------------------------- */
public Action OnBroadcastAudio(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (g_bMusicEnabled == true)
    {
        char strSound[PLATFORM_MAX_PATH];
        hEvent.GetString("sound", strSound, sizeof(strSound));
        int iTeam = hEvent.GetInt("team");
        
        if (StrEqual(strSound, "Announcer.AM_RoundStartRandom") == true)
        {
            if (g_bUseWebPlayer == false)
            {
                if (g_bMusic[Music_Gameplay])
                {
                    EmitSoundToAll(g_strMusic[Music_Gameplay], SOUND_FROM_PLAYER, SNDCHAN_MUSIC);
                    return Plugin_Handled;
                }
            }
            else
            {
                for (int iClient = 1; iClient <= MaxClients; iClient++)
                    if (IsValidClient(iClient))
                        ShowHiddenMOTDPanel(iClient, "MusicPlayerStart", g_strWebPlayerUrl);
                    
                return Plugin_Handled;
            }
        }
        else if (StrEqual(strSound, "Game.YourTeamWon") == true)
        {
            if (g_bMusic[Music_RoundWin])
            {
                for (int iClient = 1; iClient <= MaxClients; iClient++)
                    if (IsValidClient(iClient) && (iTeam == GetClientTeam(iClient)))
                        EmitSoundToClient(iClient, g_strMusic[Music_RoundWin]);
                    
                return Plugin_Handled;
            }
        }
        else if (StrEqual(strSound, "Game.YourTeamLost") == true)
        {
            if (g_bMusic[Music_RoundLose])
            {
                for (int iClient = 1; iClient <= MaxClients; iClient++)
                    if (IsValidClient(iClient) && (iTeam == GetClientTeam(iClient)))
                        EmitSoundToClient(iClient, g_strMusic[Music_RoundLose]);
                    
                return Plugin_Handled;
            }
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public void OnObjectDeflected(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iEntity = hEvent.GetInt("object_entindex");
	int iIndex  = FindRocketByEntity(iEntity);
	
	if (iIndex != -1)
	{
		g_iRocketEventDeflections[iIndex]++;
		
		if (g_iRocketFlags[iIndex] & RocketFlag_ResetBounces)
		{
			g_iRocketBounces[iIndex] = 0;
		}
		
		if (g_iRocketFlags[iIndex] & RocketFlag_ReplaceParticles)
		{
			bool bCritical = !!GetEntProp(iEntity, Prop_Send, "m_bCritical");
			
			if (bCritical)
			{
				int iRedCriticalEntity = EntRefToEntIndex(g_iRocketRedCriticalEntity[iIndex]);
				int iBluCriticalEntity = EntRefToEntIndex(g_iRocketBluCriticalEntity[iIndex]);
				
				if (iRedCriticalEntity != -1 && iBluCriticalEntity != -1)
				{
					int iTeam = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
					
					if (iTeam == view_as<int>(TFTeam_Red))
					{
						AcceptEntityInput(iBluCriticalEntity, "Stop");
						AcceptEntityInput(iRedCriticalEntity, "Start");
					}
					else if (iTeam == view_as<int>(TFTeam_Blue))
					{
						AcceptEntityInput(iBluCriticalEntity, "Start");
						AcceptEntityInput(iRedCriticalEntity, "Stop");
					}
				}
			}
		}
		
		if (g_iRocketFlags[iIndex] & RocketFlag_IsNeutral)
		{
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
		}
	}
}

public void OnGameFrame()
{
    if ((BothTeamsPlaying() == false) || !g_bEnabled) return;
    
    int iIndex = -1;
    while ((iIndex = FindNextValidRocket(iIndex)) != -1)
    {
        switch (g_iRocketClassBehaviour[g_iRocketClass[iIndex]])
        {
            case Behaviour_Unknown: {}
            case Behaviour_Homing:  { HomingRocketThink(iIndex); }
        }
    }
}

/* OnDodgeBallGameFrame()
**
** Every tick of the Dodgeball logic.
** -------------------------------------------------------------------------- */
public Action OnDodgeBallGameFrame(Handle hTimer, any Data)
{
    // Only if both teams are playing
    if (BothTeamsPlaying() == false) return Plugin_Continue;
    
    // Check if we need to fire more rockets.
    if (GetGameTime() >= g_fNextSpawnTime)
    {
        if (g_iLastDeadTeam == view_as<int>(TFTeam_Red))
        {
            int iSpawnerEntity = g_iSpawnPointsRedEntity[g_iCurrentRedSpawn];
            int iSpawnerClass  = g_iSpawnPointsRedClass[g_iCurrentRedSpawn];
            if (g_iRocketCount < g_iSpawnersMaxRockets[iSpawnerClass])
            {
                CreateRocket(iSpawnerEntity, iSpawnerClass, view_as<int>(TFTeam_Red));
                g_iCurrentRedSpawn = (g_iCurrentRedSpawn + 1) % g_iSpawnPointsRedCount;
            }
        }
        else
        {
            int iSpawnerEntity = g_iSpawnPointsBluEntity[g_iCurrentBluSpawn];
            int iSpawnerClass  = g_iSpawnPointsBluClass[g_iCurrentBluSpawn];
            if (g_iRocketCount < g_iSpawnersMaxRockets[iSpawnerClass])
            {
                CreateRocket(iSpawnerEntity, iSpawnerClass, view_as<int>(TFTeam_Blue));
                g_iCurrentBluSpawn = (g_iCurrentBluSpawn + 1) % g_iSpawnPointsBluCount;
            }
        }
    }
    
    // Manage the active rockets
    int iIndex = -1;
    while ((iIndex = FindNextValidRocket(iIndex)) != -1)
    {
        switch (g_iRocketClassBehaviour[g_iRocketClass[iIndex]])
        {
            case Behaviour_Unknown:      {}
            case Behaviour_Homing:       { RocketOtherThink(iIndex); }
            case Behaviour_LegacyHoming: { RocketLegacyThink(iIndex); }
        }
    }
    
    return Plugin_Continue;
}

//  ___         _       _      
// | _ \___  __| |_____| |_ ___
// |   / _ \/ _| / / -_)  _(_-<
// |_|_\___/\__|_\_\___|\__/__/

/* CreateRocket()
**
** Fires a new rocket entity from the spawner's position.
** -------------------------------------------------------------------------- */
void CreateRocket(int iSpawnerEntity, int iSpawnerClass, int iTeam, int iClass = -1)
{
    int iIndex = FindFreeRocketSlot();
    if (iIndex != -1)
    {
        // Fetch a random rocket class and it's parameters.
        iClass = iClass == -1 ? GetRandomRocketClass(iSpawnerClass) : iClass;
        RocketFlags iFlags = g_iRocketClassFlags[iClass];
        
        int iClassRef = iClass;
        RocketFlags iFlagsRef = iFlags;
        
        Action aResult = Forward_OnRocketCreatedPre(iIndex, iClassRef, iFlagsRef);
        
        if (aResult == Plugin_Stop || aResult == Plugin_Handled)
        {
        	return;
        }
        else if (aResult == Plugin_Changed)
        {
        	iClass = iClassRef;
        	iFlags = iFlagsRef;
        }
        
        // Create rocket entity.
        int iEntity = CreateEntityByName(TestFlags(iFlags, RocketFlag_IsAnimated)? "tf_projectile_sentryrocket" : "tf_projectile_rocket");
        if (iEntity && IsValidEntity(iEntity))
        {
            // Fetch spawn point's location and angles.
            float fPosition[3], fAngles[3], fDirection[3];
            GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
            GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
            GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
            
            // Setup rocket entity.
            SetEntProp(iEntity,    Prop_Send, "m_bCritical",    (GetURandomFloatRange(0.0, 100.0) <= g_fRocketClassCritChance[iClass])? 1 : 0, 1);
            SetEntProp(iEntity,    Prop_Send, "m_iTeamNum",     (TestFlags(iFlags, RocketFlag_IsNeutral))? 1 : iTeam, 1);
            SetEntProp(iEntity,    Prop_Send, "m_iDeflected",   0);
            TeleportEntity(iEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
            
            // Setup rocket structure with the newly created entity.
            int iTargetTeam = (TestFlags(iFlags, RocketFlag_IsNeutral))? 0 : GetAnalogueTeam(iTeam);
            int iTarget     = SelectTarget(iTargetTeam);
            
            // In order for the object_deflected event to fire, the old (previous) owner must be a valid client
            // I'm doing this as I don't want the first object_deflected event to be skipped
            int iTeamRocketTarget = GetClientTeam(iTarget);
            int iRocketOwner      = SelectTarget(GetAnalogueTeam(iTeamRocketTarget));
            SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", iRocketOwner);
            
            float fModifier = CalculateModifier(iClass, 0);
            g_bRocketIsValid[iIndex]            = true;
            g_iRocketFlags[iIndex]              = iFlags;
            g_iRocketEntity[iIndex]             = EntIndexToEntRef(iEntity);
            g_iRocketTarget[iIndex]             = EntIndexToEntRef(iTarget);
            g_iRocketClass[iIndex]              = iClass;
            g_iRocketDeflections[iIndex]        = 0;
            g_iRocketAltDeflections[iIndex]     = 0;
            g_iRocketEventDeflections[iIndex]   = 0;
            g_bIsRocketDraggable[iIndex]        = false;
            g_bIsRocketBouncing[iIndex]         = false;
            g_bPreventingDelay[iIndex]          = false;
            g_iRocketBounces[iIndex]            = 0;
            g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
            g_fRocketLastBeepTime[iIndex]       = GetGameTime();
            g_fRocketSpeed[iIndex]              = CalculateRocketSpeed(iClass, fModifier);
            g_fRocketMphSpeed[iIndex]           = CalculateRocketSpeed(iClass, fModifier) * 0.042614;
            g_bIsRocketStolen[iIndex]           = false;
            
            CopyVectors(fDirection, g_fRocketDirection[iIndex]);
            SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
            DispatchSpawn(iEntity);
            
            if (TestFlags(iFlags, RocketFlag_RemoveParticles))
            {
                int iOtherEntity = CreateEntityByName("prop_dynamic");
                if (iOtherEntity && IsValidEntity(iOtherEntity))
                {
                    SetEntProp(iEntity, Prop_Send, "m_nModelIndexOverrides", g_iEmptyModel);
                    
                    SetEntityModel(iOtherEntity, "models/weapons/w_models/w_rocket.mdl");
                    SetEntProp(iOtherEntity, Prop_Send, "m_CollisionGroup", 0);    // COLLISION_GROUP_NONE
                    SetEntProp(iOtherEntity, Prop_Send, "m_usSolidFlags", 0x0004); // FSOLID_NOT_SOLID
                    SetEntProp(iOtherEntity, Prop_Send, "m_nSolidType", 0);        // SOLID_NONE
                    TeleportEntity(iOtherEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                    g_iRocketFakeEntity[iIndex] = EntIndexToEntRef(iOtherEntity);
                    DispatchSpawn(iOtherEntity);
                    
                    SetVariantString("!activator");
                    AcceptEntityInput(iOtherEntity, "SetParent", iEntity, iOtherEntity);
                    
                    if (TestFlags(iFlags, RocketFlag_ReplaceParticles))
                    {
                        CreateTempParticle("rockettrail_fire", fPosition, NULL_VECTOR, fAngles, iOtherEntity, PATTACH_POINT, 1); // If the rocket gets instantly destroyed, the temp ent still gets sent. Why?
                        
                        bool bCritical = !!GetEntProp(iEntity, Prop_Send, "m_bCritical");
                        if (bCritical)
                        {
                            int iRedCriticalEntity = CreateEntityByName("info_particle_system");
                            int iBluCriticalEntity = CreateEntityByName("info_particle_system");
                            
                            if ((iRedCriticalEntity && IsValidEdict(iRedCriticalEntity)) && (iBluCriticalEntity && IsValidEdict(iBluCriticalEntity)))
                            {
                                TeleportEntity(iRedCriticalEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                                TeleportEntity(iBluCriticalEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                                
                                DispatchKeyValue(iRedCriticalEntity, "effect_name", "critical_rocket_red");
                                DispatchKeyValue(iBluCriticalEntity, "effect_name", "critical_rocket_blue");
                                
                                g_iRocketRedCriticalEntity[iIndex] = EntIndexToEntRef(iRedCriticalEntity);
                                g_iRocketBluCriticalEntity[iIndex] = EntIndexToEntRef(iBluCriticalEntity);
                                
                                DispatchSpawn(iRedCriticalEntity);
                                DispatchSpawn(iBluCriticalEntity);
                                
                                ActivateEntity(iRedCriticalEntity);
                                ActivateEntity(iBluCriticalEntity);
                                
                                SetVariantString("!activator");
                                AcceptEntityInput(iRedCriticalEntity, "SetParent", iOtherEntity, iRedCriticalEntity);
                                
                                SetVariantString("!activator");
                                AcceptEntityInput(iBluCriticalEntity, "SetParent", iOtherEntity, iBluCriticalEntity);
                                
                                SetVariantString("trail");
                                AcceptEntityInput(iRedCriticalEntity, "SetParentAttachment", iOtherEntity, iRedCriticalEntity);
                                
                                SetVariantString("trail");
                                AcceptEntityInput(iBluCriticalEntity, "SetParentAttachment", iOtherEntity, iBluCriticalEntity);
                                
                                if (iTeam == view_as<int>(TFTeam_Red))
                                {
                                    AcceptEntityInput(iRedCriticalEntity, "Start");
                                }
                                else if (iTeam == view_as<int>(TFTeam_Blue))
                                {
                                    AcceptEntityInput(iBluCriticalEntity, "Start");
                                }
                            }
                        }
                    }
                }
            }
            
            if (TestFlags(iFlags, RocketFlag_CustomTrail))
            {
                int iTrailEntity = CreateEntityByName("info_particle_system");
                if (iTrailEntity && IsValidEdict(iTrailEntity))
                {
                    TeleportEntity(iTrailEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                    DispatchKeyValue(iTrailEntity, "effect_name", g_strRocketClassTrail[iClass]);
                    DispatchSpawn(iTrailEntity);
                    ActivateEntity(iTrailEntity);
                    
                    if (TestFlags(iFlags, RocketFlag_RemoveParticles))
                    {
                        int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                        
                        if (iOtherEntity != -1)
                        {
                            SetVariantString("!activator");
                            AcceptEntityInput(iTrailEntity, "SetParent", iOtherEntity, iTrailEntity);
                            
                            SetVariantString("trail");
                            AcceptEntityInput(iTrailEntity, "SetParentAttachment", iOtherEntity, iTrailEntity);
                            
                            AcceptEntityInput(iTrailEntity, "Start");
                        }
                    }
                    else
                    {
                        SetVariantString("!activator");
                        AcceptEntityInput(iTrailEntity, "SetParent", iEntity, iTrailEntity);
                        
                        SetVariantString("trail");
                        AcceptEntityInput(iTrailEntity, "SetParentAttachment", iEntity, iTrailEntity);
                        
                        AcceptEntityInput(iTrailEntity, "Start");
                    }
                    
                    SetEdictFlags(iTrailEntity, (GetEdictFlags(iTrailEntity) & ~FL_EDICT_ALWAYS)); // Allows SetTransmit to work on info_particle_system
                    SDKHook(iTrailEntity, SDKHook_SetTransmit, TrailSetTransmit);
                }
            }
            
            if (TestFlags(iFlags, RocketFlag_CustomSprite))
            {
                int iSpriteEntity = CreateEntityByName("env_spritetrail");
                if (iSpriteEntity && IsValidEntity(iSpriteEntity))
                {
                    TeleportEntity(iSpriteEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                    
                    char strSpritePath[PLATFORM_MAX_PATH];
                    FormatEx(strSpritePath, PLATFORM_MAX_PATH, "%s.vmt", g_strRocketClassSprite[iClass]);
                    
                    DispatchKeyValue(iSpriteEntity, "spritename", strSpritePath);
                    DispatchKeyValueFloat(iSpriteEntity, "lifetime", g_fRocketClassSpriteLifetime[iClass] != 0 ? g_fRocketClassSpriteLifetime[iClass] : 1.0);
                    DispatchKeyValueFloat(iSpriteEntity, "endwidth", g_fRocketClassSpriteEndWidth[iClass] != 0 ? g_fRocketClassSpriteEndWidth[iClass] : 15.0);
                    DispatchKeyValueFloat(iSpriteEntity, "startwidth", g_fRocketClassSpriteStartWidth[iClass] != 0 ? g_fRocketClassSpriteStartWidth[iClass] : 6.0);
                    DispatchKeyValue(iSpriteEntity, "rendercolor", strlen(g_strRocketClassSpriteColor[iClass]) != 0 ? g_strRocketClassSpriteColor[iClass] : "255 255 255");
                    DispatchKeyValue(iSpriteEntity, "renderamt", "255");
                    DispatchKeyValue(iSpriteEntity, "rendermode", "3");
                    SetEntPropFloat(iSpriteEntity, Prop_Send, "m_flTextureRes", 0.05);
                    
                    if (TestFlags(iFlags, RocketFlag_RemoveParticles))
                    {
                        int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                        
                        if (iOtherEntity != -1)
                        {
                            SetVariantString("!activator");
                            AcceptEntityInput(iSpriteEntity, "SetParent", iOtherEntity, iSpriteEntity);
                            
                            SetVariantString("trail");
                            AcceptEntityInput(iSpriteEntity, "SetParentAttachment", iOtherEntity, iSpriteEntity);
                        }
                    }
                    else
                    {
                        SetVariantString("!activator");
                        AcceptEntityInput(iSpriteEntity, "SetParent", iEntity, iSpriteEntity);
                        
                        SetVariantString("trail");
                        AcceptEntityInput(iSpriteEntity, "SetParentAttachment", iEntity, iSpriteEntity);
                    }
                    
                    DispatchSpawn(iSpriteEntity);
                    SDKHook(iSpriteEntity, SDKHook_SetTransmit, SpriteSetTransmit);
                }
            }
            
            // Apply custom model, if specified on the flags.
            if (TestFlags(iFlags, RocketFlag_CustomModel))
            {
                SetEntityModel(iEntity, g_strRocketClassModel[iClass]);
                UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
                
                if (TestFlags(iFlags, RocketFlag_RemoveParticles))
                {
                    int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                    if (iOtherEntity != -1)
                    {
                        SetEntityModel(iOtherEntity, g_strRocketClassModel[iClass]);
                        UpdateRocketSkin(iOtherEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
                    }
                }
            }
            
            // Execute commands on spawn.
            if (TestFlags(iFlags, RocketFlag_OnSpawnCmd))
            {
                ExecuteCommands(g_hRocketClassCmdsOnSpawn[iClass], iClass, iEntity, 0, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], 0, g_fRocketMphSpeed[iIndex]);
            }
            
            // Emit required sounds.
            EmitRocketSound(RocketSound_Spawn, iClass, iEntity, iTarget, iFlags);
            EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
            
            // Done
            g_iRocketCount++;
            g_iRocketsFired++;
            g_fLastSpawnTime[iIndex] = GetGameTime();
            g_fNextSpawnTime = GetGameTime() + g_fSpawnersInterval[iSpawnerClass];
            
            SDKHook(iEntity, SDKHook_StartTouch, OnStartTouch);
            
            Forward_OnRocketCreated(iIndex, iEntity);
        }
    }
}

public Action TrailSetTransmit(int iEntity, int iClient)
{
	if (IsValidEntity(iEntity))
	{
		if(GetEdictFlags(iEntity) & FL_EDICT_ALWAYS)
		{
			SetEdictFlags(iEntity, (GetEdictFlags(iEntity) ^ FL_EDICT_ALWAYS)); // Stops the game from setting back the flag
		}
	}
	
	return g_bClientHideTrails[iClient] ? Plugin_Handled : Plugin_Continue;
}

public Action SpriteSetTransmit(int iEntity, int iClient)
{
	return g_bClientHideSprites[iClient] ? Plugin_Handled : Plugin_Continue;
}

/* DestroyRocket()
**
** Destroys the rocket at the given index.
** -------------------------------------------------------------------------- */
void DestroyRocket(int iIndex)
{
    if (IsValidRocket(iIndex) == true)
    {
        int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
        if (iEntity && IsValidEntity(iEntity)) RemoveEdict(iEntity);
        g_bRocketIsValid[iIndex] = false;
        g_iRocketCount--;
    }
}

/* DestroyRockets()
**
** Destroys all the rockets that are currently active.
** -------------------------------------------------------------------------- */
void DestroyRockets()
{
    for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
    {
        DestroyRocket(iIndex);
    }
    g_iRocketCount = 0;
}

/* IsValidRocket()
**
** Checks if a rocket structure is valid.
** -------------------------------------------------------------------------- */
bool IsValidRocket(int iIndex)
{
    if ((iIndex >= 0) && (g_bRocketIsValid[iIndex] == true))
    {
        if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == -1)
        {
            g_bRocketIsValid[iIndex] = false;
            g_iRocketCount--;
            return false;
        }
        return true;
    }
    return false;
}

/* FindNextValidRocket()
**
** Retrieves the index of the next valid rocket from the current offset.
** -------------------------------------------------------------------------- */
int FindNextValidRocket(int iIndex, bool bWrap = false)
{
    for (int iCurrent = iIndex + 1; iCurrent < MAX_ROCKETS; iCurrent++)
        if (IsValidRocket(iCurrent))
            return iCurrent;
        
    return (bWrap == true)? FindNextValidRocket(-1, false) : -1;
}

/* FindFreeRocketSlot()
**
** Retrieves the next free rocket slot since the current one. If all of them
** are full, returns -1.
** -------------------------------------------------------------------------- */
int FindFreeRocketSlot()
{
    int iCurrent = 0;
    
    do
    {
        if (!IsValidRocket(iCurrent)) return iCurrent;
        if ((++iCurrent) == MAX_ROCKETS) iCurrent = 0;
    } while (iCurrent != 0);
    
    return -1;
}

/* FindRocketByEntity()
**
** Finds a rocket index from it's entity.
** -------------------------------------------------------------------------- */
int FindRocketByEntity(int iEntity)
{
    int iIndex = -1;
    while ((iIndex = FindNextValidRocket(iIndex)) != -1)
        if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == iEntity)
            return iIndex;
        
    return -1;
}

/* HomingRocketThinkg()
**
** Logic process for the Behaviour_Homing type rockets, wich is simply a
** follower rocket, picking a random target.
** -------------------------------------------------------------------------- */
void HomingRocketThink(int iIndex)
{
    // Retrieve the rocket's attributes.
    int iEntity          = EntRefToEntIndex(g_iRocketEntity[iIndex]);
    int iClass           = g_iRocketClass[iIndex];
    RocketFlags iFlags   = g_iRocketFlags[iIndex];
    int iTarget          = EntRefToEntIndex(g_iRocketTarget[iIndex]);
    int iTeam            = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
    int iTargetTeam      = (TestFlags(iFlags, RocketFlag_IsNeutral))? 0 : GetAnalogueTeam(iTeam);
    int iDeflectionCount = g_iRocketEventDeflections[iIndex];
    float fModifier      = CalculateModifier(iClass, iDeflectionCount);
    
    if ((iDeflectionCount > g_iRocketAltDeflections[iIndex]))
    {
        int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
        g_bIsRocketDraggable[iIndex] = true;
        if (IsValidClient(iClient))
        {
            float fViewAngles[3], fDirection[3];
            GetClientEyeAngles(iClient, fViewAngles);
            GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
            CopyVectors(fDirection, g_fRocketDirection[iIndex]);
            UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
            
            if (TestFlags(iFlags, RocketFlag_RemoveParticles))
            {
                int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                if (iOtherEntity != -1)
                {
                    UpdateRocketSkin(iOtherEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
                }
            }
        }
        // Set new deflection count
        g_iRocketAltDeflections[iIndex]     = iDeflectionCount;
        g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
        
        Forward_OnRocketAltDeflect(iIndex, iEntity, iClient);
    }
    else
    {
        if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) <= g_fRocketClassDragTimeMax[iClass] + GetTickInterval())
        {
            if ((g_fRocketClassDragTimeMin[iClass] <= (GetGameTime() - g_fRocketLastDeflectionTime[iIndex])) && g_bIsRocketDraggable[iIndex])
            {
                int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
                if (IsValidClient(iClient))
                {
                    float fViewAngles[3], fDirection[3];
                    GetClientEyeAngles(iClient, fViewAngles);
                    GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
                    CopyVectors(fDirection, g_fRocketDirection[iIndex]);
                }
            }
        }
        else
        {
            // Check if the target is available
            if (!IsValidClient(iTarget, true))
            {
                int iOwner = iTarget;
                iTarget = SelectTarget(iTargetTeam);
                if (!IsValidClient(iTarget, true)) return;
                g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
                EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
                
                if (TestFlags(iFlags, RocketFlag_OnNoTargetCmd))
                {
                    int iClient = iOwner;
                    if (!IsValidClient(iClient))
                    {
                        iClient = 0;
                    }
                    
                    ExecuteCommands(g_hRocketClassCmdsOnNoTarget[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
                }
                
                if (g_hCvarNoTargetRedirectDamage.BoolValue)
                {
                    SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
                }
                
                Forward_OnRocketNoTarget(iIndex, iTarget, iOwner);
            }
            // Has the rocket been deflected recently? If so, set new target.
            else if ((iDeflectionCount > g_iRocketDeflections[iIndex]))
            {
                // Calculate new direction from the player's forward
                int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
                g_bIsRocketStolen[iIndex] = false;
                if (IsValidClient(iClient))
                {
                    if (!(iFlags & RocketFlag_CanBeStolen))
                    {
                        CheckStolenRocket(iClient, iIndex);
                    }
                }
                else
                {
                    iClient = 0;
                }
                
                // Set new target & deflection count
                iTarget = SelectTarget(iTargetTeam, iIndex);
                g_iRocketTarget[iIndex]      = EntIndexToEntRef(iTarget);
                g_iRocketDeflections[iIndex] = iDeflectionCount;
                g_fRocketSpeed[iIndex]       = CalculateRocketSpeed(iClass, fModifier);
                g_fRocketMphSpeed[iIndex]    = CalculateRocketSpeed(iClass, fModifier) * 0.042614;
                g_bPreventingDelay[iIndex]   = false;
                SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
                if (TestFlags(iFlags, RocketFlag_ElevateOnDeflect)) g_iRocketFlags[iIndex] |= RocketFlag_Elevating;
                
                int iTargetRef = iTarget;
                
                Action aResult = Forward_OnRocketDeflectPre(iIndex, iEntity, iClient, iTargetRef);
                
                if (aResult == Plugin_Stop || aResult == Plugin_Handled)
                {
                    return;
                }
                else if (aResult == Plugin_Changed)
                {
                    iTarget = iTargetRef;
                    g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
                }
                
                EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
                
                if (iFlags & RocketFlag_IsSpeedLimited)
                {
                    if (g_fRocketSpeed[iIndex] >= g_fRocketClassSpeedLimit[iClass])
                    {
                        g_fRocketSpeed[iIndex] = g_fRocketClassSpeedLimit[iClass];
                    }
                }
                
                if (g_bIsRocketStolen[iIndex] && g_hCvarStealPreventionDamage.BoolValue)
                {
                    SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
                }
                
                if (iFlags & RocketFlag_TeamlessHits)
                {
                    SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
                }
                
                // Execute appropiate command
                if (TestFlags(iFlags, RocketFlag_OnDeflectCmd))
                {
                    ExecuteCommands(g_hRocketClassCmdsOnDeflect[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
                }
                
                Forward_OnRocketDeflect(iIndex, iEntity, iClient);
            }
            // If the delay time since the last reflection has been elapsed, rotate towards the client.
            else
            {
                if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= g_fRocketClassControlDelay[iClass])
                {
                    // Calculate turn rate and retrieve directions.
                    float fTurnRate = CalculateRocketTurnRate(iClass, fModifier) / g_fTickModifier;
                    float fDirectionToTarget[3]; CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);
                    
                    if (g_iRocketFlags[iIndex] & RocketFlag_Elevating)
                    {
                        fDirectionToTarget[2] = g_fRocketDirection[iIndex][2];
                    }
                    
                    if (g_iRocketFlags[iIndex] & RocketFlag_IsTRLimited)
                    {
                        if (fTurnRate >= g_fRocketClassTurnRateLimit[iClass] / g_fTickModifier)
                        {
                            fTurnRate = g_fRocketClassTurnRateLimit[iClass] / g_fTickModifier;
                        }
                    }
                    
                    // Smoothly change the orientation to the new one.
                    LerpVectors(g_fRocketDirection[iIndex], fDirectionToTarget, g_fRocketDirection[iIndex], fTurnRate);
                }
            }
        }
    }
    // Done
    if (!g_bIsRocketBouncing[iIndex])
    {
        ApplyRocketParameters(iIndex);
    }
}

void RocketOtherThink(int iIndex)
{
    // Retrieve the rocket's attributes.
    int iEntity          = EntRefToEntIndex(g_iRocketEntity[iIndex]);
    int iClass           = g_iRocketClass[iIndex];
    RocketFlags iFlags   = g_iRocketFlags[iIndex];
    int iTarget          = EntRefToEntIndex(g_iRocketTarget[iIndex]);
    int iDeflectionCount = g_iRocketEventDeflections[iIndex];
    
    if (!(iDeflectionCount > g_iRocketDeflections[iIndex]))
    {
        if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= g_fRocketClassControlDelay[iClass])
        {
            // Elevate the rocket after a deflection (if it's enabled on the class definition, of course.)
            if (g_iRocketFlags[iIndex] & RocketFlag_Elevating)
            {
                if (g_fRocketDirection[iIndex][2] < g_fRocketClassElevationLimit[iClass])
                {
                    g_fRocketDirection[iIndex][2] = FMin(g_fRocketDirection[iIndex][2] + g_fRocketClassElevationRate[iClass], g_fRocketClassElevationLimit[iClass]);
                }
                else
                {
                    g_iRocketFlags[iIndex] &= ~RocketFlag_Elevating;
                }
            }
        }
        
        // If it's a nuke, beep every some time
        if ((GetGameTime() - g_fRocketLastBeepTime[iIndex]) >= g_fRocketClassBeepInterval[iClass])
        {
            EmitRocketSound(RocketSound_Beep, iClass, iEntity, iTarget, iFlags);
            g_fRocketLastBeepTime[iIndex] = GetGameTime();
        }
        
        if (g_hCvarDelayPrevention.BoolValue)
        {
            CheckRoundDelays(iIndex);
        }
    }
    
    g_bIsRocketBouncing[iIndex] = false;
}

void RocketLegacyThink(int iIndex)
{
    // Retrieve the rocket's attributes.
    int iEntity          = EntRefToEntIndex(g_iRocketEntity[iIndex]);
    int iClass           = g_iRocketClass[iIndex];
    RocketFlags iFlags   = g_iRocketFlags[iIndex];
    int iTarget          = EntRefToEntIndex(g_iRocketTarget[iIndex]);
    int iTeam            = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
    int iTargetTeam      = (TestFlags(iFlags, RocketFlag_IsNeutral))? 0 : GetAnalogueTeam(iTeam);
    int iDeflectionCount = g_iRocketEventDeflections[iIndex];
    float fModifier      = CalculateModifier(iClass, iDeflectionCount);
    
    // Check if the target is available
    if (!IsValidClient(iTarget, true))
    {
        int iOwner = iTarget;
        iTarget = SelectTarget(iTargetTeam);
        if (!IsValidClient(iTarget, true)) return;
        g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
        EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
        
        if (TestFlags(iFlags, RocketFlag_OnNoTargetCmd))
        {
            int iClient = iOwner;
            if (!IsValidClient(iClient))
            {
                iClient = 0;
            }
            
            ExecuteCommands(g_hRocketClassCmdsOnNoTarget[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
        }
        
        if (g_hCvarNoTargetRedirectDamage.BoolValue)
        {
            SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
        }
        
        Forward_OnRocketNoTarget(iIndex, iTarget, iOwner);
    }
    // Has the rocket been deflected recently? If so, set new target.
    else if ((iDeflectionCount > g_iRocketDeflections[iIndex]))
    {
        // Calculate new direction from the player's forward
        int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
        g_bIsRocketStolen[iIndex] = false;
        if (IsValidClient(iClient))
        {
            float fViewAngles[3], fDirection[3];
            GetClientEyeAngles(iClient, fViewAngles);
            GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
            CopyVectors(fDirection, g_fRocketDirection[iIndex]);
            UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
            if (!(iFlags & RocketFlag_CanBeStolen))
            {
                CheckStolenRocket(iClient, iIndex);
            }
            
            if (TestFlags(iFlags, RocketFlag_RemoveParticles))
            {
                int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                if (iOtherEntity != -1)
                {
                    UpdateRocketSkin(iOtherEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
                }
            }
        }
        else
        {
            iClient = 0;
        }
        
        // Set new target & deflection count
        iTarget = SelectTarget(iTargetTeam, iIndex);
        g_iRocketTarget[iIndex]             = EntIndexToEntRef(iTarget);
        g_iRocketDeflections[iIndex]        = iDeflectionCount;
        g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
        g_fRocketSpeed[iIndex]              = CalculateRocketSpeed(iClass, fModifier);
        g_fRocketMphSpeed[iIndex]           = CalculateRocketSpeed(iClass, fModifier) * 0.042614;
        g_bPreventingDelay[iIndex]          = false;
        SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
        if (TestFlags(iFlags, RocketFlag_ElevateOnDeflect)) g_iRocketFlags[iIndex] |= RocketFlag_Elevating;
        
        int iTargetRef = iTarget;
        
        Action aResult = Forward_OnRocketDeflectPre(iIndex, iEntity, iClient, iTargetRef);
        
        if (aResult == Plugin_Stop || aResult == Plugin_Handled)
        {
            return;
        }
        else if (aResult == Plugin_Changed)
        {
            iTarget = iTargetRef;
            g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
        }
        
        EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
        
        if(iFlags & RocketFlag_IsSpeedLimited)
        {
            if (g_fRocketSpeed[iIndex] >= g_fRocketClassSpeedLimit[iClass])
            {
                g_fRocketSpeed[iIndex] = g_fRocketClassSpeedLimit[iClass];
            }
        }
        
        if(g_bIsRocketStolen[iIndex] && g_hCvarStealPreventionDamage.BoolValue)
        {
            SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
        }
        
        if (iFlags & RocketFlag_TeamlessHits)
        {
            SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
        }
        
        // Execute appropiate command
        if (TestFlags(iFlags, RocketFlag_OnDeflectCmd))
        {
            ExecuteCommands(g_hRocketClassCmdsOnDeflect[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
        }
        
        Forward_OnRocketDeflect(iIndex, iEntity, iClient);
    }
    else
    {
        // If the delay time since the last reflection has been elapsed, rotate towards the client.
        if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= g_fRocketClassControlDelay[iClass])
        {
            // Calculate turn rate and retrieve directions.
            float fTurnRate = CalculateRocketTurnRate(iClass, fModifier);
            float fDirectionToTarget[3]; CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);
            
            // Elevate the rocket after a deflection (if it's enabled on the class definition, of course.)
            if (g_iRocketFlags[iIndex] & RocketFlag_Elevating)
            {
                if (g_fRocketDirection[iIndex][2] < g_fRocketClassElevationLimit[iClass])
                {
                    g_fRocketDirection[iIndex][2] = FMin(g_fRocketDirection[iIndex][2] + g_fRocketClassElevationRate[iClass], g_fRocketClassElevationLimit[iClass]);
                    fDirectionToTarget[2] = g_fRocketDirection[iIndex][2];
                }
                else
                {
                    g_iRocketFlags[iIndex] &= ~RocketFlag_Elevating;
                }
            }
            
            if(g_iRocketFlags[iIndex] & RocketFlag_IsTRLimited)
            {
                if (fTurnRate >= g_fRocketClassTurnRateLimit[iClass])
                {
                    fTurnRate = g_fRocketClassTurnRateLimit[iClass];
                }
            }
            
            // Smoothly change the orientation to the new one.
            LerpVectors(g_fRocketDirection[iIndex], fDirectionToTarget, g_fRocketDirection[iIndex], fTurnRate);
        }
        
        // If it's a nuke, beep every some time
        if ((GetGameTime() - g_fRocketLastBeepTime[iIndex]) >= g_fRocketClassBeepInterval[iClass])
        {
            EmitRocketSound(RocketSound_Beep, iClass, iEntity, iTarget, iFlags);
            g_fRocketLastBeepTime[iIndex] = GetGameTime();
        }
        
        if (g_hCvarDelayPrevention.BoolValue)
        {
            CheckRoundDelays(iIndex);
        }
    }
    
    // Done
    ApplyRocketParameters(iIndex);
}

/* CalculateModifier()
**
** Gets the modifier for the damage/speed/rotation calculations.
** -------------------------------------------------------------------------- */
float CalculateModifier(int iClass, int iDeflections)
{
    return  iDeflections + 
            (g_iRocketsFired * g_fRocketClassRocketsModifier[iClass]) + 
            (g_iPlayerCount * g_fRocketClassPlayerModifier[iClass]);
}

/* CalculateRocketDamage()
**
** Calculates the damage of the rocket based on it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketDamage(int iClass, float fModifier)
{
    return g_fRocketClassDamage[iClass] + g_fRocketClassDamageIncrement[iClass] * fModifier;
}

/* CalculateRocketSpeed()
**
** Calculates the speed of the rocket based on it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketSpeed(int iClass, float fModifier)
{
    return g_fRocketClassSpeed[iClass] + g_fRocketClassSpeedIncrement[iClass] * fModifier;
}

/* CalculateRocketTurnRate()
**
** Calculates the rocket's turn rate based upon it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketTurnRate(int iClass, float fModifier)
{
    return g_fRocketClassTurnRate[iClass] + g_fRocketClassTurnRateIncrement[iClass] * fModifier;
}

/* CalculateDirectionToClient()
**
** As the name indicates, calculates the orientation for the rocket to move
** towards the specified client.
** -------------------------------------------------------------------------- */
void CalculateDirectionToClient(int iEntity, int iClient, float fOut[3])
{
    float fRocketPosition[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
    GetClientEyePosition(iClient, fOut);
    MakeVectorFromPoints(fRocketPosition, fOut, fOut);
    NormalizeVector(fOut, fOut);
}

/* ApplyRocketParameters()
**
** Transforms and applies the speed, direction and angles for the rocket
** entity.
** -------------------------------------------------------------------------- */
void ApplyRocketParameters(int iIndex)
{
    int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
    float fAngles[3]; GetVectorAngles(g_fRocketDirection[iIndex], fAngles);
    float fVelocity[3]; CopyVectors(g_fRocketDirection[iIndex], fVelocity);
    ScaleVector(fVelocity, g_fRocketSpeed[iIndex]);
    SetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fVelocity);
    SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
}

/* UpdateRocketSkin()
**
** Changes the skin of the rocket based on it's team.
** -------------------------------------------------------------------------- */
void UpdateRocketSkin(int iEntity, int iTeam, bool bNeutral)
{
    if (bNeutral == true) SetEntProp(iEntity, Prop_Send, "m_nSkin", 2);
    else                  SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam == view_as<int>(TFTeam_Blue))? 0 : 1);
}

/* GetRandomRocketClass()
**
** Generates a random value and retrieves a rocket class based upon a chances table.
** -------------------------------------------------------------------------- */
int GetRandomRocketClass(int iSpawnerClass)
{
    int iRandom = GetURandomIntRange(1, 100);
    ArrayList hTable = g_hSpawnersChancesTable[iSpawnerClass];
    int iTableSize = hTable.Length;
    int iChancesLower = 0;
    int iChancesUpper = 0;
    
    for (int iEntry = 0; iEntry < iTableSize; iEntry++)
    {
        iChancesLower += iChancesUpper;
        iChancesUpper  = iChancesLower + hTable.Get(iEntry);
        
        if ((iRandom >= iChancesLower) && (iRandom <= iChancesUpper))
        {
            return iEntry;
        }
    }
    
    return 0;
}

/* EmitRocketSound()
**
** Emits one of the rocket sounds
** -------------------------------------------------------------------------- */
void EmitRocketSound(RocketSound iSound, int iClass, int iEntity, int iTarget, RocketFlags iFlags)
{
    switch (iSound)
    {
        case RocketSound_Spawn:
        {
            if (TestFlags(iFlags, RocketFlag_PlaySpawnSound))
            {
                if (TestFlags(iFlags, RocketFlag_CustomSpawnSound)) EmitSoundToAll(g_strRocketClassSpawnSound[iClass], iEntity);
                else                                                EmitSoundToAll(SOUND_DEFAULT_SPAWN, iEntity);
            }
        }
        case RocketSound_Beep:
        {
            if (TestFlags(iFlags, RocketFlag_PlayBeepSound))
            {
                if (TestFlags(iFlags, RocketFlag_CustomBeepSound)) EmitSoundToAll(g_strRocketClassBeepSound[iClass], iEntity);
                else                                               EmitSoundToAll(SOUND_DEFAULT_BEEP, iEntity);
            }
        }
        case RocketSound_Alert:
        {
            if (TestFlags(iFlags, RocketFlag_PlayAlertSound))
            {
                if (TestFlags(iFlags, RocketFlag_CustomAlertSound)) EmitSoundToClient(iTarget, g_strRocketClassAlertSound[iClass]);
                else                                                EmitSoundToClient(iTarget, SOUND_DEFAULT_ALERT, _, _, _, _, 0.5);
            }
        }
    }
}

//  ___         _       _      ___ _                    
// | _ \___  __| |_____| |_   / __| |__ _ ______ ___ ___
// |   / _ \/ _| / / -_)  _| | (__| / _` (_-<_-</ -_|_-<
// |_|_\___/\__|_\_\___|\__|  \___|_\__,_/__/__/\___/__/
//                                                      

/* DestroyRocketClasses()
**
** Frees up all the rocket classes defined now.
** -------------------------------------------------------------------------- */
void DestroyRocketClasses()
{
    for (int iIndex = 0; iIndex < g_iRocketClassCount; iIndex++)
    {
        DataPack hCmdOnSpawn   = g_hRocketClassCmdsOnSpawn[iIndex];
        DataPack hCmdOnKill    = g_hRocketClassCmdsOnKill[iIndex];
        DataPack hCmdOnExplode = g_hRocketClassCmdsOnExplode[iIndex];
        DataPack hCmdOnDeflect = g_hRocketClassCmdsOnDeflect[iIndex];
        DataPack hCmdOnNoTarget = g_hRocketClassCmdsOnNoTarget[iIndex];
        if (hCmdOnSpawn   != null) delete hCmdOnSpawn;
        if (hCmdOnKill    != null) delete hCmdOnKill;
        if (hCmdOnExplode != null) delete hCmdOnExplode;
        if (hCmdOnDeflect != null) delete hCmdOnDeflect;
        if (hCmdOnNoTarget != null) delete hCmdOnNoTarget;
        g_hRocketClassCmdsOnSpawn[iIndex]   = null;
        g_hRocketClassCmdsOnKill[iIndex]    = null;
        g_hRocketClassCmdsOnExplode[iIndex] = null;
        g_hRocketClassCmdsOnDeflect[iIndex] = null;
        g_hRocketClassCmdsOnNoTarget[iIndex] = null;
    }
    g_iRocketClassCount = 0;
    g_hRocketClassTrie.Clear();
}

//  ___                          ___     _     _                     _    ___ _                    
// / __|_ __  __ ___ __ ___ _   | _ \___(_)_ _| |_ ___  __ _ _ _  __| |  / __| |__ _ ______ ___ ___
// \__ \ '_ \/ _` \ V  V / ' \  |  _/ _ \ | ' \  _(_-< / _` | ' \/ _` | | (__| / _` (_-<_-</ -_|_-<
// |___/ .__/\__,_|\_/\_/|_||_| |_| \___/_|_||_\__/__/ \__,_|_||_\__,_|  \___|_\__,_/__/__/\___/__/
//     |_|                                                                                         

/* DestroySpawners()
**
** Frees up all the spawner points defined up to now.
** -------------------------------------------------------------------------- */
void DestroySpawners()
{
    for (int iIndex = 0; iIndex < g_iSpawnersCount; iIndex++)
    {
        delete g_hSpawnersChancesTable[iIndex];
        delete g_hSavedChancesTable[iIndex];
    }
    g_iSpawnersCount  = 0;
    g_iSpawnPointsRedCount = 0;
    g_iSpawnPointsBluCount = 0;
    g_iDefaultRedSpawner = -1;
    g_iDefaultBluSpawner = -1;
    g_hSpawnersTrie.Clear();
}

/* PopulateSpawnPoints()
**
** Iterates through all the possible spawn points and assigns them an spawner.
** -------------------------------------------------------------------------- */
void PopulateSpawnPoints()
{
    // Clear the current settings
    g_iSpawnPointsRedCount = 0;
    g_iSpawnPointsBluCount = 0;
    
    // Iterate through all the info target points and check 'em out.
    int iEntity = -1;
    while ((iEntity = FindEntityByClassname(iEntity, "info_target")) != -1)
    {
        char strName[32]; GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
        if ((StrContains(strName, "rocket_spawn_red") != -1) || (StrContains(strName, "tf_dodgeball_red") != -1))
        {
            // Find most appropiate spawner class for this entity.
            int iIndex = FindSpawnerByName(strName);
            if (!IsValidRocket(iIndex)) iIndex = g_iDefaultRedSpawner;
            
            // Upload to point list
            g_iSpawnPointsRedClass [g_iSpawnPointsRedCount] = iIndex;
            g_iSpawnPointsRedEntity[g_iSpawnPointsRedCount] = iEntity;
            g_iSpawnPointsRedCount++;
        }
        if ((StrContains(strName, "rocket_spawn_blu") != -1) || (StrContains(strName, "tf_dodgeball_blu") != -1))
        {
            // Find most appropiate spawner class for this entity.
            int iIndex = FindSpawnerByName(strName);
            if (!IsValidRocket(iIndex)) iIndex = g_iDefaultBluSpawner;
            
            // Upload to point list
            g_iSpawnPointsBluClass [g_iSpawnPointsBluCount] = iIndex;
            g_iSpawnPointsBluEntity[g_iSpawnPointsBluCount] = iEntity;
            g_iSpawnPointsBluCount++;
        }
    }
    
    // Check if there exists spawn points
    if (g_iSpawnPointsRedCount == 0) SetFailState("No RED spawn points found on this map.");
    if (g_iSpawnPointsBluCount == 0) SetFailState("No BLU spawn points found on this map.");
}

/* FindSpawnerByName()
**
** Finds the first spawner wich contains the given name.
** -------------------------------------------------------------------------- */
int FindSpawnerByName(char strName[32])
{
    int iIndex = -1;
    g_hSpawnersTrie.GetValue(strName, iIndex);
    return iIndex;
}        


/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**    ______                                          __    
**   / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
**  / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
** / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  ) 
** \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/  
**                                                          
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* RegisterCommands()
**
** Creates helper server commands to use with the plugin's events system.
** -------------------------------------------------------------------------- */
void RegisterCommands()
{
    RegServerCmd("tf_dodgeball_explosion", CmdExplosion);
    RegServerCmd("tf_dodgeball_shockwave", CmdShockwave);
    RegAdminCmd("tf_dodgeball_rocketspeed", CmdChangeSpeed, ADMFLAG_CONFIG, "Change rocket speed parameters.");
    RegAdminCmd("tf_dodgeball_rocketturnrate", CmdChangeTurnRate, ADMFLAG_CONFIG, "Change rocket turnrate parameters.");
    RegAdminCmd("tf_dodgeball_rocketelevation", CmdChangeElevation, ADMFLAG_CONFIG, "Change rocket elevation parameters.");
    RegAdminCmd("tf_dodgeball_spawners", CmdChangeSpawners, ADMFLAG_CONFIG, "Change the spawners' settings.");
    RegAdminCmd("tf_dodgeball_refresh", CmdRefresh, ADMFLAG_CONFIG, "Refresh the configuration.");
    RegAdminCmd("tf_dodgeball_destroyrockets", CmdDestroyRockets, ADMFLAG_CONFIG, "Destroy all current rockets.");
    RegAdminCmd("tf_dodgeball_rocketotherparams", CmdOtherParams, ADMFLAG_CONFIG, "Change other rocket parameters.");
    RegAdminCmd("tf_dodgeball_rocketdragparams", CmdDragParams, ADMFLAG_CONFIG, "Change rocket drag parameters.");
    RegConsoleCmd("sm_togglerockettrails", CmdHideTrails);
    RegConsoleCmd("sm_togglerocketsprites", CmdHideSprites);
}

/* CmdExplosion()
**
** Creates a huge explosion at the location of the client.
** -------------------------------------------------------------------------- */
public Action CmdExplosion(int iArgs)
{
    if (iArgs == 1 && g_bEnabled)
    {
        char strBuffer[8]; int iClient;
        GetCmdArg(1, strBuffer, sizeof(strBuffer));
        iClient = StringToInt(strBuffer);
        if (IsValidEntity(iClient))
        {
            float fPosition[3]; GetClientAbsOrigin(iClient, fPosition);
            switch (GetURandomIntRange(0, 4))
            {
                case 0: { PlayParticle(fPosition, PARTICLE_NUKE_1_ANGLES, PARTICLE_NUKE_1); }
                case 1: { PlayParticle(fPosition, PARTICLE_NUKE_2_ANGLES, PARTICLE_NUKE_2); }
                case 2: { PlayParticle(fPosition, PARTICLE_NUKE_3_ANGLES, PARTICLE_NUKE_3); }
                case 3: { PlayParticle(fPosition, PARTICLE_NUKE_4_ANGLES, PARTICLE_NUKE_4); }
                case 4: { PlayParticle(fPosition, PARTICLE_NUKE_5_ANGLES, PARTICLE_NUKE_5); }
            }
            PlayParticle(fPosition, PARTICLE_NUKE_COLLUMN_ANGLES, PARTICLE_NUKE_COLLUMN);
        }
    }
    else
    {
        PrintToServer("%t", g_bEnabled ? "Command_DBExplosion_Usage" : "Command_Disabled");
    }
    
    return Plugin_Handled;
}

/* CmdShockwave()
**
** Creates a huge shockwave at the location of the client, with the given
** parameters.
** -------------------------------------------------------------------------- */
public Action CmdShockwave(int iArgs)
{
    if (iArgs == 5 && g_bEnabled)
    {
        char strBuffer[8]; int iClient, iTeam; float fPosition[3]; int iDamage; float fPushStrength, fRadius, fFalloffRadius;
        GetCmdArg(1, strBuffer, sizeof(strBuffer)); iClient        = StringToInt(strBuffer);
        GetCmdArg(2, strBuffer, sizeof(strBuffer)); iDamage        = StringToInt(strBuffer);
        GetCmdArg(3, strBuffer, sizeof(strBuffer)); fPushStrength  = StringToFloat(strBuffer);
        GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRadius        = StringToFloat(strBuffer);
        GetCmdArg(5, strBuffer, sizeof(strBuffer)); fFalloffRadius = StringToFloat(strBuffer);
        
        if (IsValidClient(iClient))
        {
            iTeam = GetClientTeam(iClient);
            GetClientAbsOrigin(iClient, fPosition);
            
            for (iClient = 1; iClient <= MaxClients; iClient++)
            {
                if ((IsValidClient(iClient, true) == true) && (GetClientTeam(iClient) == iTeam))
                {
                    float fPlayerPosition[3]; GetClientEyePosition(iClient, fPlayerPosition);
                    float fDistanceToShockwave = GetVectorDistance(fPosition, fPlayerPosition);
                    
                    if (fDistanceToShockwave < fRadius)
                    {
                        float fImpulse[3], fFinalPush; int iFinalDamage;
                        fImpulse[0] = fPlayerPosition[0] - fPosition[0];
                        fImpulse[1] = fPlayerPosition[1] - fPosition[1];
                        fImpulse[2] = fPlayerPosition[2] - fPosition[2];
                        NormalizeVector(fImpulse, fImpulse);
                        if (fImpulse[2] < 0.4) { fImpulse[2] = 0.4; NormalizeVector(fImpulse, fImpulse); }
                        
                        if (fDistanceToShockwave < fFalloffRadius)
                        {
                            fFinalPush = fPushStrength;
                            iFinalDamage = iDamage;
                        }
                        else
                        {
                            float fImpact = (1.0 - ((fDistanceToShockwave - fFalloffRadius) / (fRadius - fFalloffRadius)));
                            fFinalPush   = fImpact * fPushStrength;
                            iFinalDamage = RoundToFloor(fImpact * iDamage);
                        }
                        ScaleVector(fImpulse, fFinalPush);
                        SlapPlayer(iClient, iFinalDamage, true);
                        SetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", fImpulse);
                    }
                }
            }
        }
    }
    else
    {
        PrintToServer("%t", g_bEnabled ? "Command_DBShockwave_Usage" : "Command_Disabled");
    }
    
    return Plugin_Handled;
}

public Action CmdChangeSpeed(int iClient, int iArgs)
{
	if (iArgs == 4 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex; float fRocketSpeed, fRocketSpeedIncrement, fRocketSpeedLimit;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex                = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); fRocketSpeed          = StringToFloat(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fRocketSpeedIncrement = StringToFloat(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRocketSpeedLimit     = StringToFloat(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		if (fRocketSpeedLimit == 0)
		{
			if (g_iRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited)
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsSpeedLimited;
			}
		}
		else if (fRocketSpeedLimit == -1)
		{
			g_fRocketClassSpeedLimit[iIndex] = g_fSavedParameters[iIndex][2];
			
			if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited) && !(g_iRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_IsSpeedLimited;
			}
			else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited) && (g_iRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited))
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsSpeedLimited;
			}
		}
		else
		{
			if (!(g_iRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_IsSpeedLimited;
			}
			
			g_fRocketClassSpeedLimit[iIndex]  = fRocketSpeedLimit;
		}
		
		g_fRocketClassSpeed[iIndex]          = fRocketSpeed == -1 ? g_fSavedParameters[iIndex][0] : fRocketSpeed;
		g_fRocketClassSpeedIncrement[iIndex] = fRocketSpeedIncrement == -1 ? g_fSavedParameters[iIndex][1] : fRocketSpeedIncrement;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketSpeed_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdChangeTurnRate(int iClient, int iArgs)
{
	if (iArgs == 4 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex; float fRocketTurnRate, fRocketTurnRateIncrement, fRocketTurnRateLimit;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex                   = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); fRocketTurnRate          = StringToFloat(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fRocketTurnRateIncrement = StringToFloat(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRocketTurnRateLimit     = StringToFloat(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		if (fRocketTurnRateLimit == 0)
		{
			if (g_iRocketClassFlags[iIndex] & RocketFlag_IsTRLimited)
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsTRLimited;
			}
		}
		else if (fRocketTurnRateLimit == -1)
		{
			g_fRocketClassTurnRateLimit[iIndex] = g_fSavedParameters[iIndex][5];
			
			if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsTRLimited) && !(g_iRocketClassFlags[iIndex] & RocketFlag_IsTRLimited))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_IsTRLimited;
			}
			else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsTRLimited) && (g_iRocketClassFlags[iIndex] & RocketFlag_IsTRLimited))
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsTRLimited;
			}
		}
		else
		{
			if (!(g_iRocketClassFlags[iIndex] & RocketFlag_IsTRLimited))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_IsTRLimited;
			}
			
			g_fRocketClassTurnRateLimit[iIndex]  = fRocketTurnRateLimit;
		}
		
		g_fRocketClassTurnRate[iIndex]          = fRocketTurnRate == -1 ? g_fSavedParameters[iIndex][3] : fRocketTurnRate;
		g_fRocketClassTurnRateIncrement[iIndex] = fRocketTurnRateIncrement == -1 ? g_fSavedParameters[iIndex][4] : fRocketTurnRateIncrement;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketTurnRate_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdChangeElevation(int iClient, int iArgs)
{
	if (iArgs == 3 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex; float fRocketElevationRate, fRocketElevationLimit;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex                = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); fRocketElevationRate  = StringToFloat(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fRocketElevationLimit = StringToFloat(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		if (fRocketElevationLimit == 0)
		{
			if (g_iRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect)
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_ElevateOnDeflect;
				g_iRocketFlags[iIndex]      &= ~RocketFlag_Elevating;
			}
		}
		else if (fRocketElevationLimit == -1)
		{
			g_fRocketClassElevationLimit[iIndex] = g_fSavedParameters[iIndex][7];
			
			if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect) && !(g_iRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_ElevateOnDeflect;
			}
			else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect) && (g_iRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect))
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_ElevateOnDeflect;
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_Elevating;
			}
		}
		else
		{
			if (!(g_iRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_ElevateOnDeflect;
			}
			
			g_fRocketClassElevationLimit[iIndex] = fRocketElevationLimit;
		}
		
		g_fRocketClassElevationRate[iIndex] = fRocketElevationRate == -1 ? g_fSavedParameters[iIndex][6] : fRocketElevationRate;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketElevation_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdChangeSpawners(int iClient, int iArgs)
{
	if (iArgs == 3 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex, iMaxRockets, iChances;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iMaxRockets = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); iIndex      = StringToInt(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); iChances    = StringToInt(strBuffer);
		
		int iSpawnerClassBlu = g_iSpawnPointsBluClass[g_iCurrentBluSpawn];
		g_iSpawnersMaxRockets[iSpawnerClassBlu] = iMaxRockets;
		
		int iSpawnerClassRed = g_iSpawnPointsRedClass[g_iCurrentRedSpawn];
		g_iSpawnersMaxRockets[iSpawnerClassRed] = iMaxRockets;
		
		int iTableSizeBlu = g_hSpawnersChancesTable[iSpawnerClassBlu].Length;
		int iTableSizeRed = g_hSpawnersChancesTable[iSpawnerClassRed].Length;
		
		if ((iIndex >= iTableSizeBlu) || (iIndex >= iTableSizeRed) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		if (iChances == -1)
		{
			int iDefaultChancesBlu = g_hSavedChancesTable[iSpawnerClassBlu].Get(iIndex);
			int iDefaultChancesRed = g_hSavedChancesTable[iSpawnerClassRed].Get(iIndex);
			
			g_hSpawnersChancesTable[iSpawnerClassBlu].Set(iIndex, iDefaultChancesBlu);
			g_hSpawnersChancesTable[iSpawnerClassRed].Set(iIndex, iDefaultChancesRed);
		}
		else
		{
			g_hSpawnersChancesTable[iSpawnerClassBlu].Set(iIndex, iChances);
			g_hSpawnersChancesTable[iSpawnerClassRed].Set(iIndex, iChances);
		}
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBSpawners_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdRefresh(int iClient, int iArgs)
{
	if (!iArgs && g_bEnabled)
	{
		// Clean up everything
		DestroyRocketClasses();
		DestroySpawners();
		// Then reinitialize
		char strMapName[64]; GetCurrentMap(strMapName, sizeof(strMapName));
		char strMapFile[PLATFORM_MAX_PATH]; FormatEx(strMapFile, sizeof(strMapFile), "%s.cfg", strMapName);
		ParseConfigurations();
		ParseConfigurations(strMapFile);
		PopulateSpawnPoints();
		CPrintToChatAll("%t", "Command_DBRefresh_Done", iClient);
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRefresh_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdDestroyRockets(int iClient, int iArgs)
{
	if (!iArgs && g_bEnabled)
	{
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketDestroy_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdOtherParams(int iClient, int iArgs)
{
	if (iArgs == 6 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex, bIsNeutral, bKeepDirection, bTeamlessHits, bResetBounces, iMaxBounces;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex         = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); bIsNeutral     = StringToInt(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); bKeepDirection = StringToInt(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); bTeamlessHits  = StringToInt(strBuffer);
		GetCmdArg(5, strBuffer, sizeof(strBuffer)); bResetBounces  = StringToInt(strBuffer);
		GetCmdArg(6, strBuffer, sizeof(strBuffer)); iMaxBounces    = StringToInt(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		switch (bIsNeutral)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsNeutral) && !(g_iRocketClassFlags[iIndex] & RocketFlag_IsNeutral))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_IsNeutral;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsNeutral) && (g_iRocketClassFlags[iIndex] & RocketFlag_IsNeutral))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsNeutral;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_IsNeutral)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsNeutral;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_IsNeutral))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_IsNeutral;
				}
			}
		}
		
		switch (bKeepDirection)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_KeepDirection) && !(g_iRocketClassFlags[iIndex] & RocketFlag_KeepDirection))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_KeepDirection;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_KeepDirection) && (g_iRocketClassFlags[iIndex] & RocketFlag_KeepDirection))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_KeepDirection;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_KeepDirection)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_KeepDirection;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_KeepDirection))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_KeepDirection;
				}
			}
		}
		
		switch (bTeamlessHits)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_TeamlessHits) && !(g_iRocketClassFlags[iIndex] & RocketFlag_TeamlessHits))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_TeamlessHits;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_TeamlessHits) && (g_iRocketClassFlags[iIndex] & RocketFlag_TeamlessHits))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_TeamlessHits;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_TeamlessHits)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_TeamlessHits;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_TeamlessHits))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_TeamlessHits;
				}
			}
		}
		
		switch (bResetBounces)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_ResetBounces) && !(g_iRocketClassFlags[iIndex] & RocketFlag_ResetBounces))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_ResetBounces;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_ResetBounces) && (g_iRocketClassFlags[iIndex] & RocketFlag_ResetBounces))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_ResetBounces;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_ResetBounces)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_ResetBounces;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_ResetBounces))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_ResetBounces;
				}
			}
		}
		
		g_iRocketClassMaxBounces[iIndex] = iMaxBounces == -1 ? g_iRocketClassSavedMaxBounces[iIndex] : iMaxBounces;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketOtherParams_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdDragParams(int iClient, int iArgs)
{
	if (iArgs == 4 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex; float fRocketDragTimeMin, fRocketDragTimeMax; int bRocketNoBounceDrags;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex               = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); fRocketDragTimeMin   = StringToFloat(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fRocketDragTimeMax   = StringToFloat(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); bRocketNoBounceDrags = StringToInt(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		switch (bRocketNoBounceDrags)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_NoBounceDrags) && !(g_iRocketClassFlags[iIndex] & RocketFlag_NoBounceDrags))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_NoBounceDrags;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_NoBounceDrags) && (g_iRocketClassFlags[iIndex] & RocketFlag_NoBounceDrags))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_NoBounceDrags;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_NoBounceDrags)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_NoBounceDrags;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_NoBounceDrags))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_NoBounceDrags;
				}
			}
		}
		
		g_fRocketClassDragTimeMin[iIndex] = fRocketDragTimeMin == -1 ? g_fSavedParameters[iIndex][8] : fRocketDragTimeMin;
		g_fRocketClassDragTimeMax[iIndex] = fRocketDragTimeMax == -1 ? g_fSavedParameters[iIndex][9] : fRocketDragTimeMax;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketDragParams_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdHideTrails(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		return Plugin_Handled;
	}
	
	if (!iArgs && g_bEnabled)
	{
		g_bClientHideTrails[iClient] = !g_bClientHideTrails[iClient];
		
		CPrintToChat(iClient, "%t", g_bClientHideTrails[iClient] ? "Command_DBHideParticles_Hidden" : "Command_DBHideParticles_Visible");
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBHideParticles_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdHideSprites(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		return Plugin_Handled;
	}
	
	if (!iArgs && g_bEnabled)
	{
		g_bClientHideSprites[iClient] = !g_bClientHideSprites[iClient];
		
		CPrintToChat(iClient, "%t", g_bClientHideSprites[iClient] ? "Command_DBHideSprites_Hidden" : "Command_DBHideSprites_Visible");
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBHideSprites_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

/* ExecuteCommands()
**
** The core of the plugin's event system, unpacks and correctly formats the
** given command strings to be executed.
** -------------------------------------------------------------------------- */
void ExecuteCommands(DataPack hDataPack, int iClass, int iRocket, int iOwner, int iTarget, int iLastDead, float fSpeed, int iNumDeflections, float fMphSpeed)
{
    hDataPack.Reset(false);
    int iNumCommands = hDataPack.ReadCell();
    while (iNumCommands-- > 0)
    {
        char strCmd[256], strBuffer[32];
        hDataPack.ReadString(strCmd, sizeof(strCmd));
        ReplaceString(strCmd, sizeof(strCmd), "@name", g_strRocketClassLongName[iClass]);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iRocket);                ReplaceString(strCmd, sizeof(strCmd), "@rocket", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iOwner);                 ReplaceString(strCmd, sizeof(strCmd), "@owner", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iTarget);                ReplaceString(strCmd, sizeof(strCmd), "@target", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iLastDead);              ReplaceString(strCmd, sizeof(strCmd), "@dead", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%.2f", fSpeed);               ReplaceString(strCmd, sizeof(strCmd), "@speed", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iNumDeflections);        ReplaceString(strCmd, sizeof(strCmd), "@deflections", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", RoundFloat(fMphSpeed));  ReplaceString(strCmd, sizeof(strCmd), "@mphspeed", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%.2f", fMphSpeed / 0.042614); ReplaceString(strCmd, sizeof(strCmd), "@nocapspeed", strBuffer);
        ServerCommand(strCmd);
    }
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**    ______            _____      
**   / ____/___  ____  / __(_)___ _
**  / /   / __ \/ __ \/ /_/ / __ `/
** / /___/ /_/ / / / / __/ / /_/ / 
** \____/\____/_/ /_/_/ /_/\__, /  
**                        /____/   
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* ParseConfiguration()
**
** Parses a Dodgeball configuration file. It doesn't clear any of the previous
** data, so multiple files can be parsed.
** -------------------------------------------------------------------------- */
bool ParseConfigurations(char[] strConfigFile = "general.cfg")
{
    // Parse configuration
    char strPath[PLATFORM_MAX_PATH];
    char strFileName[PLATFORM_MAX_PATH];
    FormatEx(strFileName, sizeof(strFileName), "configs/dodgeball/%s", strConfigFile);
    BuildPath(Path_SM, strPath, sizeof(strPath), strFileName);
    
    // Try to parse if it exists
    LogMessage("Executing configuration file %s", strPath);
    if (FileExists(strPath, true))
    {
        KeyValues kvConfig = new KeyValues("TF2_Dodgeball");
        if (kvConfig.ImportFromFile(strPath) == false) SetFailState("Error while parsing the configuration file.");
        kvConfig.GotoFirstSubKey();
        
        // Parse the subsections
        do
        {
            char strSection[64]; kvConfig.GetSectionName(strSection, sizeof(strSection));
            
            if (StrEqual(strSection, "general"))       ParseGeneral(kvConfig);
            else if (StrEqual(strSection, "classes"))  ParseClasses(kvConfig);
            else if (StrEqual(strSection, "spawners")) ParseSpawners(kvConfig);
        }
        while (kvConfig.GotoNextKey());
        
        delete kvConfig;
    }
}

/* ParseGeneral()
**
** Parses general settings, such as the music, urls, etc.
** -------------------------------------------------------------------------- */
void ParseGeneral(KeyValues kvConfig)
{
    g_bMusicEnabled = view_as<bool>(kvConfig.GetNum("music", 0));
    if (g_bMusicEnabled == true)
    {
        g_bUseWebPlayer = view_as<bool>(kvConfig.GetNum("use web player", 0));
        kvConfig.GetString("web player url", g_strWebPlayerUrl, sizeof(g_strWebPlayerUrl));
        
        g_bMusic[Music_RoundStart] = kvConfig.GetString("round start",      g_strMusic[Music_RoundStart], PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundStart]);
        g_bMusic[Music_RoundWin]   = kvConfig.GetString("round end (win)",  g_strMusic[Music_RoundWin],   PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundWin]);
        g_bMusic[Music_RoundLose]  = kvConfig.GetString("round end (lose)", g_strMusic[Music_RoundLose],  PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundLose]);
        g_bMusic[Music_Gameplay]   = kvConfig.GetString("gameplay",         g_strMusic[Music_Gameplay],   PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_Gameplay]);
    }
}

/* ParseClasses()
**
** Parses the rocket classes data from the given configuration file.
** -------------------------------------------------------------------------- */
void ParseClasses(KeyValues kvConfig)
{
    char strName[64];
    char strBuffer[256];
    
    kvConfig.GotoFirstSubKey();
    do
    {
        int iIndex = g_iRocketClassCount;
        RocketFlags iFlags;
        
        // Basic parameters
        kvConfig.GetSectionName(strName, sizeof(strName));         strcopy(g_strRocketClassName[iIndex], 16, strName);
        kvConfig.GetString("name", strBuffer, sizeof(strBuffer));  strcopy(g_strRocketClassLongName[iIndex], 32, strBuffer);
        if (kvConfig.GetString("model", strBuffer, sizeof(strBuffer)))
        {
            strcopy(g_strRocketClassModel[iIndex], PLATFORM_MAX_PATH, strBuffer);
            if (strlen(g_strRocketClassModel[iIndex]) != 0)
            {
                iFlags |= RocketFlag_CustomModel;
                if (kvConfig.GetNum("is animated", 0)) iFlags |= RocketFlag_IsAnimated;
            }
        }
        
        if (kvConfig.GetString("trail particle", strBuffer, sizeof(strBuffer)))
        {
            strcopy(g_strRocketClassTrail[iIndex], sizeof(g_strRocketClassTrail[]), strBuffer);
            if (strlen(g_strRocketClassTrail[iIndex]) != 0)
            {
                iFlags |= RocketFlag_CustomTrail;
            }
        }
        
        if (kvConfig.GetString("trail sprite", strBuffer, sizeof(strBuffer)))
        {
            strcopy(g_strRocketClassSprite[iIndex], PLATFORM_MAX_PATH, strBuffer);
            if (strlen(g_strRocketClassSprite[iIndex]) != 0)
            {
                iFlags |= RocketFlag_CustomSprite;
                if (kvConfig.GetString("custom color", strBuffer, sizeof(strBuffer)))
                {
                    strcopy(g_strRocketClassSpriteColor[iIndex], sizeof(g_strRocketClassSpriteColor[]), strBuffer);
                }
                
                g_fRocketClassSpriteLifetime[iIndex]   = kvConfig.GetFloat("sprite lifetime");
                g_fRocketClassSpriteStartWidth[iIndex] = kvConfig.GetFloat("sprite start width");
                g_fRocketClassSpriteEndWidth[iIndex]   = kvConfig.GetFloat("sprite end width");
            }
        }
        
        if (kvConfig.GetNum("remove particles", 0))
        {
            iFlags |= RocketFlag_RemoveParticles;
            if (kvConfig.GetNum("replace particles", 0)) iFlags |= RocketFlag_ReplaceParticles;
        }
        
        kvConfig.GetString("behaviour", strBuffer, sizeof(strBuffer), "homing");
        if (StrEqual(strBuffer, "homing"))
        {
            g_iRocketClassBehaviour[iIndex] = Behaviour_Homing;
        }
        else if (StrEqual(strBuffer, "legacy homing"))
        {
            g_iRocketClassBehaviour[iIndex] = Behaviour_LegacyHoming;
        }
        else
        {
            g_iRocketClassBehaviour[iIndex] = Behaviour_Unknown;
        }
        
        if (kvConfig.GetNum("play spawn sound", 0) == 1)
        {
            iFlags |= RocketFlag_PlaySpawnSound;
            if (kvConfig.GetString("spawn sound", g_strRocketClassSpawnSound[iIndex], PLATFORM_MAX_PATH) && (strlen(g_strRocketClassSpawnSound[iIndex]) != 0))
            {
                iFlags |= RocketFlag_CustomSpawnSound;
            }
        }
        
        if (kvConfig.GetNum("play beep sound", 0) == 1)
        {
            iFlags |= RocketFlag_PlayBeepSound;
            g_fRocketClassBeepInterval[iIndex] = kvConfig.GetFloat("beep interval", 0.5);
            if (kvConfig.GetString("beep sound", g_strRocketClassBeepSound[iIndex], PLATFORM_MAX_PATH) && (strlen(g_strRocketClassBeepSound[iIndex]) != 0))
            {
                iFlags |= RocketFlag_CustomBeepSound;
            }
        }
        
        if (kvConfig.GetNum("play alert sound", 0) == 1)
        {
            iFlags |= RocketFlag_PlayAlertSound;
            if (kvConfig.GetString("alert sound", g_strRocketClassAlertSound[iIndex], PLATFORM_MAX_PATH) && strlen(g_strRocketClassAlertSound[iIndex]) != 0)
            {
                iFlags |= RocketFlag_CustomAlertSound;
            }
        }
        
        // Behaviour modifiers
        if (kvConfig.GetNum("elevate on deflect", 1) == 1) iFlags |= RocketFlag_ElevateOnDeflect;
        if (kvConfig.GetNum("neutral rocket", 0) == 1)     iFlags |= RocketFlag_IsNeutral;
        if (kvConfig.GetNum("limit turn rate", 0) == 1)    iFlags |= RocketFlag_IsTRLimited;
        if (kvConfig.GetNum("limit speed", 0) == 1)        iFlags |= RocketFlag_IsSpeedLimited;
        if (kvConfig.GetNum("keep direction", 0) == 1)     iFlags |= RocketFlag_KeepDirection;
        if (kvConfig.GetNum("teamless deflects", 0) == 1)  iFlags |= RocketFlag_TeamlessHits;
        if (kvConfig.GetNum("reset bounces", 0) == 1)      iFlags |= RocketFlag_ResetBounces;
        if (kvConfig.GetNum("no bounce drags", 0) == 1)    iFlags |= RocketFlag_NoBounceDrags;
        if (kvConfig.GetNum("can be stolen", 0) == 1)      iFlags |= RocketFlag_CanBeStolen;
        if (kvConfig.GetNum("steal team check", 0) == 1)   iFlags |= RocketFlag_StealTeamCheck;
        
        // Movement parameters
        g_fRocketClassDamage[iIndex]            = kvConfig.GetFloat("damage");
        g_fRocketClassDamageIncrement[iIndex]   = kvConfig.GetFloat("damage increment");
        g_fRocketClassCritChance[iIndex]        = kvConfig.GetFloat("critical chance");
        g_fRocketClassSpeed[iIndex]             = kvConfig.GetFloat("speed");
        g_fSavedParameters[iIndex][0]           = g_fRocketClassSpeed[iIndex];
        g_fRocketClassSpeedIncrement[iIndex]    = kvConfig.GetFloat("speed increment");
        g_fSavedParameters[iIndex][1]           = g_fRocketClassSpeedIncrement[iIndex];
        g_fRocketClassSpeedLimit[iIndex]        = kvConfig.GetFloat("speed limit");
        g_fSavedParameters[iIndex][2]           = g_fRocketClassSpeedLimit[iIndex];
        g_fRocketClassTurnRate[iIndex]          = kvConfig.GetFloat("turn rate");
        g_fSavedParameters[iIndex][3]           = g_fRocketClassTurnRate[iIndex];
        g_fRocketClassTurnRateIncrement[iIndex] = kvConfig.GetFloat("turn rate increment");
        g_fSavedParameters[iIndex][4]           = g_fRocketClassTurnRateIncrement[iIndex];
        g_fRocketClassTurnRateLimit[iIndex]     = kvConfig.GetFloat("turn rate limit");
        g_fSavedParameters[iIndex][5]           = g_fRocketClassTurnRateLimit[iIndex];
        g_fRocketClassElevationRate[iIndex]     = kvConfig.GetFloat("elevation rate");
        g_fSavedParameters[iIndex][6]           = g_fRocketClassElevationRate[iIndex];
        g_fRocketClassElevationLimit[iIndex]    = kvConfig.GetFloat("elevation limit");
        g_fSavedParameters[iIndex][7]           = g_fRocketClassElevationLimit[iIndex];
        g_fRocketClassControlDelay[iIndex]      = kvConfig.GetFloat("control delay");
        g_fRocketClassDragTimeMin[iIndex]       = kvConfig.GetFloat("drag time min");
        g_fSavedParameters[iIndex][8]           = g_fRocketClassDragTimeMin[iIndex];
        g_fRocketClassDragTimeMax[iIndex]       = kvConfig.GetFloat("drag time max");
        g_fSavedParameters[iIndex][9]           = g_fRocketClassDragTimeMax[iIndex];
        g_iRocketClassMaxBounces[iIndex]        = kvConfig.GetNum("max bounces");
        g_iRocketClassSavedMaxBounces[iIndex]   = g_iRocketClassMaxBounces[iIndex];
        g_fRocketClassBounceScale[iIndex]       = kvConfig.GetFloat("bounce scale", 1.0);
        g_fRocketClassPlayerModifier[iIndex]    = kvConfig.GetFloat("no. players modifier");
        g_fRocketClassRocketsModifier[iIndex]   = kvConfig.GetFloat("no. rockets modifier");
        g_fRocketClassTargetWeight[iIndex]      = kvConfig.GetFloat("direction to target weight");
        
        // Events
        DataPack hCmds = null;
        kvConfig.GetString("on spawn", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnSpawnCmd; g_hRocketClassCmdsOnSpawn[iIndex] = hCmds; }
        kvConfig.GetString("on deflect", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnDeflectCmd; g_hRocketClassCmdsOnDeflect[iIndex] = hCmds; }
        kvConfig.GetString("on kill", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnKillCmd; g_hRocketClassCmdsOnKill[iIndex] = hCmds; }
        kvConfig.GetString("on explode", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnExplodeCmd; g_hRocketClassCmdsOnExplode[iIndex] = hCmds; }
        kvConfig.GetString("on no target", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnNoTargetCmd; g_hRocketClassCmdsOnNoTarget[iIndex] = hCmds; }
        
        // Done
        g_hRocketClassTrie.SetValue(strName, iIndex);
        g_iRocketClassFlags[iIndex] = iFlags;
        g_iSavedRocketClassFlags[iIndex] = iFlags;
        g_iRocketClassCount++;
    }
    while (kvConfig.GotoNextKey());
    kvConfig.GoBack(); 
}

/* ParseSpawners()
**
** Parses the spawn points classes data from the given configuration file.
** -------------------------------------------------------------------------- */
void ParseSpawners(KeyValues kvConfig)
{
    char strBuffer[256];
    kvConfig.GotoFirstSubKey();
    
    do
    {
        int iIndex = g_iSpawnersCount;
        
        // Basic parameters
        kvConfig.GetSectionName(strBuffer, sizeof(strBuffer)); strcopy(g_strSpawnersName[iIndex], 32, strBuffer);
        g_iSpawnersMaxRockets[iIndex] = kvConfig.GetNum("max rockets", 1);
        g_fSpawnersInterval[iIndex]   = kvConfig.GetFloat("interval", 1.0);
        
        // Chances table
        g_hSpawnersChancesTable[iIndex] = new ArrayList();
        g_hSavedChancesTable[iIndex] = new ArrayList();
        for (int iClassIndex = 0; iClassIndex < g_iRocketClassCount; iClassIndex++)
        {
            FormatEx(strBuffer, sizeof(strBuffer), "%s%%", g_strRocketClassName[iClassIndex]);
            g_hSpawnersChancesTable[iIndex].Push(kvConfig.GetNum(strBuffer, 0));
            g_hSavedChancesTable[iIndex].Push(kvConfig.GetNum(strBuffer, 0));
        }
        
        // Done.
        g_hSpawnersTrie.SetValue(g_strSpawnersName[iIndex], iIndex);
        g_iSpawnersCount++;
    }
    while (kvConfig.GotoNextKey());
    kvConfig.GoBack();
    
    g_hSpawnersTrie.GetValue("red", g_iDefaultRedSpawner);
    g_hSpawnersTrie.GetValue("blu", g_iDefaultBluSpawner);
}

/* ParseCommands()
**
** Part of the event system, parses the given command strings and packs them
** to a Datapack.
** -------------------------------------------------------------------------- */
DataPack ParseCommands(char[] strLine)
{
    TrimString(strLine);
    if (strlen(strLine) == 0)
    {
        return null;
    }
    else
    {
        char strStrings[8][255];
        int iNumStrings = ExplodeString(strLine, ";", strStrings, 8, 255);
        
        DataPack hDataPack = new DataPack();
        hDataPack.WriteCell(iNumStrings);
        for (int i = 0; i < iNumStrings; i++)
        {
            hDataPack.WriteString(strStrings[i]);
        }
        
        return hDataPack;
    }
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**   ______            __    
**  /_  __/___  ____  / /____
**   / / / __ \/ __ \/ / ___/
**  / / / /_/ / /_/ / (__  ) 
** /_/  \____/\____/_/____/  
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* CopyVectors()
**
** Copies the contents from a vector to another.
** -------------------------------------------------------------------------- */
stock void CopyVectors(float fFrom[3], float fTo[3])
{
    fTo[0] = fFrom[0];
    fTo[1] = fFrom[1];
    fTo[2] = fFrom[2];
}

/* LerpVectors()
**
** Calculates the linear interpolation of the two given vectors and stores
** it on the third one.
** -------------------------------------------------------------------------- */
stock void LerpVectors(float fA[3], float fB[3], float fC[3], float t)
{
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;
    
    fC[0] = fA[0] + (fB[0] - fA[0]) * t;
    fC[1] = fA[1] + (fB[1] - fA[1]) * t;
    fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}

/* IsValidClient()
**
** Checks if the given client index is valid, and if it's alive or not.
** -------------------------------------------------------------------------- */
stock bool IsValidClient(int iClient, bool bAlive = false)
{
    if (iClient >= 1 &&
    iClient <= MaxClients &&
    IsClientInGame(iClient) &&
    (bAlive == false || IsPlayerAlive(iClient)))
    {
        return true;
    }
    
    return false;
}

/* BothTeamsPlaying()
**
** Checks if there are players on both teams.
** -------------------------------------------------------------------------- */
stock bool BothTeamsPlaying()
{
    bool bRedFound, bBluFound;
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsValidClient(iClient, true) == false) continue;
        int iTeam = GetClientTeam(iClient);
        if (iTeam == view_as<int>(TFTeam_Red)) bRedFound = true;
        if (iTeam == view_as<int>(TFTeam_Blue)) bBluFound = true;
    }
    return bRedFound && bBluFound;
}

/* CountAlivePlayers()
**
** Retrieves the number of players alive.
** -------------------------------------------------------------------------- */
stock int CountAlivePlayers()
{
    int iCount = 0;
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsValidClient(iClient, true)) iCount++;
    }
    return iCount;
}

/* SelectTarget()
**
** Determines a random target of the given team for the homing rocket.
** -------------------------------------------------------------------------- */
stock int SelectTarget(int iTeam, int iRocket = -1)
{
    int iTarget = -1;
    float fTargetWeight = 0.0;
    float fRocketPosition[3];
    float fRocketDirection[3];
    float fWeight;
    bool bUseRocket;
    int iOwner = -1;
    
    if (iRocket != -1)
    {
        int iClass = g_iRocketClass[iRocket];
        int iEntity = EntRefToEntIndex(g_iRocketEntity[iRocket]);
        iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
        
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
        CopyVectors(g_fRocketDirection[iRocket], fRocketDirection);
        fWeight = g_fRocketClassTargetWeight[iClass];
        
        bUseRocket = true;
    }
    
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        // If the client isn't connected, skip.
        if (!IsValidClient(iClient, true)) continue;
        if (iTeam && GetClientTeam(iClient) != iTeam) continue;
        if (iClient == iOwner) continue;
        
        // Determine if this client should be the target.
        float fNewWeight = GetURandomFloatRange(0.0, 100.0);
        
        if (bUseRocket == true)
        {
            float fClientPosition[3]; GetClientEyePosition(iClient, fClientPosition);
            float fDirectionToClient[3]; MakeVectorFromPoints(fRocketPosition, fClientPosition, fDirectionToClient);
            fNewWeight += GetVectorDotProduct(fRocketDirection, fDirectionToClient) * fWeight;
        }
        
        if ((iTarget == -1) || fNewWeight >= fTargetWeight)
        {
            iTarget = iClient;
            fTargetWeight = fNewWeight;
        }
    }
    
    return iTarget;
}

/* StopSoundToAll()
**
** Stops a sound for all the clients on the given channel.
** -------------------------------------------------------------------------- */
stock void StopSoundToAll(int iChannel, const char[] strSound)
{
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsValidClient(iClient)) StopSound(iClient, iChannel, strSound);
    }
}

/* PlayParticle()
**
** Plays a particle system at the given location & angles.
** -------------------------------------------------------------------------- */
stock void PlayParticle(float fPosition[3], float fAngles[3], char[] strParticleName, float fEffectTime = 5.0, float fLifeTime = 9.0)
{
    int iEntity = CreateEntityByName("info_particle_system");
    if (iEntity && IsValidEdict(iEntity))
    {
        TeleportEntity(iEntity, fPosition, fAngles, NULL_VECTOR);
        DispatchKeyValue(iEntity, "effect_name", strParticleName);
        ActivateEntity(iEntity);
        AcceptEntityInput(iEntity, "Start");
        CreateTimer(fEffectTime, StopParticle, EntIndexToEntRef(iEntity));
        CreateTimer(fLifeTime, KillParticle, EntIndexToEntRef(iEntity));
    }
    else
    {
        LogError("ShowParticle: could not create info_particle_system");
    }
}

/* StopParticle()
**
** Turns of the particle system. Automatically called by PlayParticle
** -------------------------------------------------------------------------- */
public Action StopParticle(Handle hTimer, any iEntityRef)
{
    if (iEntityRef != INVALID_ENT_REFERENCE)
    {
        int iEntity = EntRefToEntIndex(iEntityRef);
        if (iEntity && IsValidEntity(iEntity))
        {
            AcceptEntityInput(iEntity, "Stop");
        }
    }
    
    return Plugin_Continue;
}

/* KillParticle()
**
** Destroys the particle system. Automatically called by PlayParticle
** -------------------------------------------------------------------------- */
public Action KillParticle(Handle hTimer, any iEntityRef)
{
    if (iEntityRef != INVALID_ENT_REFERENCE)
    {
        int iEntity = EntRefToEntIndex(iEntityRef);
        if (iEntity && IsValidEntity(iEntity))
        {
            RemoveEdict(iEntity);
        }
    }
    
    return Plugin_Continue;
}

/* PrecacheParticle()
**
** Forces the client to precache a particle system.
** -------------------------------------------------------------------------- */
stock void PrecacheParticle(char[] strParticleName)
{
    PlayParticle(view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), strParticleName, 0.1, 0.1);
}

/* FindEntityByClassnameSafe()
**
** Used to iterate through entity types, avoiding problems in cases where
** the entity may not exist anymore.
** -------------------------------------------------------------------------- */
stock int FindEntityByClassnameSafe(int iStart, const char[] strClassname)
{
    while (iStart > -1 && !IsValidEntity(iStart))
    {
        iStart--;
    }
    return FindEntityByClassname(iStart, strClassname);
}

/* GetAnalogueTeam()
**
** Gets the analogue team for this. In case of Red, it's Blue, and viceversa.
** -------------------------------------------------------------------------- */
stock int GetAnalogueTeam(int iTeam)
{
    if (iTeam == view_as<int>(TFTeam_Red)) return view_as<int>(TFTeam_Blue);
    return view_as<int>(TFTeam_Red);
}

/* ShowHiddenMOTDPanel()
**
** Shows a hidden MOTD panel, useful for streaming music.
** -------------------------------------------------------------------------- */
stock void ShowHiddenMOTDPanel(int iClient, char[] strTitle, char[] strMsg, char[] strType = "2")
{
    KeyValues hPanel = new KeyValues("data");
    hPanel.SetString("title", strTitle);
    hPanel.SetString("type", strType);
    hPanel.SetString("msg", strMsg);
    ShowVGUIPanel(iClient, "info", hPanel, false);
    delete hPanel;
}

/* PrecacheSoundEx()
**
** Precaches a sound and adds it to the download table.
** -------------------------------------------------------------------------- */
stock void PrecacheSoundEx(char[] strFileName, bool bPreload = false, bool bAddToDownloadTable = false)
{
    char strFinalPath[PLATFORM_MAX_PATH]; 
    FormatEx(strFinalPath, sizeof(strFinalPath), "sound/%s", strFileName);
    PrecacheSound(strFileName, bPreload);
    if (bAddToDownloadTable == true) AddFileToDownloadsTable(strFinalPath);
}

/* PrecacheModelEx()
**
** Precaches a models and adds it to the download table.
** -------------------------------------------------------------------------- */
stock void PrecacheModelEx(char[] strFileName, bool bPreload = false, bool bAddToDownloadTable = false)
{
    PrecacheModel(strFileName, bPreload);
    if (bAddToDownloadTable)
    {
        char strDepFileName[PLATFORM_MAX_PATH];
        FormatEx(strDepFileName, sizeof(strDepFileName), "%s.res", strFileName);
        
        if (FileExists(strDepFileName))
        {
            // Open stream, if possible
            File hStream = OpenFile(strDepFileName, "r");
            if (hStream == null) { LogMessage("Error, can't read file containing model dependencies."); return; }
            
            while(!hStream.EndOfFile())
            {
                char strBuffer[PLATFORM_MAX_PATH];
                hStream.ReadLine(strBuffer, sizeof(strBuffer));
                CleanString(strBuffer);
                
                // If file exists...
                if (FileExists(strBuffer, true))
                {
                    // Precache depending on type, and add to download table
                    if (StrContains(strBuffer, ".vmt", false) != -1)      PrecacheDecal(strBuffer, true);
                    else if (StrContains(strBuffer, ".mdl", false) != -1) PrecacheModel(strBuffer, true);
                    else if (StrContains(strBuffer, ".pcf", false) != -1) PrecacheGeneric(strBuffer, true);
                    AddFileToDownloadsTable(strBuffer);
                }
            }
            
            // Close file
            delete hStream;
        }
    }
}

/* CleanString()
**
** Cleans the given string from any illegal character.
** -------------------------------------------------------------------------- */
stock void CleanString(char[] strBuffer)
{
    // Cleanup any illegal characters
    int Length = strlen(strBuffer);
    for (int iPos=0; iPos<Length; iPos++)
    {
        switch(strBuffer[iPos])
        {
            case '\r': strBuffer[iPos] = ' ';
            case '\n': strBuffer[iPos] = ' ';
            case '\t': strBuffer[iPos] = ' ';
        }
    }
    
    // Trim string
    TrimString(strBuffer);
}

/* FMax()
**
** Returns the maximum of the two values given.
** -------------------------------------------------------------------------- */
stock float FMax(float a, float b)
{
    return (a > b)? a:b;
}

/* FMin()
**
** Returns the minimum of the two values given.
** -------------------------------------------------------------------------- */
stock float FMin(float a, float b)
{
    return (a < b)? a:b;
}

/* GetURandomIntRange()
**
** 
** -------------------------------------------------------------------------- */
stock int GetURandomIntRange(int iMin, int iMax)
{
    return iMin + (GetURandomInt() % (iMax - iMin + 1));
}

/* GetURandomFloatRange()
**
** 
** -------------------------------------------------------------------------- */
stock float GetURandomFloatRange(float fMin, float fMax)
{
    return fMin + (GetURandomFloat() * (fMax - fMin));
}

void CheckStolenRocket(int iClient, int iIndex)
{
	int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
	
	if (iTarget != iClient && 
        !bStealArray[iClient].stoleRocket && 
        (GetEntitiesDistance(iTarget, iClient) > g_fStealDistance) && 
        (!(g_iRocketFlags[iIndex] & RocketFlag_StealTeamCheck) || (GetClientTeam(iTarget) == GetClientTeam(iClient))) && 
        !g_bPreventingDelay[iIndex])
	{
		bStealArray[iClient].stoleRocket = true;
		if (bStealArray[iClient].rocketsStolen < g_hCvarStealPreventionNumber.IntValue)
		{
			bStealArray[iClient].rocketsStolen++;
			SlapPlayer(iClient, 0, true);
			CPrintToChat(iClient, "%t", "DBSteal_Warning_Client", bStealArray[iClient].rocketsStolen, g_hCvarStealPreventionNumber.IntValue);
			MC_SkipNextClient(iClient);
			CPrintToChatAll("%t", "DBSteal_Announce_All", iClient, iTarget);
			bStealArray[iClient].stoleRocket = false;
		}
		else
		{
			ForcePlayerSuicide(iClient);
			CPrintToChat(iClient, "%t", "DBSteal_Slay_Client");
			MC_SkipNextClient(iClient);
			CPrintToChatAll("%t", "DBSteal_Announce_Slay_All", iClient);
		}
		g_bIsRocketStolen[iIndex] = true;
		g_iLastStealer = iClient;
		
		Forward_OnRocketSteal(iIndex, iClient, iTarget, bStealArray[iClient].rocketsStolen);
	}
}

public bool MLTargetFilterStealer(const char[] strPattern, ArrayList hClients)
{
	bool bReverse = (StrContains(strPattern, "!", false) == 1);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && (hClients.FindValue(iClient) == -1))
		{
			if (iClient == g_iLastStealer)
			{
				if (!bReverse)
				{
					hClients.Push(iClient);
				}
			}
			else if (bReverse)
			{
				hClients.Push(iClient);
			}
		}
	}
	
	return !!hClients.Length;
}

// Asherkin's RocketBounce

public void tf2dodgeball_cvarhook(Handle hConvar, const char[] strOldValue, const char[] strNewValue)
{
	if (hConvar == g_hCvarStealDistance)
	{
		g_fStealDistance = StringToFloat(strNewValue);
	}
}

public Action OnStartTouch(int iEntity, int iOther)
{
	if (iOther > 0 && iOther <= MaxClients)
		return Plugin_Continue;
		
	int iIndex = FindRocketByEntity(iEntity);
	
	if (iIndex != -1)
	{
		// Only allow a rocket to bounce x times.
		int iClass = g_iRocketClass[iIndex];
		
		if (g_iRocketBounces[iIndex] >= g_iRocketClassMaxBounces[iClass])
			return Plugin_Continue;
	}
	else
	{
		return Plugin_Continue;
	}
	
	SDKHook(iEntity, SDKHook_Touch, OnTouch);
	
	return Plugin_Handled;
}

public Action OnTouch(int iEntity, int iOther)
{
	int iIndex = FindRocketByEntity(iEntity);
	
	if (iIndex != -1)
	{
		int iClass = g_iRocketClass[iIndex];
		
		float vOrigin[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vOrigin);
		
		float vAngles[3];
		GetEntPropVector(iEntity, Prop_Data, "m_angRotation", vAngles);
		
		float vVelocity[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", vVelocity);
		
		Handle hTrace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, iEntity);
		
		if(!TR_DidHit(hTrace))
		{
			delete hTrace;
			return Plugin_Continue;
		}
		
		float vNormal[3];
		TR_GetPlaneNormal(hTrace, vNormal);
		
		//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
		
		delete hTrace;
		
		float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
		
		ScaleVector(vNormal, dotProduct);
		ScaleVector(vNormal, 2.0);
		
		float vBounceVec[3];
		SubtractVectors(vVelocity, vNormal, vBounceVec);
		
		ScaleVector(vBounceVec, g_fRocketClassBounceScale[iClass]);
		
		float vNewAngles[3];
		GetVectorAngles(vBounceVec, vNewAngles);
		
		//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
		//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
		
		float vNewAnglesRef[3]; CopyVectors(vNewAngles, vNewAnglesRef);
		float vBounceVecRef[3]; CopyVectors(vBounceVec, vBounceVecRef);
		
		Action aResult = Forward_OnRocketBouncePre(iIndex, iEntity, vNewAnglesRef, vBounceVecRef);
		
		if (aResult == Plugin_Stop || aResult == Plugin_Handled)
        {
        	SDKUnhook(iEntity, SDKHook_Touch, OnTouch);
        	
        	return Plugin_Handled;
        }
		else if (aResult == Plugin_Changed)
		{
			CopyVectors(vNewAnglesRef, vNewAngles);
			CopyVectors(vBounceVecRef, vBounceVec);
		}
		
		TeleportEntity(iEntity, NULL_VECTOR, vNewAngles, vBounceVec);
		
		g_iRocketBounces[iIndex]++;
		
		if (g_iRocketFlags[iIndex] & RocketFlag_NoBounceDrags)
		{
			g_bIsRocketDraggable[iIndex] = false;
		}
		
		if ((g_bPreventingDelay[iIndex]) || (g_iRocketFlags[iIndex] & RocketFlag_KeepDirection))
		{
			g_bIsRocketBouncing[iIndex] = true;
		}
		else
		{
			float fDirection[3];
			GetAngleVectors(vNewAngles,fDirection,NULL_VECTOR,NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
		}
		
		Forward_OnRocketBounce(iIndex, iEntity);
	}
	
	SDKUnhook(iEntity, SDKHook_Touch, OnTouch);
	
	return Plugin_Handled;
}

public bool TEF_ExcludeEntity(int iEntity, int iContentsMask, any Data)
{
	return (iEntity != Data);
}

void CheckRoundDelays(int iIndex)
{
	int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
	float fTimeToCheck;
	
	if (g_iRocketDeflections[iIndex] == 0)
	{
		fTimeToCheck = g_fLastSpawnTime[iIndex];
	}
	else
	{
		fTimeToCheck = g_fRocketLastDeflectionTime[iIndex];
	}
	
	if (iTarget != INVALID_ENT_REFERENCE && (GetGameTime() - fTimeToCheck) >= g_hCvarDelayPreventionTime.FloatValue)
	{
		g_fRocketSpeed[iIndex] += g_hCvarDelayPreventionSpeedup.FloatValue;
		if (!g_bPreventingDelay[iIndex])
		{
			CPrintToChatAll("%t", "DBDelay_Announce_All", iTarget);
			EmitSoundToAll(SOUND_DEFAULT_SPEEDUP, iEntity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			
			Forward_OnRocketDelay(iIndex, iTarget);
		}
		g_bPreventingDelay[iIndex] = true;
	}
}

stock float GetEntitiesDistance(int iEnt1, int iEnt2)
{
	float fOrig1[3];
	GetEntPropVector(iEnt1, Prop_Send, "m_vecOrigin", fOrig1);
	
	float fOrig2[3];
	GetEntPropVector(iEnt2, Prop_Send, "m_vecOrigin", fOrig2);

	return GetVectorDistance(fOrig1, fOrig2);
}

stock void PrecacheTrail(char[] strFileName)
{
	char strDownloadString[PLATFORM_MAX_PATH];
	FormatEx(strDownloadString, sizeof(strDownloadString), "%s.vmt", strFileName);
	PrecacheGeneric(strDownloadString, true);
	AddFileToDownloadsTable(strDownloadString);
	FormatEx(strDownloadString, sizeof(strDownloadString), "%s.vtf", strFileName);
	PrecacheGeneric(strDownloadString, true);
	AddFileToDownloadsTable(strDownloadString);
}

stock void CreateTempParticle(const char[] strParticle,
                              const float vecOrigin[3] = NULL_VECTOR,
                              const float vecStart[3] = NULL_VECTOR,
                              const float vecAngles[3] = NULL_VECTOR,
                              int iEntity = -1,
                              ParticleAttachmentType AttachmentType = PATTACH_ABSORIGIN,
                              int iAttachmentPoint = -1,
                              bool bResetParticles = false)
{
	int iParticleTable, iParticleIndex;
	
	iParticleTable = FindStringTable("ParticleEffectNames");
	if (iParticleTable == INVALID_STRING_TABLE)
	{
		ThrowError("Could not find string table: ParticleEffectNames");
	}
	
	iParticleIndex = FindStringIndex(iParticleTable, strParticle);
	if (iParticleIndex == INVALID_STRING_INDEX)
	{
		ThrowError("Could not find particle index: %s", strParticle);
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", vecOrigin[0]);
	TE_WriteFloat("m_vecOrigin[1]", vecOrigin[1]);
	TE_WriteFloat("m_vecOrigin[2]", vecOrigin[2]);
	TE_WriteFloat("m_vecStart[0]", vecStart[0]);
	TE_WriteFloat("m_vecStart[1]", vecStart[1]);
	TE_WriteFloat("m_vecStart[2]", vecStart[2]);
	TE_WriteVector("m_vecAngles", vecAngles);
	TE_WriteNum("m_iParticleSystemIndex", iParticleIndex);
	
	if (iEntity != -1)
	{
		TE_WriteNum("entindex", iEntity);
	}
	
	if (AttachmentType != PATTACH_ABSORIGIN)
	{
		TE_WriteNum("m_iAttachType", view_as<int>(AttachmentType));
	}
	
	if (iAttachmentPoint != -1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", iAttachmentPoint);
	}
	
	TE_WriteNum("m_bResetParticles", bResetParticles ? 1 : 0);
	
	TE_SendToAll();
}

stock int PrecacheParticleSystem(const char[] strParticleSystem)
{
	static int iParticleEffectNames = INVALID_STRING_TABLE;
	
	if (iParticleEffectNames == INVALID_STRING_TABLE)
	{
		if ((iParticleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE)
		{
			return INVALID_STRING_INDEX;
		}
	}
	
	int iIndex = FindStringIndex2(iParticleEffectNames, strParticleSystem);
	if (iIndex == INVALID_STRING_INDEX)
	{
		int iNumStrings = GetStringTableNumStrings(iParticleEffectNames);
		if (iNumStrings >= GetStringTableMaxStrings(iParticleEffectNames))
		{
			return INVALID_STRING_INDEX;
		}
		
		AddToStringTable(iParticleEffectNames, strParticleSystem);
		iIndex = iNumStrings;
	}
	
	return iIndex;
}

stock int FindStringIndex2(int iTableIndex, const char[] strString)
{
    char strBuffer[1024];
    
    int iNumStrings = GetStringTableNumStrings(iTableIndex);
    for (int iIndex = 0; iIndex < iNumStrings; iIndex++)
    {
        ReadStringTable(iTableIndex, iIndex, strBuffer, sizeof(strBuffer));
        
        if (StrEqual(strBuffer, strString))
        {
            return iIndex;
        }
    }
    
    return INVALID_STRING_INDEX;
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**     ____      __            ____           _            
**    /  _/___  / /____  _____/ __/___ ______(_)___  ____ _
**    / // __ \/ __/ _ \/ ___/ /_/ __ `/ ___/ / __ \/ __ `/
**  _/ // / / / /_/  __/ /  / __/ /_/ / /__/ / / / / /_/ / 
** /___/_/ /_/\__/\___/_/  /_/  \__,_/\___/_/_/ /_/\__, /  
**                                                /____/   
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

// No enum structs for the rockets and rocket classes yet...
public any Native_IsValidRocket(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return IsValidRocket(iIndex);
}

public any Native_FindRocketByEntity(Handle hPlugin, int iNumParams)
{
	int iEntity = GetNativeCell(1);
	
	if (!IsValidEntity(iEntity))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Entity %i is invalid", iEntity);
	}
	
	return FindRocketByEntity(iEntity);
}

public any Native_IsDodgeballEnabled(Handle hPlugin, int iNumParams)
{
	return g_bEnabled;
}

public any Native_GetRocketEntity(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketEntity[iIndex];
}

public any Native_GetRocketFlags(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketFlags[iIndex];
}

public any Native_SetRocketFlags(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	RocketFlags iFlags = GetNativeCell(2);
	
	g_iRocketFlags[iIndex] = iFlags;
}

public any Native_GetRocketTarget(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketTarget[iIndex];
}

public any Native_SetRocketTarget(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	int iTarget = GetNativeCell(2);
	
	g_iRocketTarget[iIndex] = iTarget;
}

public any Native_GetRocketEventDeflections(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketEventDeflections[iIndex];
}

public any Native_SetRocketEventDeflections(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	int iDeflections = GetNativeCell(2);
	
	g_iRocketEventDeflections[iIndex] = iDeflections;
}

public any Native_GetRocketAltDeflections(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketAltDeflections[iIndex];
}

public any Native_SetRocketAltDeflections(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	int iDeflections = GetNativeCell(2);
	
	g_iRocketAltDeflections[iIndex] = iDeflections;
}

public any Native_GetRocketDeflections(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketDeflections[iIndex];
}

public any Native_SetRocketDeflections(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	int iDeflections = GetNativeCell(2);
	
	g_iRocketDeflections[iIndex] = iDeflections;
}

public any Native_GetRocketClass(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketClass[iIndex];
}

public any Native_SetRocketClass(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	int iClass = GetNativeCell(2);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	g_iRocketClass[iIndex] = iClass;
}

public any Native_GetRocketClassCount(Handle hPlugin, int iNumParams)
{
	return g_iRocketClassCount;
}

public any Native_GetRocketClassBehaviour(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_iRocketClassBehaviour[iClass];
}

public any Native_SetRocketClassBehaviour(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	BehaviourTypes iBehaviour = GetNativeCell(2);
	
	g_iRocketClassBehaviour[iClass] = iBehaviour;
}

public any Native_GetRocketClassFlags(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_iRocketClassFlags[iClass];
}

public any Native_SetRocketClassFlags(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	RocketFlags iFlags = GetNativeCell(2);
	
	g_iRocketClassFlags[iClass] = iFlags;
}

public any Native_GetRocketClassDamage(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassDamage[iClass];
}

public any Native_SetRocketClassDamage(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fDamage = GetNativeCell(2);
	
	g_fRocketClassDamage[iClass] = fDamage;
}

public any Native_GetRocketClassDamageIncrement(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassDamageIncrement[iClass];
}

public any Native_SetRocketClassDamageIncrement(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fDamage = GetNativeCell(2);
	
	g_fRocketClassDamageIncrement[iClass] = fDamage;
}

public any Native_GetRocketClassSpeed(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassSpeed[iClass];
}

public any Native_SetRocketClassSpeed(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fSpeed = GetNativeCell(2);
	
	g_fRocketClassSpeed[iClass] = fSpeed;
}

public any Native_GetRocketClassSpeedIncrement(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassSpeedIncrement[iClass];
}

public any Native_SetRocketClassSpeedIncrement(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fSpeed = GetNativeCell(2);
	
	g_fRocketClassSpeedIncrement[iClass] = fSpeed;
}

public any Native_GetRocketClassSpeedLimit(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassSpeedLimit[iClass];
}

public any Native_SetRocketClassSpeedLimit(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fSpeed = GetNativeCell(2);
	
	g_fRocketClassSpeedLimit[iClass] = fSpeed;
}

public any Native_GetRocketClassTurnRate(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassTurnRate[iClass];
}

public any Native_SetRocketClassTurnRate(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fTurnRate = GetNativeCell(2);
	
	g_fRocketClassTurnRate[iClass] = fTurnRate;
}

public any Native_GetRocketClassTurnRateIncrement(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassTurnRateIncrement[iClass];
}

public any Native_SetRocketClassTurnRateIncrement(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fTurnRate = GetNativeCell(2);
	
	g_fRocketClassTurnRateIncrement[iClass] = fTurnRate;
}

public any Native_GetRocketClassTurnRateLimit(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassTurnRateLimit[iClass];
}

public any Native_SetRocketClassTurnRateLimit(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fTurnRate = GetNativeCell(2);
	
	g_fRocketClassTurnRateLimit[iClass] = fTurnRate;
}

public any Native_GetRocketClassElevationRate(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassElevationRate[iClass];
}

public any Native_SetRocketClassElevationRate(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fElevation = GetNativeCell(2);
	
	g_fRocketClassElevationRate[iClass] = fElevation;
}

public any Native_GetRocketClassElevationLimit(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassElevationLimit[iClass];
}

public any Native_SetRocketClassElevationLimit(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fElevation = GetNativeCell(2);
	
	g_fRocketClassElevationLimit[iClass] = fElevation;
}

public any Native_GetRocketClassRocketsModifier(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassRocketsModifier[iClass];
}

public any Native_SetRocketClassRocketsModifier(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fModifier = GetNativeCell(2);
	
	g_fRocketClassRocketsModifier[iClass] = fModifier;
}

public any Native_GetRocketClassPlayerModifier(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassPlayerModifier[iClass];
}

public any Native_SetRocketClassPlayerModifier(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fModifier = GetNativeCell(2);
	
	g_fRocketClassPlayerModifier[iClass] = fModifier;
}

public any Native_GetRocketClassControlDelay(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassControlDelay[iClass];
}

public any Native_SetRocketClassControlDelay(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fDelay = GetNativeCell(2);
	
	g_fRocketClassControlDelay[iClass] = fDelay;
}

public any Native_GetRocketClassDragTimeMin(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassDragTimeMin[iClass];
}

public any Native_SetRocketClassDragTimeMin(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fMin = GetNativeCell(2);
	
	g_fRocketClassDragTimeMin[iClass] = fMin;
}

public any Native_GetRocketClassDragTimeMax(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassDragTimeMax[iClass];
}

public any Native_SetRocketClassDragTimeMax(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fMax = GetNativeCell(2);
	
	g_fRocketClassDragTimeMax[iClass] = fMax;
}

public any Native_SetRocketClassCount(Handle hPlugin, int iNumParams)
{
	int iCount = GetNativeCell(1);
	
	g_iRocketClassCount = iCount;
}

public any Native_SetRocketEntity(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	int iEntity = GetNativeCell(2);
	
	g_iRocketEntity[iIndex] = iEntity;
}

public any Native_GetSavedParameters(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iParam = GetNativeCell(2);
	
	if (iParam >= 10 || iParam < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Saved parameter index %i is out of bounds", iClass);
	}
	
	return g_fSavedParameters[iClass][iParam];
}

public any Native_SetSavedParameters(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iParam = GetNativeCell(2);
	
	if (iParam >= 10 || iParam < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Saved parameter index %i is out of bounds", iClass);
	}
	
	float fValue = GetNativeCell(3);
	
	g_fSavedParameters[iClass][iParam] = fValue;
}

public any Native_GetSavedRocketClassFlags(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_iSavedRocketClassFlags[iClass];
}

public any Native_SetSavedRocketClassFlags(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	RocketFlags iFlags = GetNativeCell(2);
	
	g_iSavedRocketClassFlags[iClass] = iFlags;
}

public any Native_GetRocketClassMaxBounces(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_iRocketClassMaxBounces[iClass];
}

public any Native_SetRocketClassMaxBounces(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iBounces = GetNativeCell(2);
	
	g_iRocketClassMaxBounces[iClass] = iBounces;
}

public any Native_GetRocketClassSavedMaxBounces(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_iRocketClassSavedMaxBounces[iClass];
}

public any Native_SetRocketClassSavedMaxBounces(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iBounces = GetNativeCell(2);
	
	g_iRocketClassSavedMaxBounces[iClass] = iBounces;
}

public any Native_GetSpawnersName(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strSpawnersName[iSpawnerClass], iMaxLen);
}

public any Native_SetSpawnersName(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strSpawnersName[iSpawnerClass], sizeof(g_strSpawnersName[]), strBuffer);
}

public any Native_GetSpawnersMaxRockets(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	return g_iSpawnersMaxRockets[iSpawnerClass];
}

public any Native_SetSpawnersMaxRockets(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	int iMaxRockets = GetNativeCell(2);
	
	g_iSpawnersMaxRockets[iSpawnerClass] = iMaxRockets;
}

public any Native_GetSpawnersInterval(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	return g_fSpawnersInterval[iSpawnerClass];
}

public any Native_SetSpawnersInterval(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	float fInterval = GetNativeCell(2);
	
	g_fSpawnersInterval[iSpawnerClass] = fInterval;
}

public any Native_GetSpawnersChancesTable(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	Handle hClone = CloneHandle(g_hSpawnersChancesTable[iSpawnerClass], hPlugin);
	
	return hClone;
}

public any Native_SetSpawnersChancesTable(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	ArrayList hTable = GetNativeCell(2);
	
	hTable = view_as<ArrayList>(CloneHandle(hTable));
	
	delete g_hSpawnersChancesTable[iSpawnerClass];
	
	g_hSpawnersChancesTable[iSpawnerClass] = hTable;
}

public any Native_GetSavedChancesTable(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	Handle hClone = CloneHandle(g_hSavedChancesTable[iSpawnerClass], hPlugin);
	
	return hClone;
}

public any Native_SetSavedChancesTable(Handle hPlugin, int iNumParams)
{
	int iSpawnerClass = GetNativeCell(1);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	ArrayList hTable = GetNativeCell(2);
	
	hTable = view_as<ArrayList>(CloneHandle(hTable));
	
	delete g_hSavedChancesTable[iSpawnerClass];
	
	g_hSavedChancesTable[iSpawnerClass] = hTable;
}

public any Native_GetSpawnersCount(Handle hPlugin, int iNumParams)
{
	return g_iSpawnersCount;
}

public any Native_SetSpawnersCount(Handle hPlugin, int iNumParams)
{
	int iCount = GetNativeCell(1);
	
	g_iSpawnersCount = iCount;
}

public any Native_GetCurrentRedSpawn(Handle hPlugin, int iNumParams)
{
	return g_iCurrentRedSpawn;
}

public any Native_SetCurrentRedSpawn(Handle hPlugin, int iNumParams)
{
	int iRedSpawn = GetNativeCell(1);
	
	g_iCurrentRedSpawn = iRedSpawn;
}

public any Native_GetSpawnPointsRedCount(Handle hPlugin, int iNumParams)
{
	return g_iSpawnPointsRedCount;
}

public any Native_SetSpawnPointsRedCount(Handle hPlugin, int iNumParams)
{
	int iCount = GetNativeCell(1);
	
	g_iSpawnPointsRedCount = iCount;
}

public any Native_GetSpawnPointsRedClass(Handle hPlugin, int iNumParams)
{
	int iSpawner = GetNativeCell(1);
	
	if (iSpawner >= MAX_SPAWN_POINTS || iSpawner < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner index %i is out of bounds", iSpawner);
	}
	
	return g_iSpawnPointsRedClass[iSpawner];
}

public any Native_SetSpawnPointsRedClass(Handle hPlugin, int iNumParams)
{
	int iSpawner = GetNativeCell(1);
	
	if (iSpawner >= MAX_SPAWN_POINTS || iSpawner < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner index %i is out of bounds", iSpawner);
	}
	
	int iSpawnerClass = GetNativeCell(2);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	g_iSpawnPointsRedClass[iSpawner] = iSpawnerClass;
}

public any Native_GetSpawnPointsRedEntity(Handle hPlugin, int iNumParams)
{
	int iSpawner = GetNativeCell(1);
	
	if (iSpawner >= MAX_SPAWN_POINTS || iSpawner < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner index %i is out of bounds", iSpawner);
	}
	
	return g_iSpawnPointsRedEntity[iSpawner];
}

public any Native_SetSpawnPointsRedEntity(Handle hPlugin, int iNumParams)
{
	int iSpawner = GetNativeCell(1);
	
	if (iSpawner >= MAX_SPAWN_POINTS || iSpawner < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner index %i is out of bounds", iSpawner);
	}
	
	int iEntity = GetNativeCell(2);
	
	g_iSpawnPointsRedEntity[iSpawner] = iEntity;
}

public any Native_GetCurrentBluSpawn(Handle hPlugin, int iNumParams)
{
	return g_iCurrentBluSpawn;
}

public any Native_SetCurrentBluSpawn(Handle hPlugin, int iNumParams)
{
	int iBluSpawn = GetNativeCell(1);
	
	g_iCurrentBluSpawn = iBluSpawn;
}

public any Native_GetSpawnPointsBluCount(Handle hPlugin, int iNumParams)
{
	return g_iSpawnPointsBluCount;
}

public any Native_SetSpawnPointsBluCount(Handle hPlugin, int iNumParams)
{
	int iCount = GetNativeCell(1);
	
	g_iSpawnPointsBluCount = iCount;
}

public any Native_GetSpawnPointsBluClass(Handle hPlugin, int iNumParams)
{
	int iSpawner = GetNativeCell(1);
	
	if (iSpawner >= MAX_SPAWN_POINTS || iSpawner < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner index %i is out of bounds", iSpawner);
	}
	
	return g_iSpawnPointsBluClass[iSpawner];
}

public any Native_SetSpawnPointsBluClass(Handle hPlugin, int iNumParams)
{
	int iSpawner = GetNativeCell(1);
	
	if (iSpawner >= MAX_SPAWN_POINTS || iSpawner < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner index %i is out of bounds", iSpawner);
	}
	
	int iSpawnerClass = GetNativeCell(2);
	
	if (iSpawnerClass >= MAX_SPAWNER_CLASSES || iSpawnerClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner class index %i is out of bounds", iSpawnerClass);
	}
	
	g_iSpawnPointsBluClass[iSpawner] = iSpawnerClass;
}

public any Native_GetSpawnPointsBluEntity(Handle hPlugin, int iNumParams)
{
	int iSpawner = GetNativeCell(1);
	
	if (iSpawner >= MAX_SPAWN_POINTS || iSpawner < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner index %i is out of bounds", iSpawner);
	}
	
	return g_iSpawnPointsBluEntity[iSpawner];
}

public any Native_SetSpawnPointsBluEntity(Handle hPlugin, int iNumParams)
{
	int iSpawner = GetNativeCell(1);
	
	if (iSpawner >= MAX_SPAWN_POINTS || iSpawner < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Spawner index %i is out of bounds", iSpawner);
	}
	
	int iEntity = GetNativeCell(2);
	
	g_iSpawnPointsBluEntity[iSpawner] = iEntity;
}

public any Native_GetRoundStarted(Handle hPlugin, int iNumParams)
{
	return g_bRoundStarted;
}

public any Native_GetRoundCount(Handle hPlugin, int iNumParams)
{
	return g_iRoundCount;
}

public any Native_GetRocketsFired(Handle hPlugin, int iNumParams)
{
	return g_iRocketsFired;
}

public any Native_GetNextSpawnTime(Handle hPlugin, int iNumParams)
{
	return g_fNextSpawnTime;
}

public any Native_SetNextSpawnTime(Handle hPlugin, int iNumParams)
{
	float fSpawnTime = GetNativeCell(1);
	
	g_fNextSpawnTime = fSpawnTime;
}

public any Native_GetLastDeadTeam(Handle hPlugin, int iNumParams)
{
	return g_iLastDeadTeam;
}

public any Native_GetLastDeadClient(Handle hPlugin, int iNumParams)
{
	return g_iLastDeadClient;
}

public any Native_GetLastStealer(Handle hPlugin, int iNumParams)
{
	return g_iLastStealer;
}

public any Native_GetRocketFakeEntity(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketFakeEntity[iIndex];
}

public any Native_SetRocketFakeEntity(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	int iFakeEntity = GetNativeCell(2);
	
	g_iRocketFakeEntity[iIndex] = iFakeEntity;
}

public any Native_GetRocketSpeed(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_fRocketSpeed[iIndex];
}

public any Native_SetRocketSpeed(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	float fSpeed = GetNativeCell(2);
	
	g_fRocketSpeed[iIndex] = fSpeed;
}

public any Native_GetRocketMphSpeed(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_fRocketMphSpeed[iIndex];
}

public any Native_SetRocketMphSpeed(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	float fSpeed = GetNativeCell(2);
	
	g_fRocketMphSpeed[iIndex] = fSpeed;
}

public any Native_GetRocketDirection(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	SetNativeArray(2, g_fRocketDirection[iIndex], sizeof(g_fRocketDirection[]));
}

public any Native_SetRocketDirection(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	float fDirection[3]; GetNativeArray(2, fDirection, sizeof(fDirection));
	
	CopyVectors(fDirection, g_fRocketDirection[iIndex]);
}

public any Native_GetRocketLastDeflectionTime(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_fRocketLastDeflectionTime[iIndex];
}

public any Native_GetRocketCount(Handle hPlugin, int iNumParams)
{
	return g_iRocketCount;
}

public any Native_GetIsRocketBouncing(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_bIsRocketBouncing[iIndex];
}

public any Native_SetIsRocketBouncing(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	bool bBouncing = GetNativeCell(2);
	
	g_bIsRocketBouncing[iIndex] = bBouncing;
}

public any Native_GetIsRocketStolen(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_bIsRocketStolen[iIndex];
}

public any Native_GetPreventingDelay(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_bPreventingDelay[iIndex];
}

public any Native_GetIsRocketDraggable(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_bIsRocketDraggable[iIndex];
}

public any Native_SetIsRocketDraggable(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	bool bDraggable = GetNativeCell(2);
	
	g_bIsRocketDraggable[iIndex] = bDraggable;
}

public any Native_GetRocketBounces(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	return g_iRocketBounces[iIndex];
}

public any Native_SetRocketBounces(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	if (iIndex >= MAX_ROCKETS || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket index %i is out of bounds", iIndex);
	}
	
	int iBounces = GetNativeCell(2);
	
	g_iRocketBounces[iIndex] = iBounces;
}

public any Native_GetRocketClassName(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassName[iClass], iMaxLen);
}

public any Native_SetRocketClassName(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassName[iClass], sizeof(g_strRocketClassName[]), strBuffer);
}

public any Native_GetRocketClassLongName(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassLongName[iClass], iMaxLen);
}

public any Native_SetRocketClassLongName(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassLongName[iClass], sizeof(g_strRocketClassLongName[]), strBuffer);
}

public any Native_GetRocketClassModel(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassModel[iClass], iMaxLen);
}

public any Native_SetRocketClassModel(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassModel[iClass], sizeof(g_strRocketClassModel[]), strBuffer);
}

public any Native_GetRocketClassTrail(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassTrail[iClass], iMaxLen);
}

public any Native_SetRocketClassTrail(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassTrail[iClass], sizeof(g_strRocketClassTrail[]), strBuffer);
}

public any Native_GetRocketClassSprite(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassSprite[iClass], iMaxLen);
}

public any Native_SetRocketClassSprite(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassSprite[iClass], sizeof(g_strRocketClassSprite[]), strBuffer);
}

public any Native_GetRocketClassSpriteColor(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassSpriteColor[iClass], iMaxLen);
}

public any Native_SetRocketClassSpriteColor(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassSpriteColor[iClass], sizeof(g_strRocketClassSpriteColor[]), strBuffer);
}

public any Native_GetRocketClassSpriteLifetime(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassSpriteLifetime[iClass];
}

public any Native_SetRocketClassSpriteLifetime(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fLifetime = GetNativeCell(2);
	
	g_fRocketClassSpriteLifetime[iClass] = fLifetime;
}

public any Native_GetRocketClassSpriteStartWidth(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassSpriteStartWidth[iClass];
}

public any Native_SetRocketClassSpriteStartWidth(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fWidth = GetNativeCell(2);
	
	g_fRocketClassSpriteStartWidth[iClass] = fWidth;
}

public any Native_GetRocketClassSpriteEndWidth(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassSpriteEndWidth[iClass];
}

public any Native_SetRocketClassSpriteEndWidth(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fWidth = GetNativeCell(2);
	
	g_fRocketClassSpriteEndWidth[iClass] = fWidth;
}

public any Native_GetRocketClassBeepInterval(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassBeepInterval[iClass];
}

public any Native_SetRocketClassBeepInterval(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fInterval = GetNativeCell(2);
	
	g_fRocketClassBeepInterval[iClass] = fInterval;
}

public any Native_GetRocketClassSpawnSound(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassSpawnSound[iClass], iMaxLen);
}

public any Native_SetRocketClassSpawnSound(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassSpawnSound[iClass], sizeof(g_strRocketClassSpawnSound[]), strBuffer);
}

public any Native_GetRocketClassBeepSound(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassBeepSound[iClass], iMaxLen);
}

public any Native_SetRocketClassBeepSound(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassBeepSound[iClass], sizeof(g_strRocketClassBeepSound[]), strBuffer);
}

public any Native_GetRocketClassAlertSound(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen = GetNativeCell(3);
	
	SetNativeString(2, g_strRocketClassAlertSound[iClass], iMaxLen);
}

public any Native_SetRocketClassAlertSound(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	int iMaxLen; GetNativeStringLength(2, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(2, strBuffer, iMaxLen + 1);
	
	strcopy(g_strRocketClassAlertSound[iClass], sizeof(g_strRocketClassAlertSound[]), strBuffer);
}

public any Native_GetRocketClassCritChance(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassCritChance[iClass];
}

public any Native_SetRocketClassCritChance(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fChance = GetNativeCell(2);
	
	g_fRocketClassCritChance[iClass] = fChance;
}

public any Native_GetRocketClassTargetWeight(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassTargetWeight[iClass];
}

public any Native_SetRocketClassTargetWeight(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fWeight = GetNativeCell(2);
	
	g_fRocketClassTargetWeight[iClass] = fWeight;
}

public any Native_GetRocketClassCmdsOnSpawn(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	Handle hClone = CloneHandle(g_hRocketClassCmdsOnSpawn[iClass], hPlugin);
	
	return hClone;
}

public any Native_SetRocketClassCmdsOnSpawn(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	DataPack hCmds = GetNativeCell(2);
	
	hCmds = view_as<DataPack>(CloneHandle(hCmds));
	
	delete g_hRocketClassCmdsOnSpawn[iClass];
	
	g_hRocketClassCmdsOnSpawn[iClass] = hCmds;
}

public any Native_GetRocketClassCmdsOnDeflect(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	Handle hClone = CloneHandle(g_hRocketClassCmdsOnDeflect[iClass], hPlugin);
	
	return hClone;
}

public any Native_SetRocketClassCmdsOnDeflect(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	DataPack hCmds = GetNativeCell(2);
	
	hCmds = view_as<DataPack>(CloneHandle(hCmds));
	
	delete g_hRocketClassCmdsOnDeflect[iClass];
	
	g_hRocketClassCmdsOnDeflect[iClass] = hCmds;
}

public any Native_GetRocketClassCmdsOnKill(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	Handle hClone = CloneHandle(g_hRocketClassCmdsOnKill[iClass], hPlugin);
	
	return hClone;
}

public any Native_SetRocketClassCmdsOnKill(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	DataPack hCmds = GetNativeCell(2);
	
	hCmds = view_as<DataPack>(CloneHandle(hCmds));
	
	delete g_hRocketClassCmdsOnKill[iClass];
	
	g_hRocketClassCmdsOnKill[iClass] = hCmds;
}

public any Native_GetRocketClassCmdsOnExplode(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	Handle hClone = CloneHandle(g_hRocketClassCmdsOnExplode[iClass], hPlugin);
	
	return hClone;
}

public any Native_SetRocketClassCmdsOnExplode(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	DataPack hCmds = GetNativeCell(2);
	
	hCmds = view_as<DataPack>(CloneHandle(hCmds));
	
	delete g_hRocketClassCmdsOnExplode[iClass];
	
	g_hRocketClassCmdsOnExplode[iClass] = hCmds;
}

public any Native_GetRocketClassCmdsOnNoTarget(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	Handle hClone = CloneHandle(g_hRocketClassCmdsOnNoTarget[iClass], hPlugin);
	
	return hClone;
}

public any Native_SetRocketClassCmdsOnNoTarget(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	DataPack hCmds = GetNativeCell(2);
	
	hCmds = view_as<DataPack>(CloneHandle(hCmds));
	
	delete g_hRocketClassCmdsOnNoTarget[iClass];
	
	g_hRocketClassCmdsOnNoTarget[iClass] = hCmds;
}

public any Native_GetRocketClassBounceScale(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	return g_fRocketClassBounceScale[iClass];
}

public any Native_SetRocketClassBounceScale(Handle hPlugin, int iNumParams)
{
	int iClass = GetNativeCell(1);
	
	if (iClass >= MAX_ROCKET_CLASSES || iClass < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Rocket class index %i is out of bounds", iClass);
	}
	
	float fScale = GetNativeCell(2);
	
	g_fRocketClassBounceScale[iClass] = fScale;
}

public any Native_CreateRocket(Handle hPlugin, int iNumParams)
{
	int iSpawnerEntity = GetNativeCell(1);
	int iSpawnerClass  = GetNativeCell(2);
	int iTeam  = GetNativeCell(3);
	int iClass = GetNativeCell(4);
	
	CreateRocket(iSpawnerEntity, iSpawnerClass, iTeam, iClass);
}

public any Native_DestroyRocket(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	DestroyRocket(iIndex);
}

public any Native_DestroyRockets(Handle hPlugin, int iNumParams)
{
	DestroyRockets();
}

public any Native_DestroyRocketClasses(Handle hPlugin, int iNumParams)
{
	DestroyRocketClasses();
}

public any Native_DestroySpawners(Handle hPlugin, int iNumParams)
{
	DestroySpawners();
}

public any Native_ParseConfigurations(Handle hPlugin, int iNumParams)
{
	int iMaxLen; GetNativeStringLength(1, iMaxLen);
	
	char[] strBuffer = new char[iMaxLen + 1]; GetNativeString(1, strBuffer, iMaxLen + 1);
	
	ParseConfigurations(strBuffer);
}

public any Native_PopulateSpawnPoints(Handle hPlugin, int iNumParams)
{
	PopulateSpawnPoints();
}

public any Native_HomingRocketThink(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	HomingRocketThink(iIndex);
}

public any Native_RocketOtherThink(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	RocketOtherThink(iIndex);
}

public any Native_RocketLegacyThink(Handle hPlugin, int iNumParams)
{
	int iIndex = GetNativeCell(1);
	
	RocketLegacyThink(iIndex);
}

void Forward_OnRocketCreated(int iIndex, int iEntity)
{
	Call_StartForward(g_hForwardOnRocketCreated);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_Finish();
}

Action Forward_OnRocketCreatedPre(int iIndex, int &iClass, RocketFlags &iFlags)
{
	Action aResult;
	
	Call_StartForward(g_hForwardOnRocketCreatedPre);
	Call_PushCell(iIndex);
	Call_PushCellRef(iClass);
	Call_PushCellRef(iFlags);
	Call_Finish(aResult);
	
	return aResult;
}

void Forward_OnRocketAltDeflect(int iIndex, int iEntity, int iOwner)
{
	Call_StartForward(g_hForwardOnRocketAltDeflect);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_PushCell(iOwner);
	Call_Finish();
}

void Forward_OnRocketDeflect(int iIndex, int iEntity, int iOwner)
{
	Call_StartForward(g_hForwardOnRocketDeflect);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_PushCell(iOwner);
	Call_Finish();
}

Action Forward_OnRocketDeflectPre(int iIndex, int iEntity, int iOwner, int &iTarget)
{
	Action aResult;
	
	Call_StartForward(g_hForwardOnRocketDeflectPre);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_PushCell(iOwner);
	Call_PushCellRef(iTarget);
	Call_Finish(aResult);
	
	return aResult;
}

void Forward_OnRocketSteal(int iIndex, int iOwner, int iTarget, int iStealCount)
{
	Call_StartForward(g_hForwardOnRocketSteal);
	Call_PushCell(iIndex);
	Call_PushCell(iOwner);
	Call_PushCell(iTarget);
	Call_PushCell(iStealCount);
	Call_Finish();
}

void Forward_OnRocketNoTarget(int iIndex, int iTarget, int iOwner)
{
	Call_StartForward(g_hForwardOnRocketNoTarget);
	Call_PushCell(iIndex);
	Call_PushCell(iTarget);
	Call_PushCell(iOwner);
	Call_Finish();
}

void Forward_OnRocketDelay(int iIndex, int iTarget)
{
	Call_StartForward(g_hForwardOnRocketDelay);
	Call_PushCell(iIndex);
	Call_PushCell(iTarget);
	Call_Finish();
}

void Forward_OnRocketBounce(int iIndex, int iEntity)
{
	Call_StartForward(g_hForwardOnRocketBounce);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_Finish();
}

Action Forward_OnRocketBouncePre(int iIndex, int iEntity, float fAngles[3], float fVelocity[3])
{
	Action aResult;
	
	Call_StartForward(g_hForwardOnRocketBouncePre);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_PushArrayEx(fAngles, sizeof(fAngles), SM_PARAM_COPYBACK);
	Call_PushArrayEx(fVelocity, sizeof(fVelocity), SM_PARAM_COPYBACK);
	Call_Finish(aResult);
	
	return aResult;
}

// EOF
