# -*- coding: utf-8 -*-
"""
SLM 框架模型完整性自检（防丢件）
用法: python SLM_完整性自检.py [scad路径]
默认检查同目录下的 SLM框架_工程级模型_v3.scad
任何总成包围盒越界 / 面数为0 / 面数偏离基线>10% 都会标红报警。
"""
import os, sys, re, subprocess, tempfile

OPENSCAD = r"C:\Program Files (x86)\OpenSCAD\openscad.exe"
ENV = (850.0, 570.0, 700.0)          # 整机 X/Y/Z 包络
ASSEMBLIES = {
    "skeleton": 6160, "deck_plate": 532, "chamber_panels": 200,
    "front_door": 128, "cylinder_pair": 3968, "recoater_assy": 680,
    "optical_assy": 504, "base_layer": 116, "feet": 880,
}

def bbox(stl):
    if not os.path.exists(stl):
        return None
    txt = open(stl, encoding="utf-8", errors="ignore").read()
    vs = re.findall(r"vertex\s+(-?[\d.eE+]+)\s+(-?[\d.eE+]+)\s+(-?[\d.eE+]+)", txt)
    if not vs:
        return None
    xs = [float(v[0]) for v in vs]; ys = [float(v[1]) for v in vs]; zs = [float(v[2]) for v in vs]
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs), len(vs) // 3)

def main():
    scad = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "SLM框架_工程级模型_v3.scad")
    src = open(scad, encoding="utf-8").read()
    head = src[:src.index("// 组装")] if "// 组装" in src else src
    tmp = tempfile.mkdtemp()
    bad = []
    print(f"检查文件: {scad}\n" + "-" * 78)
    for name, base_tri in ASSEMBLIES.items():
        probe = os.path.join(tmp, f"p_{name}.scad")
        open(probe, "w", encoding="utf-8").write(head + f"\n{name}();\n")
        stl = os.path.join(tmp, f"p_{name}.stl")
        subprocess.run([OPENSCAD, probe, "-o", stl], capture_output=True, text=True, timeout=1800)
        bb = bbox(stl)
        if bb is None:
            print(f"[丢件] {name:<16} 无几何输出"); bad.append(name); continue
        x0, x1, y0, y1, z0, z1, n = bb
        flag = []
        if x0 < -0.6 or x1 > ENV[0] + 0.6: flag.append("X越界")
        if y0 < -0.6 or y1 > ENV[1] + 0.6: flag.append("Y越界")
        if z0 < -0.6 or z1 > ENV[2] + 0.6: flag.append("Z越界")
        dev = (n - base_tri) / base_tri * 100 if base_tri else 0
        if abs(dev) > 10: flag.append(f"面数偏离{dev:+.1f}%")
        print(f"[{'异常' if flag else '正常'}] {name:<16} tri={n:<6}(基线{base_tri}, {dev:+.1f}%) "
              f"X[{x0:.1f},{x1:.1f}] Y[{y0:.1f},{y1:.1f}] Z[{z0:.1f},{z1:.1f}] "
              + ("| " + ",".join(flag) if flag else ""))
        if flag:
            bad.append(name)
    print("-" * 78)
    print("结论:", "全部总成完整，通过" if not bad else f"存在异常: {bad}，禁止交付")

if __name__ == "__main__":
    main()
