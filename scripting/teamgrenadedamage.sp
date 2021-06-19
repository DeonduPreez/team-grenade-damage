#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

#define MENU_TIME_LENGTH 15

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <sdkhooks>
#include <cstrike>
#include <kento_csgocolors>

/* Global Vars */
bool isHooked[MAXPLAYERS + 1]; // <- Contains the status of the clients

public Plugin myinfo = {
    name = "Team Grenade Damage",
    author = "Metal Injection",
    description = "",
    version = PLUGIN_VERSION,
    url = "https://github.com/DeonduPreez/TeamGrenadeDamage"
};

public void OnPluginStart()
{
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		if (IsClientValid(i) && !isHooked[i])
		{
			isHooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType)
{
	// Check if it's a valid client
	if (victim <= 0 || victim > MaxClients || attacker <= 0 || attacker > MaxClients || victim == attacker)
		return Plugin_Continue;

	// Check if it's a teammate
	if (!IsTeammate(victim, attacker))
		return Plugin_Continue;

	// Check if it should not do damage
	if(!ShouldDoDamage(damageType))
	{
		// Disable damage
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public bool IsTeammate(int victim, int attacker)
{
	return GetClientTeam(victim) == GetClientTeam(attacker);
}

public bool ShouldDoDamage(int damageType)
{
	return damageType == 8 || damageType == 128 || damageType == 64 || damageType == 0;
}

public void OnMapEnd()
{
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		if (IsClientValid(i) && isHooked[i])
		{
			PrintToServer("-----------------UNHOOKED: %d -----------------------", i);
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

/* SERVER JOIN */
public void OnClientPostAdminCheck(int client)
{
	if (!isHooked[client])
	{
		isHooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}

	CPrintToChat(client, "{RED}Please note: This server is currently testing molotov damage on teammates. If you find any issues, please type !report in chat, select yourself and explain the issue in chat. An admin will try and assist you as soon as possible.");
}

/* SERVER DISCONNECT */
public void OnClientDisconnect(int client)
{
	if (isHooked[client])
	{
		isHooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

/* SERVER JOIN */
public bool IsClientValid(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (IsFakeClient(client)))
    {
        return false;
    }
    return IsClientInGame(client);
}