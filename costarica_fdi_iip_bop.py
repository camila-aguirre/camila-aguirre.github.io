"""
=============================================================================
costarica_fdi_iip_bop.py
Part 2 – Costa Rica: Foreign Direct Investment, IIP vs Balance of Payments
Author: Camila Aguirre Diaz
=============================================================================

TASK 1 – DATA COLLECTION
=========================
Primary source: IMF Balance of Payments Statistics (BOP/IIP dataset)
  API: http://dataservices.imf.org/REST/SDMX_JSON.svc  (public, no auth)
  Country code: 238 (Costa Rica, IMF BOP dataset numeric code)
  Framework: BPM6 (Sixth Edition of the BOP/IIP Manual)
  Units: millions of US dollars

The script fetches QUARTERLY data from the IMF SDMX-JSON API and
aggregates to annual frequency using the appropriate method for each
series type (see aggregation section below). If the API is unreachable
the script falls back to hardcoded values transcribed from the BCCR
(Banco Central de Costa Rica) official tables on 2025-05-25.

Indicators requested:
  (A) IIP inward FDI stock  → ILFD_BP6_USD
      "IIP, Liabilities, Direct Investment"
      End-of-period stock; positive = outstanding inward FDI position

  (B) BOP inward FDI flows  → BFDI_BP6_USD
      "Financial Account, Direct Investment, Net Incurrence of Liabilities"
      Flow per period; positive = net capital inflow into Costa Rica

SIGN CONVENTION AND COMPARABILITY
===================================
Both indicators measure inward FDI from the same perspective (liability
side of the reporting economy = Costa Rica):
  ILFD_BP6_USD  positive → larger inward stock
  BFDI_BP6_USD  positive → net inflow during the period

No sign adjustment is required. The two series are directly comparable
under the same BPM6 sign convention. This is verified explicitly in
Section 2 of this script.

AGGREGATION FROM QUARTERLY TO ANNUAL
======================================
The IMF BOP dataset publishes data at quarterly frequency (Q).
Aggregation to annual frequency follows BPM6 methodology:

  BOP flows  (BFDI_BP6_USD):
    Annual = SUM of Q1 + Q2 + Q3 + Q4
    Justification: flows are additive across time periods. A transaction
    recorded in Q2 is as valid a flow as one recorded in Q4. Summing
    gives total transactions during the calendar year (BPM6 §3.7,
    "flows refer to economic actions and effects of events that take
    place within an accounting period").

  IIP stock  (ILFD_BP6_USD):
    Annual = Q4 value (end-of-year, i.e. 31 December)
    Justification: stocks represent a balance at a point in time, not
    cumulative transactions. The year-end value (Q4) is the standard
    annual IIP benchmark published by all central banks and the IMF
    (BPM6 §7.4: "the IIP is a statement... at a specific point in time").
    Summing or averaging quarterly stocks would be conceptually wrong.

TASK 2 – INDICATOR CONSTRUCTION
=================================
The BPM6 reconciliation identity (Chapter 9) states:

    IIP_t = IIP_{t-1} + Flow_t + OtherChanges_t            ...(1)

where OtherChanges_t (OVAP) captures valuation effects (price and
exchange-rate changes), reclassifications, and statistical revisions
not recorded as transactions.

Rearranging (1):
    OtherChanges_t = ΔIIP_t − Flow_t                       ...(2)

To compare cumulated flows with the IIP change over the FULL PERIOD
(cumulated over the period) we construct:

    CumFlow_t = Σ Flow_s  for s = 2016 to t                ...(3)

    Residual_t = (IIP_t − IIP_2015) − CumFlow_t            ...(4)
               = ΔIIP since 2015  −  cumulated flows since 2015

This is the quantity that reconciles cumulated BOP flows with the
change in the IIP position.

INDEX CONSTRUCTION
===================
To make IIP (stock) and BOP (flow) variations directly comparable
on a single chart, both are expressed as index numbers, 2015 = 100:

  IIP_index_t   = IIP_t / IIP_2015 × 100
  BOP_index_t   = (IIP_2015 + CumFlow_t) / IIP_2015 × 100

The BOP index is the "flow-implied position": what the IIP stock would
be if only BOP-recorded transactions had driven it, anchored to the
actual 2015 level. Both indices therefore answer the same question:
"how large is the FDI position in year t relative to 2015?" — making
their divergence directly interpretable as accumulated OVAP.

TASK 3 – OUTPUT
================
  figure1_fdi_index.pdf    Chart 1: IIP index vs BOP cumulated-flows index
  figure2_fdi_residual.pdf Chart 2: Annual residual (ΔIIP_t − Flow_t)
=============================================================================
"""

