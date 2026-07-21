---
title: "Kamikaze"
description: "This is the final project that I made in a group of 2 for the Game Design module at SAE Institute."
creationDate: "April 15, 2022"
heroImage: "../../assets/kamikaze/kamikaze.png"
order: 70
screenshots:
    [
        "/src/assets/kamikaze/kamikaze.png",
        "/src/assets/kamikaze/kamikaze2.png",
        "/src/assets/kamikaze/kamikaze3.png",
        "/src/assets/kamikaze/kamikaze4.png",
    ]
teamSize: 2
timeFrame: "1 Month"
toolUsed: "Unity"
---

import Button from "../../components/Button.astro";

<div class="grid place-items-center">
	<iframe
		class="w-full aspect-[16/9]"
		src="https://www.youtube-nocookie.com/embed/dYETKHWb-g8?si=J5tgb1_b6tgMhfzY&autoplay=1&autohide=1&mute=1&modestbranding=1&playsinline=1"
		title="YouTube video player"
		frameborder="0"
		allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
		allowfullscreen
	></iframe>
</div>

This is the **final project** of the **Game Design module** at SAE Institute.
It was made in collaboration with a classmate.

The idea was to create a **Plant vs Zombie-like** game with **Kamikaze** characters that **explode** upon reaching enemies.

We first created a [**Game Design Document**](/kamikaze/GDD_Kamikaze.pdf) (GDD) outlining the **game's progression** and various **troops and enemy types**.
For instance, we considered a shield troop that blocks enemy advancement until it's defeated.
To introduce more engaging enemies, we thought of a slow yet resilient enemy capable of destroying the shield in a single hit.

After a presentation, we received the **feedback** to incorporate **synergies between troops**, leading us to introduce an ice troop that freezes enemies and increases damage, as well as an enemy vulnerable only when frozen.
These additions significantly enhanced the fun of the game.

The game is playable in your browser on the Itch.io page.

## What I Learned

-   **Intro to Rational Game Design**: During the game design module, we recieved a lesson from [Nicolas Briere](https://www.linkedin.com/in/nicolasbriere), Old Skull Games' CEO and formerly Game Designer at Beenox and Ankama.
-   **The difficulties of making a game fun**: The project stared out being really not fun, and although it's still not great, we were able to make it more fun through various play tests.

<div class="flex">
	<Button href="https://stowy.itch.io/kamikaze">Itch.io</Button>
	<Button href="https://github.com/St0wy/GPA4300-Kamikaze">
		Github Page
	</Button>
</div>

---

## Screenshots

import ScreenshotList from "../../components/ScreenshotList.astro";

<ScreenshotList screenshots={frontmatter.screenshots} />
