---
title: Software Rasterizer
description: Project made to understand better how GPUs work, and get a better feeling of how rasterization works.
slug: software-rasterizer
pub_date_time: 2026-01-03
hero_image: /assets/images/software-raster/output.png
hero_image_alt: Software-rendered 3D head model on a checkered floor
team_size: 1
time_frame: 1 month
tools_used: Jai
repo: https://codeberg.org/St0wy/tinyrenderer
---

A CPU-based rasterizer built in Jai, following the [tinyrenderer](https://github.com/ssloy/tinyrenderer) guide by Dmitry V. Sokolov.

The goal of this project is to understand the graphics pipeline, from raw vertices to a shaded image without the help of the GPU.

## Features
- **Pipeline:** Perspective-correct interpolation, projection matrix with infinite depth.
- **Lighting & Post:** Phong shading, HDR (ACES tonemapping), and Gamma correction.
- **Mapping:** Tangent-space Normal maps, bilinear texture filtering and handmade `.obj` file loading.
- **Output:** Writes to PNG via [stb_image_write](https://github.com/nothings/stb).

You can see the source of the project on [Codeberg](https://codeberg.org/St0wy/tinyrenderer).

<div class="screenshots">
	<img src="/assets/images/software-raster/dragon.png" alt="Software-rendered horned red demon model on a checkered floor" />
	<img src="/assets/images/software-raster/head.png" alt="Software-rendered 3D head model with normal mapping on a checkered floor" />
</div>
