---
title: "Atomic Ball"
description: "Arcade game where 2 players are tying to get the highest score by going through doors and exchanging an atomic ball. The game was made with Unity during the Swiss Game Academy 2019 where it won the first price."
creationDate: "Jun 1 2019"
heroImage: "../../assets/atomicBall/atomicBall.png"
order: 20
screenshots:
    [
        "/src/assets/atomicBall/atomicScreen1.png",
        "/src/assets/atomicBall/atomicScreen2.png",
        "/src/assets/atomicBall/atomicScreen3.png",
    ]
teamSize: 6
timeFrame: "1 Week then 5 Months"
toolUsed: "Unity"
---

import Button from "../../components/Button.astro";

<div class="grid place-items-center">
	<video width="640" height="480" loop muted autoplay controls>
		<source src="/atomic_ball.webm" type="video/webm" />
		Your browser does not support the video tag.
	</video>
</div>

**Arcade** game where **2 players** are trying to get the highest score by going through doors.
Each player is restricted to one **half of the screen** and they have to **pass the ball** from one side to the other to be able to go through the doors that are on their path.
If one player touches the bottom of the screen, it's Game Over.
If one player doesn't touch the ball for too long, it will die.
So the players have to exange the ball regurlarly.

This project was made in **one week** during the **Swiss Game Academy** by a team of **6 persons** : 2 artists, 1 game designer and 3 programmers.
During this gamejam, the game looked completly different.

![The old artistic direction of Atomic Ball.](../../assets/atomicBall/oldAtomicBall.png)

We then **continued to work** on the game for **5 months** to fix bugs and change the artistic direction.
The game was then showed at multiple conventions such as **Hero Fest** and **Numerik Games**.

The work was evenly distributed between the 3 coders of the team, but I remember working on the **character controller**, and on the **death events**.
I was also in charge of the **leaderboard** implementation.

## What I Learned

-   **Working with a team**: During my programming studies, we rarely did group projects, so this one was great opportunity so see how things go in a team.
-   **Unity**: This is the first game that I finished during a game jam, and I learned a lot about how Unity works.
-   **Input Handling with 2 Players**: At the time Unity didn't have great tools for local coop, so we had to integrate a plugin to make it work and it was quite difficult.
-   **Presenting a Game at Events**: Since the game was presented at Hero Fest and Numerik Games, I added a local leaderboard to the game.
    We also added the possibility load the main menu if the game wasn't touched for a while.

<div class="flex">
	<Button href="https://orangecube.ch/game/4">Website</Button>
</div>

---

## Screenshots

import ScreenshotList from "../../components/ScreenshotList.astro";

<ScreenshotList screenshots={frontmatter.screenshots} />
