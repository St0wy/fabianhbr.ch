---
title: 2D C++ Physics Engine
description: This is a 2D physics engine made in C++ with no libraries. It has a demo project to showcase it made with SFML and a web demo made with Raylib. The project was showcased in 3 code reviews videos by The Cherno that accumulated a total of 318'000 views.
slug: physics-engine
pubDatetime: 2022-07-15
heroImage: /assets/images/physics-engine/physics-engine.png
teamSize: 1
timeFrame: 1 Month
toolsUsed: C++
---

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

You can read the project's documentation on [Read the Docs](https://stowy-physics-engine.readthedocs.io/en/latest/index.html) and see the source on [GitHub](https://github.com/St0wy/StowyPhysicsEngine).

<div class="spinner" id="spinner"></div>
<div class="emscripten" id="status">Downloading...</div>
<progress hidden id="progress" max="100" value="0"></progress>

<canvas
    class="emscripten"
    id="canvas"
    oncontextmenu="
    event.preventDefault()
    "
    tabindex="-1"></canvas>

<script is:inline>
var statusElement = document.getElementById("status"),
    progressElement = document.getElementById("progress"),
    spinnerElement = document.getElementById("spinner"),
    Module = {
        preRun: [],
        postRun: [],
        print: (function () { })(),
        canvas: (() => {
            var e = document.getElementById("canvas");
            return (
                e.addEventListener(
                    "webglcontextlost",
                    (e) => {
                        alert(
                            "WebGL context lost. You will need to reload the page."
                        ),
                            e.preventDefault();
                    },
                    !1
                ),
                e
            );
        })(),
        setStatus: (e) => {
            if (
                (Module.setStatus.last ||
                    (Module.setStatus.last = {
                        time: Date.now(),
                        text: "",
                    }),
                    e !== Module.setStatus.last.text)
            ) {
                var t = e.match(/([^(]+)\((\d+(\.\d+)?)\/(\d+)\)/),
                    n = Date.now();
                (t && n - Module.setStatus.last.time < 30) ||
                    ((Module.setStatus.last.time = n),
                        (Module.setStatus.last.text = e),
                        t
                            ? ((e = t[1]),
                                (progressElement.value = 100 * parseInt(t[2])),
                                (progressElement.max = 100 * parseInt(t[4])),
                                (progressElement.hidden = !1),
                                (spinnerElement.hidden = !1))
                            : ((progressElement.value = null),
                                (progressElement.max = null),
                                (progressElement.hidden = !0),
                                e || (spinnerElement.style.display = "none")),
                        (statusElement.innerHTML = e));
            }
        },
        totalDependencies: 0,
        monitorRunDependencies: (e) => {
            (this.totalDependencies = Math.max(this.totalDependencies, e)),
                Module.setStatus(
                    e
                        ? "Preparing... (" +
                        (this.totalDependencies - e) +
                        "/" +
                        this.totalDependencies +
                        ")"
                        : "All downloads complete."
                );
        },
    };
Module.setStatus("Downloading..."), (window.onerror = (e) => { });
</script>
<script async src="/physics_engine_web_demo.js"></script>

## What I Learned

-   **The math behind a physics engine**: Even though I already studied Newton's equations, applying them in code is a different challenge.
-   **Creating a CMake library**: Before this project, using CMake was quite complicated for me and in this project I read a lot of tutorials to be more confortable.
-   **What to think about when designing an API**: Since my physics engine is a library, I had to think about what the user code would look like.
-   **Optimization with data structures**: To optimize collision detection, we studied multiple data structures (KD-Tree, Quadtree, Grids). I choose to implement a grid.

## Code Reviews

The project was also featured in 3 code review videos made by [The Cherno](https://www.youtube.com/@TheCherno),
who was an engine developper at Electronic Arts for 4 years.
They accumulated over 318'000 views as I'm writing this.
In these, The Cherno looks at my code and makes comments on the various things that could be improved.

<iframe
	class="video"
	src="https://www.youtube-nocookie.com/embed/eNSkYAzC_ew"
	title="YouTube video player"
	frameborder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowfullscreen
></iframe>

<iframe
	class="video"
	src="https://www.youtube-nocookie.com/embed/0AFKxekpbUM"
	title="YouTube video player"
	frameborder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowfullscreen
></iframe>

<iframe
	class="video"
	src="https://www.youtube-nocookie.com/embed/o1qs-KqJlzI"
	title="YouTube video player"
	frameborder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowfullscreen
></iframe>
