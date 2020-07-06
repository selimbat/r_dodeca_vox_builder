
public class Grid {
  // Base vectors
  private final PVector I = new PVector(1.  , 0.             , 0.             );
  private final PVector J = new PVector(-0.5, 0.             , sqrt(3.) / 2.  );
  private final PVector K = new PVector(0.  , sqrt(6.) / 3.  , - 1. / sqrt(3.));
  public static final float VOXEL_SIZE = 0.5;
  
  private HashMap<String, Voxel> _voxels;
  private Voxel _cursor;
  private Material[] _materials;
  private int _currentMaterialIndex;
  
  public Grid(){
    _voxels = new HashMap<String, Voxel>();
    AddSampleVoxels();
    CreateMaterials();
    _cursor = new Voxel(1,2,1);
    _currentMaterialIndex = 1;
  }
  
  public void MoveCursor(int di, int dj, int dk){
    _cursor = new Voxel(Math.max(-127, Math.min(_cursor.i + di, 127)),
                        Math.max(-127, Math.min(_cursor.j + dj, 127)),
                        Math.max(-127, Math.min(_cursor.k + dk, 127)));
  }
  
  public void ChangeCurrentMaterial(int newIndex){
    if (newIndex >= 1 && newIndex <= 9){
      _currentMaterialIndex = newIndex;
    }
  }
  
  private void AddSampleVoxels(){
    AddWithMaterial(0, 0, 0, 2);
    AddWithMaterial(1, 0, 0, 3);
    AddWithMaterial(0, 1, 0, 4);
    AddWithMaterial(0, 0, 1, 5);
    AddWithMaterial(-1, 0, 0, 6);
    AddWithMaterial(0, -1, 0, 7);
    AddWithMaterial(0, 0, -1, 8);
    AddWithMaterial(1, 1, 0, 9);
    AddWithMaterial(-1, -1, 0, 8);
    AddWithMaterial(0, -1, -1, 7);
    AddWithMaterial(1, 1, 1, 6);
    AddWithMaterial(-1, -1, -1, 5);
    AddWithMaterial(0, 1, 1, 4);
  }
  
  private void AddWithMaterial(int i, int j, int k, int index){
    _currentMaterialIndex = index;
    Add(i, j, k);
  }
  
  private void CreateMaterials(){
    _materials = new Material[10];
    _materials[0] = new Material(new PVector(0.7, 0.7, 0.7), 1. , 1. , 1. , 2. );    // Exclusively for the cursor voxel
    _materials[1] = new Material(PVector.mult(new PVector(250., 250., 255.), 1. / 255.), 0.8, 0.2, 0.9, 32.);    // white
    _materials[2] = new Material(PVector.mult(new PVector(255., 255., 160.), 1. / 255.), 0.6, 0.5, 0.1, 32.);    // yellow
    _materials[3] = new Material(PVector.mult(new PVector(160., 255., 255.), 1. / 255.), 0.6, 0.6, 0.9, 64.);    // cyan
    _materials[4] = new Material(PVector.mult(new PVector(166., 255., 140.), 1. / 255.), 0.6, 0.2, 0.9, 32.);    // green
    _materials[5] = new Material(PVector.mult(new PVector(255., 180., 128.), 1. / 255.), 0.8, 0.3, 0.9, 32.);    // peach
    _materials[6] = new Material(PVector.mult(new PVector(255., 204., 230.), 1. / 255.), 0.8, 0.2, 0.9, 32.);    // pink
    _materials[7] = new Material(PVector.mult(new PVector(191., 179., 255.), 1. / 255.), 0.7, 0.3, 0.9, 64.);    // lavender
    _materials[8] = new Material(PVector.mult(new PVector(255., 0.  , 110.), 1. / 255.), 0.5, 0.2, 0.9, 32.);    // bordeaux
    _materials[9] = new Material(PVector.mult(new PVector(0.  , 0.  , 0.  ), 1. / 255.), 0.3, 0.2, 0.9, 32.);    // black
  }
  
  public PVector GetPositionFromCoords(int i, int j, int k) {
    return PVector.add(PVector.add(PVector.mult(I, i), PVector.mult(J, j)), PVector.mult(K, k));
  }
  
  public PVector GetPositionFromCoords(Voxel vox){
    return GetPositionFromCoords(vox.i, vox.j, vox.k);
  }
  
  public Iterable<Voxel> GetVoxels() {
    return _voxels.values();
  }
  
  public Material[] GetMaterials() {
    return _materials;
  }
  
  public Voxel GetCursor(){
    return _cursor;
  }
  
  public boolean AddAtCursor(){
    return Add(_cursor.i, _cursor.j, _cursor.k);
  }
  
  public boolean RemoveAtCursor(){
    return Remove(_cursor.i, _cursor.j, _cursor.k);
  }
  
  private boolean Add(int i, int j, int k) {
    String voxelKey = GetVoxelKey(i, j, k);
    if (!_voxels.containsKey(voxelKey)){
      Voxel voxelToAdd = new Voxel(i, j, k);
      voxelToAdd.SetMaterialIndex(_currentMaterialIndex);
      _voxels.put(voxelKey, voxelToAdd);
      return true;
    }
    return false;
  }
  
  private boolean Remove(int i, int j, int k) {
    String voxelKey = GetVoxelKey(i, j, k);
    if (!voxelKey.equals("0:0:0") && _voxels.containsKey(voxelKey)){
      _voxels.remove(voxelKey);
      return true;
    }
    return false;
  }
  
  private String GetVoxelKey(int i, int j, int k) {
    return i + ":" + j + ":" + k;
  }
}
