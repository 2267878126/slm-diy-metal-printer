// ============================================================
// 桌面级SLM金属打印机 - 整机框架工程级参数化模型 v2.1
// 参照: 大狗嚼SLM100 (SLM_V2, 850x570外形, 层高60/510)
// 目标: 全标准件可采购, 结构可验证, 可直接下单
// 分层: 底部电控粉料层(0-120) / 中部密封成型仓(120-540) / 顶部激光光路层(540-700)
// 标准件清单(全部淘宝/嘉立创可购):
//   - 欧标4040铝型材(8mm槽) 立柱 x4
//   - 欧标3030铝型材(8mm槽) 横梁 x12
//   - 欧标角件4040-3030通用 x24 (每连接处2件)
//   - T型螺母M6 + 内六角M6x16 若干
//   - 3mm铝板钣金(嘉立创折弯): 甲板/侧板x2/背板/前门/激光安装板
//   - 5mm亚克力观察窗 (320x240)
//   - φ100x300钢管 x2 (送粉缸/成型缸缸筒, 45#)
//   - SFU1605滚珠丝杠 x2 (含丝杠螺母座)
//   - MGN15线性导轨 x2 (铺粉) + MGN12 x4 (缸导向)
//   - 42步进电机(NEMA17) x4 (双缸x2 + 铺粉x1 + 备用)
//   - GT2同步带 + 20T/40T带轮
//   - 2mm橡胶密封条 + M10可调脚杯x4 + 氩气接口
// 使用: F5预览 F6渲染导出STL; 改顶部参数调尺寸
// ============================================================

// ---------------- 全局参数 ----------------
L    = 850;   // 整机长度 mm (X)
W    = 570;   // 整机宽度 mm (Y)
H1   = 120;   // 底部层高: 电控+粉料 (立柱底面~甲板)
H2   = 420;   // 中部层高: 密封成型仓
H3   = 160;   // 顶部层高: 激光光路层
POST = 40;    // 立柱 4040
PROF = 30;    // 横梁 3030
THK  = 3;     // 钣金厚 3mm
THK6 = 6;     // 激光板厚 6mm
ACRY = 5;     // 亚克力 5mm
CYL_D= 100;   // 缸筒外径 φ100
CYL_H= 300;   // 缸筒高
FLANGE= 140;  // 缸法兰外径 φ140
RAIL15= 15;   // MGN15宽
RAIL12= 12;   // MGN12宽
SCR_D = 16;   // SFU1605丝杠径
MOT   = 42;   // 42步进
MOT_H = 50;   // 丝杠起始高度 (电机输出轴上方)

// 派生尺寸
CL = L - 2*POST;          // 内框长 (立柱内侧面间距)
CW = W - 2*POST;          // 内框宽
DECK_H = 100;             // 甲板(成型仓底板)高度
CH_T = H1 + H2;           // 成型仓顶 = 540
BEAM_A = 60;              // 底层横梁中心高 (大狗嚼同60)
BEAM_B = CH_T - PROF;     // 仓顶横梁底 = 510
BEAM_C = H1+H2+H3 - PROF; // 顶部横梁底 = 670
TOP_H  = H1+H2+H3;        // 总高 700
CH_H   = CH_T - DECK_H - THK; // 成型仓净高 约417
// 双缸位置 (送粉左, 成型右, 缸中心)
FX = L/2 - 250;
BX = L/2 + 90;
CY = W/2;

// ============================================================
// 标准件模块
// ============================================================

// ---- 欧标铝型材截面 (带8mm槽, 参数化) ----
module profile(len, s) {
    half = s/2; slot = 4; sd = 8; // 槽半宽4, 槽深8
    pts = [
        [-half,-half], [-slot,-half], [-slot,-half+sd], [slot,-half+sd], [slot,-half], [half,-half],
        [half,-slot], [half-sd,-slot], [half-sd,slot], [half,slot], [half,half],
        [slot,half], [slot,half-sd], [-slot,half-sd], [-slot,half], [-half,half],
        [-half,slot], [-half+sd,slot], [-half+sd,-slot], [-half,-slot]
    ];
    color("silver") linear_extrude(len) polygon(pts);
}
module beam4040(len) { profile(len, 40); }
module beam3030(len) { profile(len, 30); }
module beam2020(len) { color("silver") cube([20,20,len]); }

// ---- 角件 (欧标 40x40x30, 双孔) ----
module corner_bracket() {
    color("#909090") {
        difference() {
            cube([40, 40, 30]);
            translate([20, -0.1, 15]) rotate([-90,0,0]) cylinder(d=5.5, h=10, $fn=24);
            translate([-0.1, 20, 15]) rotate([0,90,0])   cylinder(d=5.5, h=10, $fn=24);
        }
    }
}

