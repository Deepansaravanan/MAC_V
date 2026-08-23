"""Parse real Vivado M9 reports. Missing metrics remain blank; nothing is inferred."""
from __future__ import annotations
import argparse, csv, re
from pathlib import Path

TOPS = ["mac_int8", "mac_int16", "reconfigurable_mac_top", "reconfigurable_mac_optimized", "mac_array_4lane"]
LATENCY = {"mac_int8": 1, "mac_int16": 1, "reconfigurable_mac_top": 1, "reconfigurable_mac_optimized": 2, "mac_array_4lane": 1}
MACS_PER_CYCLE = {**{x: 1 for x in TOPS}, "mac_array_4lane": 4}

def text(path: Path) -> str:
    return path.read_text(errors="replace") if path.is_file() else ""
def number(pattern: str, data: str, flags=re.I | re.M):
    m = re.search(pattern, data, flags)
    return float(m.group(1).replace(",", "")) if m else None
def resource(label: str, data: str):
    return number(r"^\|\s*" + re.escape(label) + r"\s*\|\s*([\d,]+)", data)
def first(*values):
    return next((v for v in values if v is not None), None)
def status(path: Path):
    out = {}
    for line in text(path).splitlines():
        if "=" in line:
            k, v = line.split("=", 1); out[k.strip()] = v.strip()
    return out
def blank(v): return "" if v is None else (f"{v:.6f}".rstrip("0").rstrip(".") if isinstance(v, float) else v)

def parse_one(root: Path, arch: str):
    d = root / "results" / "vivado" / arch
    u, t, p, s = text(d/"utilization.rpt"), text(d/"timing_summary.rpt"), text(d/"power.rpt"), status(d/"status.txt")
    # Vivado timing summary's Design Timing Summary row: WNS, TNS, failing endpoints...
    wns = number(r"^\s*WNS\(ns\).*?\n[-\s]+\n\s*(-?\d+(?:\.\d+)?)", t)
    tns = number(r"^\s*WNS\(ns\).*?\n[-\s]+\n\s*-?\d+(?:\.\d+)?\s+(-?\d+(?:\.\d+)?)", t)
    period = float(s["clock_period_ns"]) if s.get("clock_period_ns") else None
    achieved_period = period - wns if period is not None and wns is not None else None
    fmax = 1000.0 / achieved_period if achieved_period and achieved_period > 0 else None
    # Data Path Delay is retained separately; it is not substituted for clock period.
    data_delay = number(r"Data Path Delay:\s*([\d.]+)ns", t)
    total = number(r"^\|\s*Total On-Chip Power \(W\)\s*\|\s*([\d.]+)", p)
    dynamic = number(r"^\|\s*Dynamic \(W\)\s*\|\s*([\d.]+)", p)
    static = number(r"^\|\s*Device Static \(W\)\s*\|\s*([\d.]+)", p)
    lut = first(resource("Slice LUTs", u), resource("CLB LUTs", u))
    ff = first(resource("Slice Registers", u), resource("CLB Registers", u))
    dsp = first(resource("DSPs", u), resource("DSP48E1", u))
    bram = resource("Block RAM Tile", u)
    throughput = fmax * 1e6 * MACS_PER_CYCLE[arch] if fmax is not None else None
    return dict(architecture=arch, fpga_part=s.get("fpga_part", ""), clock_period_ns=period,
                lut=lut, ff=ff, dsp=dsp, bram=bram, wns_ns=wns, tns_ns=tns,
                data_path_delay_ns=data_delay, estimated_fmax_mhz=fmax,
                dynamic_power_w=dynamic, static_power_w=static, total_power_w=total,
                latency_cycles=LATENCY[arch], macs_per_cycle=MACS_PER_CYCLE[arch],
                throughput_macs_per_second=throughput, flow=s.get("flow", ""))

def write(path, fields, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        w=csv.DictWriter(f, fieldnames=fields); w.writeheader(); w.writerows({k:blank(r.get(k)) for k in fields} for r in rows)

def pct(a, b): return ((a-b)/b*100) if a is not None and b not in (None, 0) else None
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1]); args=ap.parse_args()
    rows=[parse_one(args.root.resolve(), x) for x in TOPS]
    out=args.root/"results"
    write(out/"resource_comparison.csv", ["architecture","fpga_part","lut","ff","dsp","bram"], rows)
    write(out/"timing_comparison.csv", ["architecture","clock_period_ns","wns_ns","tns_ns","data_path_delay_ns","estimated_fmax_mhz","latency_cycles","macs_per_cycle","throughput_macs_per_second"], rows)
    write(out/"power_comparison.csv", ["architecture","dynamic_power_w","static_power_w","total_power_w"], rows)
    fields=list(rows[0]); write(out/"m9_summary.csv", fields, rows)
    by={r["architecture"]:r for r in rows}; base=by["reconfigurable_mac_top"]; opt=by["reconfigurable_mac_optimized"]
    derived=[{"metric":"reconfigurable_lut_overhead_vs_int8_pct","value":pct(base["lut"],by["mac_int8"]["lut"])},
             {"metric":"optimized_fmax_improvement_pct","value":pct(opt["estimated_fmax_mhz"],base["estimated_fmax_mhz"])},
             {"metric":"optimized_total_power_change_pct","value":pct(opt["total_power_w"],base["total_power_w"])}]
    write(out/"m9_derived_metrics.csv", ["metric","value"], derived)
    missing=sum(1 for r in rows if not r["flow"] or r["flow"] != "PASS")
    print(f"Parsed {len(rows)} architectures; {missing} lack a successful Vivado flow. Missing values were left blank.")
    return 0 if missing == 0 else 2
if __name__ == "__main__": raise SystemExit(main())
