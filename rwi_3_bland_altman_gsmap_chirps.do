**********************************************
* GSMAP and CHIRPS Data / BLAND ALMATPLOTS
************************************************* 
clear all
set more off

global dir "."   // change to your project folder
	global data "$dir/DATA" 		// where data is saved
	global dofiles "$dir/DO_FILES"  // where Do-File should be saved
	global res "$dir/RESULTS" 		// where results should be saved
	global log "$dir/LOGS" 			// where Log-File should be saved
	global Graph "$dir/GRAPHS" 

**log using "$log/RWI_1.log",replace // create new Log-File
	set more off
	

* Load data
use "$data/merge_CHIRPS_GSMAP_Senegal_Villages_2010_2024.dta", replace

***
preserve
* Keep only observations with both available values
drop if missing(gsmap_rain) | missing(chirps_rain)

* Bland-Altman variables
gen ba_avg  = (gsmap_rain + chirps_rain) / 2
gen ba_diff = gsmap_rain - chirps_rain
label variable ba_avg  "Average of GSMAP and CHIRPS"
label variable ba_diff "Difference: gsmap - CHIRPS"

* Bias and limits of agreement
summ ba_diff, detail
local mean_diff = r(mean)
local sd_diff   = r(sd)

local lower = `mean_diff' - 1.96 * `sd_diff'
local upper = `mean_diff' + 1.96 * `sd_diff'

* Percentage outside LoA
gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
label variable outside_loa "Outside limits of agreement"
summ outside_loa, meanonly
local pct_outside = 100 * r(mean)

display "Bias = " %9.4f `mean_diff'
display "Lower  = " %9.4f `lower'
display "Upper  = " %9.4f `upper'
display "Percent outside LoA = " %6.2f `pct_outside' "%"

* Lines for the graph
gen bias_line  = `mean_diff'
gen lower_line = `lower'
gen upper_line = `upper'

* Sort by ba_avg
sort ba_avg

* Adjust Y-axis range so the graph does not look disproportionate
summ ba_diff, meanonly
local absdiff = max(abs(r(min)), abs(r(max)))
if missing(`absdiff') local absdiff = 1

