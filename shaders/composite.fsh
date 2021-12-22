#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"

const float sunPathRotation = -15; // [-50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50]

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

#if CLOUDS == 1
uniform sampler2D colortex7; // Clouds
uniform float far;
uniform float frameTimeCounter;
uniform float rainStrength;
#endif


/* DRAWBUFFERS:0 */
void main() {
	vec3 color = getAlbedo(coord);

	#if CLOUDS == 1

		vec3  screenPos = vec3(coord, getDepth(coord));
		vec3  viewPos   = toView(screenPos * 2 - 1);
		vec3  playerPos = toPlayer(viewPos);
		vec3  worldPos  = toWorld(playerPos);
		vec3  wsDir     = normalize(playerPos);
		float wsDist    = length(playerPos);

		float rayLength = (CLOUD_HEIGHT - cameraPosition.y) / wsDir.y; // Doing a ray-plane intersection

		vec2 cloudCoords = (wsDir.xz * rayLength) + cameraPosition.xz + frameTimeCounter;
		cloudCoords      = fract(cloudCoords * 0.00025);

		if (rayLength > 0. && (wsDist > rayLength || screenPos.z == 1)) {
			vec4  cloudTexture = texture2D(colortex7, cloudCoords);
			float cloudOpacity = cloudTexture.a * smoothstep(-far*7.5, -far, -rayLength) * (1 - rainStrength);
			color.rgb = mix(color.rgb, cloudTexture.rgb, cloudOpacity);
		}

	#endif

	FD0 = vec4(color, 1.0);
}