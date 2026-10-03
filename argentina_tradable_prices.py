# =============================================================================
# argentina_tradable_prices.py
# Author: Camila Aguirre Diaz
# Argentina: Tradable and Non-Tradable Consumer Prices (2010 – present)
#
# SOURCE: INDEC – Instituto Nacional de Estadistica y Censos (official)
#         https://www.indec.gob.ar
#
# CLASSIFICATION:
#   Tradable     = Bienes   (goods)
#   Non-Tradable = Servicios (services)
#   Justification: Balassa-Samuelson framework. Goods prices are arbitraged
#   internationally via the exchange rate; service prices are set locally.
#   INDEC itself publishes this Bienes/Servicios split officially.
#
# DATA SOURCES:
#   sh_ipc_aperturas.xls  sheet "Indices aperturas"
#     Dec 2016 – present: indices by division, Total Nacional, base Dec 2016=100
#   sh_ipc_12_16.xls
#     Apr–Nov 2016: direct Bienes/Servicios rows, base Dec 2016=100
#
# PRE-2016 BACKCAST (Jan 2010 – Mar 2016):
#   Log-linear trend fitted on the observed Apr–Nov 2016 window.
#   Model: ln(P_t) = a + b*t  =>  constant monthly growth rate b.
#   Backcast: P_{t-k} = P_apr2016 * exp(-b*k)
#   The estimated monthly rates (~2–3%) are consistent with Argentina's
#   ~25–35% annual inflation in 2010–2016. Declared in report as backward
#   extrapolation under constant-growth assumption.
#
# OUTPUTS:
#   fig1_yoy_inflation.pdf / .png
#   fig2_monthly_incidence.pdf / .png
#   ipc_tradable_nontradable.csv
# =============================================================================

import io, warnings, unicodedata
warnings.filterwarnings("ignore")

import requests, xlrd
import numpy as np
import pandas as pd
from numpy.linalg import lstsq
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import matplotlib.dates as mdates

plt.rcParams.update({
    "font.family"      : "DejaVu Sans",
    "axes.spines.top"  : False,
    "axes.spines.right": False,
    "axes.grid"        : True,
    "grid.alpha"       : 0.3,
    "grid.linestyle"   : "--",
    "figure.dpi"       : 150,
})
COLOR_T  = "#E05C30"
COLOR_NT = "#2B6CB0"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
    ),
    "Referer": "https://www.indec.gob.ar/",
}
URL_AP   = "https://www.indec.gob.ar/ftp/cuadros/economia/sh_ipc_aperturas.xls"
URL_HIST = "https://www.indec.gob.ar/ftp/cuadros/economia/sh_ipc_12_16.xls"

# Weights base Dec 2016, Total Nacional (INDEC Ponderaciones sheet)
POND_BIENES = {
    "alimentos y bebidas no alcoholicas"     : 20.40,
    "bebidas alcoholicas y tabaco"           :  3.09,
    "prendas de vestir y calzado"            :  5.53,
    "equipamiento y mantenimiento del hogar" :  5.49,
}
POND_SERVICIOS = {
    "vivienda, agua, electricidad, gas y otros combustibles": 14.01,
    "salud"                  :  9.51,
    "transporte"             : 11.34,
    "comunicacion"           :  3.36,
    "recreacion y cultura"   :  7.68,
    "educacion"              :  6.46,
    "restaurantes y hoteles" :  8.47,
    "bienes y servicios varios": 4.66,
}
W_B = sum(POND_BIENES.values())
W_S = sum(POND_SERVICIOS.values())

# =============================================================================
# HELPERS
# =============================================================================

def download(url):
    print(f"  GET {url.split('/')[-1]} ...", flush=True)
    r = requests.get(url, headers=HEADERS, timeout=120, verify=False)
    r.raise_for_status()
    if len(r.content) < 5000:
        raise ValueError(f"File too small ({len(r.content)} bytes) — "
                         "possible HTML redirect.")
    return r.content

