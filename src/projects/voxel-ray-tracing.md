---
title: "Bachelor Thesis - Voxel Path Tracing"
description: "Final project of my studies at SAE Institute Geneva.
Implemented Voxel Path Tracing in a Vulkan compute shader using the Jai programming language.
The thesis document was made in Typst."
creationDate: "July 19, 2024"
heroImage: "../../assets/bsc/final.jpg"
order: 1
teamSize: 1
timeFrame: "7 Months"
toolUsed: "Jai / Vulkan"
screenshots:
    [
    	"/src/assets/bsc/smooth-shadows-noisy.png",
        "/src/assets/bsc/path-trace.jpg",
        "/src/assets/bsc/env-map.png",
        "/src/assets/bsc/final.jpg",
        "/src/assets/bsc/final-pixel.jpg",
        "/src/assets/bsc/final-russian.jpg",
    ]
---

import Button from "../../components/Button.astro";

Final project of my studies at SAE Institute Geneva.
Implemented **Voxel Path Tracing** in a **Vulkan** compute shader using the **Jai** programming language.
The thesis document was made in **Typst**.

It features :

- Per-voxel and per-pixel lighting
- Diffuse, reflective and emissive materials
- A palette compressed world
- An environement map as a light source

## What I Learned

- **The Vulkan API**: As the project requires the use of compute shaders, and because I wanted to learn the API, Vulkan was chosen.
- **Jai**: At first the project started with Rust, but then I got access to the beta of Jai, so I decided to use it.
	It is aimed to be a replacement of C++ geared towards games and the "joy of programming".
- **Various path tracing techniques**: This project deepened my understanding of the subject, with things such as cosine-weighted sampling and russian roulette.
- **Statistics**: Doing real-time path tracing requires to apply some statistics concepts,
	and I also used student's T-test to prove than an optimisation made something faster.

<Button href="https://gitlab.com/Stowy/voxel-ray-tracer">GitLab Page of Media Project</Button>
<Button href="https://gitlab.com/Stowy/bachelor-thesis">GitLab Page of Thesis</Button>

---

## The Thesis

<object data="https://stowy.gitlab.io/bachelor-thesis/main.pdf" type="application/pdf" width="100%" style="aspect-ratio: 9/10; margin-bottom: 14px;">
	<p>Unable to display PDF file. <a href="https://stowy.gitlab.io/bachelor-thesis/main.pdf">Download</a> instead.</p>
</object>

<Button href="https://stowy.gitlab.io/bachelor-thesis/main.pdf">Open in new tab</Button>

---

## Screenshots

import ScreenshotList from "../../components/ScreenshotList.astro";

<ScreenshotList screenshots={frontmatter.screenshots} />
