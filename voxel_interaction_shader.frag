#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

struct Voxel {
    vec3 Position;
    int MaterialIndex;
};

// User input uniforms
uniform mat3 cameraRotation;
uniform vec3 cameraPosition;
uniform uint mouseButton;
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

const uint LEFT_MOUSE_BUTTON = 1u;
const uint RIGHT_MOUSE_BUTTON = 2u;
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
};

RayPayLoad RayMarch(vec3 marchingPosition, vec3 rayDirection, float marchedDistance){
    RayPayLoad result;
    result.hitVoxelIndex = -1;
    float distToScene;
    int closestVoxelIndex;
    for (int i = 0; i < 100; i++) {
        distToScene = GetClosestObject(marchingPosition, closestVoxelIndex);
        marchingPosition = marchingPosition + rayDirection * distToScene;
        marchedDistance = marchedDistance + distToScene;
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

void main() {
    vec4 color;
    vec3 marchingPosition = cameraPosition;
    
    vec3 mouseRayDirection = RayAt(mousePos);
    RayPayLoad rayResult = RayMarch(marchingPosition, mouseRayDirection, 0.);
    if (rayResult.hitScene){
        if (mouseButton == LEFT_MOUSE_BUTTON){
            // Left clic : adding a voxel
            ivec3 voxelToAddCoords = WorldSpaceToHexCoords(rayResult.position + voxelSize * rayResult.normal);
            // We are outputting unisgned bytes so the max range is 255.
            if (abs(voxelToAddCoords.x) > 127 || abs(voxelToAddCoords.y) > 127 || abs(voxelToAddCoords.z) > 127){
                return;
            }
            // Recentering and scaling the coordinates.
            color = vec4(vec3(voxelToAddCoords + ivec3(128)) / 255., 0.5); // alpha channel to 0.5 means adding a voxel
        }
        else if (mouseButton == RIGHT_MOUSE_BUTTON){
            // Right clic : removing a voxel
            ivec3 voxelToRemoveCoords = WorldSpaceToHexCoords(voxels[rayResult.hitVoxelIndex].Position);
            color = vec4(vec3(voxelToRemoveCoords + ivec3(128)) / 255., 1.); // alpha channel to 1.0 means removing a voxel
        }
    }
    else {
        color = vec4(0.);
    }
    color = vec4(100. * mousePos, 0., 1.);

    gl_FragData[0] = color;
}