def norm(s):
    s = str(s).strip().lower()
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn")

# =============================================================================
# 1.  LOAD sh_ipc_aperturas.xls  sheet "Indices aperturas"
#     Dec 2016 – present, Total Nacional
# =============================================================================

def load_aperturas(raw):
    wb = xlrd.open_workbook(file_contents=raw)
    sh = wb.sheet_by_name("Índices aperturas")

    # Date row = 5 (Excel serials)
    dates = []
    for c in range(1, sh.ncols):
        v = sh.cell_value(5, c)
        if isinstance(v, float) and v > 40000:
            dates.append(pd.Timestamp(xlrd.xldate_as_datetime(v, wb.datemode)))
        else:
            dates.append(None)
    while dates and dates[-1] is None:
        dates.pop()
    dates = pd.DatetimeIndex(dates)
    n = len(dates)
    print(f"  Dates: {dates[0].strftime('%Y-%m')} → "
          f"{dates[-1].strftime('%Y-%m')} ({n} months)")

    # Find Total Nacional block
    total_row = None
    for i in range(sh.nrows):
        v = norm(str(sh.cell_value(i, 0)))
        if "total" in v and "nacional" in v:
            total_row = i
            break
    if total_row is None:
        ng_rows = [i for i in range(sh.nrows)
                   if "nivel" in norm(str(sh.cell_value(i, 0)))
                   and "general" in norm(str(sh.cell_value(i, 0)))]
        total_row = (ng_rows[-1] - 1) if ng_rows else 0
    print(f"  Total Nacional block at row {total_row}")

    # Read all rows in block
    block = {}
    for i in range(total_row, min(total_row + 80, sh.nrows)):
        label = sh.cell_value(i, 0)
        if not isinstance(label, str) or not label.strip():
            continue
        vals = np.array([
            float(sh.cell_value(i, c))
            if isinstance(sh.cell_value(i, c), (int, float)) else np.nan
            for c in range(1, n + 1)
        ])
        block[norm(label)] = vals

    # Try direct Bienes/Servicios rows first
    bi = next((block[k] for k in block if norm(k).strip() == "bienes"), None)
    sv = next((block[k] for k in block if norm(k).strip() == "servicios"), None)
    ng = next((block[k] for k in block
               if "nivel" in k and "general" in k), None)

    if bi is not None and sv is not None:
        print("  Direct Bienes/Servicios rows found.")
    else:
        print("  Aggregating from divisions ...")
        def wavg(pond):
            arrs, ws = [], []
            for key, w in pond.items():
                match = next((k for k in block if key in k or k in key), None)
                if match:
                    arrs.append(block[match])
                    ws.append(w)
            if not arrs:
                return np.full(n, np.nan)
            W  = np.array(ws)
            M  = np.vstack(arrs)
            denom = np.nansum(W[:, None] * (~np.isnan(M)), axis=0)
            denom[denom == 0] = np.nan
            return np.nansum(M * W[:, None], axis=0) / denom
        bi = wavg(POND_BIENES)
        sv = wavg(POND_SERVICIOS)
        if ng is None:
            ng = wavg({**POND_BIENES, **POND_SERVICIOS})

    return pd.DataFrame(
        {"bienes": bi, "servicios": sv, "nivel_general": ng},
        index=dates)

# =============================================================================
# 2.  LOAD sh_ipc_12_16.xls  (Apr–Nov 2016, base Dec 2016 = 100)
# =============================================================================

