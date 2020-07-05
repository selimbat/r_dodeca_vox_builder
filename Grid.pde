
public class Grid {
  // Base vectors
  private final PVector I = new PVector(1.  , 0.             , 0.             );
  private final PVector J = new PVector(-0.5, 0.             , sqrt(3.) / 2.  );
  private final PVector K = new PVector(0.  , sqrt(6.) / 3.  , - 1. / sqrt(3.));
  private final PVector L = new PVector(-0.5, - sqrt(6.) / 3., - sqrt(3.) / 6.); //  = -(I + J + K); Useful for some algorithms
  public static final float VOXEL_SIZE = 0.5;
  
  private HashMap<String, Voxel> _voxels;
  
  public Grid(){
    _voxels = new HashMap<String, Voxel>();
    AddSampleVoxels();
  }
  
  public void AddSampleVoxels(){
    Add(0, 0, 0);
    Add(1, 0, 0);
    Add(0, 1, 0);
    Add(0, 0, 1);
  }
  
  public PVector GetPositionFromCoords(int i, int j, int k) {
    return PVector.add(PVector.add(PVector.mult(I, i), PVector.mult(J, j)), PVector.mult(K, k));
  }
  
  public Iterable<Voxel> GetVoxels() {
    return _voxels.values();
  }
  
  public boolean Add(int i, int j, int k) {
    String voxelKey = GetVoxelKey(i, j, k);
    if (!_voxels.containsKey(voxelKey)){
      _voxels.put(voxelKey, new Voxel(i, j, k));
      return true;
    }
    return false;
  }
  
  public void Remove(int i, int j, int k) {
    String voxelKey = GetVoxelKey(i, j, k);
    if (voxelKey != "0:0:0"){
      _voxels.remove(voxelKey);
    }
  }
  
  private String GetVoxelKey(int i, int j, int k) {
    return i + ":" + j + ":" + k;
  }
}