// ---- 钣金板 (带四周折边) ----
module folded_plate(w, h, fold=15, t=THK) {
    color("#c8c8c8") {
        cube([w, h, t]);
        translate([0,-fold,0]) cube([w, fold, t]);
        translate([0,h,0])     cube([w, fold, t]);
        translate([-fold,0,0]) cube([fold, h, t]);
        translate([w,0,0])     cube([fold, h, t]);
    }
}

// ---- 法兰 (圆盘+螺栓孔环) ----
module flange(d, h, holes=8) {
    color("#8a8a8a") {
        difference() {
            cylinder(d=d, h=h, $fn=64);
            for(i=[0:holes-1]) rotate([0,0,i*360/holes])
                translate([d/2-12, 0, -0.1]) cylinder(d=6.5, h=h+0.2, $fn=16);
        }
    }
}

// ---- 42步进电机 (含输出轴) ----
module motor42() {
    translate([-MOT/2, -MOT/2, 0]) cube([MOT, MOT, 45]);
    translate([0, 0, 45]) color("silver") cylinder(d=22, h=24, $fn=32); // 输出轴
}

// ---- 丝杠 (SFU1605 + 螺母) ----
module screw(len) {
    color("steelblue") cylinder(d=SCR_D, h=len, $fn=24);
    translate([0, 0, len-40]) color("#556b8a") cylinder(d=40, h=35, $fn=32); // 螺母在顶部
}

// ---- MGN导轨+滑块 ----
module rail15(len) { color("dimgray") cube([RAIL15, len, 12]); }
module rail12(len) { color("dimgray") cube([RAIL12, len, 10]); }
module carriage(len=40) { color("gainsboro") cube([20, len, 18]); }

// ---- 可调脚杯 (M10) ----
module foot() {
    color("#333") cylinder(d=40, h=6, $fn=32);
    color("#666") cylinder(d=24, h=25, $fn=24);
}

// ============================================================
// 1. 骨架: 立柱 + 三层横梁 + 角件
// ============================================================
module skeleton() {
    // 四角立柱 4040 (高=总高); profile截面以中心为原点, 需 +POST/2 偏移使立柱占据 0..POST
    translate([POST/2, POST/2, 0])         beam4040(TOP_H);
    translate([L-POST/2, POST/2, 0])       beam4040(TOP_H);
    translate([POST/2, W-POST/2, 0])       beam4040(TOP_H);
    translate([L-POST/2, W-POST/2, 0])     beam4040(TOP_H);

    // 三层围框横梁 (3030)
    beam_ring(BEAM_A);
    beam_ring(BEAM_B);
    beam_ring(BEAM_C);

    // 角件: 每层每角2件, 贴横梁端跨立柱面
    for(h=[BEAM_A, BEAM_B, BEAM_C]) {
        corner_pair(0, 0, h);
        corner_pair(L-POST, 0, h);
        corner_pair(0, W-POST, h);
        corner_pair(L-POST, W-POST, h);
    }

    // 光路支撑立柱 2020 x4 (立仓顶横梁上, 留0.5mm)
    for(x=[POST+PROF, L-POST-PROF-20], y=[POST+PROF, W-POST-PROF-20])
        translate([x, y, CH_T+0.5]) beam2020(H3-30);
}
module beam_ring(h) {
    // 截面中心对齐: 型材截面以中心为原点, 需偏移 +PROF/2 使梁占据 0..PROF / h..h+PROF
    // X向两长梁 (水平, 长沿X, 两端与立柱面留0.5mm配合间隙)
    translate([POST+0.5, PROF/2, h+PROF/2]) rotate([0,90,0]) beam3030(CL-1);
    translate([POST+0.5, W-PROF/2, h+PROF/2]) rotate([0,90,0]) beam3030(CL-1);
    // Y向两短梁 (水平, 长沿Y)
    translate([PROF/2, POST+0.5, h+PROF/2]) rotate([-90,0,0]) beam3030(CW-1);
    translate([L-PROF/2, POST+0.5, h+PROF/2]) rotate([-90,0,0]) beam3030(CW-1);
}
// x,y 为立柱左下角位置; 角件贴立柱内侧面, 装在横梁下方1mm避共面
module corner_pair(x, y, h) {
    // X梁端角件 (贴立柱内侧面, 位于X梁端下方)
    ax = (x==0) ? POST : L-POST-POST;
    ay = (y==0) ? 0 : W-POST;
    translate([ax, ay, h-1]) corner_bracket();
    // Y梁端角件 (贴立柱内侧面, 位于Y梁端下方)
    bx = (x==0) ? 0 : L-POST;
    by = (y==0) ? POST : W-POST-POST;
    translate([bx, by, h-1]) corner_bracket();
}

