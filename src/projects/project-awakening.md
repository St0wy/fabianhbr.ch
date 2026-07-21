---
title: "Project Awakening"
description: "A zelda-like game made in Unity for the Procedural Generation module at SAE Institute."
creationDate: "Jun 3, 2022"
heroImage: "../../assets/project-awakening/project-awakening4.png"
order: 40
screenshots:
    [
        "/src/assets/project-awakening/project-awakening.png",
        "/src/assets/project-awakening/project-awakening1.png",
        "/src/assets/project-awakening/project-awakening2.png",
        "/src/assets/project-awakening/project-awakening3.png",
        "/src/assets/project-awakening/project-awakening4.png",
    ]
teamSize: 2
timeFrame: "1 Month"
toolUsed: "Unity"
---

import Button from "../../components/Button.astro";

<div class="grid place-items-center">
	<iframe
		class="w-full aspect-[16/9]"
		src="https://www.youtube-nocookie.com/embed/5pAEP3YIacE?si=nRx9W7C2OrJqneJg&autoplay=1&autohide=1&mute=1&modestbranding=1&playsinline=1"
		title="YouTube video player"
		autoplay="1"
		frameborder="0"
		allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
		allowfullscreen
	></iframe>
</div>

This is a **zelda-like** game made in Unity for the **Procedural Generation** module at SAE Institute.

It was made in collaboration with my classmate Némoz.

He implemented the generation of the overworld with an algorithm called the [**Wave Function Collapse**](https://en.wikipedia.org/wiki/Wave_function_collapse#Use_in_procedural_generation).
As for the dungeons, I implemented them using the same algorithm than the one used in **The Binding of Isaac**.
The character was made by me and my classmate did the enemies and the boss.

At the time, I wrote a blog post in french on how the dungeons are made : [La génération procédurale de The Binding of Isaac](https://blog.stowy.ch/posts/la-generation-procedurale-de-the-binding-of-isaac/).

## What I Learned

-   **Improving Game Feel**: The combat of game was very stiff, so I added features like input buffering to make it feel better.
-   **Dungeon Procedural Generation**: During classes I learned various techniques, but I really wanted to see how The Binding of Isaac did it, so I read blog posts about it.
-   **How to do animations with code in Unity**: Unity's animation system is nice to use for 3D animations, but in 2D it's really not ideal.
    So I decided to handle the animation transitions in code, and it was way easier to handle for this small project.

<div class="flex">
	<Button href="https://stowy.itch.io/project-awakening">Itch.io</Button>
	<Button href="https://github.com/St0wy/GPR4400-ProjectAwakening">
		Github Page
	</Button>
</div>

---

## Screenshots

import ScreenshotList from "../../components/ScreenshotList.astro";

<ScreenshotList screenshots={frontmatter.screenshots} />
