shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float seed = 0.0;
void vertex() {
    float tip = max(VERTEX.y,0.0);
    VERTEX.x += sin(TIME*7.0+seed)*tip*0.20;
    VERTEX.z += cos(TIME*9.0+seed)*tip*0.12;
    VERTEX.y *= 1.0+sin(TIME*11.0+seed)*0.12;
}
void fragment() {
    float core = pow(max(0.0,sin(UV.y*3.14159)),0.7);
    ALBEDO = mix(vec3(1.0,0.20,0.015),vec3(1.0,0.85,0.30),core);
    ALPHA = 0.80;
}
