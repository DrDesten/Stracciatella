#if TIME_MODE == 1

uniform int worldTime;
uniform int worldDay;
int worldTimeTotal = (worldDay & 255) * 24000 + worldTime;
float time = worldTimeTotal * (1./24.);

#elif TIME_MODE == 2

uniform int frameCounter;
float time = frameCounter / float(TIME_MODE_FRAME_RATE);

#else

uniform float frameTimeCounter;
float time = frameTimeCounter;

#endif