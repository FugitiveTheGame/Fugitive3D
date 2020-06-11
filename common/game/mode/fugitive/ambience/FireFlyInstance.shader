shader_type spatial;
render_mode blend_add,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,unshaded;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float alpha_override : hint_range(0, 1) = 1.0;

const float PI = 3.14159265358979323846;
const float HALF_PI = PI / 2.0;
const float FREQUENCY = 0.5;


void vertex() {
	// Billboard
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);
}


void fragment() {
	vec4 albedo_tex = texture(texture_albedo,UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	ALPHA = (albedo.a * albedo_tex.a * (1.0+sin((2.0 * PI * FREQUENCY * TIME)-HALF_PI))) * alpha_override;
}
