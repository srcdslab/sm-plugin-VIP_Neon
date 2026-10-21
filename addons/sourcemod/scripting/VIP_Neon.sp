#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>
#include <clientprefs>

public Plugin:myinfo =
{
	name        = "[VIP] Neon",
	version     = "1.3",
    description	= "Colored neons",
	author      = "R1KO & Pheonix (˙·٠●Феникс●٠·˙)",
    url			= "www.hlmod.ru",
};

static const String:g_sFeature[][] = {"VIP_Neon", "VIP_Neon_Menu"};

new g_iClientColor[MAXPLAYERS+1][4],
	g_iNeon[MAXPLAYERS+1],
	g_iClientItem[MAXPLAYERS+1];

//new bool:g_bHide;
new KeyValues:g_hKeyValues, Menu:g_hColorsMenu, Cookie:g_hCookie;

bool g_bHideNeon[MAXPLAYERS +1] = {false, ...};
Cookie g_hHideNeonCookie;

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature[0], BOOL, _, OnToggleItem);
	VIP_RegisterFeature(g_sFeature[1], _, SELECTABLE, OnSelectItem, _, OnDrawItem);
}

public OnPluginStart()
{
	g_hCookie = new Cookie("VIP_Neon", "VIP_Neon", CookieAccess_Public);
	g_hHideNeonCookie = new Cookie("VIP_HideNeon", "VIP_HideNeon", CookieAccess_Public);
	
	g_hHideNeonCookie.SetPrefabMenu(CookieMenu_YesNo_Int, "Disable VIP Neon colors", HideHandle);
	
	g_hColorsMenu = new Menu(Handler_ColorsMenu, MenuAction_Select|MenuAction_Display|MenuAction_Cancel|MenuAction_DisplayItem);
	g_hColorsMenu.ExitBackButton = true;

	HookEvent("player_death", Event_PlayerDeath);

	LoadTranslations("vip_modules.phrases");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void HideHandle(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    if(action == CookieMenuAction_SelectOption)
    {
        OnClientCookiesCached(client);
    }
}

public void OnClientCookiesCached(int client)
{
	char CookieValue[8];
	g_hHideNeonCookie.Get(client, CookieValue, sizeof(CookieValue));
	g_bHideNeon[client] = view_as<bool>(StringToInt(CookieValue));
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature[0]);
		VIP_UnregisterFeature(g_sFeature[1]);
	}
}

public OnMapStart()
{
	g_hColorsMenu.RemoveAllItems();

	if(g_hKeyValues != null)
	{
		delete g_hKeyValues;
	}
	g_hKeyValues = new KeyValues("Neon_Colors");
	if (g_hKeyValues.ImportFromFile("addons/sourcemod/data/vip/modules/neon_colors.ini") == false)
	{
		delete g_hKeyValues;
		SetFailState("Couldn't parse file \"addons/sourcemod/data/vip/modules/neon_colors.ini\"");
	}

	//g_bHide = bool:KvGetNum(g_hKeyValues, "Hide_Opposite_Team");

	g_hKeyValues.Rewind();
	if(g_hKeyValues.JumpToKey("Colors") && g_hKeyValues.GotoFirstSubKey(false))
	{
		decl String:sColor[64];
		do
		{
			if (g_hKeyValues.GetSectionName(sColor, sizeof(sColor)))
			{
				g_hColorsMenu.AddItem(sColor, sColor);
			}
		}
		while (g_hKeyValues.GotoNextKey(false));
	}
	g_hKeyValues.Rewind();
}

public VIP_OnVIPClientLoaded(iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature[0]) != NO_ACCESS)
	{
		decl String:sColor[64];
		g_hCookie.Get(iClient, sColor, sizeof(sColor));
		if(sColor[0] == 0 || LoadClientColor(iClient, sColor) == false)
		{
			g_iClientItem[iClient] = 0;
			g_hColorsMenu.GetItem(g_iClientItem[iClient], sColor, sizeof(sColor));
			g_hCookie.Set(iClient, sColor);
			LoadClientColor(iClient, sColor);
		}
		else
		{
			g_iClientItem[iClient] = UTIL_GetItemIndex(sColor);
		}
	}
}

bool:LoadClientColor(iClient, const String:sColor[])
{
	g_hKeyValues.Rewind();
	if (g_hKeyValues.JumpToKey("Colors"))
	{
		decl String:sBuffer[64];
		g_hKeyValues.GetString(sColor, sBuffer, sizeof(sBuffer));
		if(StrEqual(sBuffer, "randomcolor"))
		{
			g_iClientColor[iClient][2] = -1;
		}
		else if(StrEqual(sBuffer, "teamcolor"))
		{
			g_iClientColor[iClient][2] = -2;
		}
		else
		{
			g_hKeyValues.GetColor(sColor, g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);
		}

		g_hKeyValues.Rewind();
		return true;
	}
	
	return false;
}

UTIL_GetItemIndex(const String:sItemInfo[])
{
	decl String:sColor[64], i, iSize;
	iSize = g_hColorsMenu.ItemCount;
	for(i = 0; i < iSize; ++i)
	{
		g_hColorsMenu.GetItem(i, sColor, sizeof(sColor));
		if(strcmp(sColor, sItemInfo) == 0)
		{
			return i;
		}
	}

	return -1;
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	g_hColorsMenu.Display(iClient, MENU_TIME_FOREVER);
	return false;
}

