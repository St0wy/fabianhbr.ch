---
title: Bachelor Thesis - Voxel Path Tracing
description: Final project of my studies at SAE Institute Geneva. Implemented Voxel Path Tracing in a Vulkan compute shader using the Jai programming language. The thesis document was made in Typst.
slug: voxel-ray-tracing
pubDatetime: 2024-07-19
heroImage: /assets/images/bsc/final.jpg
teamSize: 1
timeFrame: 7 Months
toolsUsed: Jai / Vulkan
---

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

You can see the source of the [renderer on GitLab](https://gitlab.com/Stowy/voxel-ray-tracer)
and see the source of the [thesis also on GitLab](https://gitlab.com/Stowy/bachelor-thesis).

---

## The Thesis

<object data="https://stowy.gitlab.io/bachelor-thesis/main.pdf" type="application/pdf" width="100%" style="aspect-ratio: 9/10; margin-bottom: 14px;">
	<p>Unable to display PDF file. <a href="https://stowy.gitlab.io/bachelor-thesis/main.pdf">Download</a> instead.</p>
</object>

You can find the pdf at [https://stowy.gitlab.io/bachelor-thesis/main.pdf](https://stowy.gitlab.io/bachelor-thesis/main.pdf).

---

## Screenshots

<div class="screenshots">
	<img src="/assets/images/bsc/smooth-shadows-noisy.png" />
	<img src="/assets/images/bsc/path-trace.jpg" />
	<img src="/assets/images/bsc/env-map.png" />
	<img src="/assets/images/bsc/final.jpg" />
	<img src="/assets/images/bsc/final-pixel.jpg" />
	<img src="/assets/images/bsc/final-russian.jpg" />
</div>
