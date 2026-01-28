shader_type spatial;
//render_mode unshaded;

uniform bool use_local_pos = true;

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
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
