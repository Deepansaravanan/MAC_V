"""Generate M9 plots only for metrics backed by parsed Vivado reports."""
import argparse, csv
from pathlib import Path

def load(path):
    with path.open(newline="") as f: return list(csv.DictReader(f))
def svg_bar(path, pairs, label):
    width,height=900,480; margin=70; maxv=max(abs(v) for _,v in pairs) or 1; usable=height-2*margin; barw=max(20,(width-2*margin)//max(1,len(pairs))-20)
    baseline=height-margin if all(v>=0 for _,v in pairs) else height//2
    parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">', '<rect width="100%" height="100%" fill="white"/>', f'<text x="{width/2}" y="28" text-anchor="middle" font-family="sans-serif" font-size="18">{label}</text>', f'<line x1="{margin}" y1="{baseline}" x2="{width-margin}" y2="{baseline}" stroke="black"/>']
    slot=(width-2*margin)/len(pairs)
    for i,(name,value) in enumerate(pairs):
        h=abs(value)/maxv*(usable if baseline==height-margin else usable/2); x=margin+i*slot+(slot-barw)/2; y=baseline-h if value>=0 else baseline
        parts += [f'<rect x="{x:.1f}" y="{y:.1f}" width="{barw}" height="{h:.1f}" fill="#3977b8"/>', f'<text x="{x+barw/2:.1f}" y="{y-6 if value>=0 else y+h+16:.1f}" text-anchor="middle" font-family="sans-serif" font-size="12">{value:.3g}</text>', f'<text x="{x+barw/2:.1f}" y="{height-25}" text-anchor="middle" font-family="sans-serif" font-size="11">{name}</text>']
    path.write_text("".join(parts)+"</svg>",encoding="utf-8")
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1]); a=ap.parse_args()
    try: import matplotlib.pyplot as plt
    except ImportError: plt=None
    src=a.root/"results"/"m9_summary.csv"
    if not src.exists(): print("m9_summary.csv unavailable; plots skipped"); return 2
    rows=load(src); out=a.root/"results"/"plots"; out.mkdir(parents=True, exist_ok=True); made=0
    metrics=[("lut","LUTs"),("ff","Flip-flops"),("dsp","DSP blocks"),("estimated_fmax_mhz","Estimated Fmax (MHz)"),("total_power_w","Vivado estimated power (W)"),("throughput_macs_per_second","Throughput (MAC/s)")]
    for key,label in metrics:
        pairs=[(r["architecture"],float(r[key])) for r in rows if r.get(key," ").strip()]
        if not pairs: print(f"Skipping {key}: no real values"); continue
        if plt:
            names,vals=zip(*pairs); fig,ax=plt.subplots(figsize=(9,4.8)); ax.bar(names,vals); ax.set_ylabel(label); ax.tick_params(axis="x",rotation=25); fig.tight_layout(); fig.savefig(out/f"{key}.png",dpi=160); plt.close(fig)
        else: svg_bar(out/f"{key}.svg",pairs,label)
        made+=1
    derived_path=a.root/"results"/"m9_derived_metrics.csv"
    if derived_path.exists():
        derived=load(derived_path)
        for metric,filename,label in [
            ("reconfigurable_lut_overhead_vs_int8_pct","resource_overhead","LUT overhead vs INT8 (%)"),
            ("optimized_fmax_improvement_pct","performance_improvement","Optimized Fmax improvement (%)"),
            ("optimized_total_power_change_pct","power_change","Optimized total power change (%)")]:
            values=[float(r["value"]) for r in derived if r.get("metric")==metric and r.get("value","").strip()]
            if not values: print(f"Skipping {filename}: required real values unavailable"); continue
            if plt:
                fig,ax=plt.subplots(figsize=(5.5,4.5)); ax.bar([label],[values[0]]); ax.axhline(0,color="black",linewidth=.8); ax.set_ylabel("Percent"); ax.tick_params(axis="x",rotation=10); fig.tight_layout(); fig.savefig(out/f"{filename}.png",dpi=160); plt.close(fig)
            else: svg_bar(out/f"{filename}.svg",[(label,values[0])],label)
            made+=1
    print(f"Generated {made} plot(s) in {out}"); return 0 if made else 2
if __name__ == "__main__": raise SystemExit(main())
