---
title: "OpenGL - Deferred PBR Renderer"
description: "The deferred PBR renderer made in C++ with OpenGL during the Computer Graphics class at SAE Institute."
creationDate: "July 18, 2023"
heroImage: "../../assets/opengl-renderer/chat.jpg"
order: 5
teamSize: 1
timeFrame: "3 Months"
toolUsed: "C++ / OpenGL"
---

import Button from "../../components/Button.astro";

<div class="grid place-items-center">
	<video width="640" height="480" loop muted autoplay controls>
		<source src="/opengl/demo_opengl.mp4" type="video/mp4" />
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

I wrote a blog post where I explained some of the technical
details behind this renderer on <a href="https://blog.stowy.ch/posts/how-i-implemented-a-deferred-pbr-renderer-in-opengl/" target="_blank">my blog</a>.

## What I Learned

-   **The OpenGL API**: This project is the one where I learned the most about OpenGL and generally the principles on how you talk to a GPU from a CPU.
-   **Multiple rendering techniques**: Although LearnOpenGL introduces the technics I implemented in this renderer in OpenGL,
    I'm pretty confident I would be able to implement them using other APIs.
-   **My passion for the subject !**: I already knew that I liked displaying triangles on screen (see 3D Viewer), but this project convinced me to become a Graphics Programmer.

<Button href="https://github.com/St0wy/opengl-scene">GitHub Page</Button>
