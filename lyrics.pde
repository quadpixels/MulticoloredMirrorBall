import java.util.HashSet;

String g_lyrics[] = {
  "这是歌词",
  "野狼Disco", 
  "心里的花我想要带你回家", 
  "在那深夜酒吧哪管它是真是假", 
  "请你尽情摇摆忘记钟意的他", 
  "你是最迷人噶 你知道吗", 
  "这是最好的时代 这是最坏的时代", 
  "前面儿什么富二代 我拿脚往里踹", 
  "如此动感的节拍 非得搁门口耍帅", 
  "我蹦迪的动线上面儿怎么能有障碍", 
  "大背头 bb机 舞池里的007", 
  "东北初代牌牌奇 dj瞅我也懵", 
  "不管多热都不能脱下我的皮大衣", 
  "全场动作必须跟我整齐划一", 
  "来 左边 跟我一起画个龙", 
  "在你右边 画一道彩虹", 
  "来 左边 跟我一起画彩虹", 
  "在你右边 再画个龙", 
  "在你胸口比划一个郭富城", 
  "左边儿右边儿摇摇头", 
  "两个食指就像两个钻天猴", 
  "指向闪耀的灯球", 
  "心里的花我想要带你回家", 
  "在那深夜酒吧哪管它是真是假", 
  "请你尽情摇摆忘记钟意的他", 
  "你是最迷人噶 你知道吗", 
  "玩儿归玩 闹归闹 别拿蹦迪开玩笑", 
  "左手一瓶大绿棒儿 右手霹雳手套", 
  "金曲野人的士高都给我往后稍一稍", 
  "没事儿不要联系我 大哥大这没信号", 
  "小皮裙 大波浪 一扭一晃真像样", 
  "她的身上太香 忍不住想往上靠", 
  "感觉自己好像梁朝伟在演无间道", 
  "万万没想到她让我找个镜子照一照", 
  "歌照放嗷 舞照跳嗷", 
  "假装啥也不知道嗷", 
  "没有事 没有事 我对着天空笑一笑", 
  "使劲儿拔了拔了前面儿", 
  "社会儿摇的小黄毛儿", 
  "气质再次完全被我卡死哎呀我", 
  "来 全场 一起跟我 低下头儿", 
  "左手右手往前游", 
  "捂住脑门儿晃动你的垮垮轴", 
  "好像有事儿在发愁", 
  "心里的花我想要带你回家", 
  "在那深夜酒吧哪管它是真是假", 
  "请你尽情摇摆忘记钟意的他", 
  "你是最迷人噶 你知道吗", 
  "Ladies gentleman", 
  "All the party people", 
  "给你最劲爆的舞曲", 
  "给你最摇摆的节奏", 
  "Let's happy tonight", 
  "今夜让我们一起放纵", 
  "全场的帅哥美女", 
  "让我看见你们的双手", 
  "这是dj天野 mc小龙", 
  "欢迎莅临 野狼disco", 
  "来 左边 跟我一起画个龙", 
  "在你右边 画一道彩虹", 
  "来 左边 跟我一起画彩虹", 
  "在你右边 画个龙", 
  "在你胸口比划一个郭富城", 
  "左边儿右边儿摇摇头", 
  "两个食指就像两个钻天猴", 
  "指向闪耀的灯球", 
  "来 全场 一起跟我 低下头儿", 
  "左手右手往前游", 
  "捂住脑门儿晃动你的垮垮轴", 
  "好像有事儿在发愁", 
  "时时刻刻你必须要提醒你自己", 
  "不能搭讪", 
  "搭讪你就破功了 老弟", 
};

boolean g_lyric_atlas_inited = false;
ArrayList<PGraphics> g_lyric_lines;
ArrayList<PVector> g_lyric_lt, g_lyric_rb; // 左上与右下

void InitLyricAtlas(PFont font, int size) {
  g_lyric_lines = new ArrayList<PGraphics>();
  textFont(font);
  textSize(size);
  g_lyric_lt = new ArrayList<PVector>();
  g_lyric_rb = new ArrayList<PVector>();
  
  // Determine max width for texture
  for (int i=0; i<g_lyrics.length; i++) {
    String line = g_lyrics[i];
    int w = int(textWidth(line));
    
    PGraphics pg_tmp = createGraphics(w, size);
    pg_tmp.beginDraw();
    pg_tmp.background(0, 0, 0, 0);
    pg_tmp.textFont(font);
    pg_tmp.textSize(size);
    pg_tmp.textAlign(LEFT, TOP);
    pg_tmp.text(line, 0, 0);
    pg_tmp.endDraw();
    g_lyric_lines.add(pg_tmp);
  }
  
  g_lyric_atlas_inited = true;
}

public static enum BillboardState {
  INVISIBLE,
  FADING_IN,
  VISIBLE,
  FADING_OUT
}

ArrayList<Billboard> g_billboards = new ArrayList<Billboard>();
HashSet<Billboard> g_visible_billboards = new HashSet<Billboard>();

