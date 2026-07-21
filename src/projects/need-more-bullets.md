---
title: "Need More Bullets"
description: "Game made during the LvlUp Game Jam 2024 in 48 hours with a team of 3 programmers where it won the public's choice award."
creationDate: "Feb 18 2024"
heroImage: "../../assets/need-more-bullets/need_more_bullets.png"
order: 40
screenshots:
    [
        "/src/assets/need-more-bullets/nmb1.png",
        "/src/assets/need-more-bullets/nmb2.png",
    ]
teamSize: 3
timeFrame: "48 hours"
toolUsed: "Unity"
---

import Button from "../../components/Button.astro";

<div class="grid place-items-center">
	<iframe
		class="w-full aspect-[16/9]"
		src="https://www.youtube-nocookie.com/embed/xf2z48CnGp0?si=nRx9W7C2OrJqneJg&autoplay=1&autohide=1&mute=1&modestbranding=1&playsinline=1"
		title="YouTube video player"
		autoplay="1"
		frameborder="0"
		allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
		allowfullscreen
	></iframe>
</div>

Need More Bullets is a game made during the **LvlUp Game Jam 2024** in **48 hours** with a team of 3 programmers where it won the **public's choice award**.
The theme of the jam was _Reduce, Reuse, Recycle_.

## What I Learned

-   **Post-processing in Unity**: Since we didn't have any artists in the team, I tried to hide the ugly truth by adding post-processing effects.
-   **FPS Weapon Rendering**: To not have the weapon go through walls, I used a separate camera to render it so that it would always be on top.
-   **The importance of Juice**: The project is not the most balanced or the smartest in its use of the theme,
    but we tried to add as much Juice as we could and I think it plays a big part in why we won the public's choice award.

<div class="flex">
	<Button href="https://stowy.itch.io/need-more-bullets">Itch.io</Button>
	<Button href="https://gitlab.com/Stowy/lvlupgamejam2024">
		GitLab Page
	</Button>
</div>

---

## Screenshots

import ScreenshotList from "../../components/ScreenshotList.astro";

<ScreenshotList screenshots={frontmatter.screenshots} imageClasses="w-full" />
