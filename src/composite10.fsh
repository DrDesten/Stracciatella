#define PP_PREPASS

#include "/lib/settings.glsl"

#if PP_PROGRAM == 1
#include "/post_process_shaders/comic.glsl"
#elif PP_PROGRAM == 2
#include "/post_process_shaders/badtrip.glsl"
#elif PP_PROGRAM == 3
#include "/post_process_shaders/anaglyph.glsl"
#endif