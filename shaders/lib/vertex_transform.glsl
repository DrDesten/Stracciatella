#if ! defined INCLUDE_VERTEX_TRANSFORM_GLSL
#define INCLUDE_VERTEX_TRANSFORM_GLSL
#if ! defined INCLUDE_UNIFORM_vec3_cameraPosition
#define INCLUDE_UNIFORM_vec3_cameraPosition
uniform vec3 cameraPosition; 
#endif

#if ! defined INCLUDE_UNIFORM_mat4_gbufferModelView
#define INCLUDE_UNIFORM_mat4_gbufferModelView
uniform mat4 gbufferModelView; 
#endif

#if ! defined INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
#define INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
uniform mat4 gbufferModelViewInverse; 
#endif

#if ! defined INCLUDE_UNIFORM_mat4_gbufferProjectionInverse
#define INCLUDE_UNIFORM_mat4_gbufferProjectionInverse
uniform mat4 gbufferProjectionInverse; 
#endif
#include "/lib/vertex_transform_simple.glsl"

vec3 toView(vec3 clipPos) {
    return unprojectPerspectiveMAD(clipPos, gbufferProjectionInverse);
}

vec3 toPlayer(vec3 viewPos) {
    return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
}
vec4 toPlayer(vec4 viewPos) {
    return gbufferModelViewInverse * viewPos;
}

#ifndef GEO
vec3 getPlayer() {
    return mat3(gbufferModelViewInverse) * getView() + gbufferModelViewInverse[3].xyz;
}
vec4 getPlayer4() {
    return gbufferModelViewInverse * getView4();
}
#endif

vec3 playerToView(vec3 playerPos) {
    return transformMAD(playerPos, gbufferModelView);
}
vec4 playerToView4(vec3 playerPos) {
    return gbufferModelView * vec4(playerPos, 1.0);
}
vec4 playerToView(vec4 playerPos) {
    return gbufferModelView * playerPos;
}
vec4 playerToClip(vec3 playerPos) {
    return projectHomogeneousMAD(transformMAD(playerPos.xyz, gbufferModelView), gl_ProjectionMatrix);
}
vec4 playerToClip(vec4 playerPos) {
    return projectHomogeneousMAD(transformMAD(playerPos.xyz, gbufferModelView), gl_ProjectionMatrix);
}

#ifndef GEO
vec3 getWorld() {
    return getPlayer() + cameraPosition;
}
#endif

vec3 worldToPlayer(vec3 worldPos) {
    return worldPos - cameraPosition;
}
vec3 worldToView(vec3 worldPos) {
    return playerToView(worldToPlayer(worldPos));
}
vec4 worldToView4(vec3 worldPos) {
    return playerToView4(worldToPlayer(worldPos));
}
vec4 worldToClip(vec3 worldPos) {
    return playerToClip(vec4(worldPos - cameraPosition, 1));
}

#endif