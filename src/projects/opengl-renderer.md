---
title: OpenGL - Deferred PBR Renderer
description: A deferred PBR renderer made in C++ with OpenGL. Implements Image-Based Lighting, glTF format loading, GPU-compressed textures, Normal Maps, Cascaded Shadow Maps, Bloom and SSAO.
slug: opengl-renderer
pubDatetime: 2023-06-18
heroImage: /assets/images/opengl-scene/chat.jpg
teamSize: 1
timeFrame: 3 Months
toolsUsed: C++ / OpenGL
---

<div class="grid place-items-center">
	<video width="640" height="480" loop muted autoplay controls>
		<source src="/assets/images/opengl-scene/demo_opengl.mp4" type="video/mp4" />
		Your browser does not support the video tag.
	</video>
</div>

This is a **deferred PBR renderer** made in **C++** with **OpenGL** during the Computer Graphics class at SAE Institute.

It features :

-   Physically Based Rendering (PBR)
-   Image Based Lighting (IBL)
-   Deferred Rendering
-   Cascaded Shadow Maps
-   Normal Mapping
-   ACES HDR Tone Mapping
-   Bloom
-   Screen Space Ambient Occlusion (SSAO)
-   Scene Graph
-   Model Loading (OBJ and glTF)
-   KTX Textures Loading

I wrote an explanation of some of the technical
details behind this renderer in [How I implemented a deferred PBR renderer in OpenGL](/posts/how-i-implemented-a-deferred-pbr-renderer-in-opengl).

## What I Learned

-   **The OpenGL API**: This project is the one where I learned the most about OpenGL and generally the principles on how you talk to a GPU from a CPU.
-   **Multiple rendering techniques**: Although LearnOpenGL introduces the technics I implemented in this renderer in OpenGL, I'm pretty confident I would be able to implement them using other APIs.
-   **My passion for the subject !**: I already knew that I liked displaying triangles on a screen, but this project convinced me to become a Graphics Programmer.

You can find the source of the project on [GitHub](https://github.com/St0wy/opengl-scene).