// ============================================================
// 2. 甲板 + 成型仓围板 + 前门
// ============================================================
module deck_plate() {
    color("#c8c8c8") {
        difference() {
            translate([POST, POST, DECK_H]) cube([CL, CW, THK]);
            for(x=[FX, BX])
                translate([x, CY, DECK_H-1]) cylinder(d=CYL_D+5, h=THK+2, $fn=64);
        }
    }
}
module chamber_panels() {
    // 板高取 CH_H-15, 使上折边正好收在仓顶 CH_T 以内, 不穿入顶部光路层
    PH = CH_H - 15;
    // 背板 (竖直, 面朝前, 折边朝内下/上/左右, 贴后立柱内侧面)
    translate([POST+PROF, W-POST, DECK_H+THK]) rotate([90,0,0]) folded_plate(CL-60, PH, 15, THK);
    // 左侧板 (竖直, 面朝右/仓内, 贴左立柱内侧面)
    translate([POST+10, W-POST-PROF, DECK_H+THK]) rotate([0,0,-90]) rotate([90,0,0]) folded_plate(CW-60, PH, 15, THK);
    // 右侧板 (竖直, 面朝左/仓内, 贴右立柱内侧面)
    translate([L-POST-10, POST-10, DECK_H+THK]) rotate([0,0,90]) rotate([90,0,0]) folded_plate(CW-60, PH, 15, THK);
    // 密封条示意 (仓顶沿口)
    color("#222") {
        translate([POST+15, W-POST-8, CH_T-5]) cube([CL-30, 4, 4]);
        translate([POST+15, POST+10, CH_T-5]) cube([CL-30, 4, 4]);
        translate([POST+10, POST+15, CH_T-5]) cube([4, CW-30, 4]);
        translate([L-POST-14, POST+15, CH_T-5]) cube([4, CW-30, 4]);
    }
}
module front_door() {
    dw = CL - 60;
    // 门板竖直, 面朝前, 与立柱齐平
    translate([POST+30, POST-2, DECK_H+THK]) {
        // 门板 (3mm钣金, 开观察窗洞)
        color("#c8c8c8") difference() {
            cube([dw, THK, CH_H]);
            translate([(dw-320)/2, -1, 60]) cube([320, THK+2, 240]);
        }
        // 亚克力观察窗 (嵌窗洞, 与门板同厚)
        translate([(dw-320)/2, 0, 60]) color("#aee5ff") cube([320, THK, 240]);
        // 窗框压条
        color("#999") {
            translate([(dw-340)/2, -1, 50]) cube([340, 8, 8]);
            translate([(dw-340)/2, -1, 302]) cube([340, 8, 8]);
            translate([(dw-340)/2, -1, 50]) cube([8, 8, 260]);
            translate([(dw+340)/2-8, -1, 50]) cube([8, 8, 260]);
        }
        // 合页 x3 (左, 跨立柱内面与门左缘)
        for(i=[0,1,2]) translate([-30, 0, 60+i*120]) color("silver") cube([10, 6, 30]);
        // 门锁扣 (右)
        translate([dw-8, 2, 210]) color("#777") cube([8, 8, 30]);
    }
}

// ============================================================
// 3. 双缸机构 (送粉缸/成型缸)
// ============================================================
module cylinder_assy(x, has_platform) {
    translate([x, CY, 0]) {
        // 缸筒 (45#钢管 φ100)
        translate([-CYL_D/2, -CYL_D/2, DECK_H+THK]) color("#b06c49") cube([CYL_D, CYL_D, CYL_H]);
        // 底部法兰 (甲板下方)
        translate([0, 0, DECK_H-12]) flange(FLANGE, 12);
        // 顶部法兰 (密封面)
        translate([0, 0, DECK_H+THK+CYL_H]) flange(FLANGE, 10);
        // 丝杠 (缸中心)
        translate([0, 0, MOT_H+35]) screw(DECK_H+THK+CYL_H-10-MOT_H-35);
        // 缸内平台 (粉缸活塞/成型平台)
        if(has_platform)
            translate([-CYL_D/2+3, -CYL_D/2+3, DECK_H+THK+40]) color("#d9a066") cube([CYL_D-6, CYL_D-6, 12]);
        // 电机座 (铝块)
        translate([-MOT/2-5, -MOT/2-5, 42]) color("#9a9a9a") cube([MOT+10, MOT+10, 12]);
        // 42步进电机 (缸下方)
        translate([0, 0, 0]) motor42();
    }
}
module cylinder_pair() {
    cylinder_assy(FX, true);   // 送粉缸(带活塞)
    cylinder_assy(BX, false);  // 成型缸(带成型平台)
    // 缸导向: 每缸两侧 MGN12 竖向导轨 (从甲板到缸顶)
    for(x=[FX, BX]) {
        translate([x-CYL_D/2-25, CY-RAIL12/2, DECK_H+THK]) rotate([90,0,0]) rail12(CYL_H-20);
        translate([x+CYL_D/2+25, CY-RAIL12/2, DECK_H+THK]) rotate([90,0,0]) rail12(CYL_H-20);
    }
}

