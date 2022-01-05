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

float starVoronoi(vec2 coord, float maxDeviation) {
    vec2 guv = fract(coord) - 0.5;
    vec2 gid = floor(coord);
	vec2 p   = (N22(gid) - 0.5) * maxDeviation; // Get Point in grid cell
	float d  = sqmag(p-guv);                    // Get distance to that point
    return d;
}

/* DRAWBUFFERS:0 */
void main() {
	#ifdef CUSTOM_SKY
	vec4 sky = getSkyColor_fogArea(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight);
	#else
	vec4 sky = getSkyColor_fogArea(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset);
	#endif

	#ifdef CUSTOM_STARS

		vec3 color;

		if (starData.a < 0.5) {

			const mat2 skyRot = mat2(cos(sunPathRotation * (PI/180.)), sin(sunPathRotation * (PI/180.)), -sin(sunPathRotation * (PI/180.)), cos(sunPathRotation * (PI/180.)));
			vec3 skyDir       = normalize(playerPos);
			skyDir			  = vec3(skyDir.x, skyRot * skyDir.yz);
			skyDir            = vec3(rotationMatrix2D(normalizedTime * -TWO_PI) * skyDir.xy, skyDir.z);
			vec2 skyCoord     = octahedralEncode(skyDir);

			float starNoise = starVoronoi(skyCoord * STAR_DENSITY, 0.85);
			float stars     = fstep(starNoise, (STAR_SIZE * 1e-4 * STAR_DENSITY));

			float starGlow = exp(-starNoise * star_glow_size) * STAR_GLOW_AMOUNT;
			stars          = saturate(stars + starGlow);
			
			float starMask = 1 - sky.a;
			starMask      *= fstep(noise(skyCoord * 10), STAR_COVERAGE, 2);

			color = mix(sky.rgb, vec3(1), stars * starMask);

		} else {

			color = vec3(0);

		}

	#else

		float starMask = 1 - sky.a;
		vec3  color = mix(sky.rgb, saturate(starData.rgb * STAR_BRIGHTNESS) * starMask, starData.a);

	#endif

	FD0 = vec4(color, 1.0); //gcolor
}