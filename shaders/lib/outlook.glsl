if (sneaking > 1e-6) {
    vec3 player = toPlayer(toView(gl_Position.xyz / gl_Position.w));
    player.y   -= 10 * (1 - exp(sq(sqmag(vec3(player.x, player.y - 1, player.z))) * -0.004)) * sneaking;
    gl_Position = playerToClip(player);
}