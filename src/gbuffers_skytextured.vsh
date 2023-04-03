#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

#ifdef SUN_SIZE_CHANGE
uniform mat4 gbufferModelView;
#endif
uniform vec3 sunPosition;
uniform vec3 moonPosition;

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
    bool orderPos = (abs(viewPos) - abs(sunPosition)).x > 0;
    vertexId = int(orderBody) | (int(orderPos) << 1);
}