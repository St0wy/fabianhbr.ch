---
title: "2D C++ Physics Engine"
description: "This is a 2D physics engine made in C++ with no libraries. 
It has a demo project to showcase it made with SFML and a web demo made with Raylib. 
The project was showcased in 3 code reviews videos by The Cherno that accumulated a total of 261'000 views."
creationDate: "Jul 15 2022"
heroImage: "../../assets/physics-engine/physics-engine.png"
order: 10
teamSize: 1
timeFrame: "1 Month"
toolUsed: "C++"
---

import Button from "../../components/Button.astro";

This is a **2D physics engine** made in **C++** with no libraries.
It was made during the physics engine module of the SAE Institute.

It has :

-   Circle colliders
-   [AABB](https://en.wikipedia.org/wiki/Minimum_bounding_box#Axis-aligned_minimum_bounding_box) colliders
-   Broad phase collision detection with a grid

At first the demo scene was made in [SFML](https://www.sfml-dev.org/).
But recently, I ported it to [raylib](https://www.raylib.com/) so that I
could compile the projet to a web version with [Emscripten](https://emscripten.org/).
You can left click to place circles and right click to place squares.

<div class="flex" style="margin-bottom: 1em;">
	<Button href="https://stowy-physics-engine.readthedocs.io/en/latest/index.html">
		Online Docs
	</Button>
	<Button href="https://github.com/St0wy/StowyPhysicsEngine">
		Github Page
	</Button>
</div>

import PhysicsEngineDemo from "../../components/physics_engine/PhysicsEngineDemo.astro";

<PhysicsEngineDemo />

## What I Learned

-   **The math behind a physics engine**: Even though I already studied Newton's equations, applying them in code is a different challenge.
-   **Creating a CMake library**: Before this project, using CMake was quite complicated for me and in this project I read a lot of tutorials to be more confortable.
-   **What to think about when designing an API**: Since my physics engine is a library, I had to think about what the user code would look like.
-   **Optimization with data structures**: To optimize collision detection, we studied multiple data structures (KD-Tree, Quadtree, Grids). I choose to implement a grid.

## Code Reviews

The project was also featured in 3 code review videos made by [The Cherno](https://www.youtube.com/@TheCherno),
who was an engine developper at Electronic Arts for 4 years.
They accumulated a total of 260'000 views.
In these, The Cherno looks at my code and makes comments on the various things that could be improved.

<div class="grid place-items-center">
	<iframe
		style="overflow:hidden;width:90%;aspect-ratio:16/9"
		src="https://www.youtube-nocookie.com/embed/eNSkYAzC_ew"
		title="YouTube video player"
		frameborder="0"
		allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
		allowfullscreen
	/>
</div>

<div class="grid place-items-center">
	<iframe
		style="overflow:hidden;width:90%;aspect-ratio:16/9"
		src="https://www.youtube-nocookie.com/embed/0AFKxekpbUM"
		title="YouTube video player"
		frameborder="0"
		allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
		allowfullscreen
	/>
</div>

<div class="grid place-items-center">
	<iframe
		style="overflow:hidden;width:90%;aspect-ratio:16/9"
		src="https://www.youtube-nocookie.com/embed/o1qs-KqJlzI"
		title="YouTube video player"
		frameborder="0"
		allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
		allowfullscreen
	/>
</div>
