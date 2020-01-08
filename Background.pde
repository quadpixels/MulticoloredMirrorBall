float room_height = 300;

class Background {
  public int num_sides, num_sides_shown;
  public boolean is_span; // 贴图延展到所有块上与否
  Background(int _num_sides, int _num_sides_shown) {
    num_sides = _num_sides; num_sides_shown = _num_sides_shown;
    is_span = true;
  }
  public void render(PImage tex) {
    if (IsBeat()) stroke(255);
    else noStroke();
    pushMatrix();
    translate(LOGICAL_WIN_W/2, LOGICAL_WIN_H/2, 0);
    
    int N = num_sides_shown + 2; // +2 是 左边和右边的
    
    // 背景
    {
      final float dt = PI * 2.0f / num_sides,
                  theta0 = PI / 2 + dt/2 + dt * int(num_sides_shown/2);
      
      final float R = 800.0f, Z = 190.0f, H = room_height, Z_POS = 200;
      float theta = theta0;
      
      beginShape(QUADS);
      for (int i=0; i<num_sides_shown; i++, theta -= dt) {
        //float x0 = x[i], x1 = x[i+1], z0 = z[i], z1 = z[i+1];
        float x0 = cos(theta) * R, x1 = cos(theta - dt) * R;
        float z0 = -sin(theta) * Z - Z_POS, z1 = -sin(theta - dt) * Z - Z_POS;

        float u0 = 0, u1 = tex.width;
        if (is_span) {
          u0 = (1 + i) * tex.width * 1.0f / N;
          u1 = (2 + i) * tex.width * 1.0f / N;
        }
        
        texture(tex);
        fill(255, 255, 255);
        normal(0, 0, 1);
        vertex(x0,  H, z0, u0, tex.height);
        vertex(x0, -H, z0, u0, 0);
        vertex(x1, -H, z1, u1, 0);
        vertex(x1,  H, z1, u1, tex.height);
      }
      endShape();
      
      {
        //boundaries
        float x2 = cos(theta0) * R, x3 = cos(theta0 - dt * num_sides_shown) * R;
        float z2 = -sin(theta0) * Z - Z_POS, z3 = -sin(theta0 - dt * num_sides_shown) * Z - Z_POS;
        
        beginShape(QUADS);
        texture(tex);
        fill(255, 255, 255);
        
          float u00 = 0, u01 = tex.width, u10 = 0, u11 = tex.width;
          if (is_span) {
            u01 = tex.width * 1.0f / N;
            u10 = tex.width * 1.0f / N * (N-1);
          }
        
          normal(1, 0, 0);
          vertex(x2,  H, z2+H*2, u00, tex.height);
          vertex(x2, -H, z2+H*2, u00, 0);
          vertex(x2, -H, z2,     u01, 0);
          vertex(x2,  H, z2,     u01, tex.height);
          
          normal(-1, 0, 0);
          vertex(x3,  H, z3+H*2, u10, tex.height);
          vertex(x3, -H, z3+H*2, u10, 0);
          vertex(x3, -H, z3,     u11, 0);
          vertex(x3,  H, z3,     u11, tex.height);
        endShape();
      }
    }
    popMatrix();
  }
};

class Floor {
  public int hw, hh, nbreaks, nbreaks_shown;
  public float normal_y;
  public boolean is_ceiling, is_span;
  public Floor(int _hw, int _hh, int _nbreaks, int _nbreaks_shown, boolean _is_ceiling) {
    hw = _hw; hh = _hh; 
    nbreaks = _nbreaks;
    nbreaks_shown = _nbreaks;
    if (is_ceiling) normal_y = -1;
    else normal_y = 1;
    is_ceiling = _is_ceiling;
    
    is_span = true;
  }
  public void render(PImage tex) {
    
    final int Z_PROTRUDE = 100;
    
    final float H = room_height;
    pushMatrix();
    
    if (is_ceiling) translate(1280/2, 720/2 - H, 0); 
    else translate(1280/2, 720/2 + H, 0);
    
    beginShape(QUADS);
    texture(tex);
    //stroke(255);
    noStroke();
    
    float half = nbreaks * 1.0f / 2;
    
    int i0 = (nbreaks - nbreaks_shown) / 2, i1 = i0 + nbreaks_shown;
    for (int i=i0; i<i1; i++) {
      float x0 = -hw + (2.0f * hw / nbreaks) * i,
            x1 = x0 + (2.0f * hw / nbreaks);
      float zoffset0 = Z_PROTRUDE * (abs(i - half) - 0.5f),
            zoffset1 = Z_PROTRUDE * (abs(i+1-half) - 0.5f);
            
      float u0 = 0, u1 = tex.width;
      if (is_span) {
        u0 = i * tex.width * 1.0f / nbreaks;
        u1 = (i+1) * tex.width * 1.0f / nbreaks;
      }
            
      normal(0, normal_y, 0);
      fill(255, 255, 255);
      vertex(x0, 0, -hh + zoffset0, u0, tex.height);
      vertex(x0, 0,  hh + zoffset0, u0, 0);
      vertex(x1, 0,  hh + zoffset1, u1, 0);
      vertex(x1, 0, -hh + zoffset1, u1, tex.height);
    }
    endShape();
    popMatrix();
  }
}
