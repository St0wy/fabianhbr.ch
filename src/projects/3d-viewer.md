---
title: "3D Viewer"
description: "3D engine (rasteriser) made in C# (no graphics library) that allows to show models and organize them in a scene graph."
creationDate: "Jun 11 2021"
heroImage: "../../assets/3dviewer/3dviewer.png"
order: 50
screenshots:
    [
        "/src/assets/3dviewer/3DViewerScreenshot1.png",
        "/src/assets/3dviewer/3DViewerScreenshot2.png",
        "/src/assets/3dviewer/3DViewerScreenshot3.png",
        "/src/assets/3dviewer/3DViewerScreenshot4.png",
        "/src/assets/3dviewer/3DViewerScreenshot5.png",
        "/src/assets/3dviewer/3DViewerScreenshot6.png",
    ]
teamSize: 1
timeFrame: "2 Month"
toolUsed: "C#"
---

import Button from "../../components/Button.astro";

<div class="grid place-items-center">
	<video width="640" height="480" loop muted autoplay controls>
		<source src="/3DViewer.mp4" type="video/mp4" />
		Your browser does not support the video tag.
	</video>
</div>

This is my **diploma project** for my technician formation that allowed me to get the **congratulations of the jury**.
It's a **software 3D engine** (rasteriser) made in **C#** (windows form, no graphics library) that allows to show **3D models** and organize them in a **scene graph**.

## What I Learned

-   **Linear Algebra**: When I started this project, I had very little knowledge of the subject, and I had to learn most of it from a book provided by my teacher.
-   **How Scene Graphs work**: I also discovered how scene graphs work. Although the implementation is not optimal, I was able to learn the principles.
-   **Online Documentation Creation**: I had already worked on documentation before, but never for a project of this size. You can read it by clicking on the button below
-   **3D Models Loading**: The models in the project are loaded though a custom .ply loader.

<div class="flex">
	<Button href="https://3dviewer.readthedocs.io/fr/latest/">
		Online Docs (FR)
	</Button>
	<Button href="https://gitlab.com/Stowy/3dviewer">GitLab Page</Button>
</div>

---

## Screenshots

import ScreenshotList from "../../components/ScreenshotList.astro";

<ScreenshotList screenshots={frontmatter.screenshots} imageClasses="w-full" />
