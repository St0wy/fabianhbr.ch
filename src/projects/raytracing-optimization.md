---
title: Optimizations: Ray Tracing in One Weekend
description: Project where I implemented the Ray Tracing in One Weekend book in Rust and then optimized it. Making it run from 6 minutes to 5 seconds.
slug: raytracing-optimizations
pubDatetime: 2023-02-15
heroImage: /assets/images/raytracing/bigScene.png
teamSize: 1
timeFrame: 1.5 Month
toolsUsed: Rust
---

This project was made during the **optimization** module at SAE Institute.
The goal was to make a project in a **naive way**, and then **optimize** it using the various techniques we learned during the module.

I choose to follow **Ray Tracing in One Weekend** in **Rust**.
I think it was a good idea since the book has a big Object Oriented style which made it quite slow.
It allowed me to profit from Rust's design and work in a **Data Oriented** manner.

You can read about the optimizations I did on my blogpost : [Raytracing : From 6 minutes to 5 seconds](/posts/raytracing-from-6-minutes-to-5-seconds/).

## What I Learned

I learned a lot about how code is executed on modern CPUs.
Mostly on subjects such as :

-   **CPU Caches**: I learned about the L1, L2 and L3 caches and how that impacts performance and data structures.
-   **Pipelining and Branch Prediction**: The way instructions are executed on the CPU means that it has to guess where to go where there's an `if` in the code.
-   **SIMD**: I learned how SIMD can greatly impact performance and how to use it with intrinsics.
    I did a small [solar system simulation project](https://github.com/St0wy/FunWithVectors) that I then optimized with SIMD to see its impact.
-   **Reading Assembly**: I learned to read the most common x86 assembly instructions. I also implemented some simple functions in assembly, the most complex one being bubble sort.
-   **Multithreading**: I learned about the multithreading primitives present in C++. I also used [Rayon](https://github.com/rayon-rs/rayon) to parallelize my Ray Tracing project.

I also learned the **math** and logic behind **Ray Tracing**.

You can see the source code of the project on [GitHub](https://github.com/St0wy/raytracing).

---

## Screenshots

<div class="screenshots">
	<img src="/assets/images/raytracing/bigScene.png" />
	<img src="/assets/images/raytracing/perlinEarth.png" />
	<img src="/assets/images/raytracing/cornell.png" />
</div>
