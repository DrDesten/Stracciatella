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

#ifdef SHOOTING_STARS
uniform float frameTimeCounter;
#endif

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

		vec3 color = sky.rgb;

		if (starData.a < 0.5 && customStarBlend > 1e-6 && playerPos.y > 0) {

			vec3 playerDir = normalize(playerPos);

			// STARS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


			const mat2 skyRot = mat2(cos(sunPathRotation * (PI/180.)), sin(sunPathRotation * (PI/180.)), -sin(sunPathRotation * (PI/180.)), cos(sunPathRotation * (PI/180.)));
			vec3 skyDir       = vec3(playerDir.x, skyRot * playerDir.yz);
			skyDir            = vec3(rotationMatrix2D(normalizedTime * -TWO_PI) * skyDir.xy, skyDir.z);
			vec2 skyCoord     = octahedralEncode(skyDir);

			float starNoise = starVoronoi(skyCoord * STAR_DENSITY, 0.85);
			float stars     = fstep(starNoise, (STAR_SIZE * 1e-4 * STAR_DENSITY));

			float starGlow = exp(-starNoise * star_glow_size) * STAR_GLOW_AMOUNT * (customStarBlend * 3 - 2);
			stars          = saturate(stars + starGlow);
			
			stars         *= fstep(noise(skyCoord * 10), STAR_COVERAGE, 2);

			float starMask = 1 - sky.a;
			stars         *= starMask;


			#ifdef SHOOTING_STARS
			// SHOOTING STARS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

				vec2 shootingStarCoord = normalize(playerPos * vec3(1,2,1)).xz * shooting_stars_length;

				const vec2 lineDir = vec2(sin(SHOOTING_STARS_ANGLE * TWO_PI), cos(SHOOTING_STARS_ANGLE * TWO_PI));
				shootingStarCoord -= frameTimeCounter * vec2(lineDir * 2 * SHOOTING_STARS_SPEED);
				vec2  gridID       = floor(shootingStarCoord);
				vec2  gridUV       = fract(shootingStarCoord) - 0.5;
				
				float shootingStars = shootingStar(gridUV, lineDir, (9e-8 * shooting_stars_thickness), (5e5 / shooting_stars_thickness));
				shootingStars      *= fstep(shooting_stars_density, rand(gridID));

				float shootingStarMask = saturate(playerDir.y * 2 - 0.3);
				shootingStars         *= shootingStarMask;

				stars = saturate(stars + shootingStars);

			#endif


			color = mix(color, vec3(1), stars * customStarBlend);
			

		} else if (starData.a >= 0.5) {

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