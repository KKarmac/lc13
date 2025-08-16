/obj/structure/den/rce
	name = "X-Corp Attack Pylon"
	desc = "Best destroy this!"
	icon_state = "powerpylon"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	color = "#FF5522"
	light_color = "#FF5522"
	light_range = 3
	light_power = 1
	max_integrity = 500
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 4,
		/mob/living/simple_animal/hostile/xcorp/scout = 2,
	)
	var/announce = FALSE
	var/id
	var/assault_type = SEND_ONLY_DEFEATED
	var/max_mobs = 18
	var/generate_new_mob_time = NONE
	var/raider = FALSE

/obj/structure/den/rce/announcer
	light_range = 5
	max_mobs = 40
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 2,
		/mob/living/simple_animal/hostile/xcorp/scout = 3,
		/mob/living/simple_animal/hostile/xcorp/sapper = 3,
		/mob/living/simple_animal/hostile/xcorp/tank = 2,
		/mob/living/simple_animal/hostile/xcorp/dps = 2,
	)
	generate_new_mob_time = 50 SECONDS
	raider = TRUE
	announce = TRUE

/obj/structure/den/rce/mid
	light_range = 4
	max_mobs = 10
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 2,
		/mob/living/simple_animal/hostile/xcorp/dps = 1,
		/mob/living/simple_animal/hostile/xcorp/tank = 1,
		/mob/living/simple_animal/hostile/xcorp/scout = 1,
	)
	generate_new_mob_time = 22 SECONDS

/obj/structure/den/rce/high
	light_range = 7
	max_mobs = 12
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp/scout = 2,
		/mob/living/simple_animal/hostile/xcorp/sapper = 2,
		/mob/living/simple_animal/hostile/xcorp/dps = 2,
		/mob/living/simple_animal/hostile/xcorp/tank = 3,
	)
	generate_new_mob_time = 15 SECONDS

/obj/structure/den/rce/raider
	light_range = 5
	max_mobs = 30
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 2,
		/mob/living/simple_animal/hostile/xcorp/scout = 3,
		/mob/living/simple_animal/hostile/xcorp/sapper = 1,
		/mob/living/simple_animal/hostile/xcorp/tank = 2,
		/mob/living/simple_animal/hostile/xcorp/dps = 2,
	)
	assault_type = SEND_TILL_MAX
	generate_new_mob_time = 30 SECONDS
	raider = TRUE

/obj/structure/den/rce/Initialize(mapload)
	. = ..()
	if(id)
		target = SSgamedirector.GetTargetById(id)
	else
		target = SSgamedirector.GetRandomRaiderTarget()
	AddComponent(/datum/component/monwave_spawner, attack_target = target, max_mobs = max_mobs, assault_type = assault_type, new_wave_order = moblist, try_for_announcer = announce, new_wave_cooldown_time = generate_new_mob_time, raider = raider, register = TRUE)

/obj/structure/den/rce_defender
	name = "X-Corp Defense Pylon"
	desc = "Best destroy this!"
	icon_state = "defensepylon"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	color = "#FF0000"
	max_integrity = 1000
	light_color = "#aa1100"
	light_range = 5
	light_power = 2
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 4,
		/mob/living/simple_animal/hostile/xcorp/tank = 4,
		/mob/living/simple_animal/hostile/xcorp/heart = 3,
		/mob/living/simple_animal/hostile/xcorp/heart/ranged = 2,
		/mob/living/simple_animal/hostile/xcorp/heart/dps = 1,
	)
	var/announce = FALSE
	var/id
	var/assault_type = SEND_TILL_MAX
	var/max_mobs = 30
	var/generate_new_mob_time = NONE
	var/raider = FALSE

/obj/structure/den/rce_defender/Initialize(mapload)
	. = ..()
	if(id)
		target = SSgamedirector.GetTargetById(id)
	if(!target)
		target = get_turf(src)
	AddComponent(/datum/component/monwave_spawner, attack_target = target, max_mobs = max_mobs, assault_type = assault_type, new_wave_order = moblist, try_for_announcer = announce, new_wave_cooldown_time = generate_new_mob_time, raider = raider, register = TRUE)

/obj/structure/rce_heart
	name = "X-Corp Heart"
	desc = "Best destroy this!"
	icon_state = "nexus"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	color = "#FF0000"
	max_integrity = 1

/obj/structure/rce_heart/Initialize()
	. = ..()
	AddElement(/datum/element/point_of_interest)

/obj/structure/rce_heart/Destroy()
	SSgamedirector.AnnounceVictory()
	. = ..()

/obj/structure/rce_portal
	name = "Raid Portal"
	desc = span_danger("Click me to register to fight the heart")
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "fountain"
	maptext = "<b><span style='color: red;'>EXAMINE ME</span></b>"
	maptext_height = 32
	maptext_width = 64
	maptext_x = -16
	maptext_y = 8
	density = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/rce_portal/Initialize()
	. = ..()
	SSgamedirector.RegisterPortal(src)

/obj/structure/rce_portal/attack_hand(mob/living/user)
	if(tgui_alert(user, "Do you want to register to fight the Heart of Greed?", "Go die?", list("Yes", "No"), timeout = 30 SECONDS) == "Yes")
		SSgamedirector.RegisterCombatant(user)

/obj/structure/player_blocker
	name = "forcefield"
	desc = "Impassable to some."
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "cultshield"
	light_color = "#aa0000"
	light_range = 3
	light_power = 1
	alpha = 70
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	pass_flags_self = 0

/obj/structure/player_blocker/invisible
	light_color = null
	light_range = 0
	light_power = 0
	alpha = 0

/obj/structure/player_blocker/CanAllowThrough(atom/movable/A, turf/T)
	. = ..()

	if(!isliving(A))
		return FALSE
	if(istype(A, /mob/living/simple_animal))
		return TRUE
	return FALSE

/obj/structure/player_blocker/CanAStarPass(ID, to_dir, requester)
	return TRUE