// ============================================================
// 4. 铺粉机构 (MGN15 x2 + 刮刀架 + GT2同步带)
// ============================================================
module recoater_assy() {
    y1 = CY + 150;   // 导轨1
    y2 = y1 + 50;    // 导轨2
    rl = 430; rx = FX - 20; // 覆盖两缸
    rail_h = DECK_H + THK + 25; // 导轨安装高度
    // 导轨支座
    for(y=[y1,y2]) {
        translate([rx-30, y-15, DECK_H+THK]) color("#9a9a9a") cube([30, 30, 25]);
        translate([rx+rl, y-15, DECK_H+THK]) color("#9a9a9a") cube([30, 30, 25]);
        // 导轨 (沿X横跨)
        translate([rx, y, rail_h]) rotate([0,0,-90]) rail15(rl);
        // 滑块 x2
        translate([rx+40, y, rail_h+12-18]) rotate([0,0,-90]) carriage(40);
        translate([rx+rl-80, y, rail_h+12-18]) rotate([0,0,-90]) carriage(40);
    }
    // 刮刀架 (角铝, 横跨)
    translate([rx+rl/2-95, y1+50-25, rail_h+12]) {
        color("#d2691e") cube([190, 45, 20]);
        // 刮刀片
        translate([5, -3, -5]) color("#ccc") cube([180, 6, 10]);
    }
    // 同步带轮 + 电机
    translate([rx+15, y1+25, rail_h+12]) color("dimgray") cylinder(d=22, h=25, $fn=32);
    translate([rx+rl-15, y1+25, rail_h+12]) color("dimgray") cylinder(d=22, h=25, $fn=32);
    translate([rx+rl-15, y1+25-MOT/2, rail_h+12+25]) motor42();
    // 同步带
    translate([rx+15, y1+23, rail_h+12+8]) color("#333") cube([rl-30, 4, 4]);
}

// ============================================================
// 5. 顶部光路层 (2020立柱 + 激光板 + 聚焦座 + 光纤激光头)
// ============================================================
module optical_assy() {
    plate_h = CH_T + H3 - 60; // 640
    // 激光安装板 (6mm铝板)
    color("#c8c8c8") {
        difference() {
            translate([POST+PROF, POST+PROF, plate_h]) cube([CL-60, CW-60, THK6]);
            translate([BX, CY, plate_h-1]) cylinder(d=25, h=THK6+2, $fn=32);
            for(x=[POST+PROF+40, L-POST-PROF-46], y=[POST+PROF+40, W-POST-PROF-46])
                translate([x, y, plate_h-1]) cylinder(d=8, h=THK6+2, $fn=16);
        }
    }
    // 聚焦镜座 (f-theta振镜简化)
    translate([BX-35, CY-35, plate_h-40]) color("#b0b0b0") cube([70, 70, 40]);
    // 光纤激光头 (200W)
    translate([BX-20, CY-20, plate_h+THK6]) color("gold") cube([40, 40, 50]);
    // 光纤线缆示意 (水平引向背板, 不超出整机顶面)
    translate([BX, CY+20, plate_h+THK6+25]) rotate([-90,0,0]) color("#333") cylinder(d=8, h=190, $fn=16);
}

// ============================================================
// 6. 底部电控/粉料 + 脚杯
// ============================================================
module base_layer() {
    // 控制盒 (前侧)
    translate([L/2-150, POST+20, 0]) color("#555") cube([300, 180, 80]);
    // 粉料抽屉 (后侧)
    translate([L/2-100, W-POST-20-160, 0]) color("#7a5c3e") cube([200, 160, 75]);
    // 氩气接口 (背板)
    translate([L/2, W-POST-3, DECK_H+80]) color("#bbb") cylinder(d=20, h=15, $fn=24);
}
module feet() {
    for(x=[0, L-POST], y=[0, W-POST])
        translate([x+POST/2, y+POST/2, 0]) foot();
}

// ============================================================
// 组装
// ============================================================
skeleton();
deck_plate();
chamber_panels();
front_door();
cylinder_pair();
recoater_assy();
optical_assy();
base_layer();
feet();
