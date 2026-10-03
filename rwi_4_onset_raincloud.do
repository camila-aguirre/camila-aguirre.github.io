////////////////////////////////////////////////////////////////////
// HORIZONTAL RAINCLOUD - SEASONAL DISTRIBUTION OF ONSET (DAY-OF-YEAR)
// Rows: CHIRPS, GSMAP, MSWEP, TAMSAT - SINGLE PLOT 2010-2023
// X axis: day within the rainy season (not raw calendar date)
// VERSION: DISTRIBUTION ONLY (no boxplot)
////////////////////////////////////////////////////////////////////

*** FIRST ONSET ANALYSIS VARIABLE
clear all
version 16.1
set more off
capture log close

////////////////////////////////
// 0. GLOBALS
////////////////////////////////

global dir "."   // change to your project folder
	global data "$dir/DATA"
	global res "$dir/RESULTS"
	global log "$dir/LOGS"
	global Graph "$dir/GRAPHS"

	set more off

////////////////////////////////
// DATA PREPARATION
////////////////////////////////

use "$data/temp_irregular_rainfall_data_treated_merged_2010-2024", replace

keep if inrange(year_original, 2010, 2023)

bysort ea_id: egen aez_fill = min(AEZ)
replace AEZ = aez_fill if missing(AEZ)
drop aez_fill

collapse (first) first_onset first_onset_chirps first_onset_gsmap first_onset_mswep first_onset_tamsat AEZ , by(ea_id year_original)

label define aez_lbl 1 "Groundnut Basin" ///
                     2 "Senegal River Valley" ///
                     3 "Casamance" ///
                     4 "Central & Southeast" ///
                     5 "Pastoral Zone"

label values AEZ aez_lbl

* ==========================================================
* 2. Ensure date format (in case variables are still string)
* ==========================================================
foreach var of varlist first_onset_chirps first_onset_gsmap first_onset_mswep first_onset_tamsat {
    capture confirm numeric variable `var'
    if _rc {
        gen `var'_d = date(`var', "DMY")
        format `var'_d %td
        drop `var'
        rename `var'_d `var'
    }
}

* ==========================================================
* 3. Differences in days vs. base (CHIRPS)
* ==========================================================
gen diff_gsmap  = first_onset_gsmap  - first_onset_chirps
gen diff_mswep  = first_onset_mswep  - first_onset_chirps
gen diff_tamsat = first_onset_tamsat - first_onset_chirps

label var diff_gsmap  "GSMAP - Base"
label var diff_mswep  "MSWEP - Base"
label var diff_tamsat "TAMSAT - Base"

tempfile wide
save `wide'

* ==========================================================
* 1. Stack the 4 onset dates (using day-of-year to collapse into 1 season)
* ==========================================================
use `wide', clear

preserve
    gen dataset = "CHIRPS"
    gen date_raw = first_onset_chirps
    keep year_original AEZ dataset date_raw
    tempfile e1
    save `e1'
restore

preserve
    gen dataset = "GSMAP"
    gen date_raw = first_onset_gsmap
    keep year_original AEZ dataset date_raw
    tempfile e2
    save `e2'
restore

preserve
    gen dataset = "MSWEP"
    gen date_raw = first_onset_mswep
    keep year_original AEZ dataset date_raw
    tempfile e3
    save `e3'
restore

preserve
    gen dataset = "TAMSAT"
    gen date_raw = first_onset_tamsat
    keep year_original AEZ dataset date_raw
    tempfile e4
    save `e4'
restore

use `e1', clear
append using `e2'
append using `e3'
append using `e4'

format date_raw %td

* ---------- KEY STEP: convert to "day of year" to collapse the 14 years ----------
* Assumes the onset falls within a single calendar year (e.g. May-Sept),
* without crossing December-January. If it does cross, flag it to adjust the formula.
drop if missing(date_raw)
gen doy  = date_raw - mdy(1,1,year(date_raw)) + 1
gen date = mdy(1,1,2000) + doy - 1
format date %td

tempfile stacked_dates
save `stacked_dates'

* ==========================================================
* 2. Row position by dataset (4 rows)
* ==========================================================
gen row = .
replace row = 4 if dataset == "CHIRPS"
replace row = 3 if dataset == "GSMAP"
replace row = 2 if dataset == "MSWEP"
replace row = 1 if dataset == "TAMSAT"

tempfile base_allyears
save `base_allyears'

* ==========================================================
* 3. SINGLE PLOT FOR THE WHOLE PERIOD
* ==========================================================

use `base_allyears', clear

* ---------- 3a. Density by row ----------
tempfile dens
local firstd = 1
forvalues r = 1/4 {
    preserve
        keep if row == `r'
        quietly count
        if r(N) > 1 {
            quietly kdensity date, n(300) generate(x_val densv) nograph
            quietly summarize densv
            gen y_base = `r'
            gen y_top  = `r' + 0.8 * densv / r(max)
            keep x_val y_base y_top
            gen row = `r'
            if `firstd' == 1 {
                save `dens', replace
                local firstd = 0
            }
            else {
                append using `dens'
                save `dens', replace
            }
        }
    restore
}

* ---------- 3b. Horizontal baseline per row ----------
use `base_allyears', clear
quietly summarize date
local xmin = r(min) - 5
local xmax = r(max) + 5

clear
set obs 8
gen row    = ceil(_n/2)
gen x_line = cond(mod(_n,2)==1, `xmin', `xmax')
gen y_line = row
tempfile baseline
save `baseline'

* ---------- 3c. Rug plot (individual dates within the season) ----------
use `base_allyears', clear
gen y_lo = row - 0.05
gen y_hi = row + 0.05
tempfile rug
save `rug'

* ---------- 3d. Stack everything (WITHOUT boxst) ----------
use `dens', clear
append using `baseline'
append using `rug'

* ---------- 3e. Plot ----------
local col1 "teal"     // TAMSAT
local col2 "purple"   // MSWEP
local col3 "orange"   // GSMAP
local col4 "navy"     // CHIRPS

local arealayers ""
local baselayers ""
forvalues r = 1/4 {
    local arealayers `arealayers' (rarea y_base y_top x_val if row==`r', color(`col`r''%45) lcolor(`col`r''))
    local baselayers `baselayers' (line y_line x_line if row==`r', lcolor(`col`r'') lwidth(thin))
}

twoway ///
    `arealayers' ///
    `baselayers' ///
    (rspike y_lo y_hi date, lcolor(gs8) lwidth(vthin)) ///
    , ///
    ylabel(1 "TAMSAT" 2 "MSWEP" 3 "GSMAP" 4 "CHIRPS", angle(0) noticks) ///
    ytitle("") ///
    xtitle("Onset timing within rainy season") ///
    xlabel(, format(%tdMon_DD) angle(45) labsize(vsmall)) ///
    title("Distribution of onset timing within rainy season - 2010-2023") ///
    note("Dates collapsed to a generic year to reflect seasonality (2010-2023 stacked)") ///
    legend(off) ///
    yscale(range(0.5 4.8))

graph export "$Graph/raincloud_dist_season_2010-2023.png", replace width(2200)
