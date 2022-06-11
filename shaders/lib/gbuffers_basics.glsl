uniform sampler2D texture;  // Color
uniform sampler2D lightmap; // lightmap

vec4 getAlbedo(vec2 coord) {
    return texture2D(texture, coord);
}

vec3 getLightmap(vec2 lmcoord) {
    return texture2D(lightmap, lmcoord).rgb;
}