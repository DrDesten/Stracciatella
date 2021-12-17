#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

#ifdef SUN_SIZE_CHANGE
uniform mat4 gbufferModelView;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
#endif

varying vec2 coord;
varying vec4 glcolor;

bool sunOrMoon(vec3 sunPosition, vec3 moonPosition) { // True = Sun, False = Moon
	return sunPosition.z < moonPosition.z;
}
bool sunOrMoonAccurate(vec3 viewPos, vec3 sunPosition, vec3 moonPosition) { // True = Sun, False = Moon
	float dSun = sqmag(sunPosition - viewPos);
	float dMoon = sqmag(moonPosition - viewPos);
	return dSun < dMoon;
}

void main() {
	#ifndef SUN_SIZE_CHANGE
		gl_Position = ftransform();
	#else
		vec3 viewPos    = getView();
		bool isSun      = sunOrMoonAccurate(viewPos, sunPosition, moonPosition);

		vec3 sunToVert  = viewPos.xyz - (isSun ? sunPosition : moonPosition);
		viewPos.xyz    += (sunToVert - gbufferModelView[3].xyz) * SUN_SIZE;
		gl_Position     = viewToClip(vec4(viewPos, 1));
	#endif

	coord       = getCoord();
	glcolor     = gl_Color;
}