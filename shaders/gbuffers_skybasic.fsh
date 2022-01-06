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

#ifdef CUSTOM_STARS
varying vec3  playerPos;
uniform float normalizedTime;
uniform float customStarBlend;
#endif

uniform float frameTimeCounter;

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

float shootingStar(vec2 coord, vec2 dir, float thickness, float slope) {
	dir    *= 0.9;
	vec2 pa = coord + (dir * 0.5);
    float t = saturate(dot(pa, dir) * ( 1. / dot(dir,dir) ) );
    float d = sqmag(dir * -t + pa);
    return saturate((thickness - d) * slope + 1) * t;
}

vec2 rotation(float angle) {
	return vec2(sin(angle), cos(angle));
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

			vec3 playerDir = normalize(playerPos);

			const mat2 skyRot = mat2(cos(sunPathRotation * (PI/180.)), sin(sunPathRotation * (PI/180.)), -sin(sunPathRotation * (PI/180.)), cos(sunPathRotation * (PI/180.)));
			vec3 skyDir       = vec3(playerDir.x, skyRot * playerDir.yz);
			skyDir            = vec3(rotationMatrix2D(normalizedTime * -TWO_PI) * skyDir.xy, skyDir.z);
			vec2 skyCoord     = octahedralEncode(skyDir);

			float starNoise = starVoronoi(skyCoord * STAR_DENSITY, 0.85);
			float stars     = fstep(starNoise, (STAR_SIZE * 1e-4 * STAR_DENSITY));

			float starGlow = exp(-starNoise * star_glow_size) * STAR_GLOW_AMOUNT * customStarBlend;
			stars          = saturate(stars + starGlow);
			
			stars         *= fstep(noise(skyCoord * 10), STAR_COVERAGE, 2);


			vec2 shootingStarCoord = normalize(playerPos * vec3(1,3,1)).xz * 2;

			vec2  lineDir      = rotation(0.57 * TWO_PI);
			shootingStarCoord += lineDir * -frameTimeCounter * 2;
			vec2  gridID       = floor(shootingStarCoord);
			vec2  gridUV       = fract(shootingStarCoord) - 0.5;
			
			float shootingStars = shootingStar(gridUV, lineDir, 1e-5, 1e6);
			shootingStars      *= fstep(0.98, rand(gridID));


			float starMask         = 1 - sky.a;
			float shootingStarMask = saturate(playerDir.y * 2 - 0.3);

			stars = saturate(stars * starMask + shootingStars * shootingStarMask);

			color = mix(sky.rgb, vec3(1), stars * customStarBlend);
			
			//color = vec3(shootingStarMask);

		} else {

			color = vec3(0);

		}

	#else

		float starMask = 1 - sky.a;
		vec3  color = mix(sky.rgb, saturate(starData.rgb * STAR_BRIGHTNESS) * starMask, starData.a);

	#endif


	#if DITHERING >= 1
		color += ditherColor(gl_FragCoord.xy);
	#endif
	FD0 = vec4(color, 1.0); //gcolor
}