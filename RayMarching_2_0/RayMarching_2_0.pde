ShaderLinker mainShader;

Grid grid;
PShape screenQuad;
CameraController camera;
WorldOrientationArrows worldOrientation;

void setup(){
  size(1200, 675, P3D);
  noStroke();
  screenQuad = buildScreenQuad(width, height);
  
  grid = new Grid();
  
  mainShader = new ShaderLinker("ray_marching_shader.frag", false);
    
  mainShader.LinkVoxels(grid);
  mainShader.LinkCursor(grid.GetCursor());
  mainShader.LinkMaterials(grid);
  
  camera = new CameraController(0.5, 0.5);
  mainShader.UpdateCamera(camera);
  
  worldOrientation = new WorldOrientationArrows(camera);
}

void draw(){
  if (mousePressed){
    camera.UpdateCameraMovement(mouseX, mouseY, pmouseX, pmouseY);
    mainShader.UpdateCamera(camera);
  }
  shader(mainShader.GetShader());
  shape(screenQuad);
  
  worldOrientation.DrawWorldArrows();
}

PShape buildScreenQuad(int w, int h){
  textureMode(NORMAL);
  PShape quad = createShape();
  quad.beginShape(QUADS);
  quad.noStroke();
  quad.vertex(0, 0, 0, 0);
  quad.vertex(0, h, 0, 1);
  quad.vertex(w, h, 1, 1);
  quad.vertex(w, 0, 1, 0);
  quad.endShape();
  return quad;
}

void mouseWheel(MouseEvent event) {
  camera.UpdateCameraPosition(event.getCount());
  mainShader.UpdateCameraZoom(camera);
}

void keyPressed(){
  if (key == '&' || key == '1'){
    grid.ChangeCurrentMaterial(1);
  }
  else if (key == 'é' || key == '2'){
    grid.ChangeCurrentMaterial(2);
  }
  else if (key == '"' || key == '3'){
    grid.ChangeCurrentMaterial(3);
  }
  else if (key == '\'' || key == '4'){
    grid.ChangeCurrentMaterial(4);
  }
  else if (key == '(' || key == '5'){
    grid.ChangeCurrentMaterial(5);
  }
  else if (key == '-' || key == '6'){
    grid.ChangeCurrentMaterial(6);
  }
  else if (key == 'è' || key == '7'){
    grid.ChangeCurrentMaterial(7);
  }
  else if (key == '_' || key == '8'){
    grid.ChangeCurrentMaterial(8);
  }
  else if (key == 'ç' || key == '9'){
    grid.ChangeCurrentMaterial(9);
  }
  
  boolean voxelsChanged = false;
  if (key == CODED){
    if (keyCode == UP){
      grid.MoveCursor(0, 1, 0);
    }
    else if (keyCode == DOWN){
      grid.MoveCursor(0, -1, 0);
    }
    else if (keyCode == RIGHT){
      grid.MoveCursor(1, 0, 0);
    }
    else if (keyCode == LEFT){
      grid.MoveCursor(-1, 0, 0);
    }
    else if (keyCode == SHIFT){
      grid.MoveCursor(0, 0, 1);
    }
    else if (keyCode == CONTROL){
      grid.MoveCursor(0, 0, -1);
    }
    mainShader.LinkCursor(grid.GetCursor());
  }
  else if (key == 'C' || key == 'c'){
    // Add a voxel
    voxelsChanged = grid.AddAtCursor();
  }
  else if (key == 'V' || key == 'v'){
    voxelsChanged = grid.RemoveAtCursor();
  }
  if (voxelsChanged){
    mainShader.LinkVoxels(grid);
  }
  camera.UpdateLookAtPosition(grid);
  mainShader.UpdateCamera(camera);
}
