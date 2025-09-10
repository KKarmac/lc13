SUBSYSTEM_DEF(resourcewell_raids)
	name = "Resource Well Raids"
	flags = SS_KEEP_TIMING | SS_BACKGROUND
	runlevels = RUNLEVEL_GAME
	wait = 10 SECONDS

	var/list/resourcewells = list()
	var/list/active_resourcewells = list()
	var/list/raid_spots = list()
	var/next_raid_time = 0
	var/raid_cooldown_min = 5 MINUTES
	var/raid_cooldown_max = 8 MINUTES

	// Seed spawning variables
	var/next_active_seed_time = 0
	var/active_seed_cooldown_min = 16 MINUTES
	var/active_seed_cooldown_max = 22 MINUTES
	var/next_passive_seed_time = 0
	var/passive_seed_cooldown = 20 MINUTES
	var/list/wells_with_passive_seeds = list() // Track wells that already have passive seeds

	// Corrupter spawning variables
	var/next_corrupter_time = 0
	var/corrupter_cooldown_min = 20 MINUTES
	var/corrupter_cooldown_max = 30 MINUTES
	var/corrupter_rarity_threshold = 6 // Minimum total rarity needed for corrupters to spawn

	var/list/raid_tiers = list()
	var/list/seed_types = list() // Seed types based on rarity

/datum/controller/subsystem/resourcewell_raids/Initialize(timeofday)
	SetupRaidTiers()
	SetupSeedTypes()
	next_raid_time = world.time + rand(raid_cooldown_min, raid_cooldown_max)
	// Delay active seeds by 25 minutes
	next_active_seed_time = world.time + 25 MINUTES + rand(active_seed_cooldown_min, active_seed_cooldown_max)
	next_passive_seed_time = world.time + passive_seed_cooldown
	next_corrupter_time = world.time + rand(corrupter_cooldown_min, corrupter_cooldown_max)
	return ..()

/datum/controller/subsystem/resourcewell_raids/fire()
	if(world.time >= next_raid_time)
		TriggerRaid()
		next_raid_time = world.time + rand(raid_cooldown_min, raid_cooldown_max)

	if(world.time >= next_active_seed_time)
		SpawnActiveSeed()
		next_active_seed_time = world.time + rand(active_seed_cooldown_min, active_seed_cooldown_max)

	if(world.time >= next_passive_seed_time)
		SpawnPassiveSeed()
		next_passive_seed_time = world.time + passive_seed_cooldown

	// Check for corrupter spawning
	if(world.time >= next_corrupter_time)
		var/total_rarity = 0
		for(var/obj/structure/resourcepoint/well in active_resourcewells)
			total_rarity += well.rarity

		if(total_rarity >= corrupter_rarity_threshold)
			SpawnCorrupter()

		next_corrupter_time = world.time + rand(corrupter_cooldown_min, corrupter_cooldown_max)

/datum/controller/subsystem/resourcewell_raids/proc/RegisterResourceWell(obj/structure/resourcepoint/well)
	resourcewells += well

/datum/controller/subsystem/resourcewell_raids/proc/UnregisterResourceWell(obj/structure/resourcepoint/well)
	resourcewells -= well
	active_resourcewells -= well

/datum/controller/subsystem/resourcewell_raids/proc/RegisterRaidSpot(obj/effect/landmark/clan_raid_spot/spot)
	if(!raid_spots[spot.id])
		raid_spots[spot.id] = list()
	raid_spots[spot.id] += spot