* Bland-Altman graph
twoway ///
  (scatter ba_diff ba_avg, mcolor(navy) msize(vsmall) msymbol(circle_hollow)) ///
  (line bias_line  ba_avg, sort lcolor(black) lwidth(medium)) ///
  (line lower_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)) ///
  (line upper_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)), ///
  title("Bland-Altman Plot: GSMAP vs CHIRPS") ///
  subtitle("Daily rainfall comparison") ///
  xtitle("Average rainfall: (GSMAP + CHIRPS)/2") ///
  ytitle("Difference: GSMAP - CHIRPS") ///
  yscale(range(-`absdiff' `absdiff')) ///
  legend(order(1 "Observations" 2 "Bias" 3 "Lower " 4 "Upper ") rows(1) size(small)) ///
  note("Bias = `mean_diff'   Lower  = `lower'   Upper  = `upper'   Outside LoA = `pct_outside'%") ///
  graphregion(color(white)) ///
  plotregion(color(white)) ///
  name(bland_altman_gsmap_chirps, replace)

  restore
* Export graph
**graph export "$Graph/bland_altman_gsmap_chirps.png", replace width(1200)



****
**AGREGATE YEARLY 

preserve 
***************************************************
* STEP 1: DAILY country-average (mm/day)
****************************************************
collapse (mean) gsmap_rain chirps_rain, by(date2)
format date2 %td

gen year = year(date2)

****************************************************
* STEP 2: YEARLY totals (mm/year)
****************************************************
collapse (sum) gsmap_rain chirps_rain, by(year)

rename gsmap_rain  gsmap_year
rename chirps_rain chirps_year

****************************************************
* Keep only observations with both available values
****************************************************
drop if missing(gsmap_year) | missing(chirps_year)

****************************************************
* Bland-Altman variables
****************************************************
gen ba_avg  = (gsmap_year + chirps_year) / 2
gen ba_diff = gsmap_year - chirps_year
label variable ba_avg  "Average of GSMAP and CHIRPS yearly totals"
label variable ba_diff "Difference: GSMAP - CHIRPS yearly totals"

****************************************************
* Bias and limits of agreement
****************************************************
summ ba_diff, detail
local mean_diff = r(mean)
local sd_diff   = r(sd)

local lower = `mean_diff' - 1.96 * `sd_diff'
local upper = `mean_diff' + 1.96 * `sd_diff'

****************************************************
* Percentage outside LoA
****************************************************
gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
label variable outside_loa "Outside limits of agreement"
summ outside_loa, meanonly
local pct_outside = 100 * r(mean)

display "Bias = " %9.4f `mean_diff'
display "Lower = " %9.4f `lower'
display "Upper = " %9.4f `upper'
display "Percent outside LoA = " %6.2f `pct_outside' "%"

****************************************************
* Lines for the graph
****************************************************
gen bias_line  = `mean_diff'
gen lower_line = `lower'
gen upper_line = `upper'

****************************************************
* Sort by ba_avg
****************************************************
sort ba_avg

****************************************************
* Adjust Y-axis range
****************************************************
summ ba_diff, meanonly
local absdiff = max(abs(r(min)), abs(r(max)))
if missing(`absdiff') local absdiff = 1

****************************************************
* Bland-Altman graph
****************************************************
twoway ///
  (scatter ba_diff ba_avg, mcolor(navy) msize(medium) msymbol(circle_hollow) ///
      mlabel(year) mlabsize(small) mlabposition(12)) ///
  (line bias_line  ba_avg, sort lcolor(black) lwidth(medium)) ///
  (line lower_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)) ///
  (line upper_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)), ///
  title("Bland-Altman Plot: GSMAP vs CHIRPS") ///
  subtitle("Yearly national rainfall totals") ///
  xtitle("Average yearly rainfall: (GSMAP + CHIRPS)/2") ///
  ytitle("Difference: GSMAP - CHIRPS") ///
  yscale(range(-`absdiff' `absdiff')) ///
  legend(order(1 "Observations" 2 "Bias" 3 "Lower" 4 "Upper") rows(1) size(small)) ///
  note("Bias = `mean_diff'   Lower = `lower'   Upper = `upper'   Outside LoA = `pct_outside'%") ///
  graphregion(color(white)) ///
  plotregion(color(white)) ///
  name(bland_altman_gsmap_chirps_yearly, replace)
  
 
graph export "$Graph/yearly_altman_gsmap_chirps_agrega.png", replace width(1200)
  
restore 



***MONTHLY 

preserve 

****************************************************
* STEP 1: DAILY country-average (mm/day)
****************************************************
collapse (mean) gsmap_rain chirps_rain, by(date2)
format date2 %td

gen year  = year(date2)
gen month = month(date2)
gen ym    = ym(year, month)
format ym %tm

****************************************************
* STEP 2: MONTHLY totals (mm/month)
****************************************************
collapse (sum) gsmap_rain chirps_rain, by(ym year month)

rename gsmap_rain  gsmap_month
rename chirps_rain chirps_month

* Keep only observations with both available values
drop if missing(gsmap_month) | missing(chirps_month)

* Bland-Altman variables
gen ba_avg  = (gsmap_month + chirps_month) / 2
gen ba_diff = gsmap_month - chirps_month
label variable ba_avg  "Average of GSMAP and CHIRPS monthly totals"
label variable ba_diff "Difference: GSMAP - CHIRPS monthly totals"

* Bias and limits of agreement
summ ba_diff, detail
local mean_diff = r(mean)
local sd_diff   = r(sd)

local lower = `mean_diff' - 1.96 * `sd_diff'
local upper = `mean_diff' + 1.96 * `sd_diff'

* Percentage outside LoA
gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
label variable outside_loa "Outside limits of agreement"
summ outside_loa, meanonly
local pct_outside = 100 * r(mean)

display "Bias = " %9.4f `mean_diff'
display "Lower  = " %9.4f `lower'
display "Upper  = " %9.4f `upper'
display "Percent outside LoA = " %6.2f `pct_outside' "%"

* Lines for the graph
gen bias_line  = `mean_diff'
gen lower_line = `lower'
gen upper_line = `upper'

* Sort by ba_avg
sort ba_avg

* Adjust Y-axis range so the graph does not look disproportionate
summ ba_diff, meanonly
local absdiff = max(abs(r(min)), abs(r(max)))
if missing(`absdiff') local absdiff = 1

* Bland-Altman graph
twoway ///
  (scatter ba_diff ba_avg, mcolor(navy) msize(vsmall) msymbol(circle_hollow)) ///
  (line bias_line  ba_avg, sort lcolor(black) lwidth(medium)) ///
  (line lower_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)) ///
  (line upper_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)), ///
  title("Bland-Altman Plot: GSMAP vs CHIRPS") ///
  subtitle("Monthly country-level rainfall comparison") ///
  xtitle("Average monthly rainfall: (GSMAP + CHIRPS)/2") ///
  ytitle("Difference: GSMAP - CHIRPS") ///
  yscale(range(-`absdiff' `absdiff')) ///
  legend(order(1 "Observations" 2 "Bias" 3 "Lower" 4 "Upper") rows(1) size(small)) ///
  note("Bias = `mean_diff'   Lower = `lower'   Upper = `upper'   Outside LoA = `pct_outside'%") ///
  graphregion(color(white)) ///
  plotregion(color(white)) ///
  name(bland_altman_monthly, replace)

* Export graph
graph export "$Graph/bland_altman_gsmap_chirps_monthly.png", replace width(1200)

restore

*Daily 
preserve 
****************************************************
* STEP 1: DAILY country-average (mm/day)
****************************************************
collapse (mean) gsmap_rain chirps_rain, by(date2)
format date2 %td

gen year  = year(date2)
gen month = month(date2)

rename gsmap_rain  gsmap_day
rename chirps_rain chirps_day

****************************************************
* Keep only observations with both available values
****************************************************
drop if missing(gsmap_day) | missing(chirps_day)

****************************************************
* Bland-Altman variables
****************************************************
gen ba_avg  = (gsmap_day + chirps_day) / 2
gen ba_diff = gsmap_day - chirps_day

label variable ba_avg  "Average of gsmap and CHIRPS (daily)"
label variable ba_diff "Difference: gsmap - CHIRPS (daily)"

****************************************************
* Bias and limits of agreement
****************************************************
summ ba_diff, detail
local mean_diff = r(mean)
local sd_diff   = r(sd)

local lower = `mean_diff' - 1.96 * `sd_diff'
local upper = `mean_diff' + 1.96 * `sd_diff'

****************************************************
* Percentage outside LoA
****************************************************
gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
label variable outside_loa "Outside limits of agreement"

summ outside_loa, meanonly
local pct_outside = 100 * r(mean)

display "Bias = " %9.4f `mean_diff'
display "Lower  = " %9.4f `lower'
display "Upper  = " %9.4f `upper'
display "Percent outside LoA = " %6.2f `pct_outside' "%"

****************************************************
* Lines for the graph
****************************************************
gen bias_line  = `mean_diff'
gen lower_line = `lower'
gen upper_line = `upper'

****************************************************
* Sort by ba_avg
****************************************************
sort ba_avg

****************************************************
* Adjust Y-axis range so the graph does not look disproportionate
****************************************************
summ ba_diff, meanonly
local absdiff = max(abs(r(min)), abs(r(max)))
if missing(`absdiff') local absdiff = 1

****************************************************
* Bland-Altman graph
****************************************************
twoway ///
  (scatter ba_diff ba_avg, mcolor(navy) msize(vsmall) msymbol(circle_hollow)) ///
  (line bias_line  ba_avg, sort lcolor(black) lwidth(medium)) ///
  (line lower_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)) ///
  (line upper_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)), ///
  title("Bland-Altman Plot: gsmap vs CHIRPS") ///
  subtitle("Daily country-level rainfall comparison") ///
  xtitle("Average daily rainfall: (GSMAP + CHIRPS)/2") ///
  ytitle("Difference: GSMAP - CHIRPS") ///
  yscale(range(-`absdiff' `absdiff')) ///
  legend(order(1 "Observations" 2 "Bias" 3 "Lower" 4 "Upper") rows(1) size(small)) ///
  note("Bias = `mean_diff'   Lower = `lower'   Upper = `upper'   Outside LoA = `pct_outside'%") ///
  graphregion(color(white)) ///
  plotregion(color(white)) ///
  name(bland_altman_daily, replace)

****************************************************
* Export graph
****************************************************
graph export "$Graph/bland_altman_gsmap_chirps_daily.png", replace width(1200)

restore

*** WEEKLY 

preserve 

****************************************************
* STEP 1: DAILY country-average (mm/day)
****************************************************
collapse (mean) gsmap_rain chirps_rain, by(date2)
format date2 %td

gen yw = wofd(date2)
format yw %tw
gen year = year(dofw(yw))
gen week = week(dofw(yw))

****************************************************
* STEP 2: WEEKLY totals (mm/week)
****************************************************
collapse (sum) gsmap_rain chirps_rain, by(yw year week)

rename gsmap_rain  gsmap_week
rename chirps_rain chirps_week

* Keep only observations with both available values
drop if missing(gsmap_week) | missing(chirps_week)

* Bland-Altman variables
gen ba_avg  = (gsmap_week + chirps_week) / 2
gen ba_diff = gsmap_week - chirps_week
label variable ba_avg  "Average of GSMAP and CHIRPS weekly totals"
label variable ba_diff "Difference: GSMAP - CHIRPS weekly totals"

* Bias and limits of agreement
summ ba_diff, detail
local mean_diff = r(mean)
local sd_diff   = r(sd)

local lower = `mean_diff' - 1.96 * `sd_diff'
local upper = `mean_diff' + 1.96 * `sd_diff'

* Percentage outside LoA
gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
label variable outside_loa "Outside limits of agreement"
summ outside_loa, meanonly
local pct_outside = 100 * r(mean)

display "Bias = " %9.4f `mean_diff'
display "Lower  = " %9.4f `lower'
display "Upper  = " %9.4f `upper'
display "Percent outside LoA = " %6.2f `pct_outside' "%"

* Lines for the graph
gen bias_line  = `mean_diff'
gen lower_line = `lower'
gen upper_line = `upper'

* Sort by ba_avg
sort ba_avg

* Adjust Y-axis range so the graph does not look disproportionate
summ ba_diff, meanonly
local absdiff = max(abs(r(min)), abs(r(max)))
if missing(`absdiff') local absdiff = 1

* Bland-Altman graph
twoway ///
  (scatter ba_diff ba_avg, mcolor(navy) msize(vsmall) msymbol(circle_hollow)) ///
  (line bias_line  ba_avg, sort lcolor(black) lwidth(medium)) ///
  (line lower_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)) ///
  (line upper_line ba_avg, sort lcolor(red) lpattern(dash) lwidth(medium)), ///
  title("Bland-Altman Plot: GSMAP vs CHIRPS") ///
  subtitle("Weekly country-level rainfall comparison") ///
  xtitle("Average weekly rainfall: (GSMAP + CHIRPS)/2") ///
  ytitle("Difference: GSMAP - CHIRPS") ///
  yscale(range(-`absdiff' `absdiff')) ///
  legend(order(1 "Observations" 2 "Bias" 3 "Lower" 4 "Upper") rows(1) size(small)) ///
  note("Bias = `mean_diff'   Lower = `lower'   Upper = `upper'   Outside LoA = `pct_outside'%") ///
  graphregion(color(white)) ///
  plotregion(color(white)) ///
  name(bland_altman_weekly, replace)

* Export graph
graph export "$Graph/bland_altman_gsmap_chirps_weekly.png", replace width(1200)

restore



**********
**REGION all data 
clear all
set more off

* Load data
use "$data/merge_CHIRPS_GSMAP_Senegal_Villages_2010_2024.dta", replace

* Keep only valid observations
drop if missing(gsmap_rain) | missing(chirps_rain)

* Install grc1leg if needed
* ssc install grc1leg

* Get list of regions
levelsof region, local(regions)

local graphlist
local i = 1

foreach r of local regions {

    preserve
    keep if region == "`r'"

    * Bland-Altman variables
    gen ba_avg  = (gsmap_rain + chirps_rain) / 2
    gen ba_diff = gsmap_rain - chirps_rain

    * Check enough observations
    quietly count if !missing(ba_diff)
    if r(N) < 2 {
        di as error "Not enough observations in region `r' to compute Bland-Altman"
        restore
        continue
    }

    * Mean and SD of differences
    quietly summarize ba_diff
    local mean_diff = r(mean)
    local sd_diff   = r(sd)

    * Limits of agreement
    local lower = `mean_diff' - 1.96*`sd_diff'
    local upper = `mean_diff' + 1.96*`sd_diff'

    * Constant lines
    gen bias_line  = `mean_diff'
    gen lower_line = `lower'
    gen upper_line = `upper'

    * Percent outside LoA
    gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
    quietly summarize outside_loa, meanonly
    local pct_outside = 100 * r(mean)

    * Y-axis range: include both data and LoA
    quietly summarize ba_diff
    local ymin_data = r(min)
    local ymax_data = r(max)

    local ymax_plot = max(abs(`ymin_data'), abs(`ymax_data'), abs(`lower'), abs(`upper'))
    if missing(`ymax_plot') local ymax_plot = 1

    sort ba_avg

    * Note text
    local notetext `"Bias=`: display %5.2f `mean_diff''   Lower=`: display %5.2f `lower''   Upper=`: display %5.2f `upper''   Outside=`: display %4.1f `pct_outside''%"'

    * Graph name
    local gname = "ba`i'"

    * Legend only in first graph
    if `i' == 1 {
        local legopt ///
        legend(order(1 "Observations" 2 "Bias" 3 "Lower LoA" 4 "Upper LoA") ///
        rows(1) size(vsmall))
    }
    else {
        local legopt legend(off)
    }

    * Bland-Altman graph
    twoway ///
        (scatter ba_diff ba_avg, ///
            mcolor(navy) ///
            msize(vsmall) ///
            msymbol(circle_hollow)) ///
        (line bias_line ba_avg, sort ///
            lcolor(black) ///
            lwidth(medium)) ///
        (line lower_line ba_avg, sort ///
            lcolor(red) ///
            lpattern(dash) ///
            lwidth(medium)) ///
        (line upper_line ba_avg, sort ///
            lcolor(red) ///
            lpattern(dash) ///
            lwidth(medium)) ///
        , ///
        title("`r'", size(small)) ///
        subtitle("Daily rainfall comparison", size(vsmall)) ///
        xtitle("Average rainfall", size(vsmall)) ///
        ytitle("Difference: GSMAP - CHIRPS", size(vsmall)) ///
        xlabel(0(50)100, labsize(vsmall)) ///
        yscale(range(-`ymax_plot' `ymax_plot')) ///
        `legopt' ///
        note(`"`notetext'"', size(vsmall)) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`gname', replace)

    local graphlist `graphlist' `gname'
    local ++i

    restore
}

* Combine graphs with one shared legend
grc1leg `graphlist', ///
    cols(4) ///
    imargin(tiny) ///
    graphregion(color(white)) ///
    title("Bland-Altman Plots by Region", size(medium))

* Export graph
**graph export "$Graph/bland_altman_regions_grc1leg.png", replace width(2000)


***YEARLY AND REGION 
clear all
set more off

* Load data
use "$data/merge_CHIRPS_GSMAP_Senegal_Villages_2010_2024.dta", replace

* Keep only valid observations
drop if missing(gsmap_rain) | missing(chirps_rain)

****************************************************
* STEP 1: DAILY regional-average (mm/day)
****************************************************
collapse (mean) gsmap_rain chirps_rain, by(region date2)
format date2 %td

gen year = year(date2)

****************************************************
* STEP 2: YEARLY totals by region (mm/year)
****************************************************
collapse (sum) gsmap_rain chirps_rain, by(region year)

rename gsmap_rain  gsmap_year
rename chirps_rain chirps_year

* Get list of regions
levelsof region, local(regions)

local graphlist
local i = 1

foreach r of local regions {

    preserve
    keep if region == "`r'"

    * Bland-Altman variables
    gen ba_avg  = (gsmap_year + chirps_year) / 2
    gen ba_diff = gsmap_year - chirps_year

    * Check enough observations
    quietly count if !missing(ba_diff)
    if r(N) < 2 {
        di as error "Not enough yearly observations in region `r'"
        restore
        continue
    }

    * Mean and SD of differences
    quietly summarize ba_diff
    local mean_diff = r(mean)
    local sd_diff   = r(sd)

    * Limits of agreement
    local lower = `mean_diff' - 1.96*`sd_diff'
    local upper = `mean_diff' + 1.96*`sd_diff'

    * Constant lines
    gen bias_line  = `mean_diff'
    gen lower_line = `lower'
    gen upper_line = `upper'

    * Percent outside LoA
    gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
    quietly summarize outside_loa, meanonly
    local pct_outside = 100 * r(mean)

    * Y-axis range
    quietly summarize ba_diff
    local ymin_data = r(min)
    local ymax_data = r(max)

    local ymax_plot = max(abs(`ymin_data'), abs(`ymax_data'), abs(`lower'), abs(`upper'))
    if missing(`ymax_plot') local ymax_plot = 1

    sort ba_avg

    * Note text
    local notetext `"Bias=`: display %6.2f `mean_diff''   Lower=`: display %6.2f `lower''   Upper=`: display %6.2f `upper''   Outside=`: display %4.1f `pct_outside''%"'

    * Graph name
    local gname = "ba`i'"

    * Legend only in first graph
    if `i' == 1 {
        local legopt ///
        legend(order(1 "Observations" 2 "Bias" 3 "Lower LoA" 4 "Upper LoA") ///
        rows(1) size(vsmall))
    }
    else {
        local legopt legend(off)
    }

    * Bland-Altman graph
    twoway ///
        (scatter ba_diff ba_avg, ///
            mcolor(navy) ///
            msize(small) ///
            msymbol(circle_hollow) ///
            mlabel(year) ///
            mlabsize(vsmall) ///
            mlabposition(12)) ///
        (line bias_line ba_avg, sort ///
            lcolor(black) ///
            lwidth(medium)) ///
        (line lower_line ba_avg, sort ///
            lcolor(red) ///
            lpattern(dash) ///
            lwidth(medium)) ///
        (line upper_line ba_avg, sort ///
            lcolor(red) ///
            lpattern(dash) ///
            lwidth(medium)) ///
        , ///
        title("`r'", size(small)) ///
        subtitle("Yearly rainfall comparison", size(vsmall)) ///
        xtitle("Average yearly rainfall", size(vsmall)) ///
        ytitle("Difference: GSMAP - CHIRPS", size(vsmall)) ///
        xlabel(, labsize(vsmall)) ///
        ylabel(, labsize(vsmall)) ///
        yscale(range(-`ymax_plot' `ymax_plot')) ///
        `legopt' ///
        note(`"`notetext'"', size(vsmall)) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`gname', replace)

    local graphlist `graphlist' `gname'
    local ++i

    restore
}

* Combine graphs
grc1leg `graphlist', ///
    cols(4) ///
    imargin(tiny) ///
    graphregion(color(white)) ///
    title("Bland-Altman Plots by Region (Yearly Aggregation)", size(medium))

* Export graph
*graph export "$Graph/bland_altman_regions_yearly.png", replace width(2000)

***


**MONTHLY

clear all
set more off

* Load data
use "$data/merge_CHIRPS_GSMAP_Senegal_Villages_2010_2024.dta", replace

* Keep only valid observations
drop if missing(gsmap_rain) | missing(chirps_rain)

****************************************************
* STEP 1: DAILY regional-average (mm/day)
****************************************************
collapse (mean) gsmap_rain chirps_rain, by(region date2)
format date2 %td

gen year  = year(date2)
gen month = month(date2)
gen ym    = ym(year, month)
format ym %tm

****************************************************
* STEP 2: MONTHLY totals by region (mm/month)
****************************************************
collapse (sum) gsmap_rain chirps_rain, by(region ym year month)

rename gsmap_rain  gsmap_month
rename chirps_rain chirps_month

* Get list of regions
levelsof region, local(regions)

local graphlist
local i = 1

foreach r of local regions {

    preserve
    keep if region == "`r'"

    * Bland-Altman variables
    gen ba_avg  = (gsmap_month + chirps_month) / 2
    gen ba_diff = gsmap_month - chirps_month

    * Check enough observations
    quietly count if !missing(ba_diff)
    if r(N) < 2 {
        di as error "Not enough monthly observations in region `r'"
        restore
        continue
    }

    * Mean and SD of differences
    quietly summarize ba_diff
    local mean_diff = r(mean)
    local sd_diff   = r(sd)

    * Limits of agreement
    local lower = `mean_diff' - 1.96*`sd_diff'
    local upper = `mean_diff' + 1.96*`sd_diff'

    * Constant lines
    gen bias_line  = `mean_diff'
    gen lower_line = `lower'
    gen upper_line = `upper'

    * Percent outside LoA
    gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
    quietly summarize outside_loa, meanonly
    local pct_outside = 100 * r(mean)

    * Y-axis range
    quietly summarize ba_diff
    local ymin_data = r(min)
    local ymax_data = r(max)

    local ymax_plot = max(abs(`ymin_data'), abs(`ymax_data'), abs(`lower'), abs(`upper'))
    if missing(`ymax_plot') local ymax_plot = 1

    * X-axis range
    quietly summarize ba_avg
    local xmax = ceil(r(max)/50)*50
    if missing(`xmax') | `xmax'<=0 local xmax = 50

    sort ba_avg

    * Note text
    local notetext `"Bias=`: display %6.2f `mean_diff''   Lower=`: display %6.2f `lower''   Upper=`: display %6.2f `upper''   Outside=`: display %4.1f `pct_outside''%"'

    * Graph name
    local gname = "ba`i'"

    * Legend only in first graph
    if `i' == 1 {
        local legopt ///
        legend(order(1 "Observations" 2 "Bias" 3 "Lower LoA" 4 "Upper LoA") ///
        rows(1) size(vsmall))
    }
    else {
        local legopt legend(off)
    }

    * Bland-Altman graph
    twoway ///
        (scatter ba_diff ba_avg, ///
            mcolor(navy) ///
            msize(vsmall) ///
            msymbol(circle_hollow)) ///
        (line bias_line ba_avg, sort ///
            lcolor(black) ///
            lwidth(medium)) ///
        (line lower_line ba_avg, sort ///
            lcolor(red) ///
            lpattern(dash) ///
            lwidth(medium)) ///
        (line upper_line ba_avg, sort ///
            lcolor(red) ///
            lpattern(dash) ///
            lwidth(medium)) ///
        , ///
        title("`r'", size(small)) ///
        subtitle("Monthly rainfall comparison", size(vsmall)) ///
        xtitle("Average monthly rainfall", size(vsmall)) ///
        ytitle("Difference: GSMAP - CHIRPS", size(vsmall)) ///
        xlabel(0(50)`xmax', labsize(vsmall)) ///
        ylabel(, labsize(vsmall)) ///
        yscale(range(-`ymax_plot' `ymax_plot')) ///
        `legopt' ///
        note(`"`notetext'"', size(vsmall)) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`gname', replace)

    local graphlist `graphlist' `gname'
    local ++i

    restore
}

* Combine graphs with one shared legend
grc1leg `graphlist', ///
    cols(4) ///
    imargin(tiny) ///
    graphregion(color(white)) ///
    title("Bland-Altman Plots by Region (Monthly Aggregation)", size(medium))

* Export graph
graph export "$Graph/bland_altman_regions_monthly.png", replace width(2000)


***daily 

clear all
set more off

* Load data
use "$data/merge_CHIRPS_GSMAP_Senegal_Villages_2010_2024.dta", replace

drop if missing(gsmap_rain) | missing(chirps_rain)

****************************************************
* STEP 1: DAILY regional-average (mm/day)
****************************************************
collapse (mean) gsmap_rain chirps_rain, by(region date2)
format date2 %td

gen year  = year(date2)
gen month = month(date2)

rename gsmap_rain  gsmap_day
rename chirps_rain chirps_day

****************************************************
* Bland-Altman by region (daily)
****************************************************

levelsof region, local(regions)

local graphlist
local i = 1

foreach r of local regions {

    preserve
    keep if region == "`r'"

    * Bland-Altman variables
    gen ba_avg  = (gsmap_day + chirps_day)/2
    gen ba_diff = gsmap_day - chirps_day

    quietly count if !missing(ba_diff)
    if r(N) < 2 {
        restore
        continue
    }

    * Bias and SD
    quietly summarize ba_diff
    local mean_diff = r(mean)
    local sd_diff   = r(sd)

    * Limits of agreement
    local lower = `mean_diff' - 1.96*`sd_diff'
    local upper = `mean_diff' + 1.96*`sd_diff'

    gen bias_line  = `mean_diff'
    gen lower_line = `lower'
    gen upper_line = `upper'

    * Percent outside LoA
    gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
    quietly summarize outside_loa, meanonly
    local pct_outside = 100*r(mean)

    * Y-axis limits
    quietly summarize ba_diff
    local ymin = r(min)
    local ymax = r(max)

    local ymax_plot = max(abs(`ymin'),abs(`ymax'),abs(`lower'),abs(`upper'))
    if missing(`ymax_plot') local ymax_plot = 1

    * X-axis limits
    quietly summarize ba_avg
    local xmax = ceil(r(max)/20)*20
    if missing(`xmax') local xmax = 20

    sort ba_avg

    local notetext `"Bias=`: display %5.2f `mean_diff''  Lower=`: display %5.2f `lower''  Upper=`: display %5.2f `upper''  Outside=`: display %4.1f `pct_outside''%"'

    local gname = "ba`i'"

    if `i' == 1 {
        local legopt legend(order(1 "Obs" 2 "Bias" 3 "Lower LoA" 4 "Upper LoA") rows(1) size(vsmall))
    }
    else {
        local legopt legend(off)
    }

    twoway ///
        (scatter ba_diff ba_avg, ///
            mcolor(navy) ///
            msize(vsmall) ///
            msymbol(circle_hollow)) ///
        (line bias_line ba_avg, sort ///
            lcolor(black) lwidth(medium)) ///
        (line lower_line ba_avg, sort ///
            lcolor(red) lpattern(dash)) ///
        (line upper_line ba_avg, sort ///
            lcolor(red) lpattern(dash)) ///
        , ///
        title("`r'", size(small)) ///
        subtitle("Daily rainfall comparison", size(vsmall)) ///
        xtitle("Average daily rainfall (mm)", size(vsmall)) ///
        ytitle("Difference: GSMAP - CHIRPS", size(vsmall)) ///
        xlabel(0(20)`xmax', labsize(vsmall)) ///
        yscale(range(-`ymax_plot' `ymax_plot')) ///
        `legopt' ///
        note(`"`notetext'"', size(vsmall)) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`gname', replace)

    local graphlist `graphlist' `gname'
    local ++i

    restore
}

****************************************************
* Combine graphs
****************************************************

grc1leg `graphlist', ///
    cols(4) ///
    imargin(tiny) ///
    graphregion(color(white)) ///
    title("Bland-Altman Plots by Region (Daily Aggregation)", size(medium))

graph export "$Graph/bland_altman_regions_daily.png", replace width(2000)



**WEEKLY

clear all
set more off

* Load data
use "$data/merge_CHIRPS_GSMAP_Senegal_Villages_2010_2024.dta", replace

* Keep only valid observations
drop if missing(gsmap_rain) | missing(chirps_rain)

****************************************************
* STEP 1: DAILY regional-average (mm/day)
****************************************************
collapse (mean) gsmap_rain chirps_rain, by(region date2)
format date2 %td

gen yw = wofd(date2)
format yw %tw
gen year = year(dofw(yw))
gen week = week(dofw(yw))

****************************************************
* STEP 2: WEEKLY totals by region (mm/week)
****************************************************
collapse (sum) gsmap_rain chirps_rain, by(region yw year week)

rename gsmap_rain  gsmap_week
rename chirps_rain chirps_week

* Get list of regions
levelsof region, local(regions)

local graphlist
local i = 1

foreach r of local regions {

    preserve
    keep if region == "`r'"

    * Bland-Altman variables
    gen ba_avg  = (gsmap_week + chirps_week) / 2
    gen ba_diff = gsmap_week - chirps_week

    * Check enough observations
    quietly count if !missing(ba_diff)
    if r(N) < 2 {
        di as error "Not enough weekly observations in region `r'"
        restore
        continue
    }

    * Mean and SD of differences
    quietly summarize ba_diff
    local mean_diff = r(mean)
    local sd_diff   = r(sd)

    * Limits of agreement
    local lower = `mean_diff' - 1.96*`sd_diff'
    local upper = `mean_diff' + 1.96*`sd_diff'

    * Constant lines
    gen bias_line  = `mean_diff'
    gen lower_line = `lower'
    gen upper_line = `upper'

    * Percent outside LoA
    gen outside_loa = (ba_diff < `lower') | (ba_diff > `upper')
    quietly summarize outside_loa, meanonly
    local pct_outside = 100 * r(mean)

    * Y-axis range
    quietly summarize ba_diff
    local ymin_data = r(min)
    local ymax_data = r(max)

    local ymax_plot = max(abs(`ymin_data'), abs(`ymax_data'), abs(`lower'), abs(`upper'))
    if missing(`ymax_plot') local ymax_plot = 1

    * X-axis range
    quietly summarize ba_avg
    local xmax = ceil(r(max)/50)*50
    if missing(`xmax') | `xmax'<=0 local xmax = 50

    sort ba_avg

    * Note text
    local notetext `"Bias=`: display %6.2f `mean_diff''   Lower=`: display %6.2f `lower''   Upper=`: display %6.2f `upper''   Outside=`: display %4.1f `pct_outside''%"'

    * Graph name
    local gname = "ba`i'"

    * Legend only in first graph
    if `i' == 1 {
        local legopt ///
        legend(order(1 "Observations" 2 "Bias" 3 "Lower LoA" 4 "Upper LoA") ///
        rows(1) size(vsmall))
    }
    else {
        local legopt legend(off)
    }

    * Bland-Altman graph
    twoway ///
        (scatter ba_diff ba_avg, ///
            mcolor(navy) ///
            msize(vsmall) ///
            msymbol(circle_hollow)) ///
        (line bias_line ba_avg, sort ///
            lcolor(black) ///
            lwidth(medium)) ///
        (line lower_line ba_avg, sort ///
            lcolor(red) ///
            lpattern(dash) ///
            lwidth(medium)) ///
        (line upper_line ba_avg, sort ///
            lcolor(red) ///
            lpattern(dash) ///
            lwidth(medium)) ///
        , ///
        title("`r'", size(small)) ///
        subtitle("Weekly rainfall comparison", size(vsmall)) ///
        xtitle("Average weekly rainfall", size(vsmall)) ///
        ytitle("Difference: GSMAP - CHIRPS", size(vsmall)) ///
        xlabel(0(50)`xmax', labsize(vsmall)) ///
        ylabel(, labsize(vsmall)) ///
        yscale(range(-`ymax_plot' `ymax_plot')) ///
        `legopt' ///
        note(`"`notetext'"', size(vsmall)) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        name(`gname', replace)

    local graphlist `graphlist' `gname'
    local ++i

    restore
}

* Combine graphs with one shared legend
grc1leg `graphlist', ///
    cols(4) ///
    imargin(tiny) ///
    graphregion(color(white)) ///
    title("Bland-Altman Plots by Region (Weekly Aggregation)", size(medium))

* Export graph
graph export "$Graph/bland_altman_regions_weekly.png", replace width(2000)



