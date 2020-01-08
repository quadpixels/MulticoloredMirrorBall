// Super crappy beat detector
final int CLEAR_INTERVAL_SECONDS = 10; // 每十秒清零
int last_clear_millis = 0;
final float CLEAR_WEIGHT = 0.3; // 消除最高的bucket的0.5倍

final int BEAT_DETECT_HIST_LEN = 15;
final int BEAT_DETECT_LOOKBACK = 1;
final int LOW_FREQ_NUM_BAND = 100;
final float BEAT_DETECT_RATIO_THRESH = 0.8f;
float[] low_freq_sum_hist = new float[BEAT_DETECT_HIST_LEN];
int low_freq_sum_idx = 0;
int low_freq_lastflag = 0;
int low_freq_trigger_vis_until = 0;  // Actively detected
int low_freq_trigger_vis_until2 = 0; // Passively (inertia) detected
int low_freq_lastmillis = 0;
int low_freq_lastmillis1 = 0;
final int BEATDETECT_DELTAT_RES = 20; // msec
final int BEATDETECT_DELTAT_BINS = 50; // # bins
int[] beatdetect_deltat_hist = new int[BEATDETECT_DELTAT_BINS];
int beatdetect_target_idx = 0;
float beatdetect_viz_metric = 0.0f;

void LogLowFreqSum(float energy) {
  
  low_freq_sum_hist[low_freq_sum_idx] = energy;
  float s = 0;
  for (int i=0; i<BEAT_DETECT_HIST_LEN; i++) s += low_freq_sum_hist[i];
  float avg = s * 1.0f / BEAT_DETECT_HIST_LEN;
  float lookback = 0.0f;
  for (int i=0; i<BEAT_DETECT_LOOKBACK; i++) {
    lookback += low_freq_sum_hist[(-i + BEAT_DETECT_HIST_LEN + low_freq_sum_idx)%BEAT_DETECT_HIST_LEN]; 
  }
  lookback /= float(BEAT_DETECT_LOOKBACK);
  low_freq_sum_idx = (1 + low_freq_sum_idx) % BEAT_DETECT_HIST_LEN;
  
  beatdetect_viz_metric = lookback / avg;
  int flag = lookback > avg * BEAT_DETECT_RATIO_THRESH ? 1 : -1;
  int ms = millis();

  if (ms - last_clear_millis >= CLEAR_INTERVAL_SECONDS * 1000) {
    // Find delta
    int delta = 0;
    for (int i=0; i<BEATDETECT_DELTAT_BINS; i++) {
      delta = max(delta, beatdetect_deltat_hist[i]);
    }
    for (int i=0; i<BEATDETECT_DELTAT_BINS; i++) {
      beatdetect_deltat_hist[i] = max(0, int(beatdetect_deltat_hist[i] - delta * CLEAR_WEIGHT));
    }
    last_clear_millis = ms;
  }
  
  if (flag == 1 && low_freq_lastflag == -1) {
    int deltat = ms - low_freq_lastmillis, idx = deltat / BEATDETECT_DELTAT_RES;
    if (idx < BEATDETECT_DELTAT_BINS) {
      beatdetect_deltat_hist[idx] ++;
    }
    low_freq_lastmillis = ms;
    
    // Find target bucket idx
    int max_count = 0;
    for (int i=0; i<BEATDETECT_DELTAT_BINS; i++) {
      if (max_count < beatdetect_deltat_hist[i]) {
        beatdetect_target_idx = i;
        max_count = beatdetect_deltat_hist[i];
      }
    }
    
    low_freq_trigger_vis_until = ms + 100; // Triggered
    OnBeat();
  }
  
  // Passive trigger
  if (ms > beatdetect_target_idx * BEATDETECT_DELTAT_RES + low_freq_lastmillis1) {
    low_freq_trigger_vis_until2 = ms + 100;
    low_freq_lastmillis1 = ms;
    OnBeat2();
  }
  
  low_freq_lastflag = flag;
}

void DrawBeatDetectStats(int ms) {
  blendMode(REPLACE);
  if (low_freq_trigger_vis_until > ms) {
    rect(5, 10, 16, 16);
  }
  if (low_freq_trigger_vis_until2 > ms) {
    rect(5, 28, 16, 1);
  }
  int max_count = 0;
  for (int i=0; i<BEATDETECT_DELTAT_BINS; i++) {
    if (max_count < beatdetect_deltat_hist[i])
      max_count = beatdetect_deltat_hist[i];
  }
  final int bars_height = 16;
  for (int i=0; i<BEATDETECT_DELTAT_BINS; i++) {
    int dy = (max_count == 0 ? 1 : 1 + int(beatdetect_deltat_hist[i] * 1.0f * bars_height / max_count));
    rect(30 + 5*i, 10, 3, dy);
  }
  rect(30 + 5*beatdetect_target_idx, 10 + bars_height + 3, 3, 5);
  int dx = int(constrain(beatdetect_viz_metric * 100, 1, 200));
  rect(5, 2, dx, 4);
  blendMode(BLEND);
}
