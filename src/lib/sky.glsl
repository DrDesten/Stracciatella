#include "/core/dh/uniforms.glsl"
#include "/core/transform.glsl"

const vec3 sunsetColor = vec3(SKY_SUNSET_R, SKY_SUNSET_G, SKY_SUNSET_B);

const vec3 skyDayColor       = vec3(SKY_DAY_R, SKY_DAY_G, SKY_DAY_B);
const vec3 skyDayRainColor   = vec3(SKY_DAY_RAIN_R, SKY_DAY_RAIN_G, SKY_DAY_RAIN_B);
const vec3 skyNightColor     = vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B) * SKY_NIGHT_BRIGHTNESS;
const vec3 skyNightRainColor = vec3(SKY_NIGHT_RAIN_R, SKY_NIGHT_RAIN_G, SKY_NIGHT_RAIN_B) * SKY_NIGHT_BRIGHTNESS;

const vec3 fogCaveColor = vec3(FOG_CAVE_R, FOG_CAVE_G, FOG_CAVE_B);

const vec3 fogDayColor       = vec3(FOG_DAY_R, FOG_DAY_G, FOG_DAY_B);
const vec3 fogDayRainColor   = vec3(FOG_DAY_RAIN_R, FOG_DAY_RAIN_G, FOG_DAY_RAIN_B);
const vec3 fogNightColor     = vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B) * FOG_NIGHT_BRIGHTNESS;
const vec3 fogNightRainColor = vec3(FOG_NIGHT_RAIN_R, FOG_NIGHT_RAIN_G, FOG_NIGHT_RAIN_B) * FOG_NIGHT_BRIGHTNESS;

const vec3 endSkyUp   = vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B);
const vec3 endSkyDown = vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B);

uniform float sunset;
uniform float daynight;
uniform float rainStrength;
uniform int   isEyeInWater;

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform float far;
uniform vec3  up;
uniform vec3  sunDir;

uniform float frameTimeCounter;

// SKY /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec4 getSkyColor_fogArea(vec3 viewDir) {
    #ifdef NETHER

        return vec4(fogColor / (maxc(fogColor) + 0.25), 1);

    #endif
    #ifdef END 
    
        float viewHeight = dot(viewDir, up) * 0.5 + 0.5;
        return vec4(mix(endSkyDown, endSkyUp, viewHeight), 1);

    #endif
    
    float sunDot  = sq(dot(viewDir, sunDir) * 0.5 + 0.5);
	#ifdef SUN_SIZE_CHANGE
		sunDot = sunDot * (SUN_SIZE * 0.25) + sunDot;
	#endif

	float fogArea = smoothstep(-sunDot * 0.5 - 0.1, 0.05, dot(viewDir, -up)); // Adding sunDot to the upper smoothstep limit to increase fog close to sun

    #ifdef SKY_CUSTOM_COLOR
        // Custom Sky Color
	    vec3 skyRainColor  = mix(skyNightRainColor, skyDayRainColor, daynight);
	    vec3 skyClearColor = mix(skyNightColor,     skyDayColor,     daynight);
        vec3 skyCol        = mix(skyClearColor,     skyRainColor,    rainStrength);
    #else
        vec3 skyCol = skyColor;
    #endif
    #ifdef FOG_CUSTOM_COLOR
        // Custom Fog Color
	    vec3 fogRainColor  = mix(fogNightRainColor, fogDayRainColor, daynight);
	    vec3 fogClearColor = mix(fogNightColor,     fogDayColor,     daynight);
        vec3 fogCol        = mix(fogClearColor,     fogRainColor,    rainStrength);
    #else
        vec3 fogCol = fogColor;
    #endif

    #ifdef SKY_CUSTOM_SUNSET
	    fogCol = mix(fogCol, sunsetColor, (sunDot * 10 / (0.45 + sunDot * 9)) * sunset); // Make fog Color change for sunsets
    #endif

    //return vec4(vec3(sunset), fogArea);
	return vec4(mix(skyCol, fogCol, fogArea), fogArea);
}

vec3 getSkyColor(vec3 viewDir) { return getSkyColor_fogArea(viewDir).rgb; }


// FOG /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float fogSmoothStep(float distSq, float far) {
    float farSQ = sq(far);
    return smoothstep( farSQ * (SQRT2 * FOG_START / FOG_END), farSQ, distSq * (SQRT2 / FOG_END));
}

#ifdef DISTANT_HORIZONS
float fogFactorTerrain(vec3 playerPos) {
    return fogSmoothStep(sqmag(playerPos.xz), dhFarPlane);
}
#else
float fogFactorTerrain(vec3 playerPos) {
    playerPos.y *= 0.25;
    return fogSmoothStep(sqmag(playerPos), far);
}
#endif


float fogExp(vec3 viewPos, float density) {
    return 1 - exp(-length(viewPos) * density);
}
float fogExp(float dist, float density) {
    return 1 - exp(-dist * density);
}

float fogBorderExp( float dist, float far, float density ) {
    float farFog = exp( -far * SQRT2 * density );
    float expFog = exp( -dist * density );
    return 1 - saturate( expFog - farFog ) * (1 + farFog); // Dividing by (1 - farFog) is technically correct here, but for small farFog they are close. Multiplication is faster.
}

vec3 getFogSkyColor(vec3 viewDir) {
    if (isEyeInWater == 0) {
        return getSkyColor(viewDir);
    } else {
        return fogColor;
    }
}

	
#if FOG_ADVANCED

#include "/core/transform.glsl"

const float FAGlobalDensity = FA_GLOBAL_DENSITY;
const float FAOverworldDensity = FAGlobalDensity * FA_OVERWORLD_DENSITY_FACTOR;
const float FANetherDensity = FAGlobalDensity * FA_NETHER_DENSITY_FACTOR;
const float FAEndDensity = FAGlobalDensity * FA_END_DENSITY_FACTOR;

