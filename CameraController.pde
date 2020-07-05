

public class CameraController {
  public static final float FOCAL_LENGTH = 1.;
  private final float MAX_PITCH = 89.;
  private final float MIN_ZOOM = 4.;
  private final float MAX_ZOOM = 10.;
  private float _pitch;
  private float _yaw;
  private float _pitchSensitivity;
  private float _yawSensitivity;
  private float _zoomSensitivity;
  private PVector _lookAtPosition;
  private float _distFromOrigin;
  private PVector _cameraPosition;
  private PMatrix3D _rotationMatrix;
  
  public CameraController(float hSensitivity, float vSensitivity) {
    _pitch = 0;
    _yaw = 0;
    _pitchSensitivity = vSensitivity;
    _yawSensitivity = hSensitivity;
    _zoomSensitivity = 0.5;
    _lookAtPosition = new PVector(0, 0, 0);
    _distFromOrigin = (MIN_ZOOM + MAX_ZOOM) / 2.;
    _cameraPosition = new PVector(0., 0., -_distFromOrigin);
    _rotationMatrix = new PMatrix3D();
    ComputeRotationMatrix();
    UpdateCameraMovement(0., 0., 0., 0.);
    UpdateCameraPosition(0.);
  }
  
  public void UpdateCameraMovement(float mX, float mY, float pmX, float pmY) {
    _pitch = Math.max(-MAX_PITCH, Math.min(MAX_PITCH, _pitch + _pitchSensitivity * (pmY - mY)));
    _yaw += _yawSensitivity * (pmX - mX);
    _yaw = (_yaw + 540) % 360 - 180;
    ComputeRotationMatrix();  
    UpdateCameraPosition(0.);
  }
  
  public void UpdateCameraPosition(float zoomAmount) {
    _distFromOrigin = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, _distFromOrigin + _zoomSensitivity * zoomAmount));
    PVector forward = new PVector(0., 0., 1.);
    PMatrix3D rotMatCopy = GetCopyRotationMatrix();
    rotMatCopy.transpose();
    rotMatCopy.mult(forward, forward);
    _cameraPosition = PVector.mult(forward, -_distFromOrigin);
  }
  
  public PMatrix3D GetCopyRotationMatrix(){
    return _rotationMatrix.get();
  }
  
  public PVector GetCameraPosition(){
    return PVector.add(_cameraPosition, _lookAtPosition);
  }
  
  public float GetYaw(){
    return _yaw;
  }
  
  private void ComputeRotationMatrix() {
    float yawRad = (float)Math.toRadians(_yaw);
    float pitchRad = (float)Math.toRadians(_pitch);

    _rotationMatrix.m00 = (float)Math.cos(yawRad);
    _rotationMatrix.m01 = 0.;
    _rotationMatrix.m02 = (float)Math.sin(yawRad);
    
    _rotationMatrix.m10 = (float)(Math.sin(pitchRad) * Math.sin(yawRad));
    _rotationMatrix.m11 = (float)Math.cos(pitchRad);
    _rotationMatrix.m12 = (float)(- Math.sin(pitchRad) * Math.cos(yawRad));
    
    _rotationMatrix.m20 = (float)(- Math.cos(pitchRad) * Math.sin(yawRad));
    _rotationMatrix.m21 = (float)Math.sin(pitchRad);
    _rotationMatrix.m22 = (float)(Math.cos(pitchRad) * Math.cos(yawRad));
  }
}