def load_gba2016(raw):
    wb = xlrd.open_workbook(file_contents=raw)
    sh = wb.sheet_by_index(0)

    dates = []
    for c in range(1, sh.ncols):
        v = sh.cell_value(3, c)
        if isinstance(v, float) and v > 40000:
            dates.append(pd.Timestamp(xlrd.xldate_as_datetime(v, wb.datemode)))
    dates = pd.DatetimeIndex(dates)
    n = len(dates)

    row_bi, row_sv, row_ng = None, None, None
    for i in range(sh.nrows):
        v = norm(str(sh.cell_value(i, 0)))
        if v.strip() == "bienes":              row_bi = i
        elif v.strip() == "servicios":         row_sv = i
        elif "nivel" in v and "general" in v:  row_ng = i

    def get(row):
        return np.array([
            float(sh.cell_value(row, c))
            if isinstance(sh.cell_value(row, c), (int, float)) else np.nan
            for c in range(1, n + 1)
        ]) if row is not None else np.full(n, np.nan)

    df = pd.DataFrame(
        {"bienes": get(row_bi), "servicios": get(row_sv),
         "nivel_general": get(row_ng)}, index=dates)
    print(f"  GBA: {dates[0].strftime('%Y-%m')} → "
          f"{dates[-1].strftime('%Y-%m')} ({n} months)")
    print(f"  Bienes:    {np.round(df['bienes'].values, 2)}")
    print(f"  Servicios: {np.round(df['servicios'].values, 2)}")
    return df

# =============================================================================
# 3.  LOG-LINEAR TREND BACKCAST  Jan 2010 – Mar 2016
#
#  Fit log(P_t) = a + b*t on the Apr–Nov 2016 window (8 real obs).
#  b = average monthly log-growth rate estimated from real data.
#  Backcast: P_{t-k} = P_apr2016 * exp(-b * k)
#  Annualised rates should be ~25-35%, consistent with 2010-2016 Argentina.
# =============================================================================

def trend_backcast(df_gba):
    back_dates = pd.date_range("2010-01-01", "2016-03-01", freq="MS")
    n_back     = len(back_dates)   # 75 months
    results    = {}

    print("  Log-linear trend estimates (from Apr–Nov 2016 window):")
    for col in ["bienes", "servicios", "nivel_general"]:
        series = df_gba[col].dropna()
        log_p  = np.log(series.values.astype(float))
        t_obs  = np.arange(len(log_p))

        # OLS: log(P) = a + b*t
        A_mat        = np.column_stack([np.ones(len(t_obs)), t_obs])
        coef, _, _, _ = lstsq(A_mat, log_p, rcond=None)
        b            = coef[1]
        monthly_pct  = (np.exp(b) - 1) * 100
        annual_pct   = ((1 + monthly_pct / 100) ** 12 - 1) * 100
        print(f"    {col:25s}: {monthly_pct:.2f}%/month  "
              f"({annual_pct:.1f}%/year)")

        # Anchor = Apr 2016 (first observed value)
        anchor_val = float(series.iloc[0])

        # Backcast each month
        idx = np.array([
            anchor_val * np.exp(-b * (
                (df_gba.index[0].year  - d.year)  * 12 +
                (df_gba.index[0].month - d.month)
            ))
            for d in back_dates
        ])
        results[col] = idx

    return pd.DataFrame(results, index=back_dates)

# =============================================================================
# MAIN
# =============================================================================

print("=" * 60)
print("Argentina CPI – Tradable vs Non-Tradable")
print("Source: INDEC (official)")
print("=" * 60)

print("\n[1/4] Downloading files ...")
raw_ap   = download(URL_AP)
raw_hist = download(URL_HIST)

print("\n[2/4] Parsing data ...")
df_nac = load_aperturas(raw_ap)
df_gba = load_gba2016(raw_hist)

print("\n[3/4] Log-linear trend backcast Jan 2010 – Mar 2016 ...")
df_back = trend_backcast(df_gba)

# Stitch: backcast + GBA Apr–Nov 2016 + NAC Dec 2016 – present
df_full = pd.concat([df_back, df_gba, df_nac]).sort_index()
df_full = df_full[~df_full.index.duplicated(keep="last")]

# Rebase to January 2010 = 100
BASE = pd.Timestamp("2010-01-01")
for col, new in [("bienes",        "bienes_idx"),
                 ("servicios",     "servicios_idx"),
                 ("nivel_general", "nivel_general_idx")]:
    df_full[new] = df_full[col] / df_full.loc[BASE, col] * 100

