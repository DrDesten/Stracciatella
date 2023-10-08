#if ! defined INCLUDE_GBUFFERS_SKYTEXTURED_VSH
#define INCLUDE_GBUFFERS_SKYTEXTURED_VSH

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

#ifdef SUN_SIZE_CHANGE
#if ! defined INCLUDE_UNIFORM_mat4_gbufferModelView
#define INCLUDE_UNIFORM_mat4_gbufferModelView
uniform mat4 gbufferModelView; 
#endif
#endif
#if ! defined INCLUDE_UNIFORM_vec3_sunPosition
#define INCLUDE_UNIFORM_vec3_sunPosition
uniform vec3 sunPosition; 
#endif

#if ! defined INCLUDE_UNIFORM_vec3_moonPosition
#define INCLUDE_UNIFORM_vec3_moonPosition
uniform vec3 moonPosition; 
#endif
#ifdef HORIZON_CLIP
out vec3 viewPos;
#endif
out vec2 textureCoordinate;
out int vertexId;

bool sunOrMoon(vec3 sunPosition, vec3 moonPosition) { // True = Sun, False = Moon
	return sunPosition.z < moonPosition.z;
}
bool sunOrMoonAccurate(vec3 viewPos, vec3 sunPosition, vec3 moonPosition) { // True = Sun, False = Moon
	float dSun = sqmag(sunPosition - viewPos);
	float dMoon = sqmag(moonPosition - viewPos);
	return dSun < dMoon;
}

void main() {
	#ifndef SUN_SIZE_CHANGE
	
		gl_Position = ftransform();
		
		#ifdef HORIZON_CLIP
		viewPos = getView();
		#endif

	#else

		#ifdef HORIZON_CLIP
			viewPos = getView();
		#else
			vec3 viewPos = getView();
		#endif

		bool isSun      = sunOrMoonAccurate(viewPos, sunPosition, moonPosition);

		vec3 sunToVert  = viewPos.xyz - (isSun ? sunPosition : moonPosition);
		viewPos.xyz    += (sunToVert - gbufferModelView[3].xyz) * (SUN_SIZE - 1);
		gl_Position     = viewToClip(vec4(viewPos, 1));

	#endif
    
	textureCoordinate = getCoord();
    
    vec3 viewPos = getView();
    bool orderBody = sunOrMoonAccurate(viewPos, sunPosition, moonPosition);
    bool orderPos = orderBody ? textureCoordinate.y > 0.5 : textureCoordinate.y > 0.25 && textureCoordinate.y < 0.75;
    vertexId = int(orderBody) | (int(orderPos) << 1);
}

#endif