---
title: Software Rasterizer
description: Project made to understand better how GPUs work, and get a better feeling of how rasterization works.
slug: software-rasterizer
pubDatetime: 2026-01-03
heroImage: /assets/images/software-raster/output.png
teamSize: 1
timeFrame: 1 month
toolsUsed: Jai
---

A CPU-based rasterizer built in Jai, following the [tinyrenderer](https://github.com/ssloy/tinyrenderer) guide by Dmitry V. Sokolov.

The goal of this project is to understand the graphics pipeline, from raw vertices to a shaded image without the help of the GPU.

## Features
- **Pipeline:** Perspective-correct interpolation, projection matrix with infinite depth.
- **Lighting & Post:** Phong shading, HDR (ACES tonemapping), and Gamma correction.
- **Mapping:** Tangent-space Normal maps, bilinear texture filtering and handmade `.obj` file loading.
- **Output:** Writes to PNG via [stb_image_write](https://github.com/nothings/stb).

You can see the source of the project on [GitLab](https://gitlab.com/Stowy/tinyrenderer).

<div class="screenshots">
	<img src="/assets/images/software-raster/dragon.png" />
	<img src="/assets/images/software-raster/head.png" />
</div>
