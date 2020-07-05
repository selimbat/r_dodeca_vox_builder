#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

struct Material {
    vec3 Albedo;
    float Ambiant;
    float Diffuse;
    float Specular;
    float Shininess;
    //float Reflection;
};

struct Voxel {
    vec3 Position;
    int MaterialIndex;
};

// User input uniforms
uniform mat3 cameraRotation;
uniform vec3 cameraPosition;
uniform bool mouseButtonPressed;
uniform int mouseButton;
uniform vec2 mousePos;
// Geometry uniforms
uniform float focalLength;
uniform float screenWidth;
uniform float screenHeight;
uniform float epsilon;
uniform float farPlane;         // not really a plane but for the sake of easier understanding...
uniform float voxelSize;
uniform Voxel voxels[100];
uniform int voxelsCount;
// Lighting uniforms
uniform vec3 directionalLight;
uniform Material materials[5];

const float sqrt2 = 1.4142135623;
const float sqrt3 = 1.7320508075;

ivec3 WorldSpaceToHexCoords(vec3 worldPosition){
    mat3 toHexCoords = mat3(vec3(1.                , 0.         , 0.         ),
                            vec3(1./(sqrt2 * sqrt3), sqrt2/sqrt3, sqrt3/sqrt2),
                            vec3(1./sqrt3          , 2./sqrt3   , 0.         ));
    toHexCoords /= voxelSize;
    vec3 hexCoordsUnclamped = toHexCoords * worldPosition;
    float w = dot(hexCoordsUnclamped, vec3(-1.));
    ivec3 hexCoordsRounded = ivec3(round(hexCoordsUnclamped));
    int wRounded = -(hexCoordsRounded.x + hexCoordsRounded.y + hexCoordsRounded.z);
    vec4 diff = abs(vec4(hexCoordsUnclamped, w) - vec4(hexCoordsRounded, wRounded));
    if (diff.x > diff.y && diff.x > diff.z && diff.x > diff.w){
        hexCoordsRounded.x = -(hexCoordsRounded.y + hexCoordsRounded.z + wRounded);
    }
    else if (diff.y > diff.z && diff.y > diff.w){
        hexCoordsRounded.y = -(hexCoordsRounded.x + hexCoordsRounded.z + wRounded);
    }
    else if (diff.z > diff.w){
        hexCoordsRounded.z = -(hexCoordsRounded.x + hexCoordsRounded.y + wRounded);
    }
    return hexCoordsRounded;
}

// Signed distance function of a rhombic dodecahedron.
// This is a simple version that will do for the project's ambition and even saves computation time.
float Sdf(Voxel voxel, vec3 position) {
    position = position - voxel.Position;
    position = vec3(abs(position.x), sign(position.z) * position.y, abs(position.z));

    float a = dot(vec3(1.  ,   0.           , 0.          ), position) - voxelSize;
    float b = dot(vec3(0.5 ,   0.           , sqrt3 / 2.  ), position) - voxelSize;
    float c = dot(vec3(0.  , - sqrt2 / sqrt3, 1. / sqrt3  ), position) - voxelSize;
    float d = dot(vec3(0.5 ,   sqrt2 / sqrt3, sqrt3 / 6.  ), position) - voxelSize;
    float e = dot(vec3(0.5 , - sqrt2 / sqrt3, - sqrt3 / 6.), position) - voxelSize;

    return max(a, max(b, max(c, max(d, e))));
}

vec3 Normal(Voxel voxel, vec3 position) {
    vec3 normal = vec3(Sdf(voxel, position + vec3(epsilon, 0.0, 0.0)) - Sdf(voxel, position - vec3(epsilon, 0.0, 0.0)),
                       Sdf(voxel, position + vec3(0.0, epsilon, 0.0)) - Sdf(voxel, position - vec3(0.0, epsilon, 0.0)),
                       Sdf(voxel, position + vec3(0.0, 0.0, epsilon)) - Sdf(voxel, position - vec3(0.0, 0.0, epsilon)));
    return normal / length(normal);
}

vec3 AmbiantIlluminate(Material material) {
    return vec3(material.Albedo * material.Ambiant);
}

vec3 PhongIlluminate(Material material, vec3 normal, vec3 viewer) {
    vec3 lightReflection = 2 * dot(-directionalLight, normal) * normal + directionalLight;
    return vec3(material.Diffuse * max(0, dot(normal, -directionalLight))
                + material.Specular * pow(max(0, dot(viewer, lightReflection)), material.Shininess));
}