public Handler_ColorsMenu(Menu:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Display:
		{
	 		decl String:sBuffer[255];
			FormatEx(sBuffer, sizeof(sBuffer), "%T", g_sFeature[1], iClient);
 
			view_as<Panel>(Item).SetTitle(sBuffer);
		}
		case MenuAction_Select:
		{
			decl String:sColor[64];
			hMenu.GetItem(Item, sColor, sizeof(sColor));
			g_iClientItem[iClient] = Item;
			if(LoadClientColor(iClient, sColor))
			{
				VIP_PrintToChatClient(iClient, " \x03Вы изменили цвет неона на \x04%s", sColor);
				g_hCookie.Set(iClient, sColor);
				if(IsPlayerAlive(iClient))
				{
					SetClientNeon(iClient);
				}
			}
			else
			{
				VIP_PrintToChatClient(iClient, "Ошибка использования \"%s\"!.", sColor);
			}

			g_hColorsMenu.Display(iClient, MENU_TIME_FOREVER);
		}
	}
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	switch(VIP_GetClientFeatureStatus(iClient, g_sFeature[0]))
	{
		case ENABLED: return ITEMDRAW_DEFAULT;
		case DISABLED: return ITEMDRAW_DISABLED;
		case NO_ACCESS: return ITEMDRAW_RAWLINE;
	}

	return iStyle;
}

public Action:OnToggleItem(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	RemoveNeon(iClient);

	if(NewStatus == ENABLED && IsPlayerAlive(iClient) && GetClientTeam(iClient) > 1)
	{
		SetClientNeon(iClient);
	}

	return Plugin_Continue;
}

public OnClientDisconnect(iClient)
{
	g_iNeon[iClient] = 0;
	g_bHideNeon[iClient] = false;
}

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature[0]))
	{
		SetClientNeon(iClient);
	}
}

public Event_PlayerDeath(Event:hEvent, const String:sEvName[], bool:dBontBroadcast)
{
	RemoveNeon(GetClientOfUserId(hEvent.GetInt("userid")));
}

RemoveNeon(iClient)
{
	if(g_iNeon[iClient] && IsValidEdict(g_iNeon[iClient]))
	{
		AcceptEntityInput(g_iNeon[iClient], "TurnOff"); 
		AcceptEntityInput(g_iNeon[iClient], "Kill");
	}
	g_iNeon[iClient] = 0;
}

SetClientNeon(iClient)
{
	RemoveNeon(iClient);

	g_iNeon[iClient] = CreateEntityByName("light_dynamic");
	DispatchKeyValue(g_iNeon[iClient], "brightness", "5");
	decl Float:fOrigin[3],  String:sBuffer[16];
	GetClientAbsOrigin(iClient, fOrigin);
	switch(g_iClientColor[iClient][2])
	{
		case -1:
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d %d", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(120, 200));
		}
		case -2:
		{
			switch(GetClientTeam(iClient))
			{
				case 2:
				{
					strcopy(sBuffer, sizeof(sBuffer), "200 25 25 150");
				}
				case 3:
				{
					strcopy(sBuffer, sizeof(sBuffer), "25 25 200 150");
				}
			}
		}
		default:
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d %d", g_iClientColor[iClient][0],  g_iClientColor[iClient][1],  g_iClientColor[iClient][2],  g_iClientColor[iClient][3]);
		}
	}
	
	DispatchKeyValue(g_iNeon[iClient], "_light", sBuffer);
	DispatchKeyValue(g_iNeon[iClient], "spotlight_radius", "50");
	DispatchKeyValue(g_iNeon[iClient], "distance", "150");
	DispatchKeyValue(g_iNeon[iClient], "style", "0");
	SetEntPropEnt(g_iNeon[iClient], Prop_Send, "m_hOwnerEntity", iClient);
	if(DispatchSpawn(g_iNeon[iClient]))
	{
		AcceptEntityInput(g_iNeon[iClient], "TurnOn");
		TeleportEntity(g_iNeon[iClient], fOrigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(g_iNeon[iClient], "SetParent", iClient, g_iNeon[iClient], 0);
		
		/*
		if(g_bHide)
		{
			SDKHook(g_iNeon[iClient], SDKHook_SetTransmit, OnTransmit);
		}
		*/
		
		SDKHook(g_iNeon[iClient], SDKHook_SetTransmit, HideNeon);
		
		return;
	}

	g_iNeon[iClient] = 0;
}

public Action HideNeon(iEntity, iClient)
{
	if (g_iNeon[iClient] == iEntity)
	{
		return Plugin_Continue;
	}
	
	if (g_bHideNeon[iClient])
	{
	    return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/*
public Action:OnTransmit(iEntity, iClient)
{
	if (g_iNeon[iClient] == iEntity)
	{
		return Plugin_Continue;
	}

	static iOwner, iTeam;

	if ((iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) > 0 &&
		(iTeam = GetClientTeam(iClient)) > 1
		&& GetClientTeam(iOwner) != iTeam)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
*/
