//G corp remenants, Survivors of the Smoke War
//Their function is as common cannon fodder. Manager buffs make them much more effective in battle.
/mob/living/simple_animal/hostile/ordeal/steel_dawn
	name = "gene corp remnant"
	desc = "A insect augmented employee of the fallen Gene corp. Word on the street says that they banded into common backstreet gangs after the Smoke War."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "gcorp1"
	icon_living = "gcorp1"
	icon_dead = "gcorp_corpse"
	faction = list("Gene_Corp")
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID|MOB_BUG
	maxHealth = 220
	health = 220
	melee_damage_type = RED_DAMAGE
	vision_range = 8
	move_to_delay = 2.2
	melee_damage_lower = 10
	melee_damage_upper = 13
	wander = FALSE
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	footstep_type = FOOTSTEP_MOB_SHOE
	a_intent = INTENT_HELP
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)
	//similar to a human
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	butcher_results = list(/obj/item/food/meat/slab/buggy = 2)
	silk_results = list(/obj/item/stack/sheet/silk/steel_simple = 1)
	//What AI are we using?
	var/morale = "Normal"
	var/morale_active = TRUE

/mob/living/simple_animal/hostile/ordeal/steel_dawn/Initialize()
	. = ..()
	attack_sound = "sound/effects/ordeals/steel/gcorp_attack[pick(1,2,3)].ogg"
	if(icon_state == "gcorp_beetle")
		return
	var/type_into_text = "[type]"
	if(type_into_text == "/mob/living/simple_animal/hostile/ordeal/steel_dawn") //due to being a root of noon
		icon_living = "gcorp[pick(1,2,3,4)]"
		icon_state = icon_living

/mob/living/simple_animal/hostile/ordeal/steel_dawn/Life()
	. = ..()
	if(morale_active)
		//If you got no morale
		if(morale == "Retreat" || morale == "No Morale")
			ranged = 1
			retreat_distance = 5
			minimum_distance = 5
			a_intent_change(INTENT_HELP)

		else
			ranged = 0
			retreat_distance = 0
			minimum_distance = 1
			a_intent_change(INTENT_HARM)

	//Passive regen when below 50% health.
	if(health <= maxHealth*0.5 && stat != DEAD)
		if(morale != "Zealous")
			morale = "Retreat"
		adjustBruteLoss(-2)
		if(!target)
			adjustBruteLoss(-6)

	else
		morale = "Normal"

	//Soldiers when off duty will let eachother move around.
/mob/living/simple_animal/hostile/ordeal/steel_dawn/Aggro()
	. = ..()
	a_intent_change(INTENT_HARM)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/LoseAggro()
	. = ..()
	a_intent_change(INTENT_HELP)



/mob/living/simple_animal/hostile/ordeal/steel_dawn/beefy
	name = "gene corp shocktrooper"
	icon_state = "gcorp_beetle"
	icon_living = "gcorp_beetle"
	icon_dead = "dead_beetle"
	faction = list("Gene_Corp")
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID|MOB_BUG
	maxHealth = 1300
	health = 1300
	melee_damage_lower = 40
	melee_damage_upper = 45
	move_to_delay = 4
