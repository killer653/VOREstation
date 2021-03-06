//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

datum/track
	var/title
	var/sound

datum/track/New(var/title_name, var/audio)
	title = title_name
	sound = audio

/obj/machinery/media/jukebox
	name = "space jukebox"
	icon = 'icons/obj/jukebox.dmi'
	icon_state = "jukebox2-nopower"
	var/state_base = "jukebox2"
	anchored = 1
	density = 1
	power_channel = EQUIP
	use_power = 1
	idle_power_usage = 10
	active_power_usage = 100

	var/playing = 0

	// Vars for hacking
	var/datum/wires/jukebox/wires = null
	var/hacked = 0 // Whether to show the hidden songs or not
	var/freq = 0

	var/datum/track/current_track
	var/list/datum/track/tracks = list(
		new/datum/track("A Song About Hares", 'sound/music/SongAboutHares.ogg'), // 	AND WE DO NOT CARE~! AND WE DO NOT CARE~!
		new/datum/track("Below The Asteroids", 'sound/music/jukebox/BelowTheAsteroids.ogg'),
		new/datum/track("Beyond", 'sound/ambience/ambispace.ogg'),
		new/datum/track("Clouds of Fire", 'sound/music/clouds.s3m'),
		new/datum/track("D`Bert", 'sound/music/title2.ogg'),
		new/datum/track("D`Fort", 'sound/ambience/song_game.ogg'),
		new/datum/track("Duck Tales - Moon", 'sound/music/jukebox/DuckTalesMoon.mid'),
		new/datum/track("Endless Space", 'sound/music/space.ogg'),
		new/datum/track("Floating", 'sound/music/main.ogg'),
		new/datum/track("Fly Me To The Moon", 'sound/music/Fly_Me_To_The_Moon.ogg'),
		new/datum/track("Ghost Fight (Toby Fox)", 'sound/music/jukebox/TobyFoxGhostFight.mid'),
		new/datum/track("Mad About Me", 'sound/music/jukebox/Cantina.ogg'),
		new/datum/track("Minor Turbulence", 'sound/music/jukebox/MinorTurbulenceFull.ogg'),
		new/datum/track("Ode to Greed", 'sound/music/jukebox/OdeToGreed.ogg'),
		new/datum/track("Part A", 'sound/misc/TestLoop1.ogg'),
		new/datum/track("Ransacked", 'sound/music/jukebox/Ransacked.ogg'),
		new/datum/track("Russkiy rep Diskoteka", 'sound/music/russianrapdisco.ogg'), // EVEN THOUGH THE STATION IS FULL OF HUNGRY WOLVES
		new/datum/track("Scratch", 'sound/music/title1.ogg'),
		new/datum/track("Space Oddity", 'sound/music/space_oddity.ogg'),
		new/datum/track("Trai`Tor", 'sound/music/traitor.ogg'),
		new/datum/track("Welcome To Jurassic Park", 'sound/music/jukebox/WelcomeToJurassicPark.mid')
	)
	// Only visible if hacked
	var/list/datum/track/secret_tracks = list(
		new/datum/track("Bandit Radio", 'sound/music/jukebox/bandit_radio.ogg'),
		new/datum/track("Space Asshole", 'sound/music/space_asshole.ogg')
	)

/obj/machinery/media/jukebox/New()
	..()
	wires = new/datum/wires/jukebox(src)

/obj/machinery/media/jukebox/Del()
	StopPlaying()
	del(wires)
	..()

/obj/machinery/media/jukebox/power_change()
	if(!powered(power_channel) || !anchored)
		stat |= NOPOWER
	else
		stat &= ~NOPOWER

	if(stat & (NOPOWER|BROKEN) && playing)
		StopPlaying()
	update_icon()

/obj/machinery/media/jukebox/update_icon()
	overlays.Cut()
	if(stat & (NOPOWER|BROKEN) || !anchored)
		if(stat & BROKEN)
			icon_state = "[state_base]-broken"
		else
			icon_state = "[state_base]-nopower"
		return
	icon_state = state_base
	if(playing)
		if(emagged)
			overlays += "[state_base]-emagged"
		else
			overlays += "[state_base]-running"
	if (panel_open)
		overlays += "panel_open"

