#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>

public Plugin myinfo =
{
    name             = "Really Hide Cloaked Spies",
    author           = "steph&",
    description      = "Prevent cheaters from seeing or hearing cloaked spies",
    version          = "0.0.2",
    url              = "https://sappho.io"
}

int clientTeam[MAXPLAYERS+1];
bool isHooked[MAXPLAYERS+1];

public Action OnPlayerRunCmd
(
    int client,
    int& buttons,
    int& impulse,
    float vel[3],
    float angles[3],
    int& weapon,
    int& subtype,
    int& cmdnum,
    int& tickcount,
    int& seed,
    int mouse[2]
)
{
    clientTeam[client] = GetClientTeam(client);

    // dead or not on a team
    if (!IsPlayerAlive(client) || clientTeam[client] < 2)
    {
        return Plugin_Continue;
    }

    // they're a spy
    if (TF2_GetPlayerClass(client) == TFClass_Spy)
    {
        if
        (
            // they're mostly invis
            GetPercentInvisible(client) >= 0.99
            // not bumping into players
            && !TF2_IsPlayerInCondition(client, TFCond_CloakFlicker)
            // they dont have cloak particles
            && !TF2_IsPlayerInCondition(client, TFCond_Disguising)
            // theyre not covered in piss or milk or bleeding
            && !TF2_IsPlayerInCondition(client, TFCond_Jarated)
            && !TF2_IsPlayerInCondition(client, TFCond_Milked)
            && !TF2_IsPlayerInCondition(client, TFCond_Bleeding)
        )
        {
            if (!isHooked[client])
            {
                LogMessage("hooking %N - %f", client, GetPercentInvisible(client));
                SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
                isHooked[client] = true;
            }
        }
        else
        {
            if (isHooked[client])
            {
                LogMessage("unhooking %N - %f", client, GetPercentInvisible(client));
                SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit)
                isHooked[client] = false;
            }
        }
    }
    return Plugin_Continue;
}


public Action Hook_SetTransmit(int spy, int client)
{
    if (clientTeam[spy] != clientTeam[client])
    {
        SetEdictFlags(spy, (GetEdictFlags(spy) & ~FL_EDICT_ALWAYS));
        return Plugin_Handled
    }
    return Plugin_Continue;
}

stock float GetPercentInvisible(int client)
{
    static int offset;
    offset = FindSendPropInfo("CTFPlayer", "m_flInvisChangeCompleteTime") - 8;
    return GetEntDataFloat(client, offset);
}
