boolean L7_crypt()
{
	if (internalQuestStatus("questL07Cyrptic") != 0)
	{
		return false;
	}
	if(item_amount($item[chest of the bonerdagon]) == 1)
	{
		use(1, $item[chest of the bonerdagon]);
		return false;
	}
	oldPeoplePlantStuff();

	if(my_mp() > 60)
	{
		handleBjornify($familiar[Grimstone Golem]);
	}

	buffMaintain($effect[Browbeaten], 0, 1, 1);
	buffMaintain($effect[Rosewater Mark], 0, 1, 1);

	boolean edAlcove = true;
	if (isActuallyEd())
	{
		edAlcove = (have_skill($skill[More Legs]) && (expected_damage($monster[modern zmobie]) + 15) < my_maxhp());
	}

	if((get_property("romanticTarget") != $monster[modern zmobie]) && (get_property("auto_waitingArrowAlcove").to_int() < 50))
	{
		set_property("auto_waitingArrowAlcove", 50);
	}

	void useNightmareFuelIfPossible()
	{
		//chews this when there are no guaranteed uses for spleen 
		if((spleen_left() > 0) && (item_amount($item[Nightmare Fuel]) > 0) && !isActuallyEd() && 
		!(auto_havePillKeeper() && spleen_left() >= 3) && 
		(spleen_left() > 4*min(auto_spleenFamiliarAdvItemsPossessed(),floor(spleen_left()/4))))	//only uses space than can't be filled with adv item
		{
			autoChew(1, $item[Nightmare Fuel]);
		}
	}

	void knockOffCapePrep()
	{
		if (auto_configureRetrocape("vampire", "kill"))
		{
			auto_forceEquipSword();
		}
	}

	// make sure quest status is correct before we attempt to adventure.
	visit_url("crypt.php");
	use(1, $item[Evilometer]);

	if((get_property("cyrptAlcoveEvilness").to_int() > 0) && ((get_property("cyrptAlcoveEvilness").to_int() <= get_property("auto_waitingArrowAlcove").to_int()) || (get_property("cyrptAlcoveEvilness").to_int() <= 25)) && edAlcove && canGroundhog($location[The Defiled Alcove]))
	{

		if((get_property("_badlyRomanticArrows").to_int() == 0) && auto_have_familiar($familiar[Reanimated Reanimator]) && (my_daycount() == 1))
		{
			handleFamiliar($familiar[Reanimated Reanimator]);
		}

		provideInitiative(850, true);

		autoEquip($item[Gravy Boat]);
		knockOffCapePrep();
		addToMaximize("100initiative 850max");

		if(get_property("cyrptAlcoveEvilness").to_int() >= 28)
		{
			useNightmareFuelIfPossible();
		}

		auto_log_info("The Alcove! (" + initiative_modifier() + ")", "blue");
		return autoAdv($location[The Defiled Alcove]);
	}
	//current mafia bug causes us to lose track of the amount of Evil Eyes in inventory so adding a refresh here
	cli_execute("refresh inv");
	// In KoE, skeleton astronauts are random encounters that drop Evil Eyes.
	// We might be able to reach the Nook boss without adventuring.

	while((item_amount($item[Evil Eye]) > 0) && auto_is_valid($item[Evil Eye]) && (get_property("cyrptNookEvilness").to_int() > 25))
	{
		use(1, $item[Evil Eye]);
	}

	boolean skip_in_koe = in_koe() && (get_property("cyrptNookEvilness").to_int() > 25) && get_property("questL12HippyFrat") != "finished";

	if((get_property("cyrptNookEvilness").to_int() > 0) && canGroundhog($location[The Defiled Nook]) && !skip_in_koe)
	{
		auto_log_info("The Nook!", "blue");
		buffMaintain($effect[Joyful Resolve], 0, 1, 1);
		autoEquip($item[Gravy Boat]);
		knockOffCapePrep();

		bat_formBats();

		if (get_property("cyrptNookEvilness").to_int() > 26) {
			januaryToteAcquire($item[broken champagne bottle]);
		}

		return autoAdv($location[The Defiled Nook]);
	}
	else if(skip_in_koe)
	{
		auto_log_debug("In Exploathing, skipping Defiled Nook until we get more evil eyes.");
	}

	if((get_property("cyrptNicheEvilness").to_int() > 0) && canGroundhog($location[The Defiled Niche]))
	{
		if((my_daycount() == 1) && (get_property("_hipsterAdv").to_int() < 7) && is_unrestricted($familiar[Artistic Goth Kid]) && auto_have_familiar($familiar[Artistic Goth Kid]))
		{
			handleFamiliar($familiar[Artistic Goth Kid]);
		}
		autoEquip($item[Gravy Boat]);
		knockOffCapePrep();

		if(auto_have_familiar($familiar[Space Jellyfish]) && (get_property("_spaceJellyfishDrops").to_int() < 3))
		{
			handleFamiliar($familiar[Space Jellyfish]);
		}

		if(get_property("cyrptNicheEvilness").to_int() >= 28)
		{
			useNightmareFuelIfPossible();
		}

		auto_log_info("The Niche!", "blue");
		if (canSniff($monster[Dirty Old Lihc], $location[The Defiled Niche]) && auto_mapTheMonsters())
		{
			auto_log_info("Attemping to use Map the Monsters to olfact a Dirty Old Lihc.");
		}
		return autoAdv($location[The Defiled Niche]);
	}

	if(get_property("cyrptCrannyEvilness").to_int() > 0)
	{
		auto_log_info("The Cranny!", "blue");
		set_property("choiceAdventure523", "4");

		if(my_mp() > 60)
		{
			handleBjornify($familiar[Grimstone Golem]);
		}

		autoEquip($item[Gravy Boat]);
		knockOffCapePrep();

		spacegateVaccine($effect[Emotional Vaccine]);

		if(auto_have_familiar($familiar[Space Jellyfish]) && (get_property("_spaceJellyfishDrops").to_int() < 3))
		{
			handleFamiliar($familiar[Space Jellyfish]);
		}

		if(get_property("cyrptCrannyEvilness").to_int() >= 28)
		{
			useNightmareFuelIfPossible();
		}

		// In Dark Gyffte: Each dieting pill gives about 23 adventures of turngen
		if(have_skill($skill[Flock of Bats Form]) && have_skill($skill[Sharp Eyes]))
		{
			int desired_pills = in_hardcore() ? 6 : 4;
			desired_pills -= my_fullness()/2;
			auto_log_info("We want " + desired_pills + " dieting pills and have " + item_amount($item[dieting pill]), "blue");
			if(item_amount($item[dieting pill]) < desired_pills)
			{
				if(!bat_wantHowl($location[The Defiled Cranny]))
				{
					bat_formBats();
				}
				set_property("choiceAdventure523", "5");
			}
		}

		auto_MaxMLToCap(auto_convertDesiredML(149), true);

		addToMaximize("200ml " + auto_convertDesiredML(149) + "max");
		return autoAdv($location[The Defiled Cranny]);
	}

	if(get_property("cyrptTotalEvilness").to_int() <= 0)
	{
		if(my_primestat() == $stat[Muscle])
		{
			buyUpTo(1, $item[Ben-Gal&trade; Balm]);
			buffMaintain($effect[Go Get \'Em\, Tiger!], 0, 1, 1);
			buyUpTo(1, $item[Blood of the Wereseal]);
			buffMaintain($effect[Temporary Lycanthropy], 0, 1, 1);
		}

		acquireHP();
		set_property("choiceAdventure527", 1);
		if(auto_have_familiar($familiar[Machine Elf]))
		{
			handleFamiliar($familiar[Machine Elf]);
		}
		auto_change_mcd(10); // get vertebra to make the necklace.
		boolean tryBoner = autoAdv(1, $location[Haert of the Cyrpt]);
		council();
		cli_execute("refresh quests");
		if(item_amount($item[chest of the bonerdagon]) == 1)
		{
			use(1, $item[chest of the bonerdagon]);
			auto_badassBelt(); // mafia doesn't make this any more even if autoCraft = true for some random reason so lets do it manually.
		}
		else if(get_property("questL07Cyrptic") == "finished")
		{
			auto_log_warning("Looks like we don't have the chest of the bonerdagon but KoLmafia marked Cyrpt quest as finished anyway. Probably some weird path shenanigans.", "red");
		}
		else if(!tryBoner)
		{
			auto_log_warning("We tried to kill the Bonerdagon because the cyrpt was defiled but couldn't adventure there and the chest of the bonerdagon is gone so we can't check that. Anyway, we are going to assume the cyrpt is done now.", "red");
		}
		else
		{
			abort("Failed to kill bonerdagon");
		}
		return true;
	}
	return false;
}
