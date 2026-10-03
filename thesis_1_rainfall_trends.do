**=======================================================================**
*PART 1 TENDENCY ANALISYS
*========================================================================**
* Master's thesis, University of Passau (2025) - Camila Aguirre Diaz
	clear all
	set more off
		global dir "."   // change to your project folder
		global data "$dir/DATA" 		// where data is saved
		global dofiles "$dir/DO_FILES"  // where Do-File should be saved
		global res "$dir/RESULTS" 		// where results should be saved
		global log "$dir/LOGS" 			// where Log-File should be saved
		global res_des "$dir/RESULTS_DESC" 		// where results should be saved
		global Graph "$dir/GRAPHS" 
		set more off
		
set scheme Stgcolor_alt	

**=======================================================================**
*TENDENCY WITH WORLD DATA BANK: PRECIPITATION ERA 5 
**https://climateknowledgeportal.worldbank.org/country/senegal
*FIGURE 5: Precipitation Annual trends ;senegal 1950-2024
*========================================================================**

use "$data/world_bank.dta", clear
tsset year_date, yearly
rename PRECIPITATION Precipitation 
label variable Precipitation "Precipitation (mm)" 

* 1) Tendency 1951–2024
reg Precipitation year_date if inrange(year_date, 1950, 2024)
predict trend_all if inrange(year_date, 1950, 2024)
matrix results = r(table)
scalar b_all = results[1,1]     // slope (mm/año)
scalar p_all = results[4,1]     // p-value

* 2) Tendency 1971–2024
reg Precipitation year_date if inrange(year_date, 1971, 2024)
predict trend_1971 if inrange(year_date, 1971, 2024)
matrix results = r(table)
scalar b_1971 = results[1,1]
scalar p_1971 = results[4,1]

* 3) Tendency 1991–2024
reg Precipitation year_date if inrange(year_date, 1991, 2024)
predict trend_1991 if inrange(year_date, 1991, 2024)
matrix results = r(table)
scalar b_1991 = results[1,1]
scalar p_1991 = results[4,1]

* 4) Legend format
local b_all_str   : display %6.2f b_all
local b_1971_str  : display %6.2f b_1971
local b_1991_str  : display %6.2f b_1991

local p_all_str   : display %4.2f p_all
local p_1971_str  : display %4.2f p_1971
local p_1991_str  : display %4.2f p_1991

* 5) Graph wiht  slopes 
twoway ///
    line Precipitation year_date, lcolor(gs6) lwidth(medthick) ///
 || line trend_all   year_date if inrange(year_date,1950,2024),  lcolor(navy)      lwidth(medthick) ///
 || line trend_1971  year_date if inrange(year_date,1971,2024), lcolor(green*0.7) lwidth(medthick) ///
 || line trend_1991  year_date if inrange(year_date,1991,2024), lcolor(yellow)    lwidth(medthick) ///
    legend(size(*1.5) region(style(none)) ///
           order(1 "Annual Precipitation" 2 "Trend 1950–2024" 3 "Trend 1971–2024" 4 "Trend 1991–2024")) ///
    ytitle("Precipitation (mm)", size(*1.6)) ///
    xtitle("Year", size(*1.6)) ///
    title("", size(*1.2)) ///
    ylabel(300(100)1000, labsize(*1.4)) ///
    xlabel(1950(10)2020, labsize(*1.4))
graph export "$Graph/prec_trend_senga_banco_1950_2024.png", replace


**=======================================================================**
*Change in distrubution of precipitation : PRECIPITATION ERA 5 WORLD DATA BANK
*APPENDIX K  
*========================================================================**

use "$data/world_bank.dta", clear
tsset year_date, yearly
rename PRECIPITATION Precipitation 
label variable Precipitation "Precipitation (mm)" 

gen period = .
replace period = 1 if inrange( year_date,1950,1980)
replace period = 2 if inrange( year_date,1981,2000)
replace period = 3 if inrange( year_date,2001,2024)
label define period 1 "1950-1980" 2 "1981-2000" 3 "2001-2024"
label values period period
twoway ///
 (kdensity Precipitation if period==1, kernel(gaussian) bwidth(50) ///
     lcolor(orange) fcolor(orange%40) lwidth(thick)) ///
 (kdensity Precipitation if period==2, kernel(gaussian) bwidth(50) ///
     lcolor(green) fcolor(green%40) lwidth(thick)) ///
 (kdensity Precipitation if period==3, kernel(gaussian) bwidth(50) ///
     lcolor(blue) fcolor(blue%40) lwidth(thick)), ///
 legend(size(*1.4) cols(3) order(1 "1950-1980" 2 "1981-2000" 3 "2001-2024")) ///
 xtitle("Precipitation (mm)", size(*1.6)) ///
 ytitle("Distribution", size(*1.6)) ///
 xlabel(, labsize(*1.4)) ///
 ylabel(, labsize(*1.4)) ///
 title("")

