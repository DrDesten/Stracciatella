#include "/lib/settings.glsl"
#undef SMOOTHCAM

#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

#ifdef SUN_SIZE_CHANGE
uniform mat4 gbufferModelView;
#endif
uniform vec3 sunPosition;
uniform vec3 moonPosition;

out vec2 _coord;

#ifdef HORIZON_CLIP
out vec3 _viewPos;
#endif

#ifdef AURORA
out int vertexId;
#endif

bool sunOrMoon(vec3 sunPosition, vec3 moonPosition) { // True = Sun, False = Moon
	return sunPosition.z < moonPosition.z;
}
bool sunOrMoonAccurate(vec3 viewPos, vec3 sunPosition, vec3 moonPosition) { // True = Sun, False = Moon
	float dSun = sqmag(sunPosition - viewPos);
	float dMoon = sqmag(moonPosition - viewPos);
	return dSun < dMoon;
}

void main() {

#ifdef HORIZON_CLIP
	_viewPos = getView();
#endif

#ifndef SUN_SIZE_CHANGE

	gl_Position = getPosition();

#else

	#ifdef HORIZON_CLIP
	vec3 viewPos = _viewPos;
	#else
	vec3 viewPos = getView();
	#endif

	bool isSun      = sunOrMoonAccurate(viewPos, sunPosition, moonPosition);

	vec3 sunToVert  = viewPos.xyz - (isSun ? sunPosition : moonPosition);
	viewPos.xyz    += (sunToVert - gbufferModelView[3].xyz) * (SUN_SIZE - 1);
	gl_Position     = viewToClip(vec4(viewPos, 1));

#endif
    
	_coord = getCoord();

#ifdef AURORA

    vec3 viewPos = getView();
    bool orderBody = sunOrMoonAccurate(viewPos, sunPosition, moonPosition);
    bool orderPos = orderBody ? _coord.y > 0.5 : _coord.y > 0.25 && _coord.y < 0.75;
    vertexId = int(orderBody) | (int(orderPos) << 1);

#endif
}