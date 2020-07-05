public class WorldOrientationArrows {
  private CameraController _camera;
  private final float _arrowLength;
 
  public WorldOrientationArrows(CameraController camera) {
    _camera = camera;
    _arrowLength = 0.07 * height; 
  }
  
  public void DrawWorldArrows(){
    float yaw = _camera.GetYaw();
    // Drawing order matters to keep world depth perception
    if (abs(yaw) < 90) {
      DrawArrow(new PVector(0, 0, 1), new PVector(0, 0, 255), new PVector(0.9 * width, 0.1 * height));
      DrawArrow(new PVector(1, 0, 0), new PVector(255, 0, 0), new PVector(0.9 * width, 0.1 * height));
      DrawArrow(new PVector(0, 1, 0), new PVector(0, 255, 0), new PVector(0.9 * width, 0.1 * height));
    }
    else {
      DrawArrow(new PVector(1, 0, 0), new PVector(255, 0, 0), new PVector(0.9 * width, 0.1 * height));
      DrawArrow(new PVector(0, 1, 0), new PVector(0, 255, 0), new PVector(0.9 * width, 0.1 * height));
      DrawArrow(new PVector(0, 0, 1), new PVector(0, 0, 255), new PVector(0.9 * width, 0.1 * height));
    }
  }
  
  private void DrawArrow(PVector vector, PVector col, PVector screenPosition){
    PMatrix3D rotMat = _camera.GetCopyRotationMatrix();
    rotMat.mult(vector, vector);
    stroke(col.x, col.y, col.z);
    strokeWeight(4);
    line(screenPosition.x, screenPosition.y, screenPosition.x + _arrowLength * vector.x, screenPosition.y - _arrowLength * vector.y);
  }
}
