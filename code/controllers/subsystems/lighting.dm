<<<<<<< HEAD
=======
/*
** Lighting Subsystem - Process the lighting! Do it!
*/

#define SSLIGHTING_STAGE_LIGHTS 1
#define SSLIGHTING_STAGE_CORNERS 2
#define SSLIGHTING_STAGE_OVERLAYS 3
#define SSLIGHTING_STAGE_DONE 4
// This subsystem's fire() method also gets called once during Master.Initialize().
// During this fire we need to use CHECK_TICK to sleep and continue, but in all other fires we need to use MC_CHECK_TICK to pause and return.
// This leads us to a rather annoying little tidbit of code that I have stuffed into this macro so I don't have to see it.
#define DUAL_TICK_CHECK if (init_tick_checks) { CHECK_TICK; } else if (MC_TICK_CHECK) { return; }

// Globals
var/global/lighting_overlays_initialised = FALSE
var/global/list/lighting_update_lights    = list()    // List of lighting sources  queued for update.
var/global/list/lighting_update_corners   = list()    // List of lighting corners  queued for update.
var/global/list/lighting_update_overlays  = list()    // List of lighting overlays queued for update.

>>>>>>> 21bd8477c7e... Merge pull request #8531 from Spookerton/spkrtn/sys/global-agenda
SUBSYSTEM_DEF(lighting)
	name = "Lighting"
	wait = 2
	init_order = INIT_ORDER_LIGHTING
	flags = SS_TICKER
	var/static/list/sources_queue = list() // List of lighting sources queued for update.
	var/static/list/corners_queue = list() // List of lighting corners queued for update.
	var/static/list/objects_queue = list() // List of lighting objects queued for update.

/datum/controller/subsystem/lighting/stat_entry(msg)
	msg = "L:[length(sources_queue)]|C:[length(corners_queue)]|O:[length(objects_queue)]"
	return ..()


/datum/controller/subsystem/lighting/Initialize(timeofday)
	if(!subsystem_initialized)
		if (config.starlight)
			for(var/area/A in world)
				if (A.dynamic_lighting == DYNAMIC_LIGHTING_IFSTARLIGHT)
					A.luminosity = 0

		subsystem_initialized = TRUE
		create_all_lighting_objects()

	fire(FALSE, TRUE)

	return ..()

/datum/controller/subsystem/lighting/fire(resumed, init_tick_checks)
	MC_SPLIT_TICK_INIT(3)
	if(!init_tick_checks)
		MC_SPLIT_TICK
	var/list/queue = sources_queue
	var/i = 0
	for (i in 1 to length(queue))
		var/datum/light_source/L = queue[i]

		L.update_corners()

		L.needs_update = LIGHTING_NO_UPDATE

		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		queue.Cut(1, i+1)
		i = 0

	if(!init_tick_checks)
		MC_SPLIT_TICK

	queue = corners_queue
	for (i in 1 to length(queue))
		var/datum/lighting_corner/C = queue[i]

		C.needs_update = FALSE //update_objects() can call qdel if the corner is storing no data
		C.update_objects()
		
		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		queue.Cut(1, i+1)
		i = 0


	if(!init_tick_checks)
		MC_SPLIT_TICK

	queue = objects_queue
	for (i in 1 to length(queue))
		var/datum/lighting_object/O = queue[i]

		if (QDELETED(O))
			continue

		O.update()
		O.needs_update = FALSE
		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		queue.Cut(1, i+1)


/datum/controller/subsystem/lighting/Recover()
	subsystem_initialized = SSlighting.subsystem_initialized
	..()
