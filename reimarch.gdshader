shader_type canvas_item;
uniform float fov = 45.0;
uniform vec3 cameraPos = vec3(0.0,0.0,5.0);
uniform vec3 front = vec3(0.0,0.0,-1.0);
uniform vec3 up = vec3(0.0,1.0,0.0);
//Ray march uniforms
uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 20.0;
uniform float MIN_HIT_DIST = 0.00001;
//END
//Lighting Uniforms
uniform float globalAmbient = 0.01; // strength of th global ambience
uniform float globalDiffuse = 1.0; // strength of th global diffuse
uniform float globalSpecular = 0.20; // strength of th global specular
uniform float globalSpecularExponent = 64.0; //focus of specular light
uniform vec3 lightPos = vec3(-2.0,5.0,3.0); // self explanitory
uniform vec3 lightColor = vec3(0.9,0.9,0.68); // same as above comment
uniform vec3 ambientColor = vec3(1.0); // again!!! (sigh) 
uniform float DERIVATIVE_STEP = 1.0;
//END
//SDFs
float sdSphere(vec3 p, vec3 c, float r){
	return length(p - c) - r;
}
float sdf(vec3 pos){
	return sdSphere(pos, vec3(0), 1.0);
}
//END
	// Lighting
	vec3 estimateNormal(vec3 p){
		return normalize(vec3(
        sdf(vec3(p.x + DERIVATIVE_STEP, p.y, p.z)) - sdf(vec3(p.x - DERIVATIVE_STEP, p.y, p.z)),
        sdf(vec3(p.x, p.y + DERIVATIVE_STEP, p.z)) - sdf(vec3(p.x, p.y - DERIVATIVE_STEP, p.z)),
        sdf(vec3(p.x, p.y, p.z  + DERIVATIVE_STEP)) - sdf(vec3(p.x, p.y, p.z - DERIVATIVE_STEP))
    ));
	}
	vec3 phongModel(vec3 position, // hit point
                vec3 lightPosition, // position of the light source
                vec3 ambientCol, // ambient color
                vec3 lightCol, // light source color
                float ambientCoeff, // scale ambient contribution
                float diffuseCoeff, // scale diffuse contribution
                float specularCoeff, // scale specular contribution
                float specularExponent // how focused should the shiny spot be
)
{
    vec3 normal = estimateNormal(position);
    vec3 toEye = normalize(cameraPos - position);
    vec3 toLight = normalize(lightPosition - position);
    vec3 reflection = reflect(-toLight, normal);
     
    vec3 ambientFactor = ambientCol * ambientCoeff;
    vec3 diffuseFactor = diffuseCoeff * lightCol * max(0.0, dot(normal, toLight));
    vec3 specularFactor = lightCol * pow(max(0.0, dot(toEye, reflection)), specularExponent)
                     * specularCoeff;
     
    return ambientFactor + diffuseFactor + specularFactor;
}
//END

vec3 rayMarch(vec3 rayDir){
	vec3 hit_color = vec3(1.0); //white
	vec3 miss_color = vec3(0.0); // black
	float depth = 0.0;
	for(int i = 0; depth < MAX_DIST && i < MAX_STEPS; ++i){
		vec3 pos = cameraPos + rayDir * depth;
		float dist = sdf(pos);
		if(dist < MIN_HIT_DIST){
			return phongModel(pos, lightPos, ambientColor, lightColor,
           globalAmbient, globalDiffuse, globalSpecular, globalSpecularExponent);
		}
		depth += dist;	
	}
	return miss_color;
}
vec3 getRayDir(vec2 resolution, vec2 uv){
		float fov2 = radians(fov) / 2.0;
		float aspect = resolution.x / resolution.y;
		//--------------------------------------
		// covert coord from [0,1] to [-1,1]
		vec2 screenCoord = (uv - 0.5) * 2.0;
		screenCoord.x *= aspect;
		screenCoord.y *= -1.0;
		//viewport offsets
		vec2 offsets = screenCoord * tan(fov2);
		//compute 3 orthogonal vectures
		vec3 rayFront = normalize(front);
		vec3 rayRight = normalize(cross(front , normalize(up)));
		vec3 rayUp = cross(rayRight, rayFront);
		vec3 rayDir = rayFront + rayRight * offsets.x + rayUp * offsets.y;
		return normalize(rayDir);
	}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec3 rayDir = getRayDir(resolution, UV);
	//comvert ray coordinates from [-1,1] to [0,1]
	vec3 adjustedDir = (rayDir + 1.0) / 2.0;
	//show direction on screen as a color
	COLOR = vec4(rayMarch(rayDir), 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
