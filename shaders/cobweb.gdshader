shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_never;
varying vec3 world_pos;
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float loose=1.0-smoothstep(2.9,3.55,world_pos.y);
    VERTEX.z += loose*0.010*sin(TIME*.65+world_pos.x*1.3+world_pos.y);
}
void fragment() {
    // A slight fill preserves subpixel silk in the dark without brightening the room.
    float variation=0.70+0.30*sin(world_pos.x*17.0+sin(world_pos.y*21.0));
    ALBEDO = vec3(0.43, 0.45, 0.40);
    EMISSION = vec3(0.20, 0.225, 0.21)*variation;
    ROUGHNESS = 0.95;
    ALPHA = 0.72*variation;
}
