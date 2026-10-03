
*************************************************
* GSMAP and CHIRPS Data: Agregate analysis
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

use "$data/merge_CHIRPS_GSMAP_Senegal_Villages_2010_2024.dta", replace

preserve

    ****************************************************
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
    * STEP 3: Regression
    ****************************************************
    reg gsmap_year chirps_year
    local b  = _b[chirps_year]
    local a  = _b[_cons]
    local r2 = e(r2)

    ****************************************************
    * STEP 4: Pearson correlation
    ****************************************************
    pwcorr gsmap_year chirps_year, sig

/*           | gsmap_~r chirps~r
-------------+------------------
  gsmap_year |   1.0000 
             |
             |
 chirps_year |   0.8151   1.0000 
             |   0.0002
             |
*/

    ****************************************************
    * STEP 5: Error metrics
    ****************************************************
    tempvar diff absdiff sqdiff
    gen `diff'    = gsmap_year - chirps_year
    gen `absdiff' = abs(`diff')
    gen `sqdiff'  = (`diff')^2

    quietly sum `absdiff'
    local mae = r(mean)

    quietly sum `sqdiff'
    local rmse = sqrt(r(mean))

    ****************************************************
    * STEP 6: graph
    ***************************************************

quietly sum chirps_year
local xmin = r(min)
local xmax = r(max)

quietly sum gsmap_year
local ymin = r(min)
local ymax = r(max)