// Height fog density based on y-value
float FE_density(float y, float df) {
	return 1 - exp(-df * y);
}
// Integral of FE_density
float FE_densityI(float y, float df) {
	return (1 / df) * exp(-df * y) + y;
}

float fogFactorAdvanced(vec3 viewDir, vec3 playerPos)	{
    vec3  worldPos     = toWorld(playerPos);
    float playerLength = length(playerPos);

#if defined OVERWORLD

    const float constantDensity = FAOverworldDensity;

    const float scaleMultiplier  = FA_SCALE_MULTIPLIER;
    const float factorMultiplier = FA_FACTOR_MULTIPLIER;
    const float sunsetMultiplier = FA_SUNSET_MULTIPLIER;
    
    const float dynamicFactorStart      = FA_DYNAMIC_FACTOR_START;
    const float dynamicFactorMultiplier = FA_DYNAMIC_FACTOR_MULTIPLIER;

    const float wind              = FA_OVERWORLD_WIND;
    const float noiseScale        = FA_OVERWORLD_NOISE_SCALE;
    const float noiseFade         = FA_OVERWORLD_NOISE_FADE;
    const float worldNoiseFactor  = FA_OVERWORLD_NOISE_FOG_FACTOR;

    const float morningShift  = 30;
    const float morningScale  = 0.025;
    const float morningFactor = 0.016;

    const float noonShift  = 30;
    const float noonScale  = 0.035;
    const float noonFactor = 0.008;
    
    const float rainShift  = 40;
    const float rainScale  = 0.027;
    const float rainFactor = 0.07;

#ifdef FA_SUNSET_ANISOTROPIC
    float anisotropy        = dot(viewDir, sunDir);
    float sunAnisotropy     = anisotropy * (FA_SUNSET_ANISOTROPY * 0.5) + .5;
    float anisotropicSunset = sunset * sunAnisotropy;
    float sunsetMix         = anisotropicSunset * sunsetMultiplier;
#else
    float sunsetMix = sunset * sunsetMultiplier * 0.5;
#endif

    #if 1
    float shift  = mix( mix(noonShift,  morningShift, sunsetMix), rainShift, rainStrength );
    float scale  = mix( mix(noonScale,  morningScale, sunsetMix), rainScale, rainStrength ) * scaleMultiplier;
    float factor = mix( mix(noonFactor, morningFactor, sunsetMix), rainFactor, rainStrength ) * factorMultiplier;
    #else
    const float shift  = 40;
    const float scale  = 0.027;
    const float factor = 0.08;
    #endif
    
    float integratedHeightDensity = (
        FE_densityI(worldPos.y - shift, scale) - 
        FE_densityI(cameraPosition.y - shift, scale)
    ) / (worldPos.y - cameraPosition.y);

    float dynamicFactor = clamp(cameraPosition.y - dynamicFactorStart, 0, 512) * dynamicFactorMultiplier + 1;

#ifdef FA_OVERWORLD_NOISE_FOG

    vec3  playerDir     = normalize(playerPos);

    vec2  windOffset     = vec2(frameTimeCounter * wind, 0);
    vec2  worldNoisePos  = (worldPos.xz + windOffset) * noiseScale;
    float worldNoiseMix  = sqrtf01(abs(playerDir.y))
                         / (playerLength * noiseFade + 1);
    float worldFogFactor = sqsq(sfbm(worldNoisePos, 3) * 1.25)
                         * worldNoiseMix * worldNoiseFactor 
                         + (1 - worldNoiseMix);

#endif

    float heightFogFactor   = saturate(1 - integratedHeightDensity) * factor * dynamicFactor;
    float constantFogFactor = constantDensity;

#ifdef FA_OVERWORLD_NOISE_FOG
    heightFogFactor *= worldFogFactor;
#endif

    float combinedFogFactor = heightFogFactor + constantFogFactor;
    float worldFog          = exp2(-playerLength * combinedFogFactor);

    return 1 - worldFog;

#elif defined NETHER

    const float globalFogDensity    = FANetherDensity;
    const float wind                = FA_NETHER_WIND;
    const vec3  noiseScale          = FA_NETHER_NOISE_SCALE * vec3(1, 0.25, 1);
    const float noiseFade           = FA_NETHER_NOISE_FADE;
    const float playerFogMultiplier = FA_NETHER_PLAYER_FOG_MULTIPLIER;

#ifdef FA_NETHER_NOISE_FOG

    vec3 windOffset = vec3(frameTimeCounter * wind, 0, 0);

    vec3  playerDir      = normalize(playerPos);
    vec3  worldNoisePos  = (worldPos  + windOffset) * noiseScale;
    vec3  playerNoisePos = (cameraPosition + windOffset) * noiseScale + playerDir;

    float noiseMix = 1 / (playerLength * noiseFade + 1);
    float noiseFac = noiseMix;
    float noiseAdd = 1 - noiseMix;

    float worldFog  = sq(snoise(worldNoisePos)) * noiseFac + noiseAdd;
    float playerFog = sqsq(snoise(playerNoisePos)) * playerFogMultiplier;

    float expFactor       = -playerLength * globalFogDensity;
    float expFactorPlayer = -(25 * playerLength / (playerLength + 25)) * globalFogDensity;

    float fog = exp2( expFactor * worldFog + expFactorPlayer * playerFog );

#else

    float fog = exp2(-playerLength * globalFogDensity);

#endif

    return 1 - fog;

#elif defined END 

    const float constantDensity = FAEndDensity;

    const float density = 5;
    return 1 - exp2(-playerLength * density * constantDensity);

#endif

}

#endif