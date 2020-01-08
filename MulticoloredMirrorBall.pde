// 嘿嘿！
// Multicolored Mirror Ball

import processing.opengl.PGraphics2D;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import ddf.minim.*;
import ddf.minim.analysis.*;

// Audio input
Minim minim;
FFT fft;
//AudioIn audioIn;
AudioInput audioInput;
int NUM_BANDS = 4096;
int NUM_BANDS_SHOWN = 256;
final float MAGNITUDE_MULTIPLIER1 = 11.0f;
final float MAGNITUDE_MULTIPLIER2 = 11.0f;
final float OSCILLOSCOPE_MULTIPLIER = 0.2f;
final int AVG_WIDTH = 3;

PFont g_font;
int g_idx = 0;
float spectrum[] = new float[NUM_BANDS];
final float DECAY_FACTOR = 0.98;
float spectrum_hist[] = new float[NUM_BANDS];

int sphereColors[]; // RGB
//int numPointsW, numPointsH_2pi, numPointsH, ptsW, ptsH;

// 相机操纵
float rot = 1.0f, delta_rot = 0.5f;
float cam_x_delta = 0.0f, cam_y_delta = 0.0f;
final float ROT_DECAY_FACTOR = 0.93f;
PVector g_cam_pos, g_cam_p0, g_cam_vec; // 弹簧绳
final float CAM_SPRING_K = -1.0f;
final float CAM_VEC_DAMP = 0.9f;

PGraphics2D pg_fftcanvas1, pg_fftluminance, pg_fftbloom, pg_blank, pg_ffthistory;
PGraphics2D pg_fftcanvas2;
DwFilter filter;
DwPixelFlow context;
PGraphics2D pg_rendertarget;

PGraphics3D pg_lightbulb;
PGraphics3D pg_lightshafts;

// 3D primitives for rendering
WildWolfLightBulb lightbulb;
Background background;
Floor wolf_floor, wolf_ceiling;

final int LOGICAL_WIN_W = 1280, LOGICAL_WIN_H = 720;
FPS g_fps;
long g_last_update_millis;

PShader g_textshader;
boolean SHOW_DEBUG_INFO = true;

void setup() {
  size(1280, 720, P3D);
  //fullScreen(P3D, 2);
  
  print(String.format("dataPath(\"\")=%s\n", dataPath("")));
  
  // Reference: https://processing.org/tutorials/pshader/
  g_textshader = loadShader("texturewithalpha_frag.glsl");
  
  print(String.format("g_textshader=" + g_textshader + "\n"));
  g_font = createFont("STKaiTi", 76);
  frameRate(60);
  noStroke();
  
  lightbulb = new WildWolfLightBulb(50, 50);

  background   = new Background(8, 5);
  wolf_floor   = new Floor(2000, 400, 7, 3, false);
  wolf_ceiling = new Floor(2000, 400, 7, 3, true);
  
  // FFT
  minim = new Minim(this);
  //audioIn = new AudioIn(this, 0);
  //audioIn.start();
  audioInput = minim.getLineIn(Minim.MONO);
  fft = new FFT(audioInput.bufferSize(), NUM_BANDS);
  //fft.input(audioInput);
  
  final int FFT_TEX_W = 1600, FFT_TEX_H = 448;
  pg_fftcanvas1   = (PGraphics2D)createGraphics(FFT_TEX_W, FFT_TEX_H, P2D);
  pg_fftluminance = (PGraphics2D)createGraphics(FFT_TEX_W, FFT_TEX_H, P2D);
  pg_fftbloom     = (PGraphics2D)createGraphics(FFT_TEX_W, FFT_TEX_H, P2D);
  pg_fftcanvas2   = (PGraphics2D)createGraphics(FFT_TEX_W, FFT_TEX_H, P2D);
  
  pg_rendertarget = (PGraphics2D)createGraphics(1920, 1080, P2D);
  pg_lightbulb    = (PGraphics3D)createGraphics(1920, 1080, P3D);
  pg_lightshafts  = (PGraphics3D)createGraphics(1920, 1080, P3D);
  
  //InitLyricAtlas(g_font, 24);
  InitBillboards();
  
  // FFT
  context = new DwPixelFlow(this);
  context.print();
  context.printGL();
  filter = new DwFilter(context);
  
  g_fps = new FPS();
  
  // 相对于原点的偏移
  g_cam_p0 = new PVector(0, 0, 0);
  g_cam_pos = new PVector(0, 0, 0);
  g_cam_vec = new PVector(0, 0, 0);
  
  frameRate(30);
}

