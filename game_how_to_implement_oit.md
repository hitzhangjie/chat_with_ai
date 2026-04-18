Order-Independent Transparency (OIT) in rendering is implemented by resolving the color and opacity of multiple overlapping transparent surfaces on a per-pixel basis, removing the need to sort geometry by depth before drawing [1, 2, 3]. It handles non-commutative alpha blending, where the order of rendering affects the final color [2]. [1, 2, 3, 4]  
Here is how OIT rendering is implemented: 
Core OIT Implementation Techniques 

• Weighted, Blended OIT (WBOIT): A fast, approximate OIT technique popular in modern real-time rendering. It uses additive blending with custom weight functions to approximate the depth-sorted compositing of transparent surfaces in a single pass [1, 8]. 
• Per-Pixel Linked Lists (PPLL): Implemented using Read-Write Structured Buffers () in Compute Shaders. Each pixel maintains a linked list of all fragments that cover it, which are then sorted and composited during a separate screen-space pass [2, 6, 7]. 
• Depth Peeling: A robust, exact OIT solution that renders the scene multiple times, peeling one layer of depth (the nearest or farthest) per pass to correctly layer transparency [2, 9]. 
• Adaptive OIT (AOIT): Updates an AOIT surface with multiple nodes of color and depth information per-pixel, allowing for accurate transparency in complex, high-overdraw scenes [1]. [1, 5, 6, 7, 8]  

Typical Rendering Pipeline 
OIT is usually implemented in three main steps, requiring a full-screen resolve pass [1, 5, 6]: 

1. Opaque Pass: Solid geometry is rendered first to the scene framebuffer [1]. 
2. Transparent Pass: Transparent objects are rendered, but instead of blending directly to the screen, their color, depth, and alpha values are stored in specialized buffers (e.g., accumulation and revealage textures) [1, 6]. 
3. Resolve/Composite Pass: A shader reads the data from the specialized buffers for each pixel, sorts them (if required by the specific technique), and calculates the final composited color before merging it with the opaque scene [1, 5]. [1, 9, 11, 12, 13]  

Example Implementations 

• Unity: Implemented in render pipelines using PPLL with ComputeBuffers [2]. 
• Unreal Engine: Available as an experimental feature designed to handle complex transparency. 
• Three.js/WebGL: Implemented using Weighted, Blended OIT techniques [4, 9]. 
• GameTechDev/AOIT-Update:  A GitHub project demonstrating Adaptive OIT via pixel synchronization [1]. [2, 9, 14, 15, 16]  

OIT is chosen over traditional alpha blending (back-to-front sorting) to eliminate depth-sorting artifacts and allow for high-performance rendering of transparent materials, particles, and effects [2, 3]. [2, 3, 4]  

AI responses may include mistakes.

[1] https://www.youtube.com/watch?v=wXSJUjgIX6w
[2] https://www.youtube.com/watch?v=GriPX0OK1t0
[3] https://osor.io/OIT
[4] https://www.emergentmind.com/topics/order-independent-transparency-oit
[5] https://research.activision.com/publications/archives/atvi-tr-16-02practical-order-independent-transparency
[6] https://www.reddit.com/r/vulkan/comments/bmys2b/what_is_the_simplest_way_to_implement_an_order/
[7] https://www.ovito.org/manual/reference/rendering/opengl_renderer.html
[8] https://mynameismjp.wordpress.com/2014/02/03/weighted-blended-oit/
[9] https://github.com/GameTechDev/AOIT-Update
[10] https://www.instagram.com/reel/DXPLEi4AYUG/
[11] https://www.cs.cornell.edu/~bkovacs/resources/TUBudapest-Barta-Pal.pdf
[12] https://learnopengl.com/Guest-Articles/2020/OIT/Introduction
[13] https://en.wikipedia.org/wiki/Order-independent_transparency
[14] https://github.com/mhalber/Weighted-Blended-OIT
[15] https://agentlien.github.io/cameras/index.html
[16] https://irendering.net/discover-the-latest-rendering-features-in-unreal-engine-5-3/


