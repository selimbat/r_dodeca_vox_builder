
public class ShaderLinker {
  
  private PShader _shader;
  
  public ShaderLinker(String fragShaderLocation, boolean onlyGeometry){
    _shader = loadShader(fragShaderLocation);
    Init();
    if (!onlyGeometry){
      LinkMaterials();
      LinkDirectionalLight();
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
  
  public void LinkMouseInput(int button, PVector mousePosition){
    _shader.set("mouseButton", button);
    _shader.set("mousePos", mousePosition);
  }
  
  public void LinkVoxels(Grid grid) {
    Iterable<Voxel> voxels = grid.GetVoxels();
    int i = 0;
    for(Voxel vox : voxels) {
      PVector voxPos = grid.GetPositionFromCoords(vox.i, vox.j, vox.k);
      _shader.set("voxels[" + i + "].Position", voxPos.x, voxPos.y, voxPos.z);
      _shader.set("voxels[" + i + "].MaterialIndex", i % 4);
      i++;
    }
    _shader.set("voxelsCount", i);
  }
  
  private void LinkMaterials() {
    _shader.set("materials[0].Albedo", 1.0, 0.0, 0.4);
    _shader.set("materials[0].Ambiant", 0.4);    
    _shader.set("materials[0].Diffuse", 0.2);    
    _shader.set("materials[0].Specular", 0.9);    
    _shader.set("materials[0].Shininess", 16.);    
    _shader.set("materials[1].Albedo", 0.0, 1.0, 0.9);
    _shader.set("materials[1].Ambiant", 0.3);    
    _shader.set("materials[1].Diffuse", 0.2);    
    _shader.set("materials[1].Specular", 0.9);    
    _shader.set("materials[1].Shininess", 16.);    
    _shader.set("materials[2].Albedo", 0.4, 0.8, 0.4);
    _shader.set("materials[2].Ambiant", 0.3);    
    _shader.set("materials[2].Diffuse", 0.2);    
    _shader.set("materials[2].Specular", 0.1);    
    _shader.set("materials[2].Shininess", 16.);    
    _shader.set("materials[3].Albedo", 0.2, 0.5, 1.0);
    _shader.set("materials[3].Ambiant", 0.5);    
    _shader.set("materials[3].Diffuse", 0.8);    
    _shader.set("materials[3].Specular", 0.9);    
    _shader.set("materials[3].Shininess", 32.);    
  }
  
  private void LinkDirectionalLight() {
    _shader.set("directionalLight", -0.5, - sqrt(6.) / 3., - sqrt(3.) / 6.);
  }
}
