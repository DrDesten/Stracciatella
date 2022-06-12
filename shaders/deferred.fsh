#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"
#include "/lib/fog_sky.glsl"

uniform usampler2D colortex1;

#ifdef FOG

 uniform int   isEyeInWater;
 uniform float far;

 #ifdef OVERWORLD
  uniform ivec2 eyeBrightnessSmooth;
 #endif

#endif

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform vec3  sunDir;
uniform vec3  up;
uniform vec3  upPosition;
uniform float sunset;
#ifdef CUSTOM_SKY
uniform float daynight;
uniform float rainStrength;
#endif

#ifdef CUSTOM_STARS
uniform float normalizedTime;
uniform float customStarBlend;
#endif

#ifdef SHOOTING_STARS
uniform float frameTimeCounter;
#endif

#ifdef SNEAK_EFFECT
uniform float sneaking;
#endif

#ifdef CUSTOM_LIGHTMAP
#include "/lib/lightmap.glsl"
uniform float customLightmapBlend;
#else 

#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

vec2 cubemapCoords(vec3 direction) {
    float l  = max(max(abs(direction.x), abs(direction.y)), abs(direction.z));
    vec3 dir = direction / l;
    vec3 absDir = abs(dir);
    
    vec2 coord;
    if (absDir.x >= absDir.y && absDir.x > absDir.z) {
        if (dir.x > 0) {
            coord = vec2(0, 0.5) + (dir.zy * vec2(1, -1) + 1);
        } else {
            coord = vec2(2.0 / 3, 0.5) + (-dir.zy + 1);
        }
    } else if (absDir.y >= absDir.z) {
        if (dir.y > 0) {
            coord = vec2(1.0 / 3, 0) + (dir.xz * vec2(-1, 1) + 1);
        } else {
            coord = vec2(0, 0) + (-dir.xz + 1);
        }
    } else {
        if (dir.z > 0) {
            coord = vec2(1.0 / 3, 0.5) + (-dir.xy + 1);
        } else {
            coord = vec2(2.0 / 3, 0) + (dir.xy * vec2(1, -1) + 1);
        }
    }
    return coord;
}


float starVoronoi(vec2 coord, float maxDeviation) {
    vec2 guv = fract(coord) - 0.5;
    vec2 gid = floor(coord);
	vec2 p   = (N22(gid) - 0.5) * maxDeviation; // Get Point in grid cell
	float d  = sqmag(p-guv);                    // Get distance to that point
    return d;
}
vec2 starVoronoi_getCoord(vec2 coord, float maxDeviation) {
    vec2 guv = fract(coord) - 0.5;
    vec2 gid = floor(coord);
	vec2 p   = (N22(gid) - 0.5) * maxDeviation; // Get Point in grid cell
    return p;
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

uint encodeLMCoordBuffer(vec4 data) {
    uvec4 idata = uvec4(saturate(data) * 255 + 0.5);
    
    uint encoded = idata.x;
    encoded     += idata.y << 8;
    encoded     += idata.z << 16;
    encoded     += idata.w << 24;
    return encoded;
}
vec4 decodeLMCoordBuffer(uint encoded) {
    return vec4(
		float(encoded & 255) * (1./255),
		float((encoded >> 8) & 255) * (1./255),
		float((encoded >> 16) & 255) * (1./255),
		float(encoded >> 24) * (1./255)
	);
}
vec4 getLightmap(vec2 coord) {
    uint encoded = texture(colortex1, coord).x;
    return vec4(
		float(encoded & 255) * (1./255),
		float((encoded >> 8) & 255) * (1./255),
		float((encoded >> 16) & 255) * (1./255),
		float(encoded >> 24) * (1./255)
	);
}

uniform sampler2D colortex4;



/* DRAWBUFFERS:0 */
void main() {
	float depth     = getDepth(coord);
	vec3  screenPos = vec3(coord, depth);
	vec3  viewPos   = toView(screenPos * 2 - 1);
	#ifdef SNEAK_EFFECT
	if (sneaking > 1e-5) viewPos.xy *= sneaking * -.5 + 1;
	#endif
	vec3  viewDir   = normalize(viewPos);
	vec3  playerPos = toPlayer(viewPos);
	vec3  playerDir = normalize(playerPos);

	#ifdef CUSTOM_SKY
	vec4 skyGradient = getSkyColor_fogArea(viewDir, sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight);
	#else
	vec4 skyGradient = getSkyColor_fogArea(viewDir, sunDir, up, skyColor, fogColor, sunset);
	#endif

	#ifdef OVERWORLD
	#ifdef CUSTOM_STARS

		if (customStarBlend > 1e-6 && playerPos.y > 0) {

			// STARS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			const mat2 skyRot = mat2(cos(sunPathRotation * (PI/180.)), sin(sunPathRotation * (PI/180.)), -sin(sunPathRotation * (PI/180.)), cos(sunPathRotation * (PI/180.)));
			vec3 skyDir       = vec3(playerDir.x, skyRot * playerDir.yz);
			skyDir            = vec3(rotationMatrix2D(normalizedTime * -TWO_PI) * skyDir.xy, skyDir.z);
			vec2 skyCoord     = cubemapCoords(skyDir) * 0.35;

			float starNoise = starVoronoi(skyCoord * STAR_DENSITY, 0.85);
			float stars     = fstep(starNoise, (STAR_SIZE * 1e-4 * STAR_DENSITY), 5e3);

			float starGlow = exp(-starNoise * star_glow_size) * STAR_GLOW_AMOUNT * (customStarBlend * 3 - 2);
			stars          = saturate(stars + starGlow);
			
			stars         *= fstep(noise(skyCoord * 10), STAR_COVERAGE, 2);

			float starMask = 1 - skyGradient.a;
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

			// mix: <color> with <starcolor>, depending on <is there a star?> and <is it night?> and <is it blocked by sun or moon?>
			skyGradient.rgb = mix(skyGradient.rgb, vec3(1), stars * customStarBlend * saturate(abs(dot(viewDir, sunDir)) * -200 + 199.5));

		}

	#endif
	#endif

	vec3 color = getAlbedo(coord);

	if (depth >= 1) {
		#ifdef OVERWORLD
		color += skyGradient.rgb;
		#else
		color = skyGradient.rgb;
		#endif
	}

    else {

		vec4 lmcoord = getLightmap(coord);

		vec3 blockLightColor = (textureBicubic(colortex4, coord, vec2(16,9), 1./vec2(16,9)).rgb);
		blockLightColor = blockLightColor / (maxc(blockLightColor) + 0.05);
		blockLightColor = saturate(applySaturation(blockLightColor, 3));

		color *= getCustomLightmap(lmcoord.xy, customLightmapBlend, lmcoord.z, blockLightColor) * (1 - lmcoord.a) + lmcoord.a;

		//color = lmcoord.xxx;

		#ifdef FOG
			float fog     = fogFactorPlayer(playerPos, far);
			#ifdef OVERWORLD
				float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(lmcoord.y * 1.5 - 0.25) );
				color = mix(color, mix(fogCaveColor, skyGradient.rgb, cave), fog);
			#else
				color = mix(color, skyGradient.rgb, fog);
			#endif
		#endif
		
	}

	#if DITHERING >= 1
		color += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}