shader_type spatial;
render_mode blend_add,cull_disabled,depth_draw_opaque,diffuse_burley,specular_schlick_ggx,unshaded;
uniform vec4 albedo : hint_color;

void fragment() {
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a * pow(UV.y, 3);
}