import sys
import time
import warnings
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
from matplotlib.patches import Patch

try:
    import requests
except ImportError:
    print("Installing requests...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install",
                           "requests", "--break-system-packages", "-q"])
    import requests

# =============================================================================
# SECTION 0 – CONFIGURATION
# =============================================================================

IMF_BASE    = "http://dataservices.imf.org/REST/SDMX_JSON.svc"
COUNTRY     = "238"          # IMF numeric code for Costa Rica in BOP dataset
FREQ        = "Q"            # Quarterly – we aggregate to annual ourselves
BOP_IND     = "BFDI_BP6_USD" # BOP: Direct investment, net incurrence of liabilities
IIP_IND     = "ILFD_BP6_USD" # IIP: Liabilities, Direct investment (end-of-period)
START_YEAR  = 2015
MAX_RETRIES = 3
RETRY_WAIT  = 5              # seconds between retries

FIG1 = "figure1_fdi_index.pdf"
FIG2 = "figure2_fdi_residual.pdf"

# =============================================================================
# SECTION 1 – FALLBACK DATA  (BCCR, gee.bccr.fi.cr, accessed 2025-05-25)
# =============================================================================
# These values are used ONLY if the IMF API is unreachable.
# Source: Banco Central de Costa Rica (BCCR), the national compiler of BOP/IIP
# statistics for Costa Rica. BCCR reports under BPM6 and submits these figures
# to the IMF; the IMF redistributes them in the BOP/IIP dataset above.
# IIP series: "Inversión Directa en la economía declarante" (pasivos), annual
# BOP series: "Inversión directa en Costa Rica" (pasivos netos), annual
# Units: millions of US dollars | 2023–2024: preliminary figures

FALLBACK_BOP = {   # Annual net inward FDI flows (mn USD)
    2015: 2857.2, 2016: 2742.0, 2017: 3499.0, 2018: 3051.0, 2019: 2811.0,
    2020: 1698.0, 2021: 3233.0, 2022: 4111.0, 2023: 3853.0, 2024: 3848.0,
}
FALLBACK_IIP = {   # Annual end-of-year inward FDI stock (mn USD)
    2015: 34277.6, 2016: 37308.6, 2017: 40788.2, 2018: 44524.5, 2019: 47753.2,
    2020: 50128.6, 2021: 53154.9, 2022: 60356.6, 2023: 65656.1, 2024: 71059.5,
}

# =============================================================================
# SECTION 2 – IMF API: FETCH QUARTERLY DATA
# =============================================================================

def fetch_imf_quarterly(indicator: str, country: str,
                        start: int) -> pd.Series | None:
    """
    Fetch quarterly time series from IMF SDMX-JSON API.
    Returns a pandas Series indexed by 'YYYY-QN' strings, or None on failure.
    """
    url = (f"{IMF_BASE}/CompactData/BOP/"
           f"{FREQ}.{country}.{indicator}."
           f"?startPeriod={start}-Q1")

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = requests.get(url, timeout=60)
            resp.raise_for_status()
            raw  = resp.json()
            obs  = (raw["CompactData"]["DataSet"]["Series"]["Obs"])
            if isinstance(obs, dict):
                obs = [obs]
            records = {
                o["@TIME_PERIOD"]: float(o["@OBS_VALUE"])
                for o in obs
                if o.get("@OBS_VALUE") not in ("", None)
            }
            if records:
                return pd.Series(records, name=indicator)
        except requests.exceptions.ConnectionError:
            print(f"    Attempt {attempt}/{MAX_RETRIES}: connection error.")
        except requests.exceptions.HTTPError as e:
            print(f"    Attempt {attempt}/{MAX_RETRIES}: HTTP {e}.")
        except Exception as e:
            print(f"    Attempt {attempt}/{MAX_RETRIES}: {e}.")
        if attempt < MAX_RETRIES:
            time.sleep(RETRY_WAIT)
    return None


