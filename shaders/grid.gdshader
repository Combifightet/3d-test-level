shader_type spatial;
render_mode unshaded;


// nice tutorial:
// https://techarthub.com/unity-grid-shader/?utm_source=chatgpt.com

// hex to vec3 converter online:
// https://airtightinteractive.com/util/hex-to-glsl/?ref=threejsresources


// grid filtering:
// https://bgolus.medium.com/the-best-darn-grid-shader-yet-727f9278b9d8

// checker filtering:
// https://iquilezles.org/articles/checkerfiltering/


group_uniforms General;
//** Weather the grid should translate and rotate with a given object, or be linked to the global coordinates.*/
uniform bool use_local_pos = true;
uniform float normal_blending : hint_range(0, 1) = 0.8;
uniform bool use_faloff = true;
uniform float falloff_exponent : hint_range(0.0001, 3.0) = 1.;

group_uniforms Grid;
uniform vec3 grid_color : source_color = vec3(0.863,0.863,0.863);
//** Relative size of the grid lines in relation to [grid_size].*/
uniform float line_width : hint_range(0, 1) = 0.02;
uniform float roundness : hint_range(0, 1) = 0.1;
//** Major grid size in meters.*/
uniform float grid_size = 1;

group_uniforms Grid.SubGrid;
uniform float sub_line_width : hint_range(0, 1) = 0.02;
//** Set to 0 if the sub grid is unwanted.*/
uniform float line_count = 9;
uniform float distance_fade : hint_range(0, 1) = 0.5;

group_uniforms Checker;
uniform vec3 checker_color : source_color = vec3(0.302,0.608,0.827);
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

//** returns a checker mask in the range of 0. to 1. with smoothed transitions*/
float smooth_checker(vec2 uv, float smoothness) {
	// TODO: chose a fixed value for the falloff_exponent maybe just `1.` will suffice
	// exponential factor so faloff isn't to rapid
	float factor = pow(E, falloff_exponent*(1./smoothness-1.))-1.;

	float checker = (tanh(factor * sin(PI*uv.x) * sin(PI*uv.y)) + 1.);

	return clamp(checker/2., 0., 1.);
}

void fragment() {
	vec3 unit_cubes = object_pos - floor(object_pos);

	// `dFdx() == `Derivative with respect to x window coordinate
    vec3 dFdx_pos = dFdx(object_pos);
    vec3 dFdy_pos = dFdy(object_pos);
    vec2 local_change = vec2(length(dFdx_pos), length(dFdy_pos));



	// #### COMPUTE GRID PATTERN ####


	vec3 grid_pos = object_pos/grid_size;
	if (grid_size == 0.0) {
		grid_pos = vec3(0);
	}
	grid_pos -= floor(grid_pos);
	grid_pos *= 2.;
	grid_pos -= 1.;
	grid_pos = abs(grid_pos);
	grid_pos -= (1.-line_width) - (1.-line_width)*roundness;

	// in the end subtract (line_width*roundness)

	int grid_xy = (min(0., max(grid_pos.x, grid_pos.y)) + length(max(vec2(0.), grid_pos.xy)) - ((1.-line_width)*roundness)) > 0. ? 1 : 0;
	int grid_xz = (min(0., max(grid_pos.x, grid_pos.z)) + length(max(vec2(0.), grid_pos.xz)) - ((1.-line_width)*roundness)) > 0. ? 1 : 0;
	int grid_yz = (min(0., max(grid_pos.y, grid_pos.z)) + length(max(vec2(0.), grid_pos.yz)) - ((1.-line_width)*roundness)) > 0. ? 1 : 0;



	// #### COMPUTE CHECKER PATTERN ####

	float texture_blending = clamp(length(local_change), 0., 1.);


	vec3 checker_pos = object_pos/checker_size;
	if (checker_size == 0.0) {
		checker_pos = vec3(0);
	}
	int checker_xy = int(floor(checker_pos.x) + floor(checker_pos.y))%2;
	float checker_xz = smooth_checker(checker_pos.xz, use_faloff ? texture_blending : 0.);
	int checker_yz = int(floor(checker_pos.y) + floor(checker_pos.z))%2;
	//int checker = int(round(checker_pos.x) + round(checker_pos.y) + round(checker_pos.z));

	float max_channel = max(checker_color.r, max(checker_color.g, checker_color.b));
	vec3 light_color = checker_color * (1. + (1./max_channel-1.)*contrast);
	vec3 dark_color = checker_color * (1.-contrast);
	vec3 mid_color = (light_color + dark_color) / 2.;
	vec3 checker_colored = light_color*float(checker_xz) + dark_color*float(1.-checker_xz);


	ALBEDO = grid_color*float(grid_xz) + checker_colored*float(1-grid_xz);

	//ALBEDO = dark_color;
	//ALBEDO = checker_color;
	//ALBEDO = light_color;



	//ALBEDO = object_normal;

	//ALBEDO = grid_pos;
	//ALBEDO = vec3(float(grid_xz));

	//float diff = object_pos

	//ALBEDO *= vec3(length(local_change));
	//ALBEDO = vec3(local_change, 0.);

	//ALBEDO = vec3(checker_xz);





	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
	EMISSION = ALBEDO*emission;
}