expected = pd.date_range(df_full.index[0], df_full.index[-1], freq="MS")
missing  = expected.difference(df_full.index)
print(f"\n  Full series: {df_full.index[0].strftime('%b %Y')} → "
      f"{df_full.index[-1].strftime('%b %Y')} "
      f"({len(df_full)} months, {len(missing)} missing)")

# Sanity check: Dec 2016 should be ~450–700 if base Jan2010=100
dec16 = pd.Timestamp("2016-12-01")
print(f"  Dec 2016 index: bienes={df_full.loc[dec16,'bienes_idx']:.1f}  "
      f"servicios={df_full.loc[dec16,'servicios_idx']:.1f}  "
      f"(expected 450–700)")

# =============================================================================
# DERIVED SERIES
# =============================================================================

df_full["yoy_bienes"]    = df_full["bienes_idx"].pct_change(12) * 100
df_full["yoy_servicios"] = df_full["servicios_idx"].pct_change(12) * 100
df_full["yoy_ng"]        = df_full["nivel_general_idx"].pct_change(12) * 100

df_full["mom_bienes"]    = df_full["bienes_idx"].pct_change(1) * 100
df_full["mom_servicios"] = df_full["servicios_idx"].pct_change(1) * 100
df_full["mom_ng"]        = df_full["nivel_general_idx"].pct_change(1) * 100

W_BIENES    = W_B / (W_B + W_S) * 100
W_SERVICIOS = W_S / (W_B + W_S) * 100
df_full["inc_bienes"]    = (W_BIENES    / 100) * df_full["mom_bienes"]
df_full["inc_servicios"] = (W_SERVICIOS / 100) * df_full["mom_servicios"]

# =============================================================================
# FIGURE 1 – Year-on-Year Inflation
# =============================================================================

print("\n[4/4] Generating figures ...")

SPLICE       = pd.Timestamp("2016-12-01")
BACKCAST_END = pd.Timestamp("2016-03-01")
df_p = df_full.dropna(subset=["yoy_bienes", "yoy_servicios"]).copy()

fig1, ax1 = plt.subplots(figsize=(13, 5.5))

# Shade backcast region
ax1.axvspan(df_p.index[0], BACKCAST_END, color="gray", alpha=0.08,
            label="_nolegend_")
ax1.text(pd.Timestamp("2012-06-01"), 5,
         "← trend extrapolation", fontsize=7.5, color="gray", va="bottom")

# Series
ax1.plot(df_p.index, df_p["yoy_bienes"],
         color=COLOR_T,  lw=1.7, label="Bienes (tradable)")
ax1.plot(df_p.index, df_p["yoy_servicios"],
         color=COLOR_NT, lw=1.7, ls="--", label="Servicios (non-tradable)")

ax1.axvline(SPLICE, color="gray", lw=0.9, ls=":", alpha=0.7)
ax1.axhline(0, color="black", lw=0.4)

ymax = df_p[["yoy_bienes","yoy_servicios"]].max().max()
ax1.text(SPLICE + pd.DateOffset(months=1), ymax * 0.93,
         "Splice\nDec 2016", fontsize=7.5, color="gray", va="top")

ax1.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x,_: f"{x:.0f}%"))
ax1.set_title(
    "Argentina – Year-on-Year CPI Inflation\n"
    "Bienes (Tradable) vs. Servicios (Non-Tradable)",
    fontsize=12, fontweight="bold", pad=10)
ax1.set_xlabel("Date")
ax1.set_ylabel("YoY change (%)")
ax1.legend(loc="upper left", fontsize=9)
ax1.set_xlim(df_p.index[0], df_p.index[-1])
ax1.annotate(
    "Sources: INDEC sh_ipc_aperturas.xls (IPC Nacional, base Dec 2016=100) and "
    "sh_ipc_12_16.xls (IPC-GBA, Apr–Nov 2016). Base Jan 2010 = 100.\n"
    "Shaded area: Jan 2010–Mar 2016 backcasted via log-linear trend fitted "
    "on Apr–Nov 2016 GBA window.",
    xy=(0.01, 0.01), xycoords="axes fraction",
    fontsize=7, color="gray", va="bottom")

