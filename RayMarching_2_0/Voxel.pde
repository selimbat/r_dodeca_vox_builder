public class Voxel{
  
  public int i;
  public int j;
  public int k;
  
  public int MaterialIndex;
  
  public Voxel(int i, int j, int k){
    this.i = i;
    this.j = j;
    this.k = k;
    this.MaterialIndex = 0;
  }
  
  public void SetMaterialIndex(int matIndex){
    MaterialIndex = matIndex;
  }
}
