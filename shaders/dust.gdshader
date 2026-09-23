shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
void vertex() {
    // Face the camera while retaining the individual CPU particle's size.
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
        vec4(INV_VIEW_MATRIX[0].xyz * length(MODEL_MATRIX[0].xyz), 0.0),
        vec4(INV_VIEW_MATRIX[1].xyz * length(MODEL_MATRIX[1].xyz), 0.0),
        vec4(INV_VIEW_MATRIX[2].xyz * length(MODEL_MATRIX[2].xyz), 0.0),
        MODEL_MATRIX[3]);
}
void fragment() {
    float soft = 1.0-smoothstep(0.05,0.48,length(UV-vec2(0.5)));
    ALBEDO = vec3(0.85,0.83,0.70)*COLOR.rgb;
    ALPHA = soft*COLOR.a*0.70;
}
