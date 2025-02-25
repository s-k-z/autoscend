import<autoscend.ash>

void print_footer() {
	auto_log_info("HP: " + my_hp() + "/" + my_maxhp() + ", MP: " + my_mp() + "/" + my_maxmp() + " Meat: " + my_meat(), "blue");
	if (my_class() == $class[Sauceror]) {
		auto_log_info("Soulsauce: " + my_soulsauce(), "blue");
	}
	auto_log_info("Familiar: " + my_familiar().to_string() + " @ " + familiar_weight(my_familiar()) + " + " + weight_adjustment() + "lbs.", "blue");
	auto_log_info("ML: " + monster_level_adjustment() + " Encounter: " + combat_rate_modifier() + " Init: " + initiative_modifier(), "blue");
	auto_log_info("Exp Bonus: " + experience_bonus() + " Meat Drop: " + meat_drop_modifier() + " Item Drop: " + item_drop_modifier(), "blue");
	auto_log_info("Resists: " + numeric_modifier("Hot Resistance") + "/" + numeric_modifier("Cold Resistance") + "/" + numeric_modifier("Stench Resistance") + "/" + numeric_modifier("Spooky Resistance") + "/" + numeric_modifier("Sleaze Resistance"), "blue");
}

boolean auto_pre_adventure()
{
	location place = my_location();
	if(get_property("auto_disableAdventureHandling").to_boolean())
	{
		auto_log_info("Preadventure skipped by standard adventure handler.", "green");
		return true;
	}
	auto_log_info("Starting preadventure script...", "green");
	auto_log_debug("Adventuring at " + place.to_string(), "green");
	
	preAdvUpdateFamiliar(place);
	ed_handleAdventureServant(place);

	if(get_floundry_locations() contains place)
	{
		buffMaintain($effect[Baited Hook], 0, 1, 1);
	}

	if((get_property("_bittycar") == "") && (item_amount($item[Bittycar Meatcar]) > 0))
	{
		use(1, $item[Bittycar Meatcar]);
	}

	if((place == $location[The Broodling Grounds]) && (my_class() == $class[Seal Clubber]))
	{
		uneffect($effect[Spiky Shell]);
		uneffect($effect[Scarysauce]);
	}

	if($locations[Next to that Barrel with something Burning In It, Near an Abandoned Refrigerator, Over where the Old Tires Are, Out by that Rusted-Out Car] contains place)
	{
		uneffect($effect[Spiky Shell]);
		uneffect($effect[Scarysauce]);
	}

	if(in_boris())
	{
		if((have_effect($effect[Song of Solitude]) == 0) && (have_effect($effect[Song of Battle]) == 0))
		{
			//When do we consider Song of Cockiness?
			buffMaintain($effect[Song of Fortune], 10, 1, 1);
			if(have_effect($effect[Song of Fortune]) == 0)
			{
				buffMaintain($effect[Song of Accompaniment], 10, 1, 1);
			}
		}
		else if((place.turns_spent > 1) && (place != get_property("auto_priorLocation").to_location()))
		{
			//When do we consider Song of Cockiness?
			buffMaintain($effect[Song of Fortune], 10, 1, 1);
			if(have_effect($effect[Song of Fortune]) == 0)
			{
				buffMaintain($effect[Song of Accompaniment], 10, 1, 1);
			}
		}
	}

	if (isActuallyEd())
	{
		// make sure we have enough MP to cast our most expensive spells
		// Wrath of Ra (yellow ray) is 40 MP, Curse of Stench (sniff) is 35 MP & Curse of Vacation (banish) is 30 MP.
		if (place != $location[The Shore, Inc. Travel Agency])
		{
			acquireMP(40, 1000);
			// ensure we can cast at least Fist of the Mummy or Storm of the Scarab.
			// so we don't waste adventures when we can't actually kill a monster.
			acquireMP(8, 0);
		}

		if (my_hp() == 0)
		{
			// the game doesn't let you adventure if you have no HP even though Ed
			// gets a full heal when he goes to the underworld
			// only necessary if a non-combat puts you on 0 HP.
			edAcquireHP();
		}
	}

	if(in_tcrs())
	{
		if(my_class() == $class[Sauceror] && my_sign() == "Blender")
		{
			if (0 == have_effect($effect[Uncucumbered]))
			{
				buyUpTo(1, $item[hair spray]);
				use(1, $item[hair spray]);
			}
			if (0 == have_effect($effect[Minerva\'s Zen]))
			{
				buyUpTo(1, $item[glittery mascara]);
				use(1, $item[glittery mascara]);
			}
		}
	}

	// this calls the appropriate provider for +combat or -combat depending on the zone we are about to adventure in..
	boolean burningDelay = ((auto_voteMonster(true) || isOverdueDigitize() || auto_sausageGoblin()) && place == solveDelayZone());
	generic_t combatModifier = zone_combatMod(place);
	if (combatModifier._boolean && !burningDelay && !auto_haveQueuedForcedNonCombat()) {
		acquireCombatMods(combatModifier._int, true);
	}

	foreach i,mon in get_monsters(place)
	{
		if(auto_wantToYellowRay(mon, place) && !burningDelay)
		{
			adjustForYellowRayIfPossible(mon);
		}

		if(auto_wantToBanish(mon, place) && !burningDelay)
		{
			adjustForBanishIfPossible(mon, place);
		}

		if(auto_wantToReplace(mon, place) && !burningDelay)
		{
			adjustForReplaceIfPossible(mon);
		}

		if (auto_wantToSniff(mon, place) && !burningDelay)
		{
			adjustForSniffingIfPossible(mon);
		}
	}

	if (in_koe() && possessEquipment($item[low-pressure oxygen tank]))
	{
		autoEquip($item[low-pressure oxygen tank]);
	}

	// Latte may conflict with certain quests. Ignore latte drops for the greater good.
	boolean[location] IgnoreLatteDrop = $locations[The Haunted Boiler Room];
	if (auto_latteDropWanted(place) && !(IgnoreLatteDrop contains place))
	{
		if (auto_sausageGoblin() && place == solveDelayZone())
		{
			// Burning delay using a Sausage Goblin. Can't hold both the Kramco and the Latte, we only have one off-hand!
			if (canChangeToFamiliar($familiar[Left-Hand Man]))
			{
				// If we can use the Left-Hand man, we can get a two-fer with both the Kramco and Latte
				// Hurrah! We found an actual use for it, it's not useless after all!
				auto_log_info('We want to get the "' + auto_latteDropName(place) + '" ingredient for our Latte from ' + place + ", and we're buring delay using the Kramco so your Left-Hand Man will be bringing your Latte along!", "blue");				handleFamiliar($familiar[Left-Hand Man]);
				handleFamiliar($familiar[Left-Hand Man]);
				use_familiar($familiar[Left-Hand Man]); // update familiar already called so have to force.
				autoEquip($slot[familiar], $item[latte lovers member\'s mug]);
			}
		}
		else
		{
			auto_log_info('We want to get the "' + auto_latteDropName(place) + '" ingredient for our Latte from ' + place + ", so we're bringing it along.", "blue");
			autoEquip($item[latte lovers member\'s mug]);
		}
	}

	if(in_zelda())
	{
		int pool_skill = speculative_pool_skill();
		if (possessEquipment($item[Pool Cue]))
		{
			pool_skill += 3;
		}
		// Even though there are ghosts in the Billiards Room, we want to equip
		// the pool cue to finish up the quest.
		boolean skip_equipping_flower = place == $location[The Haunted Billiards Room] && 18 <= pool_skill;

		// Ziggurat has a ghost BUT when clearing out lianas, we want to equip
		// machete in mainhand and use boots.
		if(place == $location[A Massive Ziggurat])
		{
			int lianaFought = 0;
			foreach i,s in place.combat_queue.split_string("; ")
			{
				if(s == "dense liana")
				{
					++lianaFought;
				}
			}
			if(lianaFought < 3)
			{
				skip_equipping_flower = true;
			}
		}
		if ((is_ghost_in_zone(place) && !skip_equipping_flower)
			|| (place == $location[The Smut Orc Logging Camp] && possessEquipment($item[frosty button])))
		{
			if(!zelda_equipTool($stat[mysticality]))
			{
				abort("I'm scared to adventure in a zone with ghosts without a fire flower. Please fight a bit and buy me a fire flower.");
			}
		}
		else
		{
			zelda_equipTool($stat[moxie]);
		}

		// It is dangerous out there! Take this!
		int flyeredML = get_property("flyeredML").to_int();
		boolean have_pill_keeper = (possessEquipment($item[Eight Days a Week Pill Keeper])) &&
			(is_unrestricted($item[Unopened Eight Days a Week Pill Keeper]));

		if(0 < flyeredML && flyeredML < 10000 && in_zelda() && have_pill_keeper)
		{
			auto_log_debug("I expect to be flyering, equipping Pill Keeper to skip the first hit.");
			autoEquip($slot[acc3], $item[Eight Days a Week Pill Keeper]);
		}
	}

	// Use some instakills.  Removing option from Pocket Familiars so it won't unnecessarily equip in third slot.
	item DOCTOR_BAG = $item[Lil\' Doctor&trade; Bag];
	if(auto_is_valid(DOCTOR_BAG) && possessEquipment(DOCTOR_BAG) && (get_property("_chestXRayUsed").to_int() < 3) && my_adventures() <= 19 && !in_pokefam())
	{
		auto_log_info("We still haven't used Chest X-Ray, so let's equip the doctor bag.");
		autoEquip($slot[acc3], DOCTOR_BAG);
	}

	equipOverrides();
	kolhs_preadv(place);

	if (is100FamRun() && my_familiar() == $familiar[none])
	{
		// re-equip a familiar if it's a 100% run just in case something unequipped it
		// looking at you auto_maximizedConsumeStuff()...
		// and L12_themtharHills()...
		use_familiar(get_property("auto_100familiar").to_familiar());
		auto_log_debug("Re-equipped your " + get_property("auto_100familiar") + " as something had unequipped it. This is bad and should be investigated.");
	}

	if((place == $location[8-Bit Realm]) && (my_turncount() != 0))
	{
		if(!possessEquipment($item[Continuum Transfunctioner]))
		{
			abort("Tried to be retro but lacking the Continuum Transfunctioner.");
		}
		autoEquip($slot[acc3], $item[Continuum Transfunctioner]);
	}

	if((place == $location[Inside The Palindome]) && (my_turncount() != 0))
	{
		if(!possessEquipment($item[Talisman O\' Namsilat]))
		{
			abort("Tried to go to The Palindome but don't have the Namsilat");
		}
		autoEquip($slot[acc3], $item[Talisman O\' Namsilat]);
	}

	if((place == $location[The Haunted Boiler Room]) && (my_turncount() != 0) && internalQuestStatus("questL11Manor") < 3)
	{
		if(!possessEquipment($item[Unstable Fulminate]))
		{
			abort("Tried to charge a WineBomb but don't have one.");
		}
		if(equipped_amount($item[Unstable Fulminate]) == 0)
		{
			auto_log_warning("Tried to adventure in [The Haunted Boiler Room] without an [Unstable Fulminate]... correcting", "red");
			autoForceEquip($slot[off-hand], $item[Unstable Fulminate]);
			if(equipped_amount($item[Unstable Fulminate]) == 0)
			{
				abort("Correction failed, please report this. Manually get the [wine bomb] then run me again");
			}
		}
	}
	
	if(place == $location[The Black Forest])
	{
		autoEquip($slot[acc3], $item[Blackberry Galoshes]);
	}

	if ($locations[Barrrney\'s Barrr, The F\'c\'le, The Poop Deck, Belowdecks] contains place) {
		if (possessEquipment($item[pirate fledges])) {
			autoEquip($slot[acc3], $item[pirate fledges]);
		} else if (possessOutfit("Swashbuckling Getup")) {
			autoOutfit("Swashbuckling Getup");
		} else {
			abort("Trying to be a pirate without being able to dress like a pirate.");
		}
	}

	bat_formPreAdventure();
	horsePreAdventure();
	auto_snapperPreAdventure(place);

	generic_t itemNeed = zone_needItem(place);
	if(itemNeed._boolean)
	{
		addToMaximize("50item " + (ceil(itemNeed._float) + 100.0) + "max"); // maximizer treats item drop as 100 higher than it actually is for some reason.
		simMaximize();
		float itemDrop = simValue("Item Drop");
		if(itemDrop < itemNeed._float)
		{
			if (buffMaintain($effect[Fat Leon\'s Phat Loot Lyric], 20, 1, 10))
			{
				itemDrop += 20.0;
			}
			if (buffMaintain($effect[Singer\'s Faithful Ocelot], 35, 1, 10))
			{
				itemDrop += 10.0;
			}
		}
		if(itemDrop < itemNeed._float && !haveAsdonBuff())
		{
			asdonAutoFeed(37);
			if(asdonBuff($effect[Driving Observantly]))
			{
				itemDrop += 50.0;
			}
		}
		if(itemDrop < itemNeed._float)
		{
			auto_log_debug("We can't cap this drop bear!", "purple");
		}
	}


	// Only cast Paul's pop song if we expect it to more than pay for its own casting.
	//	Casting before ML variation ensures that this, the more important buff, is cast before ML.
	if(auto_predictAccordionTurns() >= 8)
	{
		buffMaintain($effect[Paul\'s Passionate Pop Song], 0, 1, 1);
	}

	// ML adjustment zone section
	boolean doML = true;
	boolean removeML = false;
		// removeML MUST be true for purgeML to be used. This is only used for -ML locations like Smut Orc, and you must have 5+ SGEAs to use.
		boolean purgeML = false;

	boolean[location] highMLZones = $locations[Oil Peak, The Typical Tavern Cellar, The Haunted Boiler Room, The Defiled Cranny];
	boolean[location] lowMLZones = $locations[The Smut Orc Logging Camp];

	// Generic Conditions
	if(inAftercore())
	{
		doML = false;
		removeML = false;
		purgeML = false;
	}

		// NOTE: If we aren't quits before we pass L13, let us gain stats.
	if ((get_property("flyeredML").to_int() > 9999 || internalQuestStatus("questL12War") > 1 || get_property("sidequestArenaCompleted") != "none") && my_level() > 12)
	{
		doML = false;
		removeML = true;
		purgeML = false;
	}

	// Allow user settable option to override the above settings to not slack off ML
	if (my_level() > 12 && get_property("auto_disregardInstantKarma").to_boolean())
	{
		doML = true;
		removeML = false;
		purgeML = false;
	}

	// Item specific Conditions
	if((equipped_amount($item[Space Trip Safety Headphones]) > 0) || (equipped_amount($item[Red Badge]) > 0))
	{
		doML = false;
		removeML = true;
		purgeML = false;
	}

	// Location Specific Conditions
	if(lowMLZones contains place)
	{
		doML = false;
		removeML = true;
		purgeML = true;
	}
	if(highMLZones contains place)
	{
		doML = true;
		removeML = false;
		purgeML = false;
	}

	// Act on ML settings
	if(doML)
	{
		// Catch when we leave lowMLZone, allow for being "side tracked" by delay burning
		if((have_effect($effect[Driving Intimidatingly]) > 0) && (get_property("auto_debuffAsdonDelay") >= 2))
		{
			auto_log_debug("No Reason to delay Asdon Usage");
			uneffect($effect[Driving Intimidatingly]);
			set_property("auto_debuffAsdonDelay", 0);
		}
		else if((have_effect($effect[Driving Intimidatingly]).to_int() == 0)  && (get_property("auto_debuffAsdonDelay") >= 0))
		{
			set_property("auto_debuffAsdonDelay", 0);
		}
		else
		{
			set_property("auto_debuffAsdonDelay", get_property("auto_debuffAsdonDelay").to_int() + 1);
			auto_log_debug("Delaying debuffing Asdon: " + get_property("auto_debuffAsdonDelay"));
		}

		auto_MaxMLToCap(auto_convertDesiredML(150), false);
	}

	// If we are in some state where we do not want +ML (Level 13 or Smut Orc) make sure ML is removed
	if(removeML)
	{
		auto_change_mcd(0);
		addToMaximize("-10ml");
		uneffect($effect[Driving Recklessly]);
		uneffect($effect[Ur-Kel\'s Aria of Annoyance]);

		if(purgeML && item_amount($item[soft green echo eyedrop antidote]) > 5)
		{
			uneffect($effect[Drescher\'s Annoying Noise]);
			uneffect($effect[Pride of the Puffin]);
			uneffect($effect[Ceaseless Snarling]);
			uneffect($effect[Blessing of Serqet]);
		}
		else if (purgeML && isActuallyEd() && (item_amount($item[ancient cure-all]) > 0 || item_amount($item[soft green echo eyedrop antidote]) > 0))
		{
			uneffect($effect[Blessing of Serqet]);
		}
	}

	// Here we enforce our ML restrictions if +/-ML is not specifically called in the current maximizer string
	enforceMLInPreAdv();
	
	// Last minute switching for garbage tote. But only if nothing called on januaryToteAcquire this turn.
	if(!get_property("auto_januaryToteAcquireCalledThisTurn").to_boolean())
	{
		januaryToteAcquire($item[Wad Of Used Tape]);
	}

	// EQUIP MAXIMIZED GEAR
	equipMaximizedGear();
	auto_handleRetrocape(); // has to be done after equipMaximizedGear otherwise the maximizer reconfigures it
	cli_execute("checkpoint clear");

	if (isActuallyEd() && is_wearing_outfit("Filthy Hippy Disguise") && place == $location[Hippy Camp]) {
		equip($slot[Pants], $item[None]);
		put_closet(item_amount($item[Filthy Corduroys]), $item[Filthy Corduroys]);
		if (is_wearing_outfit("Filthy Hippy Disguise")) {
			abort("Tried to adventure in the Hippy Camp as Actually Ed the Undying wearing the Filthy Hippy Disguise (this is bad).");
		} else {
			auto_log_info("Took off the Filthy Hippy Disguise before adventuring in the Hippy Camp so we don't waste adventures on non-combats.");
		}
	}

	// Last minute debug logging and a final MCD tweak just in case Maximizer did silly stuff
	if(lowMLZones contains place)
	{
		auto_log_debug("Going into a LOW ML ZONE with ML: " + monster_level_adjustment());
	}
	else
	{
		// Last minute MCD alterations if Limit set, otherwise trust maximizer
		if(get_property("auto_MLSafetyLimit") != "")
		{
			auto_setMCDToCap();
		}

		auto_log_debug("Going into High or Standard ML Zone with ML: " + monster_level_adjustment());
	}	

	executeFlavour();

	// After maximizing equipment, we might not be at full HP
	if ($locations[Tower Level 1, The Invader] contains place)
	{
		acquireHP();
	}

	if (my_hp() <= (my_maxhp() * 0.75)) {
		acquireHP();
	}

	// always heal to full HP for Boo Clues
	if(($locations[A-Boo Peak] contains place) && (get_property("auto_aboopending").to_int() != 0))
	{
		acquireHP();
		if(isActuallyEd())
		{
			//force Ed to heal
			edAcquireHP(my_maxhp());
		}
	}

	//my_mp is broken in Dark Gyffte
	if (my_class() != $class[Vampyre])
	{
		int wasted_mp = my_mp() + mp_regen() - my_maxmp();
		if(wasted_mp > 0 && my_mp() > 400)
		{
			auto_log_info("Burning " + wasted_mp + " MP...");
			cli_execute("burn " + wasted_mp);
		}
	}
	borisWastedMP();
	borisTrusty();

	acquireMP(32, 1000);

	if(in_hardcore() && (my_class() == $class[Sauceror]) && (my_mp() < 32))
	{
		auto_log_warning("We don't have a lot of MP but we are chugging along anyway", "red");
	}
	groundhogAbort(place);
	if (my_inebriety() > inebriety_limit())
	{
		if($locations[The Tunnel of L.O.V.E.] contains place)
		{
			auto_log_info("Trying to adv in [" +place+ "] while overdrunk... is actually permitted", "blue");
		}
		else abort("Trying to adv in [" +place+ "] while overdrunk... Stop it.");
	}
		
	if(in_pokefam())
	{
		// Build the team at the beginning of each adventure.
		pokefam_makeTeam();
	}

	set_property("auto_priorLocation", place);
	auto_log_info("Pre Adventure at " + place + " done, beep.", "blue");
	
	//to avoid constant flipping on the MCD. change it right before adventuring
	int mcd_target = get_property("auto_mcd_target").to_int();
	if(current_mcd() != mcd_target)
	{
		change_mcd(mcd_target);
	}

	print_footer();
	return true;
}

void main()
{
	boolean ret = false;
	try
	{
		ret = auto_pre_adventure();
	}
	finally
	{
		if (!ret)
		{
			auto_log_error("Error running auto_pre_adv.ash, setting auto_interrupt=true");
			set_property("auto_interrupt", true);
		}
		auto_interruptCheck();
	}
}
