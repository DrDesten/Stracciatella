#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/fog_sky.glsl"

uniform vec2 screenSizeInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform vec3  sunDir;
uniform vec3  up;
uniform float sunset;
#ifdef CUSTOM_SKY
uniform float daynight;
uniform float rainStrength;
#endif

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
varying vec3 viewPos;

varying vec3  playerPos;
uniform float normalizedTime;

vec2 signNotZero(vec2 v) {
    return vec2((v.x >= 0.0) ? +1.0 : -1.0, (v.y >= 0.0) ? +1.0 : -1.0);
}
vec2 octahedralEncode(vec3 v) {
    float l1norm = abs(v.x) + abs(v.y) + abs(v.z);
    vec2  result = v.xy * (1.0 / l1norm);
    if (v.z < 0.0) {
        result = (1.0 - abs(result.yx)) * signNotZero(result.xy);
    }
    return result;
}

/* DRAWBUFFERS:0 */
void main() {
	#ifndef CUSTOM_SKY
	vec4 sky = getSkyColor_fogArea(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset);
	#else
	vec4 sky = getSkyColor_fogArea(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight);
	#endif

	float starMask = 1 - sky.a;
	
	vec3 color = mix(sky.rgb, saturate(starData.rgb * STAR_BRIGHTNESS), starData.a * starMask);

	const mat2 skyRot = mat2(cos(sunPathRotation * (PI/180.)), sin(sunPathRotation * (PI/180.)), -sin(sunPathRotation * (PI/180.)), cos(sunPathRotation * (PI/180.)));
	vec3 skyDir       = normalize(playerPos);
	skyDir			  = vec3(skyDir.x, skyRot * skyDir.yz);
	skyDir            = vec3(rotationMatrix2D(normalizedTime * -TWO_PI) * skyDir.xy, skyDir.z);
	

	color = vec3(checkerboard(octahedralEncode(skyDir) * 25));

	//color = fogColor;
	//color = skyColor;
	//color = starData.aaa;

	FD0 = vec4(color, 1.0); //gcolor
}