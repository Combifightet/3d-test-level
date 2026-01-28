shader_type spatial;
//render_mode unshaded;


// nice tutorial:
// https://techarthub.com/unity-grid-shader/?utm_source=chatgpt.com

// hex to vec3 converter online:
// https://airtightinteractive.com/util/hex-to-glsl/?ref=threejsresources


group_uniforms General;
//** Weather the grid should translate and rotate with a given object, or be linked to the global coordinates.*/
uniform bool use_local_pos = true;
uniform float normal_blending : hint_range(0, 1) = 0.8;

group_uniforms Grid;
uniform vec3 grid_color : source_color = vec3(0.863,0.863,0.863);
//** Relative size of the grid lines in relation to [grid_size].*/
uniform float line_width : hint_range(0, 1) = 0.02;
//** Major grid size in meters.*/
uniform float grid_size = 1;

group_uniforms Grid.SubGrid;
uniform float sub_line_width : hint_range(0, 1) = 0.02;
//** Set to 0 if the sub grid is unwanted.*/
uniform float line_count = 9;
uniform float distance_fade : hint_range(0, 1) = 0.5;

group_uniforms Checker;
uniform vec3 checker_color : source_color = vec3(0.302,0.435,0.443);
//** Major checker size in meters.*/
uniform float checker_size = 1;
//* How big the contrast between the checker tiles is*/
uniform float contrast : hint_range(0, 1) = 0.2;

group_uniforms Material;
uniform float roughness : hint_range(0, 1) = 1;
uniform float metallic : hint_range(0, 1) = 0;
uniform float specular : hint_range(0, 10) = 0.5;
//* emission strength based on the albedo color*/
uniform float emission = 0;



varying vec3 object_pos;
varying vec3 object_normal;


void vertex() {
	vec3 global_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	mat3 rotation = mat3(MODEL_MATRIX);
	mat3 inv_rotation = transpose(rotation);
	
	vec3 local_pos = inv_rotation * (global_pos - NODE_POSITION_WORLD);
	
	if (use_local_pos) {
		object_pos = local_pos;
		object_normal = NORMAL;
	} else {
		object_pos = global_pos;
		object_normal = inv_rotation * NORMAL;
	}
	
	
}

void fragment() {
	vec3 unit_cubes = object_pos - floor(object_pos);
	ALBEDO = unit_cubes.xzy;
	
	//ALBEDO = vec3(float((int(object_pos.x)+int(object_pos.y)+int(object_pos.z))%2));
	int grid_xy = int(floor(object_pos.x) + floor(object_pos.y));
	int grid_xz = int(floor(object_pos.x) + floor(object_pos.z));
	int grid_yz = int(floor(object_pos.y) + floor(object_pos.z));
	//int grid = int(round(object_pos.x) + round(object_pos.y) + round(object_pos.z));
	//ALBEDO = vec3(float(grid));
	ALBEDO = vec3(float(grid_xz%2));
	
	//ALBEDO = object_normal;



	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
	EMISSION = ALBEDO*emission;
}
