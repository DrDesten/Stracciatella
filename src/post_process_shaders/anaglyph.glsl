#if defined PP_PREPASS

#include "noprepass.glsl"

#endif

#if defined PP_MAIN

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/core/dh/textures.glsl"
#include "/core/dh/transform.glsl"
#include "/lib/utils.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

#if 0

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	float depth     = getDepth(coord);
	vec3  screenPos = vec3(coord, depth);
	vec3  viewPos   = screenToView(screenPos);
	vec3  playerPos = toPlayer(viewPos);

	vec3 playerLeft  = -normalize(gbufferModelViewInverse[0].xyz);
	vec3 playerRight = -playerLeft;

	// 6cm
	const float eyeOffset = (6. / 100.) / 2.;
	
	vec3 leftEyeColor;
	{
		// left eye: looking from point in the negative x direction => player position would be shifted to positive x
		vec3 leftPlayer = playerPos + playerLeft * eyeOffset;
		vec3 leftCoord  = backToScreen(backToView(leftPlayer));

		leftEyeColor = getAlbedo(leftCoord.xy);
	}
	//leftEyeColor = vec3(luminance(leftEyeColor));
	
	vec3 rightEyeColor;
	{
		// right eye: looking from point in the positive x direction => player position would be shifted to negative x
		vec3 rightPlayer = playerPos + playerRight * eyeOffset;
		vec3 rightCoord  = backToScreen(backToView(rightPlayer));

		rightEyeColor = getAlbedo(rightCoord.xy);
	}
	//rightEyeColor = vec3(luminance(rightEyeColor));

	// Color Filters
	vec3 leftEyeFilterColor  = vec3(1.0, 0.0, 0.0);
	vec3 rightEyeFilterColor = vec3(0.0, 1.0, 1.0);

	// Apply Filters and merge colors
	vec3 color = (
		leftEyeColor * leftEyeFilterColor +
		rightEyeColor * rightEyeFilterColor
	);

	FragOut0 = vec4(color, 1);
}

#endif

#if 0

// Raytracing

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	float depth     = getDepth(coord);
	vec3  screenPos = vec3(coord, depth);
	vec3  viewPos   = screenToView(screenPos);
	vec3  viewDir   = normalize(viewPos);
	vec3  playerPos = toPlayer(viewPos);
	vec3  worldPos  = toWorld(playerPos);

	vec3 worldLeft  = -normalize(gbufferModelViewInverse[0].xyz);
	vec3 worldRight = -worldLeft;

	// 6cm
	const float eyeOffset     = (6. / 100.) / 2.;
	const int   traceSteps    = 128;
	const float traceStepSize = 1. / float(traceSteps);
	
	vec3 leftEyeColor;
	
	vec3 lcameraPos     = eyeToView(worldLeft * eyeOffset);
	vec3 ltargetPos     = viewPos * (-32 / viewPos.z);
	vec3 lviewDir       = ltargetPos - lcameraPos;

	vec3 leftScreenStart = backToScreen(lcameraPos);
	vec3 leftScreenDir   = screenPos - leftScreenStart;

	vec3 rayStep = lviewDir * traceStepSize;
	vec3 rayPos  = lcameraPos;
	vec4 hitPos  = vec4(viewPos, 1);
	
	for (int i = 0; i < traceSteps; i++) {

		rayPos += rayStep;

		vec3 screen = backToScreen(rayPos);
		vec3 hit    = screenToView(vec3(screen.xy, getDepth(screen.xy)));

		float closeness = distance(rayPos, hit);

		if (closeness <= hitPos.w) {
			hitPos = vec4(rayPos, closeness);
		}
		if (closeness <= 0.1) {
			break;
		}
	}

	leftEyeColor = getAlbedo(backToScreen(hitPos.xyz).xy);
	
	FragOut0 = vec4(leftScreenDir * .5 + .5, 1);
	FragOut0 = vec4(leftEyeColor, 1);
}

#endif


#if 1

vec3 getEyeView(vec2 coord) {
    // Get Color
	vec3 eyeColor = getAlbedo(coord);

    // Color Corrections
    //eyeColor = applyBrightness(eyeColor, 0.1);
    //eyeColor.r  *= 0.75;
    //eyeColor.gb  = eyeColor.gb * 0.75 + eyeColor.rr * 0.25;
    eyeColor     = applyVibrance(eyeColor, -0.85);
    //eyeColor = applyContrast(eyeColor, 1.5);

    //eyeColor = vec3(luminance(eyeColor));

    // Reduce peak luminance
	float eyeLuma  = luminance(eyeColor);
	eyeColor      *= saturate(0.8 / eyeLuma);

    return eyeColor;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	float depth     = getDepth(coord);
	vec3  screenPos = vec3(coord, depth);
#if !defined DISTANT_HORIZONS
	vec3  viewPos = screenToView(screenPos);
#else
	vec3 viewPos;
	if (depth < 1) {
	   viewPos = screenToView(screenPos);
	} else {
		float dhDepth = getDepthDH(coord);
		viewPos       = toViewDH(vec3(coord, dhDepth));
	}
#endif
	vec3  playerPos = toPlayer(viewPos);

	vec3 playerLeft  = -normalize(gbufferModelViewInverse[0].xyz);
	vec3 playerRight = -playerLeft;

	const float eyeOffset      = (3. / 100.) / 2.;
	const float screenOffset   = 1;
	const float depthClamp     = 1;

	float linearDepth   = -viewPos.z + screenOffset;
	float maxCoordShift = 1 / (screenOffset + depthClamp);
	float coordShift    = min(0, 1 / linearDepth - maxCoordShift);

	// Idea:
	// Binary search to avoid disocclusion artifacts

	vec3 leftEyeColor  = getEyeView(coord - vec2(coordShift * eyeOffset, 0));
	vec3 rightEyeColor = getEyeView(coord + vec2(coordShift * eyeOffset, 0));

	// Color Filters
	vec3 leftEyeFilterColor  = vec3(1.0, 0.0, 0.0);
	vec3 rightEyeFilterColor = vec3(0.0, 1.0, 1.0);

	// Apply Filters and merge colors
	vec3 color = (
		leftEyeColor * leftEyeFilterColor +
		rightEyeColor * rightEyeFilterColor
	);

	FragOut0 = vec4(color, 1);
}

#endif

#endif