shader_type spatial;
render_mode blend_add,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,unshaded;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_depth : hint_black;
uniform float depth_scale;
uniform int depth_min_layers;
uniform int depth_max_layers;
uniform vec2 depth_flip;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}


void fragment() {
	vec2 base_uv = UV;
	{
		vec3 view_dir = normalize(normalize(-VERTEX)*mat3(TANGENT*depth_flip.x,-BINORMAL*depth_flip.y,NORMAL));
		float depth = texture(texture_depth, base_uv).r;
		vec2 ofs = base_uv - view_dir.xy / view_dir.z * (depth * depth_scale);
		base_uv=ofs;
	}
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	
	ALPHA = albedo.a * albedo_tex.a;
}
