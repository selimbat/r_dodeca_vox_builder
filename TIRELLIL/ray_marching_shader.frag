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
// Geometry uniforms
uniform float focalLength;
uniform float screenWidth;
uniform float screenHeight;
uniform float epsilon;
uniform float farPlane;         // not really a plane but for the sake of easier understanding...
uniform float voxelSize;
uniform Voxel voxels[100];
uniform int voxelsCount;
uniform Voxel cursorVoxel;
// Lighting uniforms
uniform vec3 directionalLight;
uniform vec3 secondaryDirectionalLight;
uniform Material materials[10];

const float CONTOUR_WIDTH = 0.05;
const float sqrt2 = 1.4142135623;
const float sqrt3 = 1.7320508075;

// Signed distance function of a rhombic dodecahedron.
// This is a simple version (not exact distance when the closest point is one of the solid vertices)
// It will do for the project's ambition and even saves computation time.
float Sdf(Voxel voxel, vec3 position) {
    position = position - voxel.Position;
    // Exploit the solid's symmetries
    position = vec3(abs(position.x), sign(position.z) * position.y, abs(position.z));

    // distance to each face
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

vec3 PhongIlluminate(Material material, vec3 normal, vec3 viewer, vec3 lightDirection) {
    vec3 lightReflection = 2 * dot(-lightDirection, normal) * normal + lightDirection;
    return vec3(material.Diffuse * max(0, dot(normal, -lightDirection))
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

struct SceneSamplePayLoad{
    float distToScene;
    Voxel closestVoxel;
    bool isCursorClosest;
};

SceneSamplePayLoad GetClosestObject(vec3 marchingPosition, bool considerCursor) {
    SceneSamplePayLoad result;
    result.distToScene = farPlane;
    int voxelIndex = -1;
    if (voxelsCount > 0) {
        for (int i = 0; i < voxelsCount; i++) {
            float distanceToObject = Sdf(voxels[i], marchingPosition);
            if (distanceToObject < result.distToScene) {
                result.distToScene = distanceToObject;
                voxelIndex = i;
            }
        }
        result.closestVoxel = voxels[voxelIndex];
    }
    if (considerCursor){
        float distToCursor = Sdf(cursorVoxel, marchingPosition) - 0.05; // this offset makes the cursor a bit bigger than other voxels
        if (distToCursor < result.distToScene){
            result.distToScene = distToCursor;
            result.closestVoxel = cursorVoxel;
            result.isCursorClosest = true;
        }
    }
    return result;
}

struct RayPayLoad {
    bool hitScene;
    bool hitCursor;
    Voxel hitVoxel;
    vec3 hitPosition;
    vec3 normal;
    float minDistToScene;
    float marchedDistance;
};

RayPayLoad RayMarch(vec3 marchingPosition, vec3 rayDirection, float marchedDistance, bool considerCursor){
    RayPayLoad result;
    result.minDistToScene = farPlane;
    result.marchedDistance = marchedDistance;
    for (int i = 0; i < 100; i++) {
        SceneSamplePayLoad scenePayLoad = GetClosestObject(marchingPosition, considerCursor);
        marchingPosition = marchingPosition + rayDirection * scenePayLoad.distToScene;
        result.marchedDistance = result.marchedDistance + scenePayLoad.distToScene;
        result.minDistToScene = min(result.minDistToScene, scenePayLoad.distToScene);
        if (scenePayLoad.distToScene < epsilon){
            // Found object
            result.hitScene = true;
            result.hitCursor = scenePayLoad.isCursorClosest;
            result.hitVoxel = scenePayLoad.closestVoxel;
            result.hitPosition = marchingPosition;
            result.normal = Normal(scenePayLoad.closestVoxel, marchingPosition);
            break;
        }
        if (result.marchedDistance > farPlane){
            // Went too far
            result.hitScene = false;
            break;
        }
    }
    return result;
}

vec3 SampleScene(vec3 marchingPosition, vec3 rayDirection){
    vec3 color;
    bool hitCursor = false;
    RayPayLoad rayResult = RayMarch(marchingPosition, rayDirection, 0., true);
    if (rayResult.hitScene){
        Material matOfClosestVoxel = materials[rayResult.hitVoxel.MaterialIndex];
        color = AmbiantIlluminate(matOfClosestVoxel);
        bool useShadows = true;
        bool isFirstLightShadowed = false;
        bool isSecondLightShadowed = false;
        if (useShadows){
            RayPayLoad rayToLight = RayMarch(rayResult.hitPosition - 2 * epsilon * directionalLight,    // small offset to avoid shadow acne
                                            -directionalLight,
                                            rayResult.marchedDistance,
                                            false);
            isFirstLightShadowed = rayToLight.hitScene;
            rayToLight = RayMarch(rayResult.hitPosition - 2 * epsilon * secondaryDirectionalLight,    // small offset to avoid shadow acne
                                  -secondaryDirectionalLight,
                                  rayResult.marchedDistance,
                                  false);
            isSecondLightShadowed = rayToLight.hitScene;
        }
        if (!useShadows || !isFirstLightShadowed){
            color += PhongIlluminate(matOfClosestVoxel, rayResult.normal, -rayDirection, directionalLight);
        }
        if (!useShadows || !isSecondLightShadowed){
            color += PhongIlluminate(matOfClosestVoxel, rayResult.normal, -rayDirection, secondaryDirectionalLight);
        }

        if (rayResult.hitCursor){
            // Make the cursor transparent by continuing the ray marching
            hitCursor = true;
            RayPayLoad continueResult = RayMarch(rayResult.hitPosition, rayDirection, rayResult.marchedDistance, false);
            if (continueResult.hitScene){
                Material matOfHitVoxel = materials[continueResult.hitVoxel.MaterialIndex];
                color = mix(color,
                            AmbiantIlluminate(matOfHitVoxel)
                            + PhongIlluminate(matOfHitVoxel, continueResult.normal, -rayDirection, directionalLight)
                            + PhongIlluminate(matOfHitVoxel, continueResult.normal, -rayDirection, secondaryDirectionalLight),
                            0.6);
                return color;
            }
        }else{
            return color;
        }
    }
    vec3 skyBaseColor = mix(vec3(0.8, 0.97, 1.), vec3(0.9, 0.95, 1.), max(0, min(1, -rayDirection.y + 0.5)));
    vec3 skyColor = mix(skyBaseColor,
                        vec3(1.),
                        max(0, pow(dot(rayDirection, -directionalLight), 4.)));
    skyColor = mix(skyColor,
                   mix(skyBaseColor, vec3(1.), 0.5),
                   max(0., pow(dot(rayDirection, -secondaryDirectionalLight), 8.)));
    if (rayResult.minDistToScene < CONTOUR_WIDTH){
        skyColor = mix(vec3(0.), skyColor, rayResult.minDistToScene / CONTOUR_WIDTH);
    }
    if (hitCursor){
        return mix(color, skyColor, 0.6);
    }
    else {
        return skyColor;
    }
}

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(screenWidth, screenHeight);
    vec3 marchingPosition = cameraPosition;
    vec3 rayDirection = RayAt(uv);
    vec3 col = SampleScene(marchingPosition, rayDirection);
    gl_FragColor = vec4(col, 1.0);
}