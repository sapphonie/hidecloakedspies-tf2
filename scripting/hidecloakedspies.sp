#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin myinfo =
{
    name             = "Really Hide Cloaked Spies",
    author           = "steph&",
    description      = "Prevent cheaters from seeing cloaked spies!",
    version          = "0.0.1",
    url              = "https://sappho.io"
}

float timeSinceCloak[MAXPLAYERS+1];
bool isCloaked[MAXPLAYERS+1];

public void OnClientPutInServer(int client)
{
    clearVars(client);
    SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnClientDisconnect_Post(int client)
{
    clearVars(client);
}

clearVars(int client)
{
    timeSinceCloak[client] = 0.000000;
    isCloaked[client] = false;
}

public void OnPluginStart()
{
    // need this if testing with bots!!!!
    //SetConVarInt(FindConVar("sv_stressbots"), 1);

    // loop thru clients and hook valid ones
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client))
        {
            SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
        }
    }
}

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
    // only classify a player as "cloaked" if they have NO other conditions BESIDES
    // cloaked or cloaked AND disguising
    if (TF2_GetPlayerClass(client) == TFClass_Spy)
    {
        // deprecated my fuckin ass
        int flags = TF2_GetPlayerConditionFlags2(client);
        if
        (
            flags == TF_CONDFLAG_CLOAKED
            ||
            flags == (TF_CONDFLAG_DISGUISED + TF_CONDFLAG_CLOAKED)
        )
        {
            if (!isCloaked[client])
            {
                isCloaked[client] = true;
                timeSinceCloak[client] = GetEngineTime();
            }
        }
        else
        {
            if (isCloaked[client])
            {
                isCloaked[client] = false;
            }
        }
    }
}

// SetTransmit: Will entity transmit to client?
// By default, return Plugin_Continue (aka yes)
// Only return Plugin_Handled (aka no) if we meet a bunch of critereon
public Action Hook_SetTransmit(int entity, int client)
{
    // make sure we always transmit to ourselves
    if (entity != client)
    {
        // only want to check if the cloaking player (entity) is a spy
        if (TF2_GetPlayerClass(entity) == TFClass_Spy)
        {
            TFTeam eteam = TF2_GetClientTeam(entity);
            TFTeam cteam = TF2_GetClientTeam(client);

            // teammates should always be able to see their own team's cloaked spies!
            if (eteam != cteam)
            {
                // are they actually cloaked?
                if (isCloaked[entity])
                {
                    // spy cloak takes 1 second.
                    // we need to wait until they're FULLY cloaked for this to work right
                    // this also works as a nice buffer for any other conditions
                    // if we got this far, block transmitting the cloaked spy!
                    if (timeSinceCloak[entity] + 1.01 <= GetEngineTime())
                    {
                        return Plugin_Handled;
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    return ((0 < client <= MaxClients) && IsClientInGame(client));
}

// stop whining, sourcemod
int TF2_GetPlayerConditionFlags2(int client)
{
    return GetEntProp(client, Prop_Send, "m_nPlayerCond") | GetEntProp(client, Prop_Send, "_condition_bits");
}
