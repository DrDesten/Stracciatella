#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"

uniform float frameTimeCounter;

#ifdef DEBUG
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;

vec3 getBufferDebug(vec2 coord) {
	vec4 data;
	switch (DEBUG_BUFFER_INDEX) {
	case 0: data = texture(colortex0, coord); break;
	case 1: data = texture(colortex1, coord); break;
	case 2: data = texture(colortex2, coord); break;
	case 3: data = texture(colortex3, coord); break;
	case 4: data = texture(colortex4, coord); break;
	case 5: data = texture(colortex5, coord); break;
	case 6: data = texture(colortex6, coord); break;
	}
	
	vec3 color;
	switch (DEBUG_BUFFER_CHANNELS) {
	case 0: color = data.xyz; break;
	case 1: color = data.xxx; break;
	case 2: color = data.yyy; break;
	case 3: color = data.zzz; break;
	case 4: color = data.www; break;
	}

	return color;
}

vec3 getDebug(vec2 coord) {
	switch (DEBUG_MODE) {
	case 0: return getBufferDebug(coord);
	case 1: return vec3(0);
	case 2: return vec3(0);
	}
	return vec3(0);
}

#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
#ifdef HQ_UPSCALING
	vec3 color = textureBicubic(colortex0, coord, screenSize * (1./MC_RENDER_QUALITY), screenSizeInverse * MC_RENDER_QUALITY).rgb;
#else
	vec3 color = getAlbedo(coord);
#endif

#ifdef DEBUG
	color = mix(color, getDebug(coord), DEBUG_BLEND);
#endif

	FragOut0 = vec4(color, 1.0);
}

/*
#ifdef HQ_UPSCALING
dummy code (not even code lol)
#endif
*/