graph export "$Graph/prec_distribution_senga_banco_1950_2024.png", replace

**=======================================================================**
*Tendency rainy season :
*FIGURE 6: Rainy season precipitation trend (DATA SPEI_1 EXCEL/ RWI)
*========================================================================**
*USE THE DATA BASE CREATED PREVIOUSLY DO_FILE : DATA_SET_PREPARE

use "$data/TREND_ANALYSIS.dta",clear 
keep if inrange(month, 6,10) //  growing season according to agriculture minister rainy season is btw june to october

**NATIONAL LEVEL:  PRECIPITATION
collapse ///
    (mean) precipitation balance  ///
    (mean) mean_temp = mean_temp ///
    (mean) min_temp = min_temp ///
    (mean) max_temp = max_temp, ///
    by(year)
	
	
keep if year >= 1981
tsset year

* --- Tendencia 1981–2024 ---
reg precipitation year if inrange(year, 1981, 2024)
predict trend_1981 if inrange(year, 1981, 2024), xb
matrix R = r(table)
scalar b_1981 = R[1,1]      // mm/year
scalar p_1981 = R[4,1]
scalar b_1981_dec = 10*b_1981   //mm per decade

* --- Tendencia 1991–2024 ---
reg precipitation year if inrange(year, 1991, 2024)
predict trend_1991 if inrange(year, 1991, 2024), xb
matrix R = r(table)
scalar b_1991 = R[1,1]      // mm/año
scalar p_1991 = R[4,1]
scalar b_1991_dec = 10*b_1991   // mm per decade

* --- (Optional) Exponential smoothing as a reference ---
capture noisily tssmooth exponential mean_prec_exp = precipitation, parms(0.3)

* --- Formatting for display in the chart ---
local b1981_dec_str : display %6.2f b_1981_dec
local b1991_dec_str : display %6.2f b_1991_dec
local p1981_str     : display %4.2f p_1981
local p1991_str     : display %4.2f p_1991

* --- Chart: series + trends by decade ---
twoway ///
    tsline precipitation, lcolor(gs6) lwidth(medthick) ///
 || tsline trend_1981 if inrange(year,1981,2024),  lcolor(navy)      lwidth(medthick) ///
 || tsline trend_1991 if inrange(year,1991,2024),  lcolor(green*0.8) lwidth(medthick) ///
    legend(size(*1.5) region(style(none)) ///
           order(1 "Rainy season precipitation" 2 "Trend 1981–2024" 3 "Trend 1991–2024")) ///
    title("", size(*1.4)) ///
    xtitle("Year", size(*1.6)) ///
    ytitle("Avg. Precipitation (mm)", size(*1.6)) ///
    xlabel(1981(10)2024, labsize(*1.4)) ///
    ylabel(, labsize(*1.4))
graph export "$Graph/prec_trend_senga_1981_2024.png", replace
	
 
**=======================================================================**
*BOX PLOT SPEI :
*FIGURE 7,8,9,10,11,12,13 /Village-level SPEI distribution, crop growing season  (SPEI_1 EXCEL)
*========================================================================**
use "$data/mensual_spei.dta", clear // CREATED IN DO FILE DATA_SET_FAO_SPEI

graph box spei_1_values if year == 2021 & growing == 1 & inrange(month, 5, 11), ///
    over(month, label(angle(45) labsize(*1.4))) ///
    yline(0, lpattern(dash)) ///
    ylabel(-1.5(0.5)2.3, grid gstyle(dot) labsize(*1.4)) ///
    ytitle("SPEI (Z-score)", size(*1.4)) ///
    title("", size(*1.4)) ///
    name(box_spei_2021, replace)
	graph export "$Graph/box_chart_SENEGAL_GR_21.png", replace


graph box spei_1_values if year == 2022 & growing == 1 & inrange(month, 5, 11), ///
    over(month, label(angle(45) labsize(*1.4))) ///
    yline(0, lpattern(dash)) ///
    ylabel(-1.5(0.5)2.3, grid gstyle(dot) labsize(*1.4)) ///
    ytitle("SPEI (Z-score)", size(*1.4)) ///
    title("", size(*1.4)) ///
    name(box_spei_2022, replace)
graph export "$Graph/box_chart_SENEGAL_GR_22.png", replace



