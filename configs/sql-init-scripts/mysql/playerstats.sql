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
	`survivor_revived` int(10) unsigned NOT NULL DEFAULT 0,
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
SELECT
    `b`.`steam_id` AS `steam_id`,
    `b`.`steam_id64` AS `steam_id64`,
    `b`.`play_style` AS `play_style`,
    `b`.`last_known_alias` AS `last_known_alias`,
    `b`.`last_known_alias_unicode` AS `last_known_alias_unicode`,
    DATE_FORMAT(
        `b`.`last_join_date`,
        '%Y-%m-%d %h:%i:%s %p'
    ) AS `last_join_date`,
    `b`.`survivor_revived` AS `survivor_revived`,
    `b`.`survivor_healed` AS `survivor_healed`,
    `b`.`survivor_defibed` AS `survivor_defibed`,
    `b`.`survivor_death` AS `survivor_death`,
    `b`.`survivor_incapped` AS `survivor_incapped`,
    `b`.`survivor_ff` AS `survivor_ff`,
    `b`.`weapon_rifle` AS `weapon_rifle`,
    `b`.`weapon_shotgun` AS `weapon_shotgun`,
    `b`.`weapon_melee` AS `weapon_melee`,
    `b`.`weapon_deagle` AS `weapon_deagle`,
    `b`.`weapon_special` AS `weapon_special`,
    `b`.`weapon_smg` AS `weapon_smg`,
    `b`.`weapon_sniper` AS `weapon_sniper`,
    `b`.`infected_killed` AS `infected_killed`,
    `b`.`infected_headshot` AS `infected_headshot`,
    `b`.`boomer_killed` AS `boomer_killed`,
    `b`.`boomer_killed_clean` AS `boomer_killed_clean`,
    `b`.`charger_killed` AS `charger_killed`,
    `b`.`charger_pummeled` AS `charger_pummeled`,
    `b`.`hunter_killed` AS `hunter_killed`,
    `b`.`hunter_pounced` AS `hunter_pounced`,
    `b`.`hunter_shoved` AS `hunter_shoved`,
    `b`.`jockey_killed` AS `jockey_killed`,
    `b`.`jockey_pounced` AS `jockey_pounced`,
    `b`.`jockey_shoved` AS `jockey_shoved`,
    `b`.`jockey_rided` AS `jockey_rided`,
    `b`.`smoker_killed` AS `smoker_killed`,
    `b`.`smoker_choked` AS `smoker_choked`,
    `b`.`smoker_tongue_slashed` AS `smoker_tongue_slashed`,
    `b`.`spitter_killed` AS `spitter_killed`,
    `b`.`witch_killed` AS `witch_killed`,
    `b`.`witch_killed_1shot` AS `witch_killed_1shot`,
    `b`.`witch_harassed` AS `witch_harassed`,
    `b`.`tank_killed` AS `tank_killed`,
    `b`.`tank_melee` AS `tank_melee`,
    `b`.`car_alarm` AS `car_alarm`,
    ROUND(`b`.`total_points`, 2) AS `total_points`,
    `b`.`rank_num` AS `rank_num`,
    DATE_FORMAT(
        `b`.`create_date`,
        '%Y-%m-%d %h:%i:%s %p'
    ) AS `create_date`
