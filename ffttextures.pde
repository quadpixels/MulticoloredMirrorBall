void RenderFFTTexture1(PGraphics2D g, float[] spectrum) {
  g.beginDraw();
  g.background(0, 0, 0, 0);
  
  final float Y_RATIO = 1.0f;
  
  { // Draw fft
    for (int i=0; i<NUM_BANDS_SHOWN; i++) {
      float completion = (i-1) * 1.0f / (NUM_BANDS_SHOWN - 1);
      float completion1 = (i+1) * 1.0f / (NUM_BANDS_SHOWN - 1);
      int x0 = (int)(g.width * 0.5f * completion);
      int x1 = (int)(g.width * 0.5f * completion1);
      
      float samp = 0.0f;
      for (int j=i; j<i+AVG_WIDTH; j++) samp += spectrum[j];// spectrum_hist[j];
      samp /= AVG_WIDTH;
      
      int dy = (int)(samp * g.height * MAGNITUDE_MULTIPLIER1);
      pg_fftcanvas1.noStroke();
      
      //pg_fftcanvas1.fill(int(255 * completion), int(255*(1.0f-completion)), 5);
      pg_fftcanvas1.fill(128, 128, 128);
      
      
      if (i % 2 == 1) {
        pg_fftcanvas1.rect(g.width/2 + x0, g.height*Y_RATIO-5-dy, x1-x0, dy*2+1);
      } else {
        pg_fftcanvas1.rect(g.width/2 - x1, g.height*Y_RATIO-5-dy, x1-x0, dy*2+1);
      }
    }
  }
  g.endDraw();
}

float[] fftintensity2 = new float[NUM_BANDS_SHOWN];
float[] fftintensity2_remapped = new float[NUM_BANDS_SHOWN]; // 第一个 bucket 平分给其它所有人
void RenderFFTTexture2(PGraphics2D g, int w, int h, float[] spectrum) {
  
  for (int i=0; i<NUM_BANDS_SHOWN; i++) {
    fftintensity2[i] += constrain(spectrum[i] * MAGNITUDE_MULTIPLIER2, 0, 1024);
    fftintensity2[i] *= 0.7;
  }
  
  g.beginDraw();
  g.clear();
  g.background(0);
  int cellW = int(g.width * 1.0f / w), cellH = int(g.height * 1.0f / h);
  
  // 2D mapping
  if (false) {
    for (int x=0; x<w; x++) {
      for (int y=0; y<h; y++) {
        final int idx = (y*w + x) * NUM_BANDS_SHOWN / (w*h);
        g.fill(fftintensity2[idx]);
        //fill(idx % 244);
        g.rect(x * cellW, y * cellH, cellW-1, cellH-1);
      }
    }
  } else {
    // 1D mapping
    final float bucket_max = 256 * NUM_BANDS_SHOWN / w;
    final float cell_max   = bucket_max / h;
    
    {
      // 将低频削尖，分给其它所有频段
      for (int i=0; i<NUM_BANDS_SHOWN; i++) {
        fftintensity2_remapped[i] = fftintensity2[i];
      }
      int victims[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8 };
      if (NUM_BANDS_SHOWN > 1) {
        for (int j=0; j<victims.length; j++) {
          int vi = victims[j];
          float delta = fftintensity2[vi] / (NUM_BANDS_SHOWN - 1);
          for (int i=0; i<NUM_BANDS_SHOWN; i++) {
            fftintensity2_remapped[vi] -= delta;
            fftintensity2_remapped[i] += delta;
          }
        }
      }
    }
    
    final float PAD = 0.1, proxy_x_scale = 0.01f;
    float lb_proxy = log(PAD), ub_proxy = log(PAD + (w-1) * proxy_x_scale);
    
    boolean USE_LOG = true;
    
    for (int x=0; x<w; x++) {
      float bucket_value = 0.0f;
      
      int idx_lb = 0, idx_ub = 0;
      if (USE_LOG) {
        float proxy  = log(PAD + x * proxy_x_scale), 
              proxy1 = log(PAD + (x + 1) * proxy_x_scale);
        idx_lb = int(NUM_BANDS_SHOWN * (proxy - lb_proxy) / (ub_proxy - lb_proxy));
        idx_ub = int(NUM_BANDS_SHOWN * (proxy1- lb_proxy) / (ub_proxy - lb_proxy));
      } else {
        idx_lb = NUM_BANDS_SHOWN * x     / w;
        idx_ub = NUM_BANDS_SHOWN * (x+1) / w;
      }
      
      for (int i=idx_lb; i<idx_ub; i++) 
        bucket_value += fftintensity2_remapped[i];
      for (int y=h-1; y>=0; y--) {
        float deduct = min(cell_max, bucket_value);
        float alpha = constrain(deduct * 1.0f / cell_max, 0.1, 1);
        int offset = lightbulb.color_offset;
        int rr = (x * 33 + y * 127 + offset * 11) % 180 + 12;
        int gg = (x * 133 + y * 147 + offset * 3) % 180 + 12;
        int bb = (x * 313 + y * 137 + offset * 7) % 180 + 12;
        //g.fill(fillcolor, fillcolor, 128);
        g.fill(rr * alpha, gg * alpha, bb * alpha);
        g.rect(x*cellW, y*cellH, cellW-1, cellH-1);
        bucket_value -= deduct;
      }
    }
  }
  
  g.endDraw();
}

void RenderAudioSamples(PGraphics2D g, AudioInput in) {
  float YPOS = 0.7f;
  g.beginDraw();
  g.background(0, 0, 0, 0);
  
  final int nsamp = min(in.bufferSize(), 2048);
  g.strokeWeight(2);
  for (int i=0; i<nsamp-1; i++) {
    float samp0 = in.mix.get(i), samp1 = in.mix.get(i+1),
          x0 = g.width * 1.0f / nsamp * i, x1 = g.width * 1.0f / nsamp * (i+1),
          y0 = g.height * YPOS + samp0 * g.width / 2.0f * OSCILLOSCOPE_MULTIPLIER,
          y1 = g.height * YPOS + samp1 * g.width / 2.0f * OSCILLOSCOPE_MULTIPLIER;
    g.stroke(160, 160, y1 * 1.0f, 255);
    g.line(x0, y0, x1, y1);
  }
  g.strokeWeight(1);
  g.endDraw();
}