def quarterly_to_annual_flows(q_series: pd.Series,
                               start: int) -> pd.Series:
    """
    Aggregate quarterly BOP FLOWS to annual by SUMMING Q1+Q2+Q3+Q4.
    Justification: flows are additive across time sub-periods (BPM6 §3.7).
    Only complete years (all 4 quarters present) are retained.
    """
    records = {}
    for yr in range(start, 2030):
        quarters = [f"{yr}-Q{q}" for q in range(1, 5)]
        if all(q in q_series.index for q in quarters):
            records[yr] = sum(q_series[q] for q in quarters)
        else:
            break   # stop at first incomplete year
    return pd.Series(records, name="bop_flow_musd")


def quarterly_to_annual_stock(q_series: pd.Series,
                               start: int) -> pd.Series:
    """
    Aggregate quarterly IIP STOCK to annual by taking the Q4 (end-of-year) value.
    Justification: stocks represent a position at a point in time; the year-end
    value (31 December = Q4) is the standard annual benchmark (BPM6 §7.4).
    Averaging or summing quarterly stocks would be conceptually incorrect.
    """
    records = {}
    for yr in range(start, 2030):
        q4 = f"{yr}-Q4"
        if q4 in q_series.index:
            records[yr] = q_series[q4]
        else:
            break
    return pd.Series(records, name="iip_stock_musd")


# =============================================================================
# SECTION 3 – SIGN CONVENTION VERIFICATION
# =============================================================================

def verify_sign_convention(bop: pd.Series, iip: pd.Series) -> None:
    """
    Verify that BOP flows and IIP stock use compatible sign conventions.

    Under BPM6:
      BFDI_BP6_USD  = net incurrence of liabilities, direct investment
                      positive → Costa Rica received net inward FDI
      ILFD_BP6_USD  = IIP liabilities, direct investment
                      positive → outstanding inward FDI stock

    Both are measured from the LIABILITY side of Costa Rica's balance sheet.
    A sustained positive flow (BFDI) should be associated with a growing
    stock (ILFD). We verify this empirically:
      - majority of BOP flow observations should be positive (net inflows)
      - IIP stock should be consistently positive and generally increasing
      - correlation between cumulated flows and IIP stock should be high (>0.9)
    """
    common = bop.index.intersection(iip.index)
    bop_c  = bop.loc[common]
    iip_c  = iip.loc[common]

    pct_positive_bop = (bop_c > 0).mean()
    iip_increasing   = (iip_c.diff().dropna() > 0).mean()
    cum_flows        = bop_c.cumsum()
    correlation      = cum_flows.corr(iip_c)

    print("\n--- Sign Convention Verification ---")
    print(f"  BOP flows positive:         {pct_positive_bop:.0%} of years")
    print(f"  IIP stock increasing:       {iip_increasing:.0%} of years")
    print(f"  Corr(cumulated flows, IIP): {correlation:.4f}")

    if pct_positive_bop < 0.5:
        warnings.warn(
            "Majority of BOP flows are negative — sign inversion may be needed."
        )
        print("  *** WARNING: BOP sign may need inversion ***")
    elif correlation < 0.8:
        warnings.warn(
            "Low correlation between cumulated flows and IIP stock — "
            "check sign conventions."
        )
        print("  *** WARNING: Low correlation — check sign conventions ***")
    else:
        print("  ✓ Sign conventions are compatible. No adjustment required.")
        print("  ✓ Both series measure inward FDI from the liability side (BPM6).")


# =============================================================================
# SECTION 4 – MAIN DATA COLLECTION LOGIC
# =============================================================================

print("=" * 68)
print("Part 2 – Costa Rica: FDI, IIP vs Balance of Payments")
print("=" * 68)
print(f"\nPrimary source : IMF BOP/IIP SDMX-JSON API")
print(f"Fallback source: BCCR (gee.bccr.fi.cr), accessed 2025-05-25")
print(f"Country code   : {COUNTRY} (Costa Rica, IMF BOP dataset)")
print(f"Indicators     : {BOP_IND} (BOP flows), {IIP_IND} (IIP stock)")
print(f"Frequency      : Quarterly fetch → aggregated to Annual\n")

