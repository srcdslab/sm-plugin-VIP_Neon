# Copilot Instructions for VIP_Neon SourceMod Plugin

## Repository Overview

This repository contains **VIP_Neon**, a SourceMod plugin that provides customizable neon lighting effects for VIP players in Source engine games. The plugin integrates with the VIP Core system to offer colored light halos around VIP players with configurable colors and client preferences.

**Current Version**: 1.2 (as defined in plugin info block)
- **Language**: SourcePawn (SourceMod scripting language)
- **Platform**: SourceMod 1.11+ / Source Engine games
- **Build System**: SourceKnight (modern SourceMod build tool)
- **Dependencies**: VIP Core plugin system

## Project Structure

```
addons/sourcemod/
├── scripting/
│   └── VIP_Neon.sp           # Main plugin source code
└── data/vip/modules/
    └── neon_colors.ini       # Color configuration file

.github/workflows/ci.yml      # GitHub Actions CI/CD
sourceknight.yaml            # Build configuration
```

## Build System & Development Workflow

### SourceKnight Build System
This project uses **SourceKnight** instead of traditional `spcomp` compilation:

```bash
# Install SourceKnight (if needed)
pip install sourceknight

# Build the plugin
sourceknight build

# The compiled .smx file will be in the output directory
```

**Note**: SourceKnight may have dependency conflicts in some environments. The GitHub Actions CI/CD pipeline uses a containerized environment that handles these dependencies automatically.

**Key SourceKnight files:**
- `sourceknight.yaml` - Build configuration with dependencies
- Dependencies auto-downloaded: SourceMod 1.11.0-git6917, VIP Core includes

### CI/CD Pipeline
- **Automated builds** on push/PR via GitHub Actions
- **Artifact generation** with packaged plugin files
- **Automatic releases** on tags and main branch updates
- Uses `maxime1907/action-sourceknight@v1` for builds

## Code Patterns & Architecture

### VIP Core Integration
This plugin follows VIP Core's feature registration pattern:

```sourcepawn
// Feature registration
VIP_RegisterFeature(g_sFeature[0], BOOL, _, OnToggleItem);          // Toggle feature
VIP_RegisterFeature(g_sFeature[1], _, SELECTABLE, OnSelectItem);    // Menu feature

// Status checking
if(VIP_IsClientFeatureUse(iClient, g_sFeature[0])) {
    // Player has neon enabled
}
```

### Entity Management Pattern
Neon effects use dynamic light entities:

```sourcepawn
// Create entity
g_iNeon[iClient] = CreateEntityByName("light_dynamic");

// Set properties and parent to player
SetEntPropEnt(g_iNeon[iClient], Prop_Send, "m_hOwnerEntity", iClient);
AcceptEntityInput(g_iNeon[iClient], "SetParent", iClient);

// Always clean up on disconnect/death
RemoveNeon(iClient);
```

### Client Preferences & Cookies
Uses SourceMod cookies for persistent settings:

```sourcepawn
g_hCookie = RegClientCookie("VIP_Neon", "VIP_Neon", CookieAccess_Public);
g_hHideNeonCookie = RegClientCookie("VIP_HideNeon", "VIP_HideNeon", CookieAccess_Public);
```

## Configuration System

### Color Configuration (`neon_colors.ini`)
KeyValues format with special color types:
- `"teamcolor"` - Automatic team-based colors
- `"randomcolor"` - Random RGB values  
- `"R G B A"` - Direct RGBA values (0-255)

```ini
"Colors"
{
    "Red"       "255 0 0 150"
    "Teamcolor" "teamcolor"
    "Random"    "randomcolor"
}
```

## Code Style & Modernization Guidelines

### Current Code Issues to Address
When modifying this codebase, prioritize these modernizations:

1. **Replace deprecated syntax:**
   ```sourcepawn
   // OLD (current code)
   new g_iClientColor[MAXPLAYERS+1][4];
   
   // NEW (preferred)
   int g_iClientColor[MAXPLAYERS+1][4];
   ```

2. **Handle cleanup properly:**
   ```sourcepawn
   // OLD
   if(g_hKeyValues != INVALID_HANDLE) {
       CloseHandle(g_hKeyValues);
   }
   
   // NEW
   delete g_hKeyValues;  // Safe to call on null
   ```

