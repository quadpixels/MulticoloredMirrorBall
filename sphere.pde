class WildWolfLightBulb {
  public float coorX[], coorY[], coorZ[], multXZ[]; 
  public int sphereColors[]; // RGB
  public int numPointsW, numPointsH_2pi, numPointsH, ptsW, ptsH;
  
  public PVector pos;
  public float rot = 0.0f;
  public int color_offset = 0, color_offset_inhibit = 0;
  
  public WildWolfLightBulb(int numPtsW, int numPtsH_2pi) {
    pos = new PVector(0, 150, -200);
    // The number of points around the width and height
    numPointsW=numPtsW+1;
    numPointsH_2pi=numPtsH_2pi;  // How many actual pts around the sphere (not just from top to bottom)
    numPointsH=ceil((float)numPointsH_2pi/2)+1;  // How many pts from top to bottom (abs(....) b/c of the possibility of an odd numPointsH_2pi)
  
    coorX = new float[numPointsW];   // All the x-coor in a horizontal circle radius 1
    coorY = new float[numPointsH];   // All the y-coor in a vertical circle radius 1
    coorZ = new float[numPointsW];   // All the z-coor in a horizontal circle radius 1
    multXZ = new float[numPointsH];  // The radius of each horizontal circle (that you will multiply with coorX and coorZ)
    sphereColors = new int[3 * numPointsW * numPointsH];
  
    for (int i=0; i<numPointsW; i++) {  // For all the points around the width
      float thetaW=i*2*PI/(numPointsW-1);
      coorX[i]=sin(thetaW);
      coorZ[i]=cos(thetaW);
    }
  
    for (int i=0; i<numPointsH; i++) {  // For all points from top to bottom
      if (int(numPointsH_2pi/2) != (float)numPointsH_2pi/2 && i==numPointsH-1) {  // If the numPointsH_2pi is odd and it is at the last pt
        float thetaH=(i-1)*2*PI/(numPointsH_2pi);
        coorY[i]=cos(PI+thetaH); 
        multXZ[i]=0;
      } else {
        //The numPointsH_2pi and 2 below allows there to be a flat bottom if the numPointsH is odd
        float thetaH=i*2*PI/(numPointsH_2pi);
  
        //PI+ below makes the top always the point instead of the bottom.
        coorY[i]=cos(PI+thetaH); 
        multXZ[i]=sin(thetaH);
      }
    }
    
    // Assign random colors
    for (int i=0; i<numPointsW * numPointsH * 3; i++) {
      sphereColors[i] = int(random(16, 240));
    }
  }
  
  
  // 0x1: 本体
  // 0x2: 光线
  void render(float rx, float ry, float rz, PImage t, PGraphics rendertarget, int mode) {
    
    // These are so we can map certain parts of the image on to the shape 
    float changeU = 0;//t.width/(float)(numPointsW-1); 
    float changeV = 0;//t.height/(float)(numPointsH-1); 
    float u=0;  // Width variable for the texture
    float v=0;  // Height variable for the texture
  
    //noStroke();
    rendertarget.beginDraw();
    
    rendertarget.pushMatrix();
    rendertarget.texture(null);
    rendertarget.translate(rendertarget.width/2,
                           rendertarget.height/2 - pos.y, pos.z + cos(this.rot * 10) * 10);
    rendertarget.rotateY(this.rot);
    rendertarget.stroke(32);
    //rendertarget.noStroke();
    
    if ((mode & 1) == 1) {
      // 本体
      rendertarget.beginShape(QUADS);
      rendertarget.background(0, 0, 0, 0);
      //texture(t);
      for (int i=0; i<(numPointsH-1); i++) {  // For all the rings but top and bottom
        // Goes into the array here instead of loop to save time
        float coory=coorY[i];
        float cooryPlus=coorY[i+1];
    
        float multxz=multXZ[i];
        float multxzPlus=multXZ[i+1];
    
        for (int j=0; j<numPointsW - 1; j++) { // For all the pts in the ring

          int N = numPointsW * numPointsH;
          if (N == 0) N = 1000000007;
          int colorIdx = ((i * numPointsW + j) + color_offset) % N * 3,
              r = sphereColors[colorIdx  ],
              g = sphereColors[colorIdx+1],
              b = sphereColors[colorIdx+2];
        
          float x0 = coorX[j]   * multxz     * rx, x1 = coorX[j]   * multxzPlus * rx,
                x2 = coorX[j+1] * multxzPlus * rx, x3 = coorX[j+1] * multxz     * rx;
          float y0 = coory*ry, y1 = cooryPlus*ry;
          float z0 = coorZ[j]   * multxz     * rz, z1 = coorZ[j]   * multxzPlus * rz,
                z2 = coorZ[j+1] * multxzPlus * rz, z3 = coorZ[j+1] * multxz     * rz;
                
          float nx0 = -coorX[j]*multxz,     ny0 = -coory,     nz0 = -coorZ[j]*multxz,
                nx1 = -coorX[j]*multxzPlus, ny1 = -cooryPlus, nz1 = -coorZ[j]*multxzPlus;
        
          rendertarget.fill(r, g, b);
          rendertarget.normal(nx0, ny0, nz0);
          rendertarget.vertex(x0, y0, z0, u, v);
          rendertarget.fill(r, g, b);
          rendertarget.normal(nx1, ny1, nz1);
          rendertarget.vertex(x1, y1, z1, u, v+changeV);
          
          rendertarget.fill(r, g, b);
          rendertarget.normal(-coorX[j+1]*multxzPlus, -cooryPlus, -coorZ[j+1]*multxzPlus);
          rendertarget.vertex(x2, y1, z2, u, v+changeV);
          rendertarget.fill(r, g, b);
          rendertarget.normal(-coorX[j+1]*multxz, -coory, -coorZ[j+1]*multxz);
          rendertarget.vertex(x3, y0, z3, u, v);
          
          u+=changeU;
        }
        v+=changeV;
        u=0;
      }
      rendertarget.endShape();
    }
    
    if ((mode & 2) == 2)
    {
      rendertarget.beginShape(LINES);
      rendertarget.strokeWeight(5);
      for (int i=0; i<(numPointsH-1); i++) {  // For all the rings but top and bottom
        // Goes into the array here instead of loop to save time
        float coory=coorY[i];
        float cooryPlus=coorY[i+1];
    
        float multxz=multXZ[i];
        float multxzPlus=multXZ[i+1];
    
        for (int j=0; j<numPointsW - 1; j++) { // For all the pts in the ring
          int N = numPointsW * numPointsH;
          if (N == 0) N = 1000000007;
          int colorIdx = ((i * numPointsW + j) + color_offset) % N * 3,
              r = sphereColors[colorIdx  ],
              g = sphereColors[colorIdx+1],
              b = sphereColors[colorIdx+2];
        
          float x0 = coorX[j]   * multxz     * rx, x1 = coorX[j]   * multxzPlus * rx,
                x2 = coorX[j+1] * multxzPlus * rx, x3 = coorX[j+1] * multxz     * rx;
          float y0 = coory*ry, y1 = cooryPlus*ry;
          float z0 = coorZ[j]   * multxz     * rz, z1 = coorZ[j]   * multxzPlus * rz,
                z2 = coorZ[j+1] * multxzPlus * rz, z3 = coorZ[j+1] * multxz     * rz;
                
          float nx0 = -coorX[j]*multxz,     ny0 = -coory,     nz0 = -coorZ[j]*multxz,
                nx1 = -coorX[j]*multxzPlus, ny1 = -cooryPlus, nz1 = -coorZ[j]*multxzPlus;
        
          float xc = (x0 + x1 + x2 + x3) / 4.0f, yc = (y0 + y1) / 2.0f, zc = (z0 + z1 + z2 + z3) / 4.0f;
        
          // LIGHT SHAFT, two sizes
          if (r > 16 && g > 16 && b > 16) {
            final float L = 10000.0f;
            rendertarget.stroke(r, g, b, 64);
            rendertarget.vertex(xc, yc, zc);
            rendertarget.stroke(r, g, b, 8);
            rendertarget.vertex(xc - nx0 * L, yc - ny0 * L, zc - nz0 * L);
          }
        }
      }
      rendertarget.strokeWeight(1);
      rendertarget.endShape();
    }
    
    
    rendertarget.popMatrix();
    rendertarget.endDraw();
  }
  
  void setColorByFFT(float spectrum[]) {
    for (int i=0; i<numPointsW * numPointsH * 3; i++) {
        sphereColors[i] = constrain(int(spectrum[i % NUM_BANDS_SHOWN] * MAGNITUDE_MULTIPLIER2), 1, 1024);
    }
  }
  
  void update(long ms) {
    //rot = rot + ms / 1000.0f * 0.5f;
    this.rot += ms / 1000.0f * 0.7f;
  }
  
  void OnBeat() {
    color_offset_inhibit ++;
  }
  
  void OnBeat2() {
    if (color_offset_inhibit > 0) color_offset_inhibit --;
    else color_offset += numPointsW - 1;
  }
};