/obj/machinery/media/jukebox/Topic(href, href_list)
	if(..() || !(Adjacent(usr) || istype(usr, /mob/living/silicon)))
		return

	if(!anchored)
		usr << "<span class='warning'>You must secure \the [src] first.</span>"
		return

	if(stat & (NOPOWER|BROKEN))
		usr << "\The [src] doesn't appear to function."
		return

	if(href_list["change_track"])
		for(var/datum/track/T in tracks)
			if(T.title == href_list["title"])
				current_track = T
				StartPlaying()
				break
	else if(href_list["stop"])
		StopPlaying()
	else if(href_list["play"])
		if(emagged)
			playsound(src.loc, 'sound/items/AirHorn.ogg', 100, 1)
			for(var/mob/living/carbon/M in ohearers(6, src))
				if(istype(M, /mob/living/carbon/human))
					var/mob/living/carbon/human/H = M
					if(istype(H.l_ear, /obj/item/clothing/ears/earmuffs) || istype(H.r_ear, /obj/item/clothing/ears/earmuffs))
						continue
				M.sleeping = 0
				M.stuttering += 20
				M.ear_deaf += 30
				M.Weaken(3)
				if(prob(30))
					M.Stun(10)
					M.Paralyse(4)
				else
					M.make_jittery(500)
			spawn(15)
				explode()
		else if(current_track == null)
			usr << "No track selected."
		else
			StartPlaying()

	return 1

/obj/machinery/media/jukebox/interact(mob/user)
	if(stat & (NOPOWER|BROKEN))
		usr << "\The [src] doesn't appear to function."
		return

	ui_interact(user)

/obj/machinery/media/jukebox/ui_interact(mob/user, ui_key = "jukebox", var/datum/nanoui/ui = null, var/force_open = 1)
	var/title = "RetroBox - Space Style"
	var/data[0]

	if(!(stat & (NOPOWER|BROKEN)))
		data["current_track"] = current_track != null ? current_track.title : ""
		data["playing"] = playing

		var/list/nano_tracks = new
		for(var/datum/track/T in tracks)
			nano_tracks[++nano_tracks.len] = list("track" = T.title)

		data["tracks"] = nano_tracks

	// update the ui if it exists, returns null if no ui is passed/found
	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
        // for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "jukebox.tmpl", title, 450, 600)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()

/obj/machinery/media/jukebox/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/media/jukebox/attack_hand(var/mob/user as mob)
	interact(user)

/obj/machinery/media/jukebox/proc/set_hacked(var/newhacked)
	if (hacked == newhacked) return
	hacked = newhacked
	if (hacked)
		tracks.Add(secret_tracks)
	else
		tracks.Remove(secret_tracks)
	updateDialog()

/obj/machinery/media/jukebox/proc/explode()
	walk_to(src,0)
	src.visible_message("<span class='danger'>\the [src] blows apart!</span>", 1)

	explosion(src.loc, 0, 0, 1, rand(1,2), 1)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(3, 1, src)
	s.start()

	new /obj/effect/decal/cleanable/blood/oil(src.loc)
	del(src)

/obj/machinery/media/jukebox/attackby(obj/item/W as obj, mob/user as mob)
	src.add_fingerprint(user)

	if (default_deconstruction_screwdriver(user, W))
		return
	if(istype(W, /obj/item/weapon/wirecutters))
		return wires.Interact(user)
	if(istype(W, /obj/item/device/multitool))
		return wires.Interact(user)
	if(istype(W, /obj/item/weapon/wrench))
		if(playing)
			StopPlaying()
		user.visible_message("<span class='warning'>[user] has [anchored ? "un" : ""]secured \the [src].</span>", "<span class='notice'>You [anchored ? "un" : ""]secure \the [src].</span>")
		anchored = !anchored
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		power_change()
		update_icon()
		return
	if(istype(W, /obj/item/weapon/card/emag))
		if(!emagged)
			emagged = 1
			StopPlaying()
			visible_message("<span class='danger'>\the [src] makes a fizzling sound.</span>")
			log_and_message_admins("emagged \the [src]")
			update_icon()
			return

	return ..()

/obj/machinery/media/jukebox/proc/StopPlaying()
	var/area/A = get_area(src)
	// Always kill the current sound
	for(var/mob/living/M in mobs_in_area(A))
		M << sound(null, channel = 1)

	A.forced_ambience = null
	playing = 0
	update_use_power(1)
	update_icon()


/obj/machinery/media/jukebox/proc/StartPlaying()
	StopPlaying()
	if(!current_track)
		return

	var/area/A = get_area(src)
	A.forced_ambience = sound(current_track.sound, channel = 1, repeat = 1, volume = 25)
	if (freq)
		A.forced_ambience.frequency = freq

	for(var/mob/living/M in mobs_in_area(A))
		if(M.mind)
			A.play_ambience(M)

	playing = 1
	update_use_power(2)
	update_icon()


///////////////////////////////////////////
// Event-specific jukeboxes go below here
///////////////////////////////////////////

/obj/machinery/media/jukebox/clowntemple
	idle_power_usage = 0
	active_power_usage = 0
	tracks = list(new/datum/track("Mad Jack", 'sound/music/jukebox/madjack.ogg'))