# --- Attempt IMF API ---
print("[1/4] Fetching quarterly BOP flows from IMF API...")
q_bop_raw = fetch_imf_quarterly(BOP_IND, COUNTRY, START_YEAR)

print("[2/4] Fetching quarterly IIP stock from IMF API...")
q_iip_raw = fetch_imf_quarterly(IIP_IND, COUNTRY, START_YEAR)

# --- Aggregate or fall back ---
use_fallback_bop = False
use_fallback_iip = False

if q_bop_raw is not None and not q_bop_raw.empty:
    print(f"      API OK: {len(q_bop_raw)} quarterly BOP observations")
    bop_annual = quarterly_to_annual_flows(q_bop_raw, START_YEAR)
    print(f"      Aggregated to annual (SUM Q1–Q4): {len(bop_annual)} years")
else:
    print("      API unreachable — using BCCR fallback data")
    bop_annual = pd.Series(FALLBACK_BOP, name="bop_flow_musd")
    use_fallback_bop = True

if q_iip_raw is not None and not q_iip_raw.empty:
    print(f"      API OK: {len(q_iip_raw)} quarterly IIP observations")
    iip_annual = quarterly_to_annual_stock(q_iip_raw, START_YEAR)
    print(f"      Aggregated to annual (Q4 end-of-year): {len(iip_annual)} years")
else:
    print("      API unreachable — using BCCR fallback data")
    iip_annual = pd.Series(FALLBACK_IIP, name="iip_stock_musd")
    use_fallback_iip = True

# --- Build unified DataFrame ---
df = pd.DataFrame({
    "flow": bop_annual,
    "iip" : iip_annual,
}).dropna()

# Determine actual end year from data
END_YEAR = int(df.index.max())
df = df.loc[START_YEAR:END_YEAR]

print(f"\n      Period covered: {START_YEAR}–{END_YEAR} "
      f"({'API' if not use_fallback_bop else 'BCCR fallback'} for BOP, "
      f"{'API' if not use_fallback_iip else 'BCCR fallback'} for IIP)")

print("\nRaw annual data (million USD):")
print(df.rename(columns={"flow":"BOP Flow (mn USD)",
                          "iip" :"IIP Stock (mn USD)"
                         }).to_string(float_format="{:,.1f}".format))

# =============================================================================
# SECTION 5 – SIGN CONVENTION VERIFICATION
# =============================================================================

print("\n[3/4] Verifying sign conventions...")
verify_sign_convention(df["flow"], df["iip"])

# =============================================================================
# SECTION 6 – INDICATOR CONSTRUCTION
# =============================================================================

print("\n[4/4] Constructing indicators and residual...\n")

# --- 6a. Annual change in IIP ---
df["delta_iip"] = df["iip"].diff()

# --- 6b. Annual residual: OtherChanges = ΔIIP_t − Flow_t ---
# Per BPM6 Ch.9: IIP_t = IIP_{t-1} + Flow_t + OtherChanges_t
# => OtherChanges_t = ΔIIP_t − Flow_t
# Positive: IIP grew more than flows (valuation gains, upward revisions)
# Negative: IIP grew less than flows (valuation losses, write-offs)
df["residual_annual"] = df["delta_iip"] - df["flow"]

# --- 6c. Cumulated flows since 2015, anchored to IIP_2015 ---
# This gives the "flow-implied position": the IIP level that would
# prevail if ONLY BOP-recorded transactions drove the position.
base_iip = float(df.loc[START_YEAR, "iip"])

df["iip_from_flows"] = np.nan
df.loc[START_YEAR, "iip_from_flows"] = base_iip
for yr in range(START_YEAR + 1, END_YEAR + 1):
    if yr in df.index:
        df.loc[yr, "iip_from_flows"] = (
            df.loc[yr - 1, "iip_from_flows"] + df.loc[yr, "flow"]
        )

# --- 6d. Period residual (cumulated): (IIP_t − IIP_2015) − CumFlows_t ---
# Reconciles BOP flows cumulated over the period with the CHANGE
# in the FDI position recorded in the IIP
df["residual_cumulated"] = (df["iip"] - base_iip) - (
    df["iip_from_flows"] - base_iip
)