vec3 RayAt(vec2 fragCoord) {
    float x = 2 * fragCoord.x - 1.0;
    float y = 2 * fragCoord.y - 1.0;
    if (screenWidth > screenHeight) {
        x *= screenWidth / screenHeight;
    } else if (screenHeight > screenWidth) {
        y *= screenHeight / screenWidth;
    }
    float z = focalLength;
    vec3 ray = cameraRotation * vec3(x, y, z);
    return ray / length(ray);
}

float GetClosestObject(vec3 marchingPosition, inout int voxelIndex) {
    float minDist = farPlane;
    voxelIndex = -1;
    if (voxelsCount > 0) {
        for (int i = 0; i < voxelsCount; i++) {
            float distanceToObject = Sdf(voxels[i], marchingPosition);
            if (distanceToObject < minDist) {
                minDist = distanceToObject;
                voxelIndex = i;
            }
        }
    }
    return minDist;
}

struct RayPayLoad {
    bool hitScene;
    int hitVoxelIndex;
    vec3 normal;
    vec3 position;
    float minDistToScene;
};

RayPayLoad RayMarch(vec3 marchingPosition, vec3 rayDirection, float marchedDistance, int nbReflections){
    RayPayLoad result;
    result.hitVoxelIndex = -1;
    result.minDistToScene = farPlane;
    float distToScene;
    int closestVoxelIndex;
    if (nbReflections > 4){
        return result;
    }
    for (int i = 0; i < 100; i++) {
        distToScene = GetClosestObject(marchingPosition, closestVoxelIndex);
        marchingPosition = marchingPosition + rayDirection * distToScene;
        marchedDistance = marchedDistance + distToScene;
        result.minDistToScene = min(result.minDistToScene, distToScene);
        if (distToScene < epsilon){
            // Found object
            result.hitScene = true;
            result.hitVoxelIndex = closestVoxelIndex;
            result.normal = Normal(voxels[closestVoxelIndex], marchingPosition);
            result.position = marchingPosition;
            break;
        }
        if (marchedDistance > farPlane){
            // Went too far
            result.hitScene = false;
            break;
        }
    }
    return result;
}

vec3 SampleScene(vec3 marchingPosition, vec3 rayDirection){
    RayPayLoad rayResult = RayMarch(marchingPosition, rayDirection, 0., 0);
    if (rayResult.hitScene){
        Material matOfClosestVoxel = materials[voxels[rayResult.hitVoxelIndex].MaterialIndex];
        vec3 objColor = AmbiantIlluminate(matOfClosestVoxel) + PhongIlluminate(matOfClosestVoxel, rayResult.normal, -rayDirection);
        return objColor;
    }
    else{
        float glow = (.2 - min(.2, rayResult.minDistToScene)) / .2;
        return vec3(0.0, glow, glow);
    }
}

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(screenWidth, screenHeight);
    vec3 marchingPosition = cameraPosition;
    
    if (mouseButtonPressed && uv == vec2(0.)){ // we want to do this only once, hence the condition on the UV coordinates
        vec3 mouseRayDirection = RayAt(mousePos);
        RayPayLoad rayResult = RayMarch(marchingPosition, mouseRayDirection, 0., 0);
        if (rayResult.hitScene){
            if (mouseButton == 1){
                // Left clic : adding a voxel
                ivec3 voxelToAddCoords = WorldSpaceToHexCoords(rayResult.position + voxelSize * rayResult.normal);
            }
            else if (mouseButton == 2){
                // Right clic : removing a voxel
                ivec3 voxelToRemoveCoords = WorldSpaceToHexCoords(voxels[rayResult.hitVoxelIndex].Position);
            }
        }
    }
    vec3 rayDirection = RayAt(uv);
    vec3 col = SampleScene(marchingPosition, rayDirection);
    gl_FragColor = vec4(col, 1.0);

/*
    float distToScene;
    float minDistToScene = farPlane;
    int closestVoxelIndex;
    for (int i = 0; i < 100; i++) {
        distToScene = GetClosestObject(marchingPosition, closestVoxelIndex);
        marchingPosition = marchingPosition + rayDirection * distToScene;
        marchedDistance = marchedDistance + distToScene;
        minDistToScene = min(minDistToScene, distToScene);
        if (distToScene < epsilon){
            // Found object
            Material matOfClosestVoxel = materials[voxels[closestVoxelIndex].MaterialIndex];
            vec3 normal = Normal(voxels[closestVoxelIndex], marchingPosition);
            gl_FragColor = vec4(Illuminate(matOfClosestVoxel, normal), 1.0);
            break;
        }
        if (marchedDistance > farPlane){
            // Went too far
            float glow = (.2 - min(.2, minDistToScene)) / .2;
            gl_FragColor = vec4(0.0, glow, glow, 1.0);
            break;
        }
    }*/
}