local low  = floor(min(`xmin',`ymin')/50)*50
local high = ceil(max(`xmax',`ymax')/50)*50

twoway ///
    (scatter gsmap_year chirps_year, ///
        msize(medlarge) mcolor(forest_green)) ///
    (lfit gsmap_year chirps_year, ///
        lcolor(red) lwidth(medthick)) ///
    (function y=x, range(`low' `high') ///
        lcolor(navy) lwidth(medthick)), ///
    xlabel(`low'(100)`high') ///
    ylabel(`low'(100)`high') ///
    xscale(range(`low' `high')) ///
    yscale(range(`low' `high')) ///
    xtitle("Yearly CHIRPS total (mm)") ///
    ytitle("Yearly GSMAP total (mm)") ///
    legend(order(1 "Yearly totals" 2 "Linear fit" 3 "45° line") ///
           cols(3) position(6) ring(1) ///
           region(lcolor(none) fcolor(white))) ///
    text(`=`high'-20' `=`low'+30' ///
        "Slope = `: display %4.2f `b''", size(medsmall)) ///
    text(`=`high'-60' `=`low'+30' ///
        "Intercept = `: display %6.0f `a''", size(medsmall)) ///
    graphregion(color(white)) ///
    plotregion(color(white) margin(large)) ///
    aspectratio(1)

graph export "$Graph/rainfall_graph_yearly.png", replace width(3000)
    ****************************************************
    * STEP 7: Excel output
    ****************************************************
    local xls "$res/Yearly_Rainfall_Validation_All_Senegal.xlsx"

    putexcel set "`xls'", replace sheet("summary")
    putexcel A1=("Metric")          B1=("Value")
    putexcel A2=("Slope")           B2=(round(`b',.001))
    putexcel A3=("Intercept")       B3=(round(`a',.001))
    putexcel A4=("MAE (mm)")        B4=(round(`mae',.001))
    putexcel A5=("RMSE (mm)")       B5=(round(`rmse',.001))
    putexcel A6=("R-squared")       B6=(round(`r2',.001))
    
    gen diff_year = gsmap_year - chirps_year

    export excel year chirps_year gsmap_year diff_year ///
        using "`xls'", sheet("yearly_data") ///
        firstrow(variables) sheetreplace

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

    ****************************************************
    * STEP 3: Regression
    ****************************************************
    reg gsmap_month chirps_month
    local b  = _b[chirps_month]
    local a  = _b[_cons]
    local r2 = e(r2)

    ****************************************************
    * STEP 4: Pearson correlation
    ****************************************************
    pwcorr gsmap_month chirps_month, sig
       
	   /*   | gsmap_~h chirps~h
-------------+------------------
 gsmap_month |   1.0000 
             |
             |
chirps_month |   0.9822   1.0000 
             |   0.0000
             |
*/

    ****************************************************
    * STEP 5: Error metrics
    ****************************************************
    tempvar diff absdiff sqdiff
    gen `diff'    = gsmap_month - chirps_month
    gen `absdiff' = abs(`diff')
    gen `sqdiff'  = (`diff')^2

    quietly sum `absdiff'
    local mae = r(mean)

    quietly sum `sqdiff'
    local rmse = sqrt(r(mean))

    ****************************************************
    * STEP 6: Clean graph (legend outside)
    ****************************************************
    quietly sum chirps_month
    local xmin = r(min)
    local xmax = r(max)

    quietly sum gsmap_month
    local ymin = r(min)
    local ymax = r(max)

    local low  = floor(min(`xmin',`ymin')/50)*50
    local high = ceil(max(`xmax',`ymax')/50)*50

    twoway ///
        (scatter gsmap_month chirps_month, ///
            msize(medium) mcolor(forest_green)) ///
        (lfit gsmap_month chirps_month, ///
            lcolor(red) lwidth(medthick)) ///
        (function y=x, range(`low' `high') ///
            lcolor(navy) lwidth(medthick)), ///
        xlabel(`low'(100)`high') ///
        ylabel(`low'(100)`high') ///
        xscale(range(`low' `high')) ///
        yscale(range(`low' `high')) ///
        xtitle("Monthly CHIRPS total (mm)") ///
        ytitle("Monthly GSMAP total (mm)") ///
        legend(order(1 "Monthly totals" 2 "Linear fit" 3 "45° line") ///
               cols(3) position(6) ring(1) ///
               region(lcolor(none))) ///
        text(`=`high'-20' `=`low'+30' ///
            "Slope = `: display %4.2f `b''", size(medsmall)) ///
        text(`=`high'-60' `=`low'+30' ///
            "Intercept = `: display %6.0f `a''", size(medsmall)) ///
        graphregion(color(white)) ///
        plotregion(color(white) margin(large)) ///
        aspectratio(1)

    graph export "$Graph/rainfall_graph_monthly.png", replace width(3000)

    ****************************************************
    * STEP 7: Excel output
    ****************************************************
    local xls "$res/Monthly_Rainfall_Validation_All_Senegal.xlsx"

    putexcel set "`xls'", replace sheet("summary")
    putexcel A1=("Metric")          B1=("Value")
    putexcel A2=("Slope")           B2=(round(`b',.001))
    putexcel A3=("Intercept")       B3=(round(`a',.001))
    putexcel A4=("MAE (mm)")        B4=(round(`mae',.001))
    putexcel A5=("RMSE (mm)")       B5=(round(`rmse',.001))
    putexcel A6=("R-squared")       B6=(round(`r2',.001))
    

    gen diff_month = gsmap_month - chirps_month

    export excel ym year month chirps_month gsmap_month diff_month ///
        using "`xls'", sheet("monthly_data") ///
        firstrow(variables) sheetreplace

restore

*/ DAILY analysis – ALL YEARS – ALL SENEGAL – NO BINS  (+ pwcorr to Excel)
/////////////////////////////////////////////////////////////////////

preserve

    ****************************************************
    * STEP 1: DAILY country-average across villages (mm/day)
    ****************************************************
    collapse (mean) gsmap_rain chirps_rain, by(date2)
    format date2 %td

    gen year  = year(date2)
    gen month = month(date2)

    rename gsmap_rain  gsmap_day
    rename chirps_rain chirps_day

    ****************************************************
    * STEP 2: Regression (all days pooled)
    ****************************************************
    reg gsmap_day chirps_day
    local b  = _b[chirps_day]
    local a  = _b[_cons]
    local r2 = e(r2)

    ****************************************************
    * STEP 3: Pearson correlation (rho + p-value)
    ****************************************************
    pwcorr gsmap_day chirps_day, sig
       
    ****************************************************
    * STEP 4: Error metrics (MAE, RMSE)
    ****************************************************
    tempvar diff absdiff sqdiff
    gen `diff'    = gsmap_day - chirps_day
    gen `absdiff' = abs(`diff')
    gen `sqdiff'  = (`diff')^2

    quietly sum `absdiff'
    local mae = r(mean)

    quietly sum `sqdiff'
    local rmse = sqrt(r(mean))

    ****************************************************
    * STEP 5: Clean graph (legend outside, daily scale)
    ****************************************************
    quietly sum chirps_day
    local xmin = r(min)
    local xmax = r(max)

    quietly sum gsmap_day
    local ymin = r(min)
    local ymax = r(max)

    * Use same axis limits for fair visual comparison
    local low  = floor(min(`xmin',`ymin')/10)*10
    local high = ceil(max(`xmax',`ymax')/10)*10

    twoway ///
        (scatter gsmap_day chirps_day, ///
            msize(vsmall) mcolor(forest_green)) ///
        (lfit gsmap_day chirps_day, ///
            lcolor(red) lwidth(medthick)) ///
        (function y=x, range(`low' `high') ///
            lcolor(navy) lwidth(medthick)), ///
        xlabel(`low'(20)`high') ///
        ylabel(`low'(20)`high') ///
        xscale(range(`low' `high')) ///
        yscale(range(`low' `high')) ///
        xtitle("Daily CHIRPS (mm/day)") ///
        ytitle("Daily GSMAP (mm/day)") ///
        legend(order(1 "Daily means" 2 "Linear fit" 3 "45° line") ///
               cols(3) position(6) ring(1) ///
               region(lcolor(none))) ///
        text(`=`high'-2' `=`low'+2' ///
            "Slope = `: display %4.2f `b''", size(medsmall)) ///
        text(`=`high'-6' `=`low'+2' ///
            "Intercept = `: display %6.2f `a''", size(medsmall)) ///
        graphregion(color(white)) ///
        plotregion(color(white) margin(large)) ///
        aspectratio(1)

    graph export "$Graph/rainfall_graph_daily.png", replace width(3000)

    ****************************************************
    * STEP 6: Excel output (summary + daily data)
    ****************************************************
    local xls "$res/Daily_Rainfall_Validation_All_Senegal.xlsx"

    putexcel set "`xls'", replace sheet("summary")
    putexcel A1=("Metric")          B1=("Value")
    putexcel A2=("Slope")           B2=(round(`b',.001))
    putexcel A3=("Intercept")       B3=(round(`a',.001))
    putexcel A4=("MAE (mm)")        B4=(round(`mae',.001))
    putexcel A5=("RMSE (mm)")       B5=(round(`rmse',.001))
    putexcel A6=("R-squared")       B6=(round(`r2',.001))
    

    gen diff_day  = gsmap_day - chirps_day
    gen date_str  = string(date2, "%tdCCYY-NN-DD")
    order date2 date_str year month chirps_day gsmap_day diff_day

    export excel date2 date_str year month chirps_day gsmap_day diff_day ///
        using "`xls'", sheet("daily_data") ///
        firstrow(variables) sheetreplace

restore


*** WEEKLY

preserve

    ****************************************************
    * STEP 1: DAILY country-average (mm/day)
    ****************************************************
    collapse (mean) gsmap_rain chirps_rain, by(date2)
    format date2 %td

    gen year  = year(date2)
    gen week  = week(date2)
    gen yw    = yw(year, week)
    format yw %tw

    ****************************************************
    * STEP 2: WEEKLY totals (mm/week)
    ****************************************************
    collapse (sum) gsmap_rain chirps_rain, by(yw year week)

    rename gsmap_rain  gsmap_week
    rename chirps_rain chirps_week

    ****************************************************
    * STEP 3: Regression
    ****************************************************
    reg gsmap_week chirps_week
    local b  = _b[chirps_week]
    local a  = _b[_cons]
    local r2 = e(r2)

    ****************************************************
    * STEP 4: Pearson correlation
    ****************************************************
    pwcorr gsmap_week chirps_week, sig

    ****************************************************
    * STEP 5: Error metrics
    ****************************************************
    tempvar diff absdiff sqdiff
    gen `diff'    = gsmap_week - chirps_week
    gen `absdiff' = abs(`diff')
    gen `sqdiff'  = (`diff')^2

    quietly sum `absdiff'
    local mae = r(mean)

    quietly sum `sqdiff'
    local rmse = sqrt(r(mean))

    ****************************************************
    * STEP 6: Clean graph
    ****************************************************
    quietly sum chirps_week
    local xmin = r(min)
    local xmax = r(max)

    quietly sum gsmap_week
    local ymin = r(min)
    local ymax = r(max)

    local low  = floor(min(`xmin',`ymin')/50)*50
    local high = ceil(max(`xmax',`ymax')/50)*50

    twoway ///
        (scatter gsmap_week chirps_week, ///
            msize(medium) mcolor(forest_green)) ///
        (lfit gsmap_week chirps_week, ///
            lcolor(red) lwidth(medthick)) ///
        (function y=x, range(`low' `high') ///
            lcolor(navy) lwidth(medthick)), ///
        xlabel(`low'(100)`high') ///
        ylabel(`low'(100)`high') ///
        xscale(range(`low' `high')) ///
        yscale(range(`low' `high')) ///
        xtitle("Weekly CHIRPS total (mm)") ///
        ytitle("Weekly GSMAP total (mm)") ///
        legend(order(1 "Weekly totals" 2 "Linear fit" 3 "45° line") ///
               cols(3) position(6) ring(1) ///
               region(lcolor(none))) ///
        text(`=`high'-20' `=`low'+30' ///
            "Slope = `: display %4.2f `b''", size(medsmall)) ///
        text(`=`high'-60' `=`low'+30' ///
            "Intercept = `: display %6.0f `a''", size(medsmall)) ///
        graphregion(color(white)) ///
        plotregion(color(white) margin(large)) ///
        aspectratio(1)

    graph export "$Graph/rainfall_graph_weekly.png", replace width(3000)

    ****************************************************
    * STEP 7: Excel output
    ****************************************************
    local xls "$res/Weekly_Rainfall_Validation_All_Senegal.xlsx"

    putexcel set "`xls'", replace sheet("summary")
    putexcel A1=("Metric")          B1=("Value")
    putexcel A2=("Slope")           B2=(round(`b',.001))
    putexcel A3=("Intercept")       B3=(round(`a',.001))
    putexcel A4=("MAE (mm)")        B4=(round(`mae',.001))
    putexcel A5=("RMSE (mm)")       B5=(round(`rmse',.001))
    putexcel A6=("R-squared")       B6=(round(`r2',.001))

    gen diff_week = gsmap_week - chirps_week

    export excel yw year week chirps_week gsmap_week diff_week ///
        using "`xls'", sheet("weekly_data") ///
        firstrow(variables) sheetreplace

restore