fig1.tight_layout()
fig1.savefig("fig1_yoy_inflation.pdf", bbox_inches="tight")
fig1.savefig("fig1_yoy_inflation.png", bbox_inches="tight", dpi=150)
print("  Saved fig1_yoy_inflation.pdf / .png")

# =============================================================================
# FIGURE 2 – Monthly Incidence (last 5 years)
# =============================================================================

df_inc = df_full.dropna(subset=["inc_bienes","inc_servicios"]).iloc[-60:]

fig2, ax2 = plt.subplots(figsize=(15, 5.5))
dn = mdates.date2num(df_inc.index.to_pydatetime())
BW = 18

b_pos = np.maximum(df_inc["inc_bienes"].values,    0)
b_neg = np.minimum(df_inc["inc_bienes"].values,    0)
s_pos = np.maximum(df_inc["inc_servicios"].values, 0)
s_neg = np.minimum(df_inc["inc_servicios"].values, 0)

ax2.bar(dn, b_pos, BW, color=COLOR_T,  label="Bienes (tradable)")
ax2.bar(dn, s_pos, BW, color=COLOR_NT, label="Servicios (non-tradable)",
        bottom=b_pos)
ax2.bar(dn, b_neg, BW, color=COLOR_T,  alpha=0.7)
ax2.bar(dn, s_neg, BW, color=COLOR_NT, bottom=b_neg, alpha=0.7)
ax2.plot(dn, df_inc["mom_ng"].values,
         color="black", lw=1.2, marker=".", ms=3,
         label="Nivel general (total)", zorder=5)

ax2.xaxis_date()
ax2.xaxis.set_major_formatter(mdates.DateFormatter("%b\n%Y"))
ax2.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1, 7]))
ax2.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x,_: f"{x:.1f}%"))
ax2.axhline(0, color="black", lw=0.6)
ax2.set_title(
    "Argentina – Monthly CPI Incidence by Component\n"
    "Bienes (Tradable) vs. Servicios (Non-Tradable)",
    fontsize=12, fontweight="bold", pad=10)
ax2.set_xlabel("Date")
ax2.set_ylabel("Monthly contribution (pp)")
ax2.legend(loc="upper left", fontsize=9)
ax2.set_xlim(dn[0] - 30, dn[-1] + 30)
s0 = df_inc.index[0].strftime("%b %Y")
s1 = df_inc.index[-1].strftime("%b %Y")
ax2.annotate(
    f"Period: {s0}–{s1}.  "
    f"Weights: Bienes {W_BIENES:.1f}%, Servicios {W_SERVICIOS:.1f}% "
    "(INDEC, base Dec 2016).\nSource: INDEC sh_ipc_aperturas.xls.",
    xy=(0.01, 0.01), xycoords="axes fraction",
    fontsize=7, color="gray", va="bottom")

fig2.tight_layout()
fig2.savefig("fig2_monthly_incidence.pdf", bbox_inches="tight")
fig2.savefig("fig2_monthly_incidence.png", bbox_inches="tight", dpi=150)
print("  Saved fig2_monthly_incidence.pdf / .png")

# =============================================================================
# EXPORT CSV
# =============================================================================
out = ["bienes_idx","servicios_idx","nivel_general_idx",
       "yoy_bienes","yoy_servicios","yoy_ng",
       "mom_bienes","mom_servicios","mom_ng",
       "inc_bienes","inc_servicios"]
df_full[out].to_csv("ipc_tradable_nontradable.csv", float_format="%.4f")
print("  Saved ipc_tradable_nontradable.csv")
print("\nDone.")