abstract class Billboard {
  public PVector pos;
  int last_update_ms, event_end_ms, curr_duration;
  int enter_duration = 500; // ms
  int exit_duration  = 500; // ms
  final static float Y_ENTER_DELTA = -5, Y_EXIT_DELTA = 5;
  final static float Z_ENTER_DELTA =  900, Z_EXIT_DELTA = -900;
  BillboardState state;
  
  Billboard() { last_update_ms = 0; state = BillboardState.INVISIBLE; }
  
  public void Enter() {
    print("Enter\n");
    state = BillboardState.FADING_IN;
    event_end_ms = enter_duration + millis();
    curr_duration = enter_duration;
    g_visible_billboards.add(this);
  }
  
  public void Exit() {
    print("Exit\n");
    state = BillboardState.FADING_OUT;
    event_end_ms = exit_duration + millis();
    curr_duration = exit_duration;
  }
  
  public void Update(int ms) {
    last_update_ms = ms;
    if (ms >= event_end_ms) {
      switch (state) {
        case FADING_IN: state = BillboardState.VISIBLE; break;
        case FADING_OUT: {
          state = BillboardState.INVISIBLE;
          g_visible_billboards.remove(this);
          break;
        }
        default: break;
      }
    }
  }
  
  public float GetTweenCompletion(int ms) {
    return 1.0f - constrain((event_end_ms - ms) * 1.0 / curr_duration, 0, 1);
  }
  
  public float GetOpacity(int ms) {
    float c = GetTweenCompletion(ms);
    switch (state) {
      case FADING_IN: return c;
      case FADING_OUT: return 1-c;
      case VISIBLE: return 1;
      default: return 0;
    }
  }
  
  public PVector GetEffectivePos() {
    PVector ret = pos.copy();
    float c = GetTweenCompletion(millis());
    float c1 = 1 - (1-c) * (1-c);
    switch (state) {
      case FADING_IN:
        ret.y = map(c1, 0, 1, pos.y + Y_ENTER_DELTA, pos.y);
        ret.z = map(c1, 0, 1, pos.z + Z_ENTER_DELTA, pos.z);
        break;
      case FADING_OUT:
        ret.y = map(c1, 0, 1, pos.y, pos.y + Y_EXIT_DELTA);
        ret.z = map(c1, 0, 1, pos.z, pos.z + Z_EXIT_DELTA);
        break;
      case INVISIBLE: ret.y = -1e9; break;
      case VISIBLE: break;
      default: break;
    }
    return ret;
  }
  
  abstract void render();
}

class LyricBillboard extends Billboard {
  public PGraphics2D tex;
  public int w, h;
  
  public LyricBillboard(String txt, PFont font, float font_size) {
    super();
    
    float PAD = font_size / 3; // g y 等字母 有 descent
    
    textFont(font);
    textAlign(LEFT, TOP);
    textSize(font_size);
    w = int(textWidth(txt));
    h = int(font_size + PAD);
    tex = (PGraphics2D)createGraphics(w, h, P2D);
    tex.beginDraw();
    fill(255);
    tex.textFont(font);
    tex.textAlign(LEFT, TOP);
    tex.textSize(font_size);
    tex.text("  ", 0, 0);
    tex.text(txt, 0, 0);
    tex.text(txt, 0, 0); // 中文字体 的 HACK
    tex.endDraw();
    
    pos = new PVector();
    pos.x = 0; pos.y = -100; pos.z = -1;
  }
  
  public void render() {
    PVector p = GetEffectivePos();
    int ms = millis();
    float o = GetOpacity(ms);
    //print(String.format("pos=%g,%g,%g\n", p.x, p.y, p.z));
    blendMode(ADD);
    g_textshader.set("my_opacity", o*o*o);
    shader(g_textshader);
    pushMatrix();
    translate(LOGICAL_WIN_W/2 + p.x, LOGICAL_WIN_H/2 - p.y, p.z);
      beginShape();
      fill(255, 0, 0, 64);
      texture(tex);
      normal(0, 0, 1);
      vertex(-w/2,  h/2, 0, 0,         tex.height);
      vertex(-w/2, -h/2, 0, 0,         0);
      vertex(w/2,  -h/2, 0, tex.width, 0);
      vertex(w/2,   h/2, 0, tex.width, tex.height);
      endShape();
    popMatrix();
    blendMode(BLEND);
    resetShader();
  }
};

int g_billboard_idx = -999, g_billboard_lastidx = -999;
void InitBillboards() {
  for (int i=0; i<g_lyrics.length; i++) {
    Billboard b = new LyricBillboard(g_lyrics[i], g_font, 64);
    g_billboards.add(b);
  }
}

void NextBillboard() {
  if (g_billboard_lastidx >= 0 && g_billboard_lastidx < g_billboards.size())
    g_billboards.get(g_billboard_lastidx).Exit();
  
  if (g_billboard_idx == -999) g_billboard_idx = 0;
  else g_billboard_idx ++;
  if (g_billboard_idx >= g_billboards.size()) {
    g_billboard_idx = -999;
  }
  
  if (g_billboard_idx >= 0 && g_billboard_idx < g_billboards.size())
    g_billboards.get(g_billboard_idx).Enter();
  
  print(String.format("[NextBillboard] idx=%d\n", g_billboard_idx));
  g_billboard_lastidx = g_billboard_idx;
}
