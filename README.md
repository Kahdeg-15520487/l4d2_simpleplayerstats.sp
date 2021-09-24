### **Simple In-Game Player Statistics Plugin for Left 4 Dead 2**

### Features

- This plugin records statistics gathered from human players. The following statistics are currently being recorded:

  Basic stat

  | Name               | Description                                                  |
  | ------------------ | ------------------------------------------------------------ |
  | Survivors Death    | Number of times a survivor has been killed |
  | Weapon Class     | Based on most kill by weapon |
  | Common Kills     | Number of times a survivor has killed a Common |
  | Boomer Kills     | Number of times a survivor has killed a Boomer |
  | Charger Kills     | Number of times a survivor has killed a Charger |
  | Hunter Kills     | Number of times a survivor has killed a Hunter |
  | Jockey Kills     | Number of times a survivor has killed a Jockey |
  | Smoker Kills     | Number of times a survivor has killed a Smoker |
  | Witch Kills     | Number of times a survivor has killed a Witch |
  | Tank Kills     | Number of times a survivor has killed a Tank |

  Extra stat

  | Name               | Description                                                  |
  | ------------------ | ------------------------------------------------------------ |
  | TBD | TBD |


  Weapon Class  
  | Weapon Type | Weapon Class |
  | ----------- | ------------ |
  | Rifle | Rifler |
  | Melee | Brawler |
  | Shotgun | Supporter |
  | SMG | Run'n'Gun |
  | Sniper | Markman |
  | Deagle | Cowboy |
  | Special | Specialist |
  | None | Balancer |

### Requirements

- Sourcemod 1.7 above
- A working database system (mysql)

### Installation

Download the [latest](https://github.com/Kahdeg-15520487/l4d2_simpleplayerstats.sp/releases) version from the repository and extract the contents to the root of the left 4 dead 2 server installation directory. 

### Configuration

#### Database Configuration

1. Create and setup the appropriate users/credentials/privileges on your MySQL/MariaDB database system.

2. Import the [provided SQL script](configs/sql-init-scripts/mysql/playerstats.sql) (under `/configs/sql-init-scripts/mysql/playerstats.sql`\) into your MySQL/MariaDB system.

#### Plugin Configuration

The plugin can be further customized through the `playerstats.cfg` file located under `addons/sourcemod/configs/`. The default entries will look like this:

> *REMEMBER*: After you have edited the StatModifiers section, you need to run the command `sm_pstats_reload sync` to update the values on the database

```
"PlayerStats" {
    "StatModifiers" 
    {
      "survivor_healed"		"1.0"
      "survivor_defibed"	"1.0"
      "survivor_death"		"1.0"
      "survivor_incapped"	"1.0"
      "survivor_ff"			 "1.0"

      "weapon_rifle"		"1.0"
      "weapon_shotgun"		"1.0"
      "weapon_melee"		"1.0"
      "weapon_deagle"		"1.0"
      "weapon_sniper"		"1.0"
      "weapon_smg"			"1.0"
      "weapon_special"		"1.0"

      "infected_killed"		"1.0"
      "infected_headshot"	"1.0"

      "boomer_killed"		"1.0"
      "boomer_killed_clean"	"1.0"

      "charger_killed"		"1.0"
      "charger_pummeled"	"1.0"

      "hunter_killed"		"1.0"
      "hunter_pounced"		"1.0"
      "hunter_shoved"		"1.0"

      "jockey_killed"		"1.0"
      "jockey_pounced"	    "1.0"
      "jockey_shoved"		"1.0"
      "jockey_rided"		"1.0"

      "smoker_killed"		"1.0"
      "smoker_choked"		"1.0"
      "smoker_tongue_slashed""1.0"

      "spitter_killed"		"1.0"

      "witch_killed"		"1.0"
      "witch_killed_1shot"	"1.0"
      "witch_harassed"		"1.0"

      "tank_killed"			"1.0"
      "tank_melee"			"1.0"
    }
    "StatPanels" 
    {
        "title_rank_player"   "Player Stats"
        "title_rank_topn"     "Top {top_player_count} Players"
        "title_rank_ingame"   "In-Game Player Ranks"
        "title_rank_extras"   "Extra Player Stats"
    }
    "ConnectAnnounce" 
    {
        "format"    "{N}Player '{G}{last_known_alias}{N}' ({B}{steam_id}{N}) has joined the game ({G}Rank:{N} {i:rank_num}, {G}Points:{N} {f:total_points})"
    }
    "SQL"
    {
        "host"				"host"
        "database"			"l4d2playerstat"
        "user"				"username"
        "pass"				"password"
    }
}
```

### ConVars

| Name                     | Description                                                  | Default value | Min Value | Max Value |
| ------------------------ | ------------------------------------------------------------ | :------------ | --------- | --------- |
| pstats_enabled           | Enable/Disable this plugin                                   | 1             | 0         | 1         |
| pstats_debug_enabled     | Enable debug messages (for debugging purposes only)          | 0             | 0         | 1         |
| pstats_menu_timeout      | The timeout value for the player stats panel                 | 5 (seconds)  | 3         | 9999      |
| pstats_max_top_players   | The max top N players to display                             | 10            | 10        | 50        |
| pstats_display_type      | 1 = Display points, 2 = Display the count, 3 = Both points and count | 2             | 1         | 3         |
| pstats_show_rank_onjoin  | If set, player rank will be displayed to the user on the start of each map | 0             | 0         | 1         |
| pstats_cannounce_enabled | If set, connect announce will be displayed to chat when a player joins | 0             | 0         | 1         |

### Commands

>  **Note**: These commands can also be invoked from chat (e.g. `!rank`, `!top 10`, `!ranks`, `!pstats_reload`)

| Name             | Description                                                  | Parameters | Permission   | Parameter Description                  |
| ---------------- | ------------------------------------------------------------ | ---------- | ------------ | -------------------------------------- |
| sm_rank          | Display the current stats & ranking of the requesting player. A panel will be displayed to the player. | None       | Anyone       | None                                   |
| sm_wiperank     | Allows a player to wipe their stats. | String     | Anyone       | yes |
| sm_top           | Display the top N players. A menu panel will be displayed to the requesting player | Number     | Anyone       | The number of players to be displayed. |
| sm_ranks         | Display the ranks of the players currently playing in the server. A menu panel will be displayed to the requesting player. | Number     | Anyone       | None                                   |
| sm_pstats_reload | Reloads plugin configuration. This is useful if you have modified the `playerstats.cfg` file. 'This command also synchronizes the modifier values set from the configuration file to the database. This is quite an expensive operation, so please only use this command when necessary. | None       | Admin (Root) | None                                   |


