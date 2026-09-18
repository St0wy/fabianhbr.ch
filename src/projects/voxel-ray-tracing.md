---
title: Bachelor Thesis - Voxel Path Tracing
description: Final project of my studies at SAE Institute Geneva. Implemented Voxel Path Tracing in a Vulkan compute shader using the Jai programming language. The thesis document was made in Typst.
slug: voxel-ray-tracing
pub_date_time: 2024-07-19
hero_image: /assets/images/bsc/final.jpg
hero_image_alt: Path-traced voxel Cornell box with red, green and blue cubes
team_size: 1
time_frame: 7 Months
tools_used: Jai / Vulkan
repo: https://codeberg.org/St0wy/voxel-ray-tracer
---

Final project of my studies at SAE Institute Geneva.
Implemented **Voxel Path Tracing** in a **Vulkan** compute shader using the **Jai** programming language.
The thesis document was made in **Typst**.

It features :

- Per-voxel and per-pixel lighting
- Diffuse, reflective and emissive materials
- A palette compressed world
- An environment map as a light source

## What I Learned

- **The Vulkan API**: As the project requires the use of compute shaders, and because I wanted to learn the API, Vulkan was chosen.
- **Jai**: At first the project started with Rust, but then I got access to the beta of Jai, so I decided to use it. It is aimed to be a replacement of C++ geared towards games and the "joy of programming".
- **Various path tracing techniques**: This project deepened my understanding of the subject, with things such as cosine-weighted sampling and russian roulette.
- **Statistics**: Doing real-time path tracing requires to apply some statistics concepts, and I also used student's T-test to prove than an optimisation made something faster.

You can see the source of the [renderer on Codeberg](https://codeberg.org/St0wy/voxel-ray-tracer)
and see the source of the [thesis is also on Codeberg](https://codeberg.org/St0wy/bachelor-thesis).

---

## The Thesis

<object data="https://st0wy.codeberg.page/bachelor-thesis/main.pdf" type="application/pdf" width="100%" style="aspect-ratio: 9/10; margin-bottom: 14px;">
	<p>Unable to display PDF file. <a href="https://st0wy.codeberg.page/bachelor-thesis/main.pdf">Download</a> instead.</p>
</object>

You can find the pdf at [https://st0wy.codeberg.page/bachelor-thesis/main.pdf](https://st0wy.codeberg.page/bachelor-thesis/main.pdf).

---

## Screenshots

<div class="screenshots">
	<img src="/assets/images/bsc/smooth-shadows-noisy.png" alt="Voxel model rendered with noisy soft shadows, with the debug overlay open" />
	<img src="/assets/images/bsc/path-trace.jpg" alt="Path-traced voxel house with a wooden roof on a grassy island" />
	<img src="/assets/images/bsc/env-map.png" alt="Voxel house and tower lit by a sky environment map" />
	<img src="/assets/images/bsc/final.jpg" alt="Path-traced voxel Cornell box with red, green and blue cubes" />
	<img src="/assets/images/bsc/final-pixel.jpg" alt="The same Cornell box scene with per-pixel lighting enabled" />
	<img src="/assets/images/bsc/final-russian.jpg" alt="The same Cornell box scene with Russian roulette enabled" />
</div>
