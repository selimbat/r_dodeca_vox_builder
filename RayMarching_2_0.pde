import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2ES2;
import java.nio.IntBuffer;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

PJOGL pgl;
GL2ES2 gl;

ShaderLinker mainShader;
ShaderLinker interactionShader;

Grid grid;
PShape screenQuad;
CameraController camera;
WorldOrientationArrows worldOrientation;

float[] positions;
int[] indices;

FloatBuffer posBuffer;
IntBuffer indicesBuffer;

int posVboId;
int indicesVboId;

int posLoc;

void setup(){
  size(800, 450, P3D);
  noStroke();
  screenQuad = buildScreenQuad(width, height);
  
  positions = GetQuadPositions(1, 1);
  posBuffer = ByteBuffer.allocateDirect(positions.length * Float.BYTES).order(ByteOrder.nativeOrder()).asFloatBuffer();
  posBuffer.rewind();
  posBuffer.put(positions);
  posBuffer.rewind();
  
  indices = GetQuadIndices();
  indicesBuffer = ByteBuffer.allocateDirect(indices.length * Integer.BYTES).order(ByteOrder.nativeOrder()).asIntBuffer();
  indicesBuffer.rewind();
  indicesBuffer.put(indices);
  indicesBuffer.rewind();


  grid = new Grid();
  
  mainShader = new ShaderLinker("ray_marching_shader.frag", false);
  
  interactionShader = new ShaderLinker("voxel_interaction_shader.frag", true);
  
  mainShader.LinkVoxels(grid);
  interactionShader.LinkVoxels(grid);
  
  pgl = (PJOGL) beginPGL();  
  gl = pgl.gl.getGL2ES2();

  // Get GL ids for all the buffers
  IntBuffer intBuffer = IntBuffer.allocate(2);  
  gl.glGenBuffers(2, intBuffer);
  posVboId = intBuffer.get(0);
  indicesVboId = intBuffer.get(1);

  interactionShader.GetShader().bind();
  posLoc = gl.glGetAttribLocation(interactionShader.GetShader().glProgram, "position");
  interactionShader.GetShader().unbind();

  endPGL();

  camera = new CameraController(0.5, 0.5);
  mainShader.UpdateCamera(camera);
  interactionShader.UpdateCamera(camera);
  
  worldOrientation = new WorldOrientationArrows(camera);
}