/datum/controller/subsystem/resourcewell_raids/proc/TriggerRaid()
	if(!length(active_resourcewells))
		return

	var/obj/structure/resourcepoint/target_well

	// 15% chance to ignore priority system
	if(prob(15))
		target_well = pick(active_resourcewells)
	else
		target_well = GetPriorityRaidTarget()

	if(!target_well)
		target_well = pick(active_resourcewells) // Fallback

	var/total_rarity = 0
	for(var/obj/structure/resourcepoint/well in active_resourcewells)
		total_rarity += well.rarity

	var/list/spawn_spots = raid_spots[target_well.id]
	if(!spawn_spots || !length(spawn_spots))
		return

	var/list/raid_data = GetRaidData(total_rarity)
	if(!raid_data)
		return

	var/raid_name = raid_data["name"]
	var/list/raid_composition = raid_data["composition"]

	show_global_blurb(10 SECONDS, "Warning: Greed-touched '[raid_name]' detected approaching [target_well.name]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

	addtimer(CALLBACK(src, PROC_REF(SpawnRaid), spawn_spots, raid_composition, target_well, raid_name), 12 SECONDS)

/datum/controller/subsystem/resourcewell_raids/proc/SpawnRaid(list/spawn_spots, list/raid_composition, obj/structure/resourcepoint/target_well, raid_name)
	var/spot_index = 1
	var/list/available_spots = spawn_spots.Copy()

	for(var/mob_type in raid_composition)
		var/spawn_count = raid_composition[mob_type]
		for(var/i in 1 to spawn_count)
			var/turf/spawn_turf
			if(length(available_spots))
				var/obj/effect/landmark/clan_raid_spot/spot = pick(available_spots)
				spawn_turf = get_turf(spot)
			else
				var/obj/effect/landmark/clan_raid_spot/spot = spawn_spots[spot_index]
				spawn_turf = get_turf(spot)
				spot_index++
				if(spot_index > length(spawn_spots))
					spot_index = 1

			var/obj/structure/closet/supplypod/extractionpod/pod = new()
			pod.explosionSize = list(0,0,0,0)
			pod.icon_state = "pod"
			pod.door = "pod_door"
			pod.decal = "cultist"
			new mob_type(pod)
			new /obj/effect/pod_landingzone(spawn_turf, pod)
			stoplag(2)

	show_global_blurb(5 SECONDS, "The '[raid_name]' has arrived at [target_well.name]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

/datum/controller/subsystem/resourcewell_raids/proc/GetRaidData(rarity)
	var/list/valid_raids = list()
	for(var/list/raid in raid_tiers)
		if(rarity >= raid["min_rarity"] && rarity <= raid["max_rarity"])
			valid_raids += list(raid)

	if(!length(valid_raids))
		return null

	var/list/chosen_raid = pick(valid_raids)
	return chosen_raid

/datum/controller/subsystem/resourcewell_raids/proc/SetupRaidTiers()
	raid_tiers = list(
		// Basic scout party
		list(
			"name" = "Scout Patrol",
			"min_rarity" = 1,
			"max_rarity" = 3,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/scout/greed = 3,
				/mob/living/simple_animal/hostile/clan/drone/greed = 1
			)
		),
		// Drone support team
		list(
			"name" = "Support Squad",
			"min_rarity" = 1,
			"max_rarity" = 4,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 1,
				/mob/living/simple_animal/hostile/clan/drone/greed = 2
			)
		),
		// Rapid response
		list(
			"name" = "Rapid Response",
			"min_rarity" = 2,
			"max_rarity" = 5,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 3,
				/mob/living/simple_animal/hostile/clan/scout/greed = 2
			)
		),
		// Bomber spider swarm
		list(
			"name" = "Spider Swarm",
			"min_rarity" = 1,
			"max_rarity" = 6,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 6
			)
		),
		// Sniper with drone support
		list(
			"name" = "Sniper Team",
			"min_rarity" = 1,
			"max_rarity" = 6,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 1,
				/mob/living/simple_animal/hostile/clan/drone/greed = 2
			)
		),
		// Gunner squad
		list(
			"name" = "Gunner Squad",
			"min_rarity" = 4,
			"max_rarity" = 7,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 3,
				/mob/living/simple_animal/hostile/clan/ranged/rapid/greed = 1
			)
		),
		// Defensive formation
		list(
			"name" = "Shield Wall",
			"min_rarity" = 5,
			"max_rarity" = 8,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/defender/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 2,
				/mob/living/simple_animal/hostile/clan/drone/greed = 1
			)
		),
		// Assassin strike team
		list(
			"name" = "Shadow Strike",
			"min_rarity" = 5,
			"max_rarity" = 9,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/assassin/greed = 2,
				/mob/living/simple_animal/hostile/clan/scout/greed = 3
			)
		),
		// Mixed assault
		list(
			"name" = "Assault Team",
			"min_rarity" = 6,
			"max_rarity" = 9,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/defender/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/rapid/greed = 2,
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 2
			)
		),
		// Sniper overwatch
		list(
			"name" = "Overwatch",
			"min_rarity" = 7,
			"max_rarity" = 10,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 3,
				/mob/living/simple_animal/hostile/clan/defender/greed = 1,
				/mob/living/simple_animal/hostile/clan/drone/greed = 1
			)
		),
		// Warper teleport assault
		list(
			"name" = "Warp Strike",
			"min_rarity" = 7,
			"max_rarity" = 11,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 1,
				/mob/living/simple_animal/hostile/clan/assassin/greed = 2,
				/mob/living/simple_animal/hostile/clan/scout/greed = 2
			)
		),
		// Harpooner ambush
		list(
			"name" = "Hook Squad",
			"min_rarity" = 8,
			"max_rarity" = 11,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 2,
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 1
			)
		),
		// Heavy assault with demolisher
		list(
			"name" = "Siege Force",
			"min_rarity" = 9,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/demolisher/greed = 1,
				/mob/living/simple_animal/hostile/clan/defender/greed = 2,
				/mob/living/simple_animal/hostile/clan/drone/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 1
			)
		),
		// Elite strike force
		list(
			"name" = "Elite Strike",
			"min_rarity" = 10,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/assassin/greed = 3,
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 1
			)
		),
		// Maximum spider chaos
		list(
			"name" = "Spider Apocalypse",
			"min_rarity" = 10,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 10
			)
		),
		// Combined arms
		list(
			"name" = "Combined Arms",
			"min_rarity" = 11,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed = 1,
				/mob/living/simple_animal/hostile/clan/assassin/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 1,
				/mob/living/simple_animal/hostile/clan/defender/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 1
			)
		),
		// Ultimate assault
		list(
			"name" = "Apocalypse Squad",
			"min_rarity" = 12,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/demolisher/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed = 2,
				/mob/living/simple_animal/hostile/clan/assassin/greed = 2,
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 3
			)
		)
	)