# --- 6e. Index both series to 2015 = 100 ---
df["iip_index"]   = df["iip"]            / base_iip * 100
df["flows_index"] = df["iip_from_flows"] / base_iip * 100

# --- Print full results table ---
print("Full results table (million USD unless noted):\n")
print(f"{'Year':<6} {'BOP Flow':>10} {'IIP Stock':>11} {'IIP(flows)':>11} "
      f"{'ΔIIP':>10} {'Res.(ann.)':>11} {'IIP idx':>9} {'BOP idx':>9}")
print("-" * 80)
for yr in df.index:
    r   = df.loc[yr]
    d   = f"{r['delta_iip']:>10,.1f}"       if pd.notna(r['delta_iip'])       else f"{'N/A':>10}"
    ra  = f"{r['residual_annual']:>11,.1f}"  if pd.notna(r['residual_annual'])  else f"{'N/A':>11}"
    print(f"{yr:<6} {r['flow']:>10,.1f} {r['iip']:>11,.1f} "
          f"{r['iip_from_flows']:>11,.1f} {d} {ra} "
          f"{r['iip_index']:>9.2f} {r['flows_index']:>9.2f}")

print("-" * 80)
post = df.loc[START_YEAR + 1:]
tot_flow = post["flow"].sum()
tot_diip = post["delta_iip"].sum()
tot_res  = post["residual_annual"].dropna().sum()
print(f"\nCumulated BOP flows  {START_YEAR+1}–{END_YEAR}: ${tot_flow:>10,.1f} mn")
print(f"Total ΔIIP           {START_YEAR+1}–{END_YEAR}: ${tot_diip:>10,.1f} mn")
print(f"Total residual(OVAP) {START_YEAR+1}–{END_YEAR}: ${tot_res:>10,.1f} mn  "
      f"({tot_res/tot_diip*100:.1f}% of ΔIIP)")
print(f"IIP 2015: ${base_iip:,.1f} mn  →  IIP {END_YEAR}: "
      f"${df.loc[END_YEAR,'iip']:,.1f} mn  "
      f"(+{(df.loc[END_YEAR,'iip']/base_iip-1)*100:.1f}%)")

# =============================================================================
# SECTION 7 – FIGURE 1: IIP INDEX vs BOP CUMULATED-FLOWS INDEX (2015=100)
# =============================================================================

plt.rcParams.update({
    "font.family"      : "serif",
    "font.size"        : 10,
    "axes.titlesize"   : 11,
    "axes.titleweight" : "bold",
    "axes.labelsize"   : 9,
    "axes.spines.top"  : False,
    "axes.spines.right": False,
    "legend.frameon"   : False,
    "legend.fontsize"  : 9,
    "lines.linewidth"  : 2.0,
    "grid.alpha"       : 0.35,
    "grid.linewidth"   : 0.6,
})

years = df.index.tolist()
src_note = ("Source: IMF BOP/IIP dataset (SDMX-JSON API)"
            if not (use_fallback_bop and use_fallback_iip)
            else "Source: BCCR – Banco Central de Costa Rica (fallback)")

fig1, ax1 = plt.subplots(figsize=(8, 4.8))

ax1.plot(years, df["iip_index"],
         color="#1a5276", marker="o", markersize=5, linewidth=2,
         label=f"IIP – Inward FDI position\n({IIP_IND})")

ax1.plot(years, df["flows_index"],
         color="#c0392b", marker="s", markersize=5,
         linewidth=2, linestyle="--",
         label=f"BOP – Cumulated inward FDI flows\n({BOP_IND}, anchored to IIP 2015)")

ax1.axhline(100, color="#888", linewidth=0.8, linestyle=":")

ax1.fill_between(years,
                 df["iip_index"], df["flows_index"],
                 where=(df["iip_index"] >= df["flows_index"]),
                 alpha=0.10, color="#1a5276",
                 label="Accumulated OVAP > 0")
ax1.fill_between(years,
                 df["iip_index"], df["flows_index"],
                 where=(df["iip_index"] < df["flows_index"]),
                 alpha=0.10, color="#c0392b",
                 label="Accumulated OVAP < 0")

