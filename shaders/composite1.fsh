#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

/*
const int colortex0Format = RGBA8;  // Color
const int colortex1Format = R32UI;  // Lightmap, AO, Emissiveness (encoded)
const int colortex2Format = R8;     // Unused (LUT)
const int colortex3Format = R8;     // Effects
const int colortex4Format = RGBA16; // LightmapColor + Depth
const int colortex5Format = RGB8;   // EmissiveColor
*/

const vec4 colortex3ClearColor = vec4(0,0,0,0);
const vec4 colortex5ClearColor = vec4(0,0,0,0);

const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = true;
const bool colortex4Clear = false;
const bool colortex5Clear = true;

const float wetnessHalflife = 200;
const float drynessHalflife = 400;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float frameTimeCounter;

#ifdef COLOR_LUT
uniform sampler2D colortex2; // LUT
#endif

#ifdef RAIN_EFFECTS
uniform sampler2D colortex3; // Rain Effects
#endif

#include "/lib/transform.glsl"
#include "/lib/fog_sky.glsl"

uniform int  isEyeInWater;
uniform vec2 playerLMCSmooth;
uniform vec3 fogColor;

uniform float blindness;
uniform float nightVision;
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

uniform sampler2D colortex4;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	#ifdef RAIN_EFFECTS
		float rain  = texture(colortex3, coord).r;
		coord      += sin(vec2(rain * (TWO_PI * 10))) * RAIN_EFFECTS_STRENGTH;
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

		color.r = getAlbedo(coord + vec2(finalNoise,0)).r;
		color.g = getAlbedo(coord - finalNoise).g * (damage * -DAMAGE_EFFECT_REDNESS + 1);
		color.b = getAlbedo(coord + vec2(0,finalNoise)).b * (damage * -DAMAGE_EFFECT_REDNESS + 1);

	} else {
		color = getAlbedo(coord);
	}

	#else
		vec3 color = getAlbedo(coord);
	#endif

	//color = texture(colortex4, coord).rgb;

	if (isEyeInWater == 2) {
		vec3  viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		float fogFac  = fogExp(viewPos, 2);

		color = mix(color, fogColor * 0.75, fogFac);
	} else if (isEyeInWater != 0) {
		vec3  viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		float fogFac  = fogExp(length(viewPos) + 25, FOG_UNDERWATER_DENSITY * exp(playerLMCSmooth.y * -FOG_UNDERWATER_DENSITY_DEPTH_INFLUENCE + FOG_UNDERWATER_DENSITY_DEPTH_INFLUENCE));

		color = mix(color, fogColor * (playerLMCSmooth.y * 0.6 + 0.4), saturate(nightVision * -0.1 + fogFac));
	}

	if (blindness > 1e-10) {
		vec3 viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		color *= saturate(1. / (sqmag(viewPos) * blindness));
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
		color *= roundVignette(coord) * VIGNETTE_STRENGTH + (1 - VIGNETTE_STRENGTH);;
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