class Material{
  public PVector Albedo;
  public float Ambiant;
  public float Diffuse;
  public float Specular;
  public float Shininess;

  public Material(PVector albedo, float ambiant, float diffuse, float specular, float shininess){
    Albedo = albedo;
    Ambiant = ambiant;
    Diffuse = diffuse;
    Specular = specular;
    Shininess = shininess;
  }
}