ax1.set_title(
    f"Costa Rica – Inward FDI: IIP Position vs Cumulated BOP Flows\n"
    f"Index, {START_YEAR} = 100  |  {src_note}  |  BPM6"
)
ax1.set_xlabel("Year")
ax1.set_ylabel(f"Index  ({START_YEAR} = 100)")
ax1.set_xticks(years)
ax1.set_xticklabels(years, rotation=45)
ax1.yaxis.set_major_formatter(mticker.FormatStrFormatter("%.0f"))
ax1.legend(loc="upper left", fontsize=8.5)
ax1.grid(axis="y")

ax1.annotate(
    f"IIP index = IIP$_t$ / IIP$_{{\\mathbf{{{START_YEAR}}}}}$ × 100\n"
    f"BOP index = (IIP$_{{{START_YEAR}}}$ + $\\Sigma$ Flow$_{{s={START_YEAR+1}}}^t$)"
    f" / IIP$_{{{START_YEAR}}}$ × 100\n"
    f"Aggregation: BOP annual = $\\Sigma$ quarterly flows; "
    f"IIP annual = Q4 end-of-year value",
    xy=(0.01, 0.02), xycoords="axes fraction",
    fontsize=7, color="#444", va="bottom",
)

fig1.tight_layout()
fig1.savefig(FIG1, dpi=150, bbox_inches="tight")
plt.close(fig1)
print(f"\nSaved: {FIG1}")

# =============================================================================
# SECTION 8 – FIGURE 2: ANNUAL RESIDUAL  (ΔIIP_t − Flow_t)
# =============================================================================

res_yrs = df.dropna(subset=["residual_annual"]).index.tolist()
res_val = df.loc[res_yrs, "residual_annual"].values
colors  = ["#1a5276" if v >= 0 else "#c0392b" for v in res_val]

fig2, ax2 = plt.subplots(figsize=(8, 4.8))

ax2.bar(res_yrs, res_val, color=colors, width=0.6,
        edgecolor="white", linewidth=0.5, zorder=3)
ax2.axhline(0, color="black", linewidth=0.9, zorder=4)

cum_res = float(res_val.sum())
ax2.annotate(
    f"Cumulative residual {res_yrs[0]}–{res_yrs[-1]}:\n${cum_res:,.0f}M  "
    f"({cum_res / df.loc[START_YEAR+1:END_YEAR,'delta_iip'].sum()*100:.1f}% of ΔIIP)",
    xy=(0.97, 0.97), xycoords="axes fraction",
    fontsize=8.5, ha="right", va="top",
    bbox=dict(boxstyle="round,pad=0.35", facecolor="#f5f5f5",
              edgecolor="#cccccc", alpha=0.95),
)

ax2.set_title(
    f"Costa Rica – Other Changes in Position (OVAP / Residual)\n"
    r"$\Delta$IIP$_t$ $-$ BOP Flow$_t$  "
    f"|  {src_note}  |  BPM6 Ch. 9"
)
ax2.set_xlabel("Year")
ax2.set_ylabel("Millions USD")
ax2.set_xticks(res_yrs)
ax2.set_xticklabels(res_yrs, rotation=45)
ax2.yaxis.set_major_formatter(
    mticker.FuncFormatter(lambda x, _: f"${x:,.0f}M"))
ax2.grid(axis="y", zorder=0)

legend_elements = [
    Patch(facecolor="#1a5276",
          label="Positive OVAP: IIP grew faster than flows\n"
                "(valuation gains, upward statistical revisions)"),
    Patch(facecolor="#c0392b",
          label="Negative OVAP: flows exceeded IIP growth\n"
                "(valuation losses, downward revisions)"),
]
ax2.legend(handles=legend_elements, loc="upper left", fontsize=8.5)

ax2.annotate(
    "Residual$_t$ = $\\Delta$IIP$_t$ $-$ Flow$_t$ "
    "(Other Changes in Position, BPM6 §9.3).\n"
    "Captures price changes, exchange-rate movements, "
    "reclassifications and statistical revisions.",
    xy=(0.01, 0.02), xycoords="axes fraction",
    fontsize=7, color="#444", va="bottom",
)

fig2.tight_layout()
fig2.savefig(FIG2, dpi=150, bbox_inches="tight")
plt.close(fig2)
print(f"Saved: {FIG2}")
print("\nScript completed successfully.")
