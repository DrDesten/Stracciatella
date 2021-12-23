#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"

/*
const int colortex0Format = RGBA8; // Color Buffer
const int colortex4Format = R8;    // Effects Buffer

const vec4 colortex4ClearColor = vec4(0)
*/


const float sunPathRotation = -15; // [-50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50]

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform sampler2D colortex4; // Effects

#if CLOUDS != 0
uniform sampler2D colortex7; // Clouds
uniform float far;
uniform float frameTimeCounter;
uniform float rainStrength;
#endif


/* DRAWBUFFERS:0 */
void main() {
	float rain = texture2D(colortex4, coord).r;
	coord      = (coord - 0.5) * (rain * 0.2 + 1) + 0.5;

	vec3 color = getAlbedo(coord);

	//color = vec3(rain);

	#if CLOUDS == 1

		vec3  screenPos = vec3(coord, getDepth(coord));
		vec3  viewPos   = toView(screenPos * 2 - 1);
		vec3  playerPos = toPlayer(viewPos);
		vec3  wsDir     = normalize(playerPos);
		float wsDist    = length(playerPos);

		float rayLength = (CLOUD_HEIGHT - cameraPosition.y) / wsDir.y; // Doing a ray-plane intersection

		vec2 cloudCoords = (wsDir.xz * rayLength) + cameraPosition.xz + frameTimeCounter;
		cloudCoords      = fract(cloudCoords * (1. / CLOUD_SIZE));

		if (rayLength > 0. && (wsDist > rayLength || screenPos.z == 1)) {
			vec4  cloudTexture = texture2D(colortex7, cloudCoords);
			float cloudOpacity = cloudTexture.a * smoothstep(-far*7.5, -far, -rayLength) * (1 - rainStrength);
			color.rgb = mix(color.rgb, cloudTexture.rgb, cloudOpacity);
		}

	#elif CLOUDS == 2

		/* vec3  screenPos = vec3(coord, getDepth(coord));
		vec3  viewPos   = toView(screenPos * 2 - 1);
		vec3  playerPos = toPlayer(viewPos);
		vec3  worldPos  = toWorld(playerPos);
		vec3  wsDir     = normalize(playerPos);
		float wsDist    = length(playerPos);

		float rayLength = (CLOUD_HEIGHT - cameraPosition.y) / wsDir.y; // Doing a ray-plane intersection

		vec2 cloudCoords = (wsDir.xz * rayLength) + cameraPosition.xz;// + frameTimeCounter;
		cloudCoords      = fract(cloudCoords * (1. / CLOUD_SIZE));

		if (rayLength > 0. && (wsDist > rayLength || screenPos.z == 1)) {

			vec4  cloudTexture        = texture2D(colortex7, cloudCoords);

			if (cloudTexture.a > 0.5 && false) {

				float cloudOpacity = cloudTexture.a * smoothstep(-far*7.5, -far, -rayLength) * (1 - rainStrength);
				color.rgb = mix(color.rgb, cloudTexture.rgb, cloudOpacity);

			} else {

				vec3  cloudSpaceRayStep = wsDir.xzy * (CLOUD_THICKNESS / wsDir.y) * vec3(vec2(1. / CLOUD_SIZE), 1) * (1. / CLOUD_STEPS);
				float dither = Bayer16(vec2(gl_FragCoord.xy)) - 0.5;
				vec3  cloudSpaceRay     = vec3(cloudCoords, 0) + cloudSpaceRayStep * dither;

				float thickness = 0;
				for (int i = 0; i < CLOUD_STEPS; i++) {
					cloudSpaceRay += cloudSpaceRayStep;

					vec4 ct = texture2D(colortex7, fract(cloudSpaceRay.xy));
					if (ct.a > 0.5) {
						color.rgb  = ct.rgb;
						thickness += (1. / CLOUD_STEPS);
					}
				}

				color.rgb *= 1 - sq(thickness) * 0.1;



			}

			if (cloudTexture.a > 0.5) {

				float cloudOpacity = cloudTexture.a * smoothstep(-far*7.5, -far, -rayLength) * (1 - rainStrength);
				color.rgb = mix(color.rgb, cloudTexture.rgb, cloudOpacity);

			} else {

				vec2 cloudSize          = vec2(textureSize(colortex7, 0));
				vec2 cloudPixelSize     = 1. / cloudSize;
				vec2 cloudPixelCoord    = fract(cloudCoords * cloudSize);
				vec2 cloudPixelEdgeDist = 0.5 - abs(cloudPixelCoord - 0.5);

				float passThroughRayLength = CLOUD_THICKNESS / wsDir.y;
				vec3  passThroughRay       = wsDir * passThroughRayLength;
				
				vec3  passThroughCloudTexelSpace     = vec3(passThroughRay.xz * cloudSize * 0.00025, 1);
				vec3  passThroughCloudTexelSpaceStep = passThroughCloudTexelSpace / 5;

				vec2 ray = cloudCoords;

				for (int i = 0; i < 5; i++) {

					ray += passThroughCloudTexelSpaceStep.xy;

					vec4 cloudTex = texture2D(colortex7, ray);

					if (cloudTex.a > 0.5) {
						color.rgb = cloudTex.rgb;
						break;
					}


				} 

			}
		} */

	#endif

	FD0 = vec4(color, 1.0);
}