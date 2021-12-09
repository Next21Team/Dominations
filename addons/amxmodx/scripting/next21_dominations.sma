#include <amxmodx>

new const PLUGIN[] = "Dominations"
new const VERSION[] = "0.65"
new const AUTHOR[] = "Psycrow"

new const CHAT_MESSAGE_FMT[] = "^4[%s] %L"

new const SOUND_DOMINATION[] = "next21_dominations/tf_domination.wav"
new const SOUND_REVENGE[] = "next21_dominations/tf_revenge.wav"
new const SOUND_FREEZE_CAM[] = "next21_dominations/freeze_cam.wav"

#define is_entity_player(%1)	(1<=%1&&%1<=g_iMaxplayers)

new g_iFrags[MAX_PLAYERS + 1][MAX_PLAYERS + 1], g_iMaxplayers
new g_iCvarFrags, g_iCvarSounds, g_iCvarTeam


public plugin_natives()
{
    register_native("n21_set_flag_dmn", "_n21_set_flag_dmn", 0)
}

public plugin_precache()
{		
    precache_sound(SOUND_DOMINATION)
    precache_sound(SOUND_REVENGE)
    precache_sound(SOUND_FREEZE_CAM)
}
    
public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    register_event("DeathMsg", "Event_DeathMsg", "a")

    bind_pcvar_num(register_cvar("dominations_frags", "3"), g_iCvarFrags)
    bind_pcvar_num(register_cvar("dominations_sounds", "1"), g_iCvarSounds)
    bind_pcvar_num(register_cvar("dominations_team", "1"), g_iCvarTeam)

    register_dictionary("next21_dominations.txt")
            
    g_iMaxplayers = get_maxplayers()
}

public client_disconnected(iPlayer)
{
    arrayset(g_iFrags[iPlayer], 0, MAX_PLAYERS + 1)

    new aDominators[MAX_PLAYERS], iNum
    for (new i = 1; i <= g_iMaxplayers; i++)
    {
        if (g_iFrags[i][iPlayer] >= g_iCvarFrags)
            aDominators[iNum++] = i 
        g_iFrags[i][iPlayer] = 0
    }

    if (iNum)
    {
        if (iNum > 1)
        {
            new szMessage[256], iLen
            client_print_color(0, iPlayer, CHAT_MESSAGE_FMT, PLUGIN, LANG_PLAYER,
                "DOMINATION_DISCONNECT_MULT", iPlayer)
            szMessage[0] = '^t'
            for (new i; i < iNum; i++)
            {
                iLen += add(szMessage, charsmax(szMessage), fmt("^4%n%s", aDominators[i], (i < iNum - 1) ? "^1, " : ""))
                if (iLen > 93)
                {
                    add(szMessage, charsmax(szMessage), "...")
                    break
                }
            }
            client_print_color(0, print_team_default, "%s", szMessage)
        }
        else
        {
            client_print_color(0, iPlayer, CHAT_MESSAGE_FMT, PLUGIN, LANG_PLAYER,
                "DOMINATION_DISCONNECT_ONE", iPlayer, aDominators[0])
        }
    }
}

public Event_DeathMsg()
{
    set_flags(read_data(1), read_data(2))
}

set_flags(iAttacker, iVictim)
{
    if (!is_entity_player(iAttacker))
        return
    
    if (g_iCvarTeam && get_user_team(iAttacker) == get_user_team(iVictim))
        return

    g_iFrags[iAttacker][iVictim]++

    if (g_iFrags[iAttacker][iVictim] == g_iCvarFrags)
    {
        client_print_color(0, iAttacker, CHAT_MESSAGE_FMT, PLUGIN, LANG_PLAYER,
            "DOMINATION_ADD", iAttacker, iVictim)
        if (g_iCvarSounds)
            emit_sound(iAttacker, CHAN_AUTO, SOUND_DOMINATION, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    }
    else if (g_iFrags[iAttacker][iVictim] > g_iCvarFrags)
    {
        client_print_color(iAttacker, iVictim, CHAT_MESSAGE_FMT, PLUGIN, iVictim,
            "DOMINATION_KILL_A", iVictim)
        client_print_color(iVictim, iAttacker, CHAT_MESSAGE_FMT, PLUGIN, iVictim,
            "DOMINATION_KILL_V", iAttacker)
        if (g_iCvarSounds)
            client_cmd(iVictim, "spk %s", SOUND_FREEZE_CAM)
    }
    else if (g_iFrags[iVictim][iAttacker] >= g_iCvarFrags)
    {
        client_print_color(0, iAttacker, CHAT_MESSAGE_FMT, PLUGIN, LANG_PLAYER, 
            "DOMINATION_REVENGE", iAttacker, iVictim)
        if (g_iCvarSounds)
            emit_sound(iAttacker, CHAN_AUTO, SOUND_REVENGE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    }
    
    g_iFrags[iVictim][iAttacker] = 0
}

public _n21_set_flag_dmn(plugin, num_params)
{
    set_flags(get_param(1), get_param(2))
}