3. **Use proper string methods:**
   ```sourcepawn
   // OLD
   decl String:sBuffer[64];
   
   // NEW  
   char sBuffer[64];
   ```

4. **Add translation support:**
   - Currently missing: No translation files exist
   - Replace hardcoded Russian strings with translation keys
   - Use `%T` format specifiers for all user messages
   - Create `addons/sourcemod/translations/vip_modules.phrases.txt` (referenced but missing)

### Required Pragmas
Always maintain these at the top of SourcePawn files:
```sourcepawn
#pragma semicolon 1
#pragma newdecls required  // NOTE: Currently missing in VIP_Neon.sp
```

**Current Status**: The main plugin file is missing `#pragma newdecls required` which should be added for modern SourcePawn compliance.

## Testing & Validation

### Manual Testing Checklist
When modifying the plugin:

1. **Build verification:**
   ```bash
   sourceknight build
   # Check for compilation warnings/errors
   ```

2. **Feature testing:**
   - VIP neon toggle on/off functionality
   - Color selection menu navigation
   - Client preference persistence (cookies)
   - Hide neon option functionality
   - Team color and random color modes

3. **Integration testing:**
   - VIP Core feature registration
   - Player spawn/death event handling
   - Entity cleanup on disconnect

### Common Issues to Check
- **Memory leaks**: Ensure all entities are properly cleaned up
- **Entity limits**: Monitor dynamic entity creation
- **Client state**: Verify arrays are reset on disconnect
- **VIP status changes**: Handle VIP status revocation properly

## Development Guidelines

### Making Changes
1. **Always test locally** with a development server
2. **Follow minimal change principle** - only modify what's necessary
3. **Maintain backward compatibility** with existing configurations
4. **Update version number** in plugin info when making changes

### Entity Management Best Practices
- Always call `RemoveNeon()` before creating new neon entities
- Use `IsValidEdict()` checks before entity operations
- Properly handle entity parenting to avoid orphaned entities

### Client Data Management
- Reset client arrays in `OnClientDisconnect()`
- Use proper bounds checking for client indices
- Handle late-loaded clients in `VIP_OnVIPClientLoaded()`

### Adding Features
When adding new functionality:
1. Register features with VIP Core using appropriate flags
2. Add configuration options to `neon_colors.ini` if needed
3. Implement proper menu integration for user selection
4. Add client preferences via cookies if user-configurable

## Debugging Tips

### Common Issues
- **Entity not appearing**: Check `DispatchSpawn()` return value
- **Neon not following player**: Verify entity parenting
- **Settings not saving**: Check cookie registration and callbacks
- **VIP integration broken**: Verify feature registration timing

### Useful Debug Commands
```sourcepawn
// Entity debugging
PrintToServer("Neon entity: %d, valid: %b", g_iNeon[client], IsValidEdict(g_iNeon[client]));

// Client state debugging  
PrintToServer("Client %d: VIP=%b, Color=[%d,%d,%d,%d]", 
    client, VIP_IsClientFeatureUse(client, g_sFeature[0]),
    g_iClientColor[client][0], g_iClientColor[client][1], 
    g_iClientColor[client][2], g_iClientColor[client][3]);
```

## Release Process

1. **Update version** in plugin info block
2. **Test thoroughly** on development server
3. **Commit changes** with clear description
4. **Tag release** (triggers automated build/release)
5. **Monitor CI/CD** pipeline for successful build
6. **Verify artifact** contains all necessary files

The GitHub Actions workflow automatically:
- Builds the plugin with SourceKnight
- Packages data files with the compiled plugin
- Creates releases with downloadable archives
- Maintains a "latest" release tag

## Dependencies & External Integration

### VIP Core Dependency
This plugin requires VIP Core for:
- Feature registration and management
- Client VIP status checking
- Menu integration
- Chat message formatting

### SourceMod APIs Used
- **Entity system**: Dynamic light creation and management
- **Client cookies**: Persistent preferences
- **Events**: Player spawn/death handling
- **SDKHooks**: Entity transmission control
- **Menus**: Color selection interface

When modifying, ensure compatibility with SourceMod 1.11+ and maintain the existing VIP Core integration patterns.