/datum/controller/subsystem/resourcewell_raids/proc/SetupSeedTypes()
	seed_types = list(
		list(
			"min_rarity" = 1,
			"max_rarity" = 4,
			"types" = list(
				/obj/structure/seed_of_greed/basic/level1,
				/obj/structure/seed_of_greed/shield/level1,
				/obj/structure/seed_of_greed/defensive/level1
			)
		),
		list(
			"min_rarity" = 5,
			"max_rarity" = 8,
			"types" = list(
				/obj/structure/seed_of_greed/basic/level2,
				/obj/structure/seed_of_greed/shield/level2,
				/obj/structure/seed_of_greed/defensive/level2,
				/obj/structure/seed_of_greed/assault/level1
			)
		),
		list(
			"min_rarity" = 9,
			"max_rarity" = 12,
			"types" = list(
				/obj/structure/seed_of_greed/basic/level3,
				/obj/structure/seed_of_greed/shield/level3,
				/obj/structure/seed_of_greed/defensive/level3,
				/obj/structure/seed_of_greed/assault/level2,
				/obj/structure/seed_of_greed/assault/level3
			)
		)
	)

/datum/controller/subsystem/resourcewell_raids/proc/SpawnActiveSeed()
	if(!length(active_resourcewells))
		return

	var/obj/structure/resourcepoint/target_well = pick(active_resourcewells)

	var/total_rarity = 0
	for(var/obj/structure/resourcepoint/well in active_resourcewells)
		total_rarity += well.rarity

	var/seed_type = GetSeedType(total_rarity)
	if(!seed_type)
		return

	show_global_blurb(10 SECONDS, "Warning: Seed of Greed detected materializing at [target_well.name]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

	addtimer(CALLBACK(src, PROC_REF(PlaceSeed), target_well, seed_type), 12 SECONDS)

/datum/controller/subsystem/resourcewell_raids/proc/SpawnPassiveSeed()
	var/list/inactive_wells = resourcewells - active_resourcewells - wells_with_passive_seeds

	if(!length(inactive_wells))
		return

	var/obj/structure/resourcepoint/target_well = pick(inactive_wells)
	wells_with_passive_seeds += target_well

	// Always spawn level 1 seeds on inactive wells
	var/list/level1_seeds = list(
		/obj/structure/seed_of_greed/basic/level1,
		/obj/structure/seed_of_greed/shield/level1,
		/obj/structure/seed_of_greed/defensive/level1
	)

	var/seed_type = pick(level1_seeds)

	// No warning for passive seeds - they spawn silently
	new seed_type(get_turf(target_well))

/datum/controller/subsystem/resourcewell_raids/proc/PlaceSeed(obj/structure/resourcepoint/target_well, seed_type)
	new seed_type(get_turf(target_well))
	show_global_blurb(5 SECONDS, "Seed of Greed has materialized at [target_well.name]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

/datum/controller/subsystem/resourcewell_raids/proc/GetSeedType(rarity)
	for(var/list/tier in seed_types)
		if(rarity >= tier["min_rarity"] && rarity <= tier["max_rarity"])
			var/list/types = tier["types"]
			return pick(types)
	return null

/datum/controller/subsystem/resourcewell_raids/proc/GetPriorityRaidTarget()
	// Define the two priority lanes
	// Lane 1: green -> blue -> orange (priority: orange > blue > green)
	// Lane 2: red -> purple -> silver (priority: silver > purple > red)

	var/list/lane1_priority = list("orange", "blue", "green")
	var/list/lane2_priority = list("silver", "purple", "red")

	// Check what's active in each lane
	var/list/active_lane1 = list()
	var/list/active_lane2 = list()

	for(var/obj/structure/resourcepoint/well in active_resourcewells)
		if(well.id in lane1_priority)
			active_lane1[well.id] = well
		else if(well.id in lane2_priority)
			active_lane2[well.id] = well

	// Find the highest priority target in lane 1
	var/obj/structure/resourcepoint/lane1_target
	for(var/priority_id in lane1_priority)
		if(active_lane1[priority_id])
			lane1_target = active_lane1[priority_id]
			break

	// Find the highest priority target in lane 2
	var/obj/structure/resourcepoint/lane2_target
	for(var/priority_id in lane2_priority)
		if(active_lane2[priority_id])
			lane2_target = active_lane2[priority_id]
			break

	// Choose between the two lanes based on which has higher priority
	if(lane1_target && lane2_target)
		// Compare priorities - lower index = higher priority
		var/lane1_priority_index = lane1_priority.Find(lane1_target.id)
		var/lane2_priority_index = lane2_priority.Find(lane2_target.id)

		// Lower index means higher priority
		if(lane1_priority_index < lane2_priority_index)
			return lane1_target
		else if(lane2_priority_index < lane1_priority_index)
			return lane2_target
		else
			// Equal priority, pick randomly
			return pick(lane1_target, lane2_target)
	else if(lane1_target)
		return lane1_target
	else if(lane2_target)
		return lane2_target
	else
		return null

// Clear passive seed marker when well becomes active
/datum/controller/subsystem/resourcewell_raids/proc/UpdateActiveStatus(obj/structure/resourcepoint/well)
	if(well.active > 0)
		active_resourcewells |= well
		wells_with_passive_seeds -= well // Clear passive seed marker when activated
	else
		active_resourcewells -= well

/datum/controller/subsystem/resourcewell_raids/proc/SpawnCorrupter()
	// Get all raid spots from all IDs
	var/list/all_raid_spots = list()
	for(var/id in raid_spots)
		all_raid_spots += raid_spots[id]

	if(!length(all_raid_spots))
		return

	var/obj/effect/landmark/clan_raid_spot/chosen_spot = pick(all_raid_spots)
	var/turf/spawn_turf = get_turf(chosen_spot)

	if(!spawn_turf)
		return

	// Find the nearest resource well to give location context
	var/obj/structure/resourcepoint/nearest_well = null
	var/min_dist = 15
	for(var/obj/structure/resourcepoint/well in resourcewells)
		var/dist = get_dist(spawn_turf, well)
		if(dist < min_dist)
			min_dist = dist
			nearest_well = well

	var/location_text = nearest_well ? "near [nearest_well.name]" : "at unknown location"

	// Warning message with location
	show_global_blurb(10 SECONDS, "CRITICAL WARNING: Greed-touched Corrupter detected materializing near [location_text]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

	// Spawn the corrupter after delay
	addtimer(CALLBACK(src, PROC_REF(ActuallySpawnCorrupter), spawn_turf, location_text), 12 SECONDS)

/datum/controller/subsystem/resourcewell_raids/proc/ActuallySpawnCorrupter(turf/spawn_turf, location_text)
	new /mob/living/simple_animal/hostile/clan/ranged/corrupter/greed(spawn_turf)
	show_global_blurb(5 SECONDS, "Greed-touched Corrupter has arrived near [location_text]! Extreme caution advised!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")