FROM
    (
    SELECT
        `s`.`steam_id` AS `steam_id`,
        `s`.`steam_id64` AS `steam_id64`,
        `s`.`play_style` AS `play_style`,
        `s`.`last_known_alias` AS `last_known_alias`,
        `s`.`last_known_alias_unicode` AS `last_known_alias_unicode`,
        `s`.`last_join_date` AS `last_join_date`,
        `s`.`survivor_revived` AS `survivor_revived`,
        `s`.`survivor_healed` AS `survivor_healed`,
        `s`.`survivor_defibed` AS `survivor_defibed`,
        `s`.`survivor_death` AS `survivor_death`,
        `s`.`survivor_incapped` AS `survivor_incapped`,
        `s`.`survivor_ff` AS `survivor_ff`,
        `s`.`weapon_rifle` AS `weapon_rifle`,
        `s`.`weapon_shotgun` AS `weapon_shotgun`,
        `s`.`weapon_melee` AS `weapon_melee`,
        `s`.`weapon_deagle` AS `weapon_deagle`,
        `s`.`weapon_special` AS `weapon_special`,
        `s`.`weapon_smg` AS `weapon_smg`,
        `s`.`weapon_sniper` AS `weapon_sniper`,
        `s`.`infected_killed` AS `infected_killed`,
        `s`.`infected_headshot` AS `infected_headshot`,
        `s`.`boomer_killed` AS `boomer_killed`,
        `s`.`boomer_killed_clean` AS `boomer_killed_clean`,
        `s`.`charger_killed` AS `charger_killed`,
        `s`.`charger_pummeled` AS `charger_pummeled`,
        `s`.`hunter_killed` AS `hunter_killed`,
        `s`.`hunter_pounced` AS `hunter_pounced`,
        `s`.`hunter_shoved` AS `hunter_shoved`,
        `s`.`jockey_killed` AS `jockey_killed`,
        `s`.`jockey_pounced` AS `jockey_pounced`,
        `s`.`jockey_shoved` AS `jockey_shoved`,
        `s`.`jockey_rided` AS `jockey_rided`,
        `s`.`smoker_killed` AS `smoker_killed`,
        `s`.`smoker_choked` AS `smoker_choked`,
        `s`.`smoker_tongue_slashed` AS `smoker_tongue_slashed`,
        `s`.`spitter_killed` AS `spitter_killed`,
        `s`.`witch_killed` AS `witch_killed`,
        `s`.`witch_killed_1shot` AS `witch_killed_1shot`,
        `s`.`witch_harassed` AS `witch_harassed`,
        `s`.`tank_killed` AS `tank_killed`,
        `s`.`tank_melee` AS `tank_melee`,
        `s`.`car_alarm` AS `car_alarm`,
        (
            (
                (
                    (
                        (
                            (
                                (
                                    (
                                        (
                                            (
                                                (
                                                    (
                                                        (
                                                            `APPLY_MODIFIER`(
                                                                'survivor_revived',
                                                                `s`.`survivor_revived`
                                                            ) + `APPLY_MODIFIER`(
                                                                'survivor_healed',
                                                                `s`.`survivor_healed`
                                                            )
                                                        ) + `APPLY_MODIFIER`(
                                                            'survivor_defibed',
                                                            `s`.`survivor_defibed`
                                                        )
                                                    ) + `APPLY_MODIFIER`('survivor_ff', `s`.`survivor_ff`)
                                                ) - `APPLY_MODIFIER`(
                                                    'survivor_death',
                                                    `s`.`survivor_death`
                                                )
                                            ) + `APPLY_MODIFIER`(
                                                'infected_killed',
                                                `s`.`infected_killed`
                                            )
                                        ) + `APPLY_MODIFIER`(
                                            'infected_headshot',
                                            `s`.`infected_headshot`
                                        )
                                    ) + `APPLY_MODIFIER`('boomer_killed', `s`.`boomer_killed`)
                                ) + `APPLY_MODIFIER`(
                                    'charger_killed',
                                    `s`.`charger_killed`
                                )
                            ) + `APPLY_MODIFIER`('hunter_killed', `s`.`hunter_killed`)
                        ) + `APPLY_MODIFIER`('jockey_killed', `s`.`jockey_killed`)
                    ) + `APPLY_MODIFIER`(
                        'spitter_killed',
                        `s`.`spitter_killed`
                    )
                ) + `APPLY_MODIFIER`('witch_killed', `s`.`witch_killed`)
            ) + `APPLY_MODIFIER`('tank_killed', `s`.`tank_killed`)
        ) AS `total_points`,
        row_number() OVER(
        ORDER BY
            (
            (
                (
                    (
                        (
                            (
                                (
                                    (
                                        (
                                            (
                                                (
                                                    (
                                                        (
                                                            `APPLY_MODIFIER`(
                                                                'survivor_revived',
                                                                `s`.`survivor_revived`
                                                            ) + `APPLY_MODIFIER`(
                                                                'survivor_healed',
                                                                `s`.`survivor_healed`
                                                            )
                                                        ) + `APPLY_MODIFIER`(
                                                            'survivor_defibed',
                                                            `s`.`survivor_defibed`
                                                        )
                                                    ) + `APPLY_MODIFIER`('survivor_ff', `s`.`survivor_ff`)
                                                ) - `APPLY_MODIFIER`(
                                                    'survivor_death',
                                                    `s`.`survivor_death`
                                                )
                                            ) + `APPLY_MODIFIER`(
                                                'infected_killed',
                                                `s`.`infected_killed`
                                            )
                                        ) + `APPLY_MODIFIER`(
                                            'infected_headshot',
                                            `s`.`infected_headshot`
                                        )
                                    ) + `APPLY_MODIFIER`('boomer_killed', `s`.`boomer_killed`)
                                ) + `APPLY_MODIFIER`(
                                    'charger_killed',
                                    `s`.`charger_killed`
                                )
                            ) + `APPLY_MODIFIER`('hunter_killed', `s`.`hunter_killed`)
                        ) + `APPLY_MODIFIER`('jockey_killed', `s`.`jockey_killed`)
                    ) + `APPLY_MODIFIER`(
                        'spitter_killed',
                        `s`.`spitter_killed`
                    )
                ) + `APPLY_MODIFIER`('witch_killed', `s`.`witch_killed`)
            ) + `APPLY_MODIFIER`('tank_killed', `s`.`tank_killed`)
        )
        DESC
            ,
            `s`.`create_date`
    ) AS `rank_num`,
    `s`.`create_date` AS `create_date`
FROM
    `l4d2playerstat`.`STATS_PLAYERS` `s`) `b`
   
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
  isdatetime tinyint(4) DEFAULT 0,
  hasformat tinyint(4) DEFAULT 0,
  formatstring VARCHAR(255),
  
  PRIMARY KEY (id),
  
  templatename VARCHAR(255),
  FOREIGN KEY (templatename) REFERENCES DISPLAY_TEMPLATE(name) ON DELETE CASCADE
  );