graph box spei_1_values if year == 2023 & growing == 1 & inrange(month, 5, 11), ///
    over(month, label(angle(45) labsize(*1.4))) ///
    yline(0, lpattern(dash)) ///
    ylabel(-2(0.8)2, grid gstyle(dot) labsize(*1.4)) ///
    ytitle("SPEI (Z-score)", size(*1.4)) ///
    title("", size(*1.4)) ///
    name(box_spei_2023, replace)
graph export "$Graph/box_chart_SENEGAL_GR_23.png", replace



graph box spei_1_values if year == 2024 & growing == 1 & inrange(month, 5, 11), ///
    over(month, label(angle(45) labsize(*1.4))) ///
    yline(0, lpattern(dash)) ///
    ylabel(-2.5(1)2.5, grid gstyle(dot) labsize(*1.4)) ///
    ytitle("SPEI (Z-score)", size(*1.4)) ///
    title("", size(*1.4)) ///
    name(box_spei_2024, replace)
graph export "$Graph/box_chart_SENEGAL_GR_24.png", replace

	
**REGION LEVEL 
	
*kaolack
	graph box spei_1_values if region == 4 & growing == 1, ///
    over(year, label(angle(360) labsize(*1.4))) ///
    yline(0, lpattern(dash) lcolor(dark)) ///
    medline(lwidth(medthick) lcolor(dark)) ///
    graphregion(color(white)) ///
    ylabel(-2(0.5)2, grid gstyle(dot) labsize(*1.4)) ///
    ytitle("SPEI (Z-score)", size(*1.4)) ///
    title("", size(*1.4)) ///
    name(box_spei_Kaolack, replace)
graph export "$Graph/box_chart_SEASON_KAOLACK.png", replace

*Matam
graph box spei_1_values if region == 8 & growing == 1, ///
    over(year, label(angle(360) labsize(*1.4))) ///
    yline(0, lpattern(dash) lcolor(dark)) ///
    medline(lwidth(medthick) lcolor(dark)) ///
    graphregion(color(white)) ///
    ylabel(-2(0.5)2, grid gstyle(dot) labsize(*1.4)) ///
    ytitle("SPEI (Z-score)", size(*1.4)) ///
    title("", size(*1.4)) ///
    name(box_spei_Matam, replace)
graph export "$Graph/box_chart_SEASON_MATAM.png", replace

*Sedhiuou
graph box spei_1_values if region == 10 & growing == 1, ///
    over(year, label(angle(360) labsize(*1.4))) ///
    yline(0, lpattern(dash) lcolor(dark)) ///
    medline(lwidth(medthick) lcolor(dark)) ///
    graphregion(color(white)) ///
    ylabel(-2(0.5)2, grid gstyle(dot) labsize(*1.4)) ///
    ytitle("SPEI (Z-score)", size(*1.4)) ///
    title("", size(*1.4)) ///
    name(box_spei_Sedhiou, replace)
graph export "$Graph/box_chart_SEASON_Sedhiou.png", replace

*END

**=======================================================================**
*TABLE SEN SLOPE :
*TABLE 9,10 Trends in rainy season precipitation across regions and AEZ (SPEI_1_EXCEL)
*========================================================================**

*** REGION LEVEL USED KENDALL AND SLOPE
use "$data/PASSAU_THESIS_MODELO.dta" ,replace // Use de data set created in: Panel_Data_Set

* Create summary by region
collapse ///
    (mean)  mean_slope   = sen_slope ///
    (mean)  mean_p       = p_value ///
    (mean)  mean_zscore  = Z_MK ///
    (mean)  mean_tau     = tau ///
    (mean)  mean_CV      = CV ///
    (mean)  mean_DWstat  = DW_stat /// durbin-watson Appendix L
    (mean)  mean_DWpv    = DW_p_value ///
	(mean)  mean_dwr2    = R2 ///
    (count) N            = sen_slope, by(region)

* Export to Excel
export excel using "$res/sen_slope_summary_by_region.xlsx", /// 
    sheet("summary") firstrow(variables) replace

	
*** REGION LEVEL USED KENDALL AND SLOPE
use "$data/PASSAU_THESIS_MODELO.dta" ,replace // Use de data set created in: Panel_Data_Set

* Create summary by  AEZ 
collapse ///
    (mean)  mean_slope   = sen_slope ///
    (mean)  mean_p       = p_value ///
    (mean)  mean_zscore  = Z_MK ///
    (mean)  mean_tau     = tau ///
    (mean)  mean_CV      = CV ///
    (mean)  mean_DWstat  = DW_stat /// durbin-watson Appendix L
    (mean)  mean_DWpv    = DW_p_value ///
	(mean)  mean_dwr2    = R2 ///
    (count) N            = sen_slope, by(AEZ)

* Export a Excel
export excel using "$res/sen_slope_summary_by_aez.xlsx", ///
    sheet("summary") firstrow(variables) replace

	






