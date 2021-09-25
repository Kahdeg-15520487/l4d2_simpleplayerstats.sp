DELIMITER //
CREATE FUNCTION `APPLY_MODIFIER`(
	`name` VARCHAR(50),
	`value` INT
) RETURNS double
BEGIN
	DECLARE modifier FLOAT;
	
	SELECT s.modifier INTO modifier FROM STATS_SKILLS s WHERE s.name = name;
	
	IF modifier IS NULL 
	THEN
		SELECT 1.0 INTO modifier;
	END IF;
		
	RETURN value * modifier;
END//
DELIMITER ;

CREATE TABLE IF NOT EXISTS `STATS_PLAYERS` (
	`steam_id` varchar(64) NOT NULL,
	`steam_id64` varchar(64) NULL,
	`play_style` varchar(255) NULL,
	`last_known_alias` varchar(255) DEFAULT NULL,
	`last_known_alias_unicode` varchar(255) DEFAULT NULL,
	`last_join_date` timestamp NULL DEFAULT current_timestamp(),
	`hide_extra_stats` tinyint(4) DEFAULT 0,
	`survivor_healed` int(10) unsigned NOT NULL DEFAULT 0,
	`survivor_defibed` int(10) unsigned NOT NULL DEFAULT 0,
	`survivor_death` int(10) unsigned NOT NULL DEFAULT 0,
	`survivor_incapped` int(10) unsigned NOT NULL DEFAULT 0,
	`survivor_ff` int(10) unsigned NOT NULL DEFAULT 0,

	`weapon_rifle` int(10) unsigned NOT NULL DEFAULT 0,
	`weapon_shotgun` int(10) unsigned NOT NULL DEFAULT 0,
	`weapon_melee` int(10) unsigned NOT NULL DEFAULT 0,
	`weapon_deagle` int(10) unsigned NOT NULL DEFAULT 0,
	`weapon_special` int(10) unsigned NOT NULL DEFAULT 0,
	`weapon_smg` int(10) unsigned NOT NULL DEFAULT 0,
	`weapon_sniper` int(10) unsigned NOT NULL DEFAULT 0,

	`infected_killed` int(10) unsigned NOT NULL DEFAULT 0,
	`infected_headshot` int(10) unsigned NOT NULL DEFAULT 0,

	`boomer_killed` int(10) unsigned NOT NULL DEFAULT 0,
	`boomer_killed_clean` int(10) unsigned NOT NULL DEFAULT 0,

	`charger_killed` int(10) unsigned NOT NULL DEFAULT 0,
	`charger_pummeled` int(10) unsigned NOT NULL DEFAULT 0,

	`hunter_killed` int(10) unsigned NOT NULL DEFAULT 0,
	`hunter_pounced` int(10) unsigned NOT NULL DEFAULT 0,
	`hunter_shoved` int(10) unsigned NOT NULL DEFAULT 0,

	`jockey_killed` int(10) unsigned NOT NULL DEFAULT 0,
	`jockey_pounced` int(10) unsigned NOT NULL DEFAULT 0,
	`jockey_shoved` int(10) unsigned NOT NULL DEFAULT 0,
	`jockey_rided` int(10) unsigned NOT NULL DEFAULT 0,

	`smoker_killed` int(10) unsigned NOT NULL DEFAULT 0,
	`smoker_choked` int(10) unsigned NOT NULL DEFAULT 0,
	`smoker_tongue_slashed` int(10) unsigned NOT NULL DEFAULT 0,

	`spitter_killed` int(10) unsigned NOT NULL DEFAULT 0,

	`witch_killed` int(10) unsigned NOT NULL DEFAULT 0,
	`witch_killed_1shot` int(10) unsigned NOT NULL DEFAULT 0,
	`witch_harassed` int(10) unsigned NOT NULL DEFAULT 0,

	`tank_killed` int(10) unsigned NOT NULL DEFAULT 0,
	`tank_melee` int(10) unsigned NOT NULL DEFAULT 0,
	`car_alarm` int(10) unsigned NOT NULL DEFAULT 0,
	`create_date` timestamp NOT NULL DEFAULT current_timestamp(),
	PRIMARY KEY (`steam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `STATS_SKILLS` (
  `name` varchar(50) NOT NULL,
  `modifier` float DEFAULT NULL,
  `update_date` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE VIEW `STATS_VW_PLAYER_RANKS` AS
SELECT `b`.`steam_id` AS `steam_id`,
	   `b`.`steam_id64` AS `steam_id64`,
	   `b`.`play_style` AS `play_style`,
       `b`.`last_known_alias` AS `last_known_alias`,
	   `b`.`last_known_alias_unicode` AS `last_known_alias_unicode`,
       date_format(`b`.`last_join_date`, '%Y-%m-%d %h:%i:%s %p') AS `last_join_date`,

		`b`.`survivor_healed` as `survivor_healed`,
		`b`.`survivor_defibed` as `survivor_defibed`,
		`b`.`survivor_death` as `survivor_death`,
		`b`.`survivor_incapped` as `survivor_incapped`,
		`b`.`survivor_ff` as `survivor_ff`,

		`b`.`weapon_rifle` as `weapon_rifle`,
		`b`.`weapon_shotgun` as `weapon_shotgun`,
		`b`.`weapon_melee` as `weapon_melee`,
		`b`.`weapon_deagle` as `weapon_deagle`,
		`b`.`weapon_special` as `weapon_special`,
		`b`.`weapon_smg` as `weapon_smg`,
		`b`.`weapon_sniper` as `weapon_sniper`,

		`b`.`infected_killed` as `infected_killed`,
		`b`.`infected_headshot` as `infected_headshot`,

		`b`.`boomer_killed` as `boomer_killed`,
		`b`.`boomer_killed_clean` as `boomer_killed_clean`,

		`b`.`charger_killed` as `charger_killed`,
		`b`.`charger_pummeled` as `charger_pummeled`,

		`b`.`hunter_killed` as `hunter_killed`,
		`b`.`hunter_pounced` as `hunter_pounced`,
		`b`.`hunter_shoved` as `hunter_shoved`,

		`b`.`jockey_killed` as `jockey_killed`,
		`b`.`jockey_pounced` as `jockey_pounced`,
		`b`.`jockey_shoved` as `jockey_shoved`,
		`b`.`jockey_rided` as `jockey_rided`,

		`b`.`smoker_killed` as `smoker_killed`,
		`b`.`smoker_choked` as `smoker_choked`,
		`b`.`smoker_tongue_slashed` as `smoker_tongue_slashed`,

		`b`.`spitter_killed` as `spitter_killed`,

		`b`.`witch_killed` as `witch_killed`,
		`b`.`witch_killed_1shot` as `witch_killed_1shot`,
		`b`.`witch_harassed` as `witch_harassed`,

		`b`.`tank_killed` as `tank_killed`,
		`b`.`tank_melee` as `tank_melee`,
		`b`.`car_alarm` as `car_alarm`,
		
       round(`b`.`total_points`, 2) AS `total_points`,
       `b`.`rank_num` AS `rank_num`,
       date_format(`b`.`create_date`, '%Y-%m-%d %h:%i:%s %p') AS `create_date`
FROM
  (SELECT	`s`.`steam_id` AS `steam_id`,
			`s`.`steam_id64` AS `steam_id64`,
			`s`.`play_style` AS `play_style`,
			`s`.`last_known_alias` AS `last_known_alias`,
			`s`.`last_known_alias_unicode` AS `last_known_alias_unicode`,
			`s`.`last_join_date` AS `last_join_date`,

			`s`.`survivor_healed` as `survivor_healed`,
			`s`.`survivor_defibed` as `survivor_defibed`,
			`s`.`survivor_death` as `survivor_death`,
			`s`.`survivor_incapped` as `survivor_incapped`,
			`s`.`survivor_ff` as `survivor_ff`,

			`s`.`weapon_rifle` as `weapon_rifle`,
			`s`.`weapon_shotgun` as `weapon_shotgun`,
			`s`.`weapon_melee` as `weapon_melee`,
			`s`.`weapon_deagle` as `weapon_deagle`,
			`s`.`weapon_special` as `weapon_special`,
			`s`.`weapon_smg` as `weapon_smg`,
			`s`.`weapon_sniper` as `weapon_sniper`,

			`s`.`infected_killed` as `infected_killed`,
			`s`.`infected_headshot` as `infected_headshot`,

			`s`.`boomer_killed` as `boomer_killed`,
			`s`.`boomer_killed_clean` as `boomer_killed_clean`,

			`s`.`charger_killed` as `charger_killed`,
			`s`.`charger_pummeled` as `charger_pummeled`,

			`s`.`hunter_killed` as `hunter_killed`,
			`s`.`hunter_pounced` as `hunter_pounced`,
			`s`.`hunter_shoved` as `hunter_shoved`,

			`s`.`jockey_killed` as `jockey_killed`,
			`s`.`jockey_pounced` as `jockey_pounced`,
			`s`.`jockey_shoved` as `jockey_shoved`,
			`s`.`jockey_rided` as `jockey_rided`,

			`s`.`smoker_killed` as `smoker_killed`,
			`s`.`smoker_choked` as `smoker_choked`,
			`s`.`smoker_tongue_slashed` as `smoker_tongue_slashed`,

			`s`.`spitter_killed` as `spitter_killed`,

			`s`.`witch_killed` as `witch_killed`,
			`s`.`witch_killed_1shot` as `witch_killed_1shot`,
			`s`.`witch_harassed` as `witch_harassed`,

			`s`.`tank_killed` as `tank_killed`,
			`s`.`tank_melee` as `tank_melee`,
			`s`.`car_alarm` as `car_alarm`,
		  
          `APPLY_MODIFIER`('survivor_healed', `s`.`survivor_healed`)
		- `APPLY_MODIFIER`('survivor_death', `s`.`survivor_death`)
		+ `APPLY_MODIFIER`('infected_killed', `s`.`infected_killed`)
		+ `APPLY_MODIFIER`('infected_headshot', `s`.`infected_headshot`)
		+ `APPLY_MODIFIER`('boomer_killed', `s`.`boomer_killed`)
		+ `APPLY_MODIFIER`('charger_killed', `s`.`charger_killed`)
		+ `APPLY_MODIFIER`('hunter_killed', `s`.`hunter_killed`)
		+ `APPLY_MODIFIER`('jockey_killed', `s`.`jockey_killed`)
		+ `APPLY_MODIFIER`('spitter_killed', `s`.`spitter_killed`)
		+ `APPLY_MODIFIER`('witch_killed', `s`.`witch_killed`)
		+ `APPLY_MODIFIER`('tank_killed', `s`.`tank_killed`)
			AS `total_points`,
          row_number() OVER ( ORDER BY 	  `s`.`survivor_healed`
										- `s`.`survivor_death`
										+ `s`.`infected_headshot`
										+ `s`.`infected_killed`
										+ `s`.`boomer_killed`
										+ `s`.`charger_killed`
										+ `s`.`hunter_killed`
										+ `s`.`jockey_killed`
										+ `s`.`spitter_killed`
										+ `s`.`witch_killed`
										+ `s`.`tank_killed` DESC,`s`.`create_date`) AS `rank_num`,
          `s`.`create_date` AS `create_date`
   FROM `STATS_PLAYERS` `s`) `b`;
   
CREATE TABLE DISPLAY_TEMPLATE (
  name VARCHAR(255) NOT NULL,
  title VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (name)
  );
CREATE TABLE DISPLAY_COLUMN (
  id integer NOT NULL AUTO_INCREMENT,
  title VARCHAR(255),
  propertyname VARCHAR(255),
  searchable tinyint(4) DEFAULT 0,
  sortable tinyint(4) DEFAULT 0,
  israwhtml tinyint(4) DEFAULT 0,
  hasformat tinyint(4) DEFAULT 0,
  formatstring VARCHAR(255),
  
  PRIMARY KEY (id),
  
  templatename VARCHAR(255),
  FOREIGN KEY (templatename) REFERENCES DISPLAY_TEMPLATE(name) ON DELETE CASCADE
  );