#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

#if CLOUDS != 0
#include "/lib/transform.glsl"
uniform sampler2D colortex4; // Clouds
uniform float frameTimeCounter;
uniform float far;
uniform float rainStrength;
#endif

/* DRAWBUFFERS:0 */
void main() {
	vec3 color = getAlbedo(coord);

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
			vec4  cloudTexture = texture2D(colortex4, cloudCoords);
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

			vec4  cloudTexture        = texture2D(colortex4, cloudCoords);

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

					vec4 ct = texture2D(colortex4, fract(cloudSpaceRay.xy));
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

				vec2 cloudSize          = vec2(textureSize(colortex4, 0));
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

					vec4 cloudTex = texture2D(colortex4, ray);

					if (cloudTex.a > 0.5) {
						color.rgb = cloudTex.rgb;
						break;
					}


				} 

			}
		} */

	#endif

	FD0 = vec4(color, 1.0); //gcolor
}