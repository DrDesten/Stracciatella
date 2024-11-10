#ifdef WORLD_TIME_ANIMATION

uniform int worldTime;
float time = (worldTime * (1./24.));

#else

uniform float frameTimeCounter;
float time = frameTimeCounter;

#endif