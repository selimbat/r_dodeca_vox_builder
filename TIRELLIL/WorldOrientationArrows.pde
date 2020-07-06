public class WorldOrientationArrows {
  private CameraController _camera;
  private final float _arrowLength;
  private final PVector _arrowsPosition;
 
  public WorldOrientationArrows(CameraController camera) {
    _camera = camera;
    _arrowLength = 0.07 * height; 
    _arrowsPosition = new PVector(0.93 * width, 0.1 * height);
  }
  
  public void DrawWorldArrows(){
    float yaw = _camera.GetYaw();
    float pitch = _camera.GetPitch();
    // Drawing order matters to keep world depth perception
    if (abs(yaw) < 90) {
      if (pitch > 0.){
        DrawArrow(new PVector(0, 1, 0), new PVector(0, 255, 0), _arrowsPosition);
      }
      DrawArrow(new PVector(0, 0, 1), new PVector(0, 0, 255), _arrowsPosition);
      DrawArrow(new PVector(1, 0, 0), new PVector(255, 0, 0), _arrowsPosition);
      if (pitch <= 0.){
        DrawArrow(new PVector(0, 1, 0), new PVector(0, 255, 0), _arrowsPosition);
      }
    }
    else {
      if (pitch > 0.){
        DrawArrow(new PVector(0, 1, 0), new PVector(0, 255, 0), _arrowsPosition);
      }
      DrawArrow(new PVector(1, 0, 0), new PVector(255, 0, 0), _arrowsPosition);
      if (pitch <= 0.){
        DrawArrow(new PVector(0, 1, 0), new PVector(0, 255, 0), _arrowsPosition);
      }
      DrawArrow(new PVector(0, 0, 1), new PVector(0, 0, 255), _arrowsPosition);
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
