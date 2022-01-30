

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

/*
const int colortex0Format = RGB8;  // Color
const int colortex1Format = R8;    // Empty
const int colortex2Format = R8;    // Empty
const int colortex3Format = R8;    // Effects
*/

const vec4 colortex3ClearColor = vec4(0,0,0,0);

const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = true;

const float wetnessHalflife = 200;
const float drynessHalflife = 400;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;


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


vec3 applyBrightness(vec3 color, float brightness, float colorOffset) { // Range: inf-0
	float tmp = (1 / (2 * colorOffset + 1));
	color = color * tmp + (colorOffset * tmp);
	return pow(color, vec3(brightness));
}
vec3 applyContrast(vec3 color, float contrast) { // Range: 0-inf
	color = color * 0.99 + 0.005;
	vec3 colorHigh = 1 - 0.5 * pow(-2 * color + 2, vec3(contrast));
	vec3 colorLow  =     0.5 * pow( 2 * color,     vec3(contrast));
	return saturate(mix(colorLow, colorHigh, color));
}
vec3 applySaturation(vec3 color, float saturation) { // Range: 0-2
    return saturate(mix(vec3(luminance(color)), color, saturation));
}
vec3 applyVibrance(vec3 color, float vibrance) { // -1 to 1
	float luminance  = luminance(color);
	float saturation = distance(vec3(luminance), color);
	return applySaturation(color, (1 - saturation) * vibrance + 1);
}



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
	color = texture2D(luttex, lutCoord).rgb;
	return color;
} */
vec3 applyLUT(sampler2D luttex, vec3 color, float sides) {
	float lutRes   = sides * sides;
	float lutPixel = 0.5 / lutRes;
	vec2  lutCoord = map3d2d(clamp(color, lutPixel, 1 - lutPixel), sides);
	color = texture2D(luttex, lutCoord).rgb;
	return color;
}

float roundVignette(vec2 coord) {
	return saturate(exp(-sq(sqmag(coord * 1.75 - 0.875))));
}
float squareVignette(vec2 coord) {
	return smoothstep( 0.7, 0.25, pow(sq(sq(coord.x - 0.5)) + sq(sq(coord.y - 0.5)), 0.25) );
}

/* DRAWBUFFERS:0 */
void main() {
	
	#ifdef RAIN_EFFECTS
		float rain  = texture2D(colortex3, coord).r;
		coord      += sin(vec2(rain * (TWO_PI * 10))) * RAIN_EFFECTS_STRENGTH;
	#endif

	vec3 color = getAlbedo(coord);

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
	gl_FragData[0] = vec4(color, 1.0);
}