void draw() {
  
  // UPDATE
  delta_rot *= ROT_DECAY_FACTOR;
  cam_x_delta *= ROT_DECAY_FACTOR;
  cam_y_delta *= ROT_DECAY_FACTOR;
  fft.forward(audioInput.mix);
  for (int i=0; i<NUM_BANDS; i++) spectrum[i] = fft.getBand(i);
  //fft.analyze(spectrum)
  lightbulb.setColorByFFT(spectrum);
  float delta_s = 0.0f;
  int ms = millis();
  if (g_last_update_millis > 0) {
    delta_s = (ms - g_last_update_millis) / 1000.0f;
    lightbulb.update(ms - g_last_update_millis);
  }
  rot += delta_rot * delta_s;
  g_last_update_millis = ms;
  
  // CAM
  {
    PVector delta = g_cam_pos.copy();
    delta.sub(g_cam_p0);
    delta.mult(CAM_SPRING_K);
    g_cam_vec.add(delta);
    g_cam_vec.mult(CAM_VEC_DAMP);
    g_cam_pos.add(g_cam_vec);
//    print(String.format("Vec: (%g,%g,%g), Pos:(%g,%g,%g)\n",
//      g_cam_vec.x, g_cam_vec.y, g_cam_vec.z,
//      g_cam_pos.x, g_cam_pos.y, g_cam_pos.z));
  }
  
  // BD
  float low_freq_energy = 0.0f;
  for (int i=0; i<LOW_FREQ_NUM_BAND; i++) {
    low_freq_energy += abs(spectrum[i]);
  }
  LogLowFreqSum(low_freq_energy);
  
  // 衰减
  for (int i=0; i<NUM_BANDS; i++) {
    spectrum_hist[i] += spectrum[i];
    spectrum_hist[i] *= DECAY_FACTOR;
    if (spectrum_hist[i] < 1e-8) spectrum_hist[i] = 0;
  }
  
  //RenderFFTTexture1(pg_fftcanvas1, spectrum);
  RenderAudioSamples(pg_fftcanvas1, audioInput);
  RenderFFTTexture2(pg_fftcanvas2, 160, 32, spectrum);
  
  // BLUR FFT
  if (false) {
    filter.luminance_threshold.param.threshold = 0.4f; // when 0, all colors are used
    filter.luminance_threshold.param.exponent  = 4;
    filter.luminance_threshold.apply(pg_fftcanvas1, pg_fftluminance);
    
    filter.bloom.param.mult   = 1.4f; //map(mouseX, 0, width, 0, 10);
    filter.bloom.param.radius = 0.9f; //map(mouseY, 0, height, 0, 1);
    filter.bloom.apply(pg_fftluminance, pg_fftbloom, pg_fftcanvas1);
  }
  
  background(0);
  fill(200);
  
  {
    int W = LOGICAL_WIN_W, H = LOGICAL_WIN_H;
    float eyeX = W/2 + g_cam_pos.x,
          eyeY = H/2 + g_cam_pos.y,
          eyeZ = H/2/tan(PI*30.0 / 180.0) + g_cam_pos.z;
    camera(eyeX, 
           eyeY,
           eyeZ, 
           W/2, H/2.0, 0, 
           0, 1, 0);
    
    eyeX = eyeX / W * pg_lightbulb.width;
    eyeY = eyeY / H * pg_lightbulb.height;
    eyeZ = eyeZ / H * pg_lightbulb.height;
    pg_lightbulb.camera(eyeX, 
           eyeY,
           pg_lightbulb.height/2/tan(PI*30.0 / 180.0), 
           pg_lightbulb.width/2, pg_lightbulb.height/2.0, 0, 
           0, 1, 0);
    pg_lightshafts.camera(eyeX, 
           eyeY,
           pg_lightbulb.height/2/tan(PI*30.0 / 180.0), 
           pg_lightbulb.width/2, pg_lightbulb.height/2.0, 0, 
           0, 1, 0);
  }
  
  if(true) {
    background.render(pg_fftcanvas2);
    blendMode(ADD);
    background.render(pg_fftcanvas1);
    blendMode(BLEND);
    
    wolf_floor.render(pg_fftcanvas2);
    //wolf_floor.render(pg_fftcanvas1);
    
    wolf_ceiling.render(pg_fftcanvas2);
    
    lightbulb.render(150, 150, 150, null, pg_lightbulb, 1);
    lightbulb.render(150, 150, 150, null, pg_lightshafts, 3);
    //lightbulb.render(150, 150, 150, null, pg_lightshafts);
    //lightbulb.render(150, 150, 150, null, pg_lightbulb, true);
  }
  
  // Pass 2: 显示歌词
  for (Billboard b : g_visible_billboards) b.render();
  
  // 这样可以只给灯球本身加上BLOOM效果
  
  if (SHOW_DEBUG_INFO) {
    resetMatrix();
    camera();
    
    hint(DISABLE_DEPTH_TEST);
    // BLUR lightbulb's backbuffer
    if (true) {
      filter.luminance_threshold.param.threshold = 0.1f; // when 0, all colors are used
      filter.luminance_threshold.param.exponent  = 4;
      filter.luminance_threshold.apply(pg_lightbulb, pg_fftluminance);
      
      filter.bloom.param.mult   = 1.4f; //map(mouseX, 0, width, 0, 10);
      filter.bloom.param.radius = 0.9f; //map(mouseY, 0, height, 0, 1);
      filter.bloom.apply(pg_fftluminance, pg_fftbloom, pg_lightbulb);
    }
    
    blendMode(BLEND);
    image(pg_lightbulb, 0, 0, width, height);
    blendMode(ADD);
    image(pg_lightshafts, 0, 0, width, height);
    blendMode(BLEND);
    
    
    // Some stats
    {
      textFont(g_font);
      textAlign(LEFT, TOP);
      textSize(24);
      fill(255);
      String msg = String.format("Light Ball %dx%d, %.2f FPS", width, height, g_fps.GetCurrFPS());
      surface.setTitle(msg);
      text(msg, 0, 40);
    }
    
    DrawBeatDetectStats(ms);
    
    hint(ENABLE_DEPTH_TEST);
  }
  
  g_fps.Increment();
}

