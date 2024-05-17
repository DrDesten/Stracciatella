#include "/lib/settings.glsl"
#include "/lib/blending.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/setup.glsl"

const float wetnessHalflife = 200;
const float drynessHalflife = 400;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float frameTimeCounter;

#ifdef COLOR_LUT
uniform sampler2D colortex2; // LUT
#endif

#if RAIN_REFRACTION != 0
uniform sampler2D colortex3; // Rain Effects
#endif

#include "/lib/transform.glsl"
#include "/lib/sky.glsl"

uniform int   isEyeInWater;
uniform float far;
uniform float daynight;
uniform vec2  playerLMCSmooth;

uniform float blindness;
uniform float nightVision;
uniform float darknessFactor;
#ifdef DAMAGE_EFFECT
uniform float damage;
#endif

vec2 map3d2d(vec3 pos, float sides) {
	float cellSize  = 1 / sides;
	float cellIndex = floor(pos.z * sides * sides) * cellSize;
	vec2  offset    = vec2(
		fract(cellIndex),
		floor(cellIndex) * cellSize
	);
	vec2 mappedCoords = pos.xy * cellSize + offset;
	return mappedCoords;
}

/* vec3 applyLUT(sampler2D luttex, vec3 color, float sides) {
	vec2 lutCoord = map3d2d(clamp(color, 0.00001, 0.99999), sides);
	color = texture(luttex, lutCoord).rgb;
	return color;
} */
vec3 applyLUT(sampler2D luttex, vec3 color, float sides) {
	float lutRes   = sides * sides;
	float lutPixel = 0.5 / lutRes;
	vec2  lutCoord = map3d2d(clamp(color, lutPixel, 1 - lutPixel), sides);
	color = texture(luttex, lutCoord).rgb;
	return color;
}

float roundVignette(vec2 coord) {
	return saturate(exp(-sq(sqmag(coord * 1.75 - 0.875))));
}
float squareVignette(vec2 coord) {
	return smoothstep( 0.7, 0.25, pow(sq(sq(coord.x - 0.5)) + sq(sq(coord.y - 0.5)), 0.25) );
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
#if RAIN_REFRACTION == 1
	float rain  = texture(colortex3, coord).r;
	coord      += rain * sin(vec2(coord * TWO_PI + frameTimeCounter * 0.3 )) * RAIN_REFRACTION_STRENGTH;
#elif RAIN_REFRACTION == 2
	float rain  = texture(colortex3, coord).r;
	float noise = fbm( coord * 15, 3, 3, 0.75);
	coord      += rain * sin(vec2(noise * TWO_PI + frameTimeCounter * 0.3 )) * sqrt(noise) * RAIN_REFRACTION_STRENGTH;
#endif

#ifdef DAMAGE_EFFECT

	vec3 color;
	if (damage > 1e-15) {

		const float rows = 30;
		const float cols = 7;
		
		float cellNoiseHorizontal = rand(floor((coord.y + frameTimeCounter * 0.1) * rows));

		vec2  noiseSeed = coord + vec2(sin(frameTimeCounter * .1), cos(frameTimeCounter * .1));
		noiseSeed.x    += cellNoiseHorizontal;
		noiseSeed       = noiseSeed * vec2(cols * (cellNoiseHorizontal + 0.5), rows);

		float cellNoise  = sin(rand(floor(noiseSeed)) * (10./DAMAGE_EFFECT_DISPLACEMENT_SIZE));
		float finalNoise = damage * cellNoise * (0.02 * DAMAGE_EFFECT_DISPLACEMENT);

		color.r = unBlendColor(getAlbedo(coord + vec2(finalNoise,0))).r;
		color.g = unBlendColor(getAlbedo(coord - finalNoise)).g * (damage * -DAMAGE_EFFECT_REDNESS + 1);
		color.b = unBlendColor(getAlbedo(coord + vec2(0,finalNoise))).b * (damage * -DAMAGE_EFFECT_REDNESS + 1);

	} else {
		color = unBlendColor(getAlbedo(coord));
	}

#else
	vec3 color = unBlendColor(getAlbedo(coord));
#endif

	if (isEyeInWater == 1) {
		vec3  viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		float fogFac  = fogBorderExp(length(viewPos) + 15, far, FOG_UNDERWATER_DENSITY * exp(playerLMCSmooth.y * -FOG_UNDERWATER_DENSITY_DEPTH_INFLUENCE + FOG_UNDERWATER_DENSITY_DEPTH_INFLUENCE));

		color = mix(color, fogColor * (playerLMCSmooth.y * 0.6 + 0.4) * (daynight * 0.75 + 0.25), saturate(nightVision * -0.1 + fogFac));
	} else if (isEyeInWater == 2) {
		vec3  viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		float fogFac  = fogExp(viewPos, 2);

		color = mix(color, fogColor * 0.75, fogFac);
	}

	if (blindness > 0 || darknessFactor > 0) {
		vec3 viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		color *= 1. / (sqmag(viewPos) * max(blindness, darknessFactor * 0.1) + 1);
	}

#if CONTRAST != 0
	const float contrastAmount = 1 / (1 - (CONTRAST / 300. + 0.5)) - 1;
	color = applyContrast(color, contrastAmount);
#endif
#if VIBRANCE != 0
	const float vibranceAmount = (VIBRANCE / 100.);
	color = applyVibrance(color, vibranceAmount);
#endif
#if SATURATION != 0
	const float saturationAmount = SATURATION / 100. + 1.;
	color = applySaturation(color, saturationAmount);
#endif
#if BRIGHTNESS != 0
	const float brightnessAmount      = 1 / (BRIGHTNESS / 250. + 0.5) - 1;
	const float brightnessColorOffset = abs(BRIGHTNESS - 50.) / 500.;
	color = applyBrightness(color, brightnessAmount, brightnessColorOffset);
#endif

#if VIGNETTE == 1
	color *= roundVignette(coord) * VIGNETTE_STRENGTH + (1 - VIGNETTE_STRENGTH);
#elif VIGNETTE == 2
	color *= squareVignette(coord) * VIGNETTE_STRENGTH + (1 - VIGNETTE_STRENGTH);
#endif

#ifdef COLOR_LUT
	#ifdef LUT_LOG_COLOR
	color = log(color * (E-1) + 1);
	#endif
	color -= Bayer8(gl_FragCoord.xy) * (3./ (LUT_CELL_SIZE * LUT_CELL_SIZE)) - (1.5/ (LUT_CELL_SIZE * LUT_CELL_SIZE));
	color  = applyLUT(colortex2, color, LUT_CELL_SIZE);
#endif

#if DITHERING >= 2 && !defined COLOR_LUT
	color.rgb -= ditherColor(gl_FragCoord.xy);
#endif
	FragOut0 = vec4(color, luminance(color));
}