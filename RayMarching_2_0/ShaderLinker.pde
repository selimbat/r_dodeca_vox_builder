
public class ShaderLinker {
  
  private PShader _shader;
  
  public ShaderLinker(String fragShaderLocation, boolean onlyGeometry){
    _shader = loadShader(fragShaderLocation);
    Init();
    if (!onlyGeometry){
      LinkDirectionalLight();
      LinkSecondaryDirectionalLight();      
    }
  }
  
  public PShader GetShader(){
    return _shader;
  }
  
  private void Init() {
    _shader.set("focalLength", CameraController.FOCAL_LENGTH);
    _shader.set("screenWidth", float(width));
    _shader.set("screenHeight", float(height));
    _shader.set("epsilon", 0.005);
    _shader.set("farPlane", 100.0);
    _shader.set("voxelSize", Grid.VOXEL_SIZE);
  }  
  
  public void UpdateCamera(CameraController camera){
    LinkRotationMatrix(camera.GetCopyRotationMatrix());
    LinkCameraPosition(camera.GetCameraPosition());
  }
  
  public void UpdateCameraZoom(CameraController camera){
    LinkCameraPosition(camera.GetCameraPosition());
  }
  
  private void LinkRotationMatrix(PMatrix3D mat){
    _shader.set("cameraRotation", mat, true);
  }
  
  private void LinkCameraPosition(PVector cameraPosition){
    _shader.set("cameraPosition", cameraPosition);
  }
    
  public void LinkVoxels(Grid grid) {
    Iterable<Voxel> voxels = grid.GetVoxels();
    int i = 0;
    for(Voxel vox : voxels) {
      PVector voxPos = grid.GetPositionFromCoords(vox.i, vox.j, vox.k);
      _shader.set("voxels[" + i + "].Position", voxPos.x, voxPos.y, voxPos.z);
      _shader.set("voxels[" + i + "].MaterialIndex", vox.MaterialIndex);
      i++;
    }
    _shader.set("voxelsCount", i);
  }
  
  public void LinkCursor(Voxel cursor){
    PVector voxPos = grid.GetPositionFromCoords(cursor.i, cursor.j, cursor.k);
    _shader.set("cursorVoxel.Position", voxPos.x, voxPos.y, voxPos.z);
    _shader.set("cursorVoxel.MaterialIndex", 0);
  }
  
  public void LinkMaterials(Grid grid){
    Material[] materials = grid.GetMaterials();
    int i = 0;
    for(Material material : materials){
      _shader.set("materials[" + i + "].Albedo", material.Albedo);
      _shader.set("materials[" + i + "].Ambiant", material.Ambiant);    
      _shader.set("materials[" + i + "].Diffuse", material.Diffuse);    
      _shader.set("materials[" + i + "].Specular", material.Specular);    
      _shader.set("materials[" + i + "].Shininess", material.Shininess);    
      i++;
    }
  }
    
  private void LinkDirectionalLight() {
    PVector directionalLight = new PVector(-0.5, - 0.8, - 0.1);
    directionalLight.normalize();
    _shader.set("directionalLight", directionalLight.x, directionalLight.y, directionalLight.z);
  }
  
  private void LinkSecondaryDirectionalLight() {
    PVector directionalLight = new PVector(0.5, 0.8, 0.5);
    directionalLight.normalize();
    _shader.set("secondaryDirectionalLight", directionalLight.x, directionalLight.y, directionalLight.z);
  }
}