void keyPressed() {
  if (keyCode == UP) g_idx = ((g_idx - 1) + g_lyrics.length) % g_lyrics.length;
  else if (keyCode == DOWN) g_idx = (g_idx + 1) % g_lyrics.length;
  else if (key == ' ') NextBillboard();
}

void keyReleased() {
  
}

void OnBeat() {
  lightbulb.OnBeat();
  if (delta_rot > 0) {
    delta_rot += 1;
    if (random(0, 100) > 50)
      g_cam_vec.x += 5;
    else 
      g_cam_vec.x -= 5;
  } else { 
    delta_rot -= 1;
    if (random(0, 100) > 50)
      g_cam_vec.y += 5;
    else
      g_cam_vec.y -= 5;
  }
}

void OnBeat2() {
  lightbulb.OnBeat2();
}

boolean IsBeat() {
  return low_freq_trigger_vis_until > millis();
}

class FPS {
  int last_update_millis;
  int frames_in_window;
  float curr_fps;
  void Increment() {
    frames_in_window ++;
    int ms = millis();
    if (last_update_millis == 0) {
      last_update_millis = ms;
    } else {
      if (ms > 500 + last_update_millis) {
        curr_fps = frames_in_window * 1.0 / (ms - last_update_millis) * 1000.0f;
        frames_in_window = 0;
        last_update_millis = ms;
      }
    }
  }
  float GetCurrFPS() { return curr_fps; }
  float GetFrameTimeInSec() {
    if (last_update_millis < 1) return 0.0f;
    else return (millis() - last_update_millis) / 1000.0f; 
  }
}