void draw(){
  //background(0);
  if (mousePressed){
    camera.UpdateCameraMovement(mouseX, mouseY, pmouseX, pmouseY);
    mainShader.UpdateCamera(camera);
    interactionShader.UpdateCamera(camera);
  }
  shader(interactionShader.GetShader());
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

float[] GetQuadPositions(int w, int h){
  float[] result = new float[16];
  result[0]  = 0; result[1]  = 0; result[2]  = 0; result[3]  = 0; // Vertex 1
  result[4]  = 0; result[5]  = h; result[6]  = 0; result[7]  = 1; // Vertex 2
  result[8]  = w; result[9]  = h; result[10] = 1; result[11] = 1; // Vertex 3
  result[12] = w; result[13] = 0; result[14] = 1; result[15] = 0; // Vertex 4
  return result;
}

int[] GetQuadIndices(){
  int[] result = new int[6];
  result[0] = 0; result[1] = 1; result[2] = 2; // Triangle 1
  result[3] = 2; result[4] = 1; result[5] = 3; // Triangle 2
  return result;
}

void mousePressed(){
  // Set uniforms
  if (mouseButton == LEFT){
    print("left clic\n");
    interactionShader.LinkMouseInput(1, new PVector(mouseX / width, mouseY / height));
  }
  else if (mouseButton == RIGHT){
    print("right clic\n");
    interactionShader.LinkMouseInput(2, new PVector(mouseX / width, mouseY / height));
  }

  pgl = (PJOGL) beginPGL();  
  gl = pgl.gl.getGL2ES2();
  
  interactionShader.GetShader().bind();
  
  gl.glEnableVertexAttribArray(posLoc);

  // Copy vertex data to VBOs
  gl.glBindBuffer(GL.GL_ARRAY_BUFFER, posVboId);
  gl.glBufferData(GL.GL_ARRAY_BUFFER, Float.BYTES * positions.length, posBuffer, GL.GL_STATIC_DRAW);
  gl.glVertexAttribPointer(posLoc, 4, GL.GL_FLOAT, false, 4 * Float.BYTES, 0);

  gl.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
  gl.glDisableVertexAttribArray(posLoc);

  // Generating the framebuffer
  IntBuffer framebuffer = IntBuffer.allocate(1);
  gl.glGenFramebuffers(1, framebuffer);
  gl.glBindFramebuffer(GL.GL_FRAMEBUFFER, framebuffer.get(0));
  
  // Generating and binding the texture to render to
  IntBuffer renderedTexture = IntBuffer.allocate(1);
  gl.glGenTextures(1, renderedTexture);
  gl.glBindTexture(GL.GL_TEXTURE_2D, renderedTexture.get(0));

  // Give an empty image to OpenGL. The texture is 1x1 texels. One RGBA texel is enough to know wich voxel we need to add or remove. 
  gl.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_RGBA, 1, 1, 0, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, null);
  // Nearest-neighbor interpolation filtering. Useful since we need the exact output on each texel to update the voxel list
  gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
  gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);

  // Set renderedTexture as our colour attachement #0
  gl.glFramebufferTexture2D(GL.GL_FRAMEBUFFER, GL.GL_COLOR_ATTACHMENT0, GL.GL_TEXTURE_2D, renderedTexture.get(0), 0);
  
  // Set the list of draw buffers.
  IntBuffer drawBuffer = IntBuffer.allocate(1);
  drawBuffer.put(GL.GL_COLOR_ATTACHMENT0);
  gl.glDrawBuffers(1, drawBuffer);
  
  int framebufferStatus = gl.glCheckFramebufferStatus(GL.GL_FRAMEBUFFER);
  if(framebufferStatus != GL.GL_FRAMEBUFFER_COMPLETE)
  {
    print("Framebuffer error : " + framebufferStatus);
    return;
  }  
    
  // Render to the framebuffer
  gl.glBindFramebuffer(GL.GL_FRAMEBUFFER, framebuffer.get(0));
  gl.glViewport(0, 0, 1, 1);

  // Draw the triangle elements
  gl.glBindBuffer(PGL.ELEMENT_ARRAY_BUFFER, indicesVboId);
  pgl.bufferData(PGL.ELEMENT_ARRAY_BUFFER, Integer.BYTES * indices.length, indicesBuffer, GL.GL_STATIC_DRAW);
  gl.glDrawElements(PGL.TRIANGLES, 6, GL.GL_UNSIGNED_INT, 0);
  gl.glBindBuffer(PGL.ELEMENT_ARRAY_BUFFER, 0);    

  ByteBuffer outputData = ByteBuffer.allocate(4);
  gl.glReadPixels(0, 0, 1, 1, GL2ES2.GL_RGBA, GL2ES2.GL_UNSIGNED_BYTE, outputData);
  
  interactionShader.GetShader().unbind();
  endPGL();
  
  //--------- DEBUG -----------
  print("Framebuffer status : " + framebufferStatus + "\n");
  byte[] array = outputData.array();
  print("outputData : [" + outputData.get(0) + ", " + outputData.get(1) + ", " + outputData.get(2) + ", " + outputData.get(3) + "]\n");
  print("outputData array : [" + array[0] + ", " + array[1] + ", " + array[2] + ", " + array[3] + "]\n");
  //--------- DEBUG -----------
}

void mouseWheel(MouseEvent event) {
  camera.UpdateCameraPosition(event.getCount());
  mainShader.UpdateCameraZoom(camera);
  interactionShader.UpdateCameraZoom(camera);
}
