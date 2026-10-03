
***********************************************************************
*** 07.30 DO FILE - Test other satellite data sets against CHIRPS - ***

* Project: Weather Shocks and Migration Responses in Senegal
* Last edited: Noc 2025
***********************************************************************

clear all
version 16.1
set more off
capture log close

////////////////////////////////
// 0. GLOBALS
////////////////////////////////


global dir "."   // change to your project folder
	global data "$dir/DATA" 		// where data is saved
	global res "$dir/RESULTS" 		// where results should be saved
	global log "$dir/LOGS" 			// where Log-File should be saved
	global Graph "$dir/GRAPHS" 

	set more off
	

*IMPORTANT: The SMP waves are 2022, 2023, 2024. But we ask retrsopective questions on past migration and agricultural season, so rainfall from 2021 must be merged to 2022-SMP wave, rainfall from 2022 to 2023-SMP wave, and rainfall from 2023 to 2024-SMP wave. 
**have done in the dataset temp_irregular_rainfall_data_treated_merged.dta
// DATA PREPARATION
////////////////////////////////

use "$data/temp_irregular_rainfall_data_treated_merged.dta", replace

rename DS14_gsmap DS14_G
rename DS20_gsmap DS20_G
rename DS30_gsmap DS30_G

rename DS14_mswep DS14_M
rename DS20_mswep DS20_M
rename DS30_mswep DS30_M

rename DS14_tamsat DS14_T
rename DS20_tamsat DS20_T
rename DS30_tamsat DS30_T


drop if year == 2025 // merged 2024-2025SMP without data 
* Treatment suffixes: _G = GSMAP, _M = MSWEP, _T = TAMSAT (no suffix = CHIRPS)
 

////////////////////////
// Run Regressions
////////////////////////

* -------------------------------------------------------------------------------	
* HH FE x Year FE model
* ------------------------------------------------------------------------------

** Gbasin sample
* Set panel
xtset hhid_num year

*------------------------------------------------------------------------------
* 1. Outcome and Controls
*------------------------------------------------------------------------------
global outcome "hh_int_mig_panel"
global controls "temp_anomaly"

*------------------------------------------------------------------------------
* 2. Shocks
*------------------------------------------------------------------------------
global all_shocks "DS14 DS20 DS30 DS14_G DS20_G DS30_G DS14_M DS20_M DS30_M  DS14_T DS20_T DS30_T"
*global all_shocks "DS20 DS20_G   DS20_M  DS20_T" 
*global all_shocks "DS14 DS14_G   DS14_M  DS14_T" 
*global all_shocks "DS30 DS30_G   DS30_M  DS30_T" 

*------------------------------------------------------------------------------
* 3. Subsets
*------------------------------------------------------------------------------
local s1 "if panel == 1 & AEZ == 1 & inlist(year, 2022, 2023, 2024)"
local s2 "if panel == 1 & inlist(year, 2022, 2023, 2024)"
local s3 "if panel == 1 & AEZ == 1 & inlist(year, 2022, 2024)"
local s4 "if panel == 1 & inlist(year, 2022, 2024)"

* Names for output files
local names "gb full gb_22_24 full_22_24"

*------------------------------------------------------------------------------
* 4. Main loop
*------------------------------------------------------------------------------
foreach i in 1 2 3 4 {

    local models ""
    local suffix : word `i' of `names'

    di _newline "{hline 70}"
    di "SUBSET S`i'"
    di "{hline 70}"

    * Loop over shocks (only one outcome now)
    foreach shock in $all_shocks {

        * Short model name
        local m_name "m`i'_ext_`shock'"

        * Estimation
        xtreg $outcome `shock' $controls i.year `s`i'', ///
            fe vce(cluster ea_id)

        * Add FE indicators
        estadd local fe_hh   "Yes"
        estadd local fe_year "Yes"

        * Mean + SD of DV
        quietly summarize $outcome if e(sample)
        estadd scalar mean_dv = r(mean)
        estadd scalar sd_dv   = r(sd)

        * Store
        estimates store `m_name'
        local models "`models' `m_name'"
    }

    *--------------------------------------------------------------------------
    * Console output (quick check)
    *--------------------------------------------------------------------------
    estimates table `models',                   ///
        keep($all_shocks $controls)             ///
        star(.1 .05 .01) b(%9.4f)              ///
        stats(N_g r2_w mean_dv sd_dv)          ///
        title("Subset `suffix'")

    *--------------------------------------------------------------------------
    * RTF output
    *--------------------------------------------------------------------------
    cd "$res/regressions"

    esttab `models' using "final_reg_results_extensive_`suffix'.rtf", replace ///
        cells(b(star fmt(%9.4f)) se(par("(" ")") fmt(%9.4f)))       ///
        starlevels(* 0.1 ** 0.05 *** 0.01)                          ///
        keep($all_shocks $controls)                                 ///
        order($all_shocks $controls)                                ///
        varlabels(DS14 "Dry spell (14-day)"                         ///
                  DS20 "Dry spell (20-day)"                         ///
                  DS30 "Dry spell (30-day)"                         ///
                  temp_anomaly "Temperature Anomaly")               ///
        stats(fe_hh fe_year N_g r2_w mean_dv sd_dv,                 ///
              fmt(%s %s %9.0f %9.4f %9.4f %9.4f)                    ///
              labels("HH Fixed Effects"                             ///
                     "Year Fixed Effects"                           ///
                     "Observations"                                 ///
                     "R2 (within)"                                  ///
                     "Mean DV"                                      ///
                     "SD DV"))                                      ///
        mgroups("Outcome: Household has internal migrant",         ///
                pattern(1 1 1)                                      ///
                prefix(\qc\b\~) suffix(\b0))                        ///
        mlabels(none)                                               ///
        collabels(none)                                             ///
        title("{\b Table:} Internal Migration (Extensive margin)")  ///
        nonotes                                                     ///
        addnotes("Standard errors clustered at EA level in parentheses." ///
                 "* p<0.1  ** p<0.05  *** p<0.01"                  ///
                 "All models include household and year fixed effects.")

    estimates clear
}


***********************************************
* Two Way FE Decomposition (only for DS20_x)
***********************************************

ssc install twowayfeweights

twowayfeweights hh_int_mig_panel hhid_num year DS20 DS20_G DS20_M DS20_T ///
if AEZ == 1 & panel==1, controls(temp_anomaly) ///
type(feTR)


***************************************
* If time allows: 1 coefficient plot
**************************************

* Only For DS20_x: 1 coef-estimate per rainfall data set, so 4 estimates (CHIRPS, MSWEP, GSMAP, TAMSAT)	

***************************************
* 1 Coefficient plot (DS20 fUll sample)
***************************************

ssc install coefplot

* Same sample as twowayfeweights for consistency
xtset hhid_num year

* CHIRPS
xtreg hh_int_mig_panel DS20 temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS20_chirps_full

* GSMAP
xtreg hh_int_mig_panel DS20_G temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS20_gsmap_full

* MSWEP
xtreg hh_int_mig_panel DS20_M temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS20_mswep_full

* TAMSAT
xtreg hh_int_mig_panel DS20_T temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS20_tamsat_full

* Plot
coefplot (DS20_chirps_full, label("CHIRPS") keep(DS20))          ///
         (DS20_gsmap_full,  label("GSMAP")  keep(DS20_G))        ///
         (DS20_mswep_full,  label("MSWEP")  keep(DS20_M))        ///
         (DS20_tamsat_full, label("TAMSAT") keep(DS20_T)),       ///
    level(90)                                                     ///
    xline(0, lcolor(red) lpattern(dash))                          ///
    coeflabels(DS20 = "CHIRPS" DS20_G = "GSMAP" DS20_M = "MSWEP" DS20_T = "TAMSAT") ///
    title("Dry Spell (20-day) Effect on Internal Migration")   ///
    subtitle("Full Sample")                                       ///
    xtitle("Coefficient Estimate")                                ///
    ytitle("")                                                     ///
    mcolor(navy) ciopts(lcolor(navy))  legend(off)                    ///
    note("*90% confidence intervals")                              ///
	 grid(none)      ///
	 xscale(range(-.17 .17))            ///
     xlabel(-.15(.05).15, grid)          
graph export "$Graph/coefplot_DS20_rainfall_datasets_full.png", replace width(2000)
estimates clear

***************************************
* 2  Coefficient plot (DS20 Groundnut + full sample)
***************************************
* CHIRPS
xtreg hh_int_mig_panel DS20 temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS20_chirps

* GSMAP
xtreg hh_int_mig_panel DS20_G temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS20_gsmap

* MSWEP
xtreg hh_int_mig_panel DS20_M temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS20_mswep

* TAMSAT
xtreg hh_int_mig_panel DS20_T temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS20_tamsat

* Plot
coefplot (DS20_chirps, label("CHIRPS") keep(DS20))          ///
         (DS20_gsmap,  label("GSMAP")  keep(DS20_G))        ///
         (DS20_mswep,  label("MSWEP")  keep(DS20_M))        ///
         (DS20_tamsat, label("TAMSAT") keep(DS20_T)),       ///
    level(90)                                                     ///
    xline(0, lcolor(red) lpattern(dash))                          ///
    coeflabels(DS20 = "CHIRPS" DS20_G = "GSMAP" DS20_M = "MSWEP" DS20_T = "TAMSAT") ///
    title("Dry Spell (20-day) Effect on Internal Migration")   ///
    subtitle("Groundnut Basin & full sample")                                       ///
    xtitle("Coefficient Estimate")                                ///
    ytitle("")                                                     ///
    mcolor(navy) ciopts(lcolor(navy))  legend(off)                    ///
    note("*90% confidence intervals")                              ///
	 grid(none)      ///
	 xscale(range(-.17 .17))            ///
     xlabel(-.15(.05).15, grid)          

graph export "$Graph/coefplot_DS20_rainfall_datasets_AEZ1+fullsample.png", replace width(2000)

estimates clear



***************************************
* 2  Coefficient plot (DS20 Groundnut)
***************************************
* CHIRPS
xtreg hh_int_mig_panel DS20 temp_anomaly i.year if AEZ==1 , fe vce(cluster ea_id)
estimates store DS20_chirps

* GSMAP
xtreg hh_int_mig_panel DS20_G temp_anomaly i.year if AEZ==1 , fe vce(cluster ea_id)
estimates store DS20_gsmap

* MSWEP
xtreg hh_int_mig_panel DS20_M temp_anomaly i.year if AEZ==1 , fe vce(cluster ea_id)
estimates store DS20_mswep

* TAMSAT
xtreg hh_int_mig_panel DS20_T temp_anomaly i.year if AEZ==1 , fe vce(cluster ea_id)
estimates store DS20_tamsat

* Plot
coefplot (DS20_chirps, label("CHIRPS") keep(DS20))          ///
         (DS20_gsmap,  label("GSMAP")  keep(DS20_G))        ///
         (DS20_mswep,  label("MSWEP")  keep(DS20_M))        ///
         (DS20_tamsat, label("TAMSAT") keep(DS20_T)),       ///
    level(90)                                                     ///
    xline(0, lcolor(red) lpattern(dash))                          ///
    coeflabels(DS20 = "CHIRPS" DS20_G = "GSMAP" DS20_M = "MSWEP" DS20_T = "TAMSAT") ///
    title("Dry Spell (20-day) Effect on Internal Migration")   ///
    subtitle("Groundnut Basin")                                       ///
    xtitle("Coefficient Estimate")                                ///
    ytitle("")                                                     ///
    mcolor(navy) ciopts(lcolor(navy))  legend(off)                    ///
    note("*90% confidence intervals")                              ///
	 grid(none)      ///
	 xscale(range(-.17 .17))            ///
     xlabel(-.15(.05).15, grid)          

graph export "$Graph/coefplot_DS20_rainfall_datasets_AEZ1.png", replace width(2000)

estimates clear



***************************************
* 1 Coefficient plot (DS14 fUll sample)
***************************************

* Same sample as twowayfeweights for consistency
xtset hhid_num year

* CHIRPS
xtreg hh_int_mig_panel DS14 temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS14_chirps_full

* GSMAP
xtreg hh_int_mig_panel DS14_G temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS14_gsmap_full

* MSWEP
xtreg hh_int_mig_panel DS14_M temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS14_mswep_full

* TAMSAT
xtreg hh_int_mig_panel DS14_T temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS14_tamsat_full

* Plot
coefplot (DS14_chirps_full, label("CHIRPS") keep(DS14))          ///
         (DS14_gsmap_full,  label("GSMAP")  keep(DS14_G))        ///
         (DS14_mswep_full,  label("MSWEP")  keep(DS14_M))        ///
         (DS14_tamsat_full, label("TAMSAT") keep(DS14_T)),       ///
    level(90)                                                     ///
    xline(0, lcolor(red) lpattern(dash))                          ///
    coeflabels(DS14 = "CHIRPS" DS14_G = "GSMAP" DS14_M = "MSWEP" DS14_T = "TAMSAT") ///
    title("Dry Spell (14-day) Effect on Internal Migration")   ///
    subtitle("Full Sample")                                       ///
    xtitle("Coefficient Estimate")                                ///
    ytitle("")                                                     ///
    mcolor(navy) ciopts(lcolor(navy))  legend(off)                    ///
    note("*90% confidence intervals")                              ///
	 grid(none)      ///
     xlabel(-.1(.05).1, grid)          
graph export "$Graph/coefplot_DS14_rainfall_datasets_full.png", replace width(2000)
estimates clear

***************************************
* 2  Coefficient plot (DS14 Groundnut)
***************************************
* CHIRPS
xtreg hh_int_mig_panel DS14 temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS14_chirps

* GSMAP
xtreg hh_int_mig_panel DS14_G temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS14_gsmap

* MSWEP
xtreg hh_int_mig_panel DS14_M temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS14_mswep

* TAMSAT
xtreg hh_int_mig_panel DS14_T temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS14_tamsat

* Plot
coefplot (DS14_chirps, label("CHIRPS") keep(DS14))          ///
         (DS14_gsmap,  label("GSMAP")  keep(DS14_G))        ///
         (DS14_mswep,  label("MSWEP")  keep(DS14_M))        ///
         (DS14_tamsat, label("TAMSAT") keep(DS14_T)),       ///
    level(90)                                                     ///
    xline(0, lcolor(red) lpattern(dash))                          ///
    coeflabels(DS14 = "CHIRPS" DS14_G = "GSMAP" DS14_M = "MSWEP" DS14_T = "TAMSAT") ///
    title("Dry Spell (14-day) Effect on Internal Migration")   ///
    subtitle("Groundnut Basin & full sample")                                       ///
    xtitle("Coefficient Estimate")                                ///
    ytitle("")                                                     ///
    mcolor(navy) ciopts(lcolor(navy))  legend(off)                    ///
    note("*90% confidence intervals")                              ///
	 grid(none)      ///
     xlabel(-.1(.05).1, grid)          

graph export "$Graph/coefplot_DS14_rainfall_datasets_AEZ1+fullsample.png", replace width(2000)

estimates clear



***************************************
* 2  Coefficient plot (DS14 Groundnut)
***************************************
* CHIRPS
xtreg hh_int_mig_panel DS14 temp_anomaly i.year if AEZ==1 , fe vce(cluster ea_id)
estimates store DS14_chirps

* GSMAP
xtreg hh_int_mig_panel DS14_G temp_anomaly i.year if AEZ==1 , fe vce(cluster ea_id)
estimates store DS14_gsmap

* MSWEP
xtreg hh_int_mig_panel DS14_M temp_anomaly i.year if AEZ==1 , fe vce(cluster ea_id)
estimates store DS14_mswep

* TAMSAT
xtreg hh_int_mig_panel DS14_T temp_anomaly i.year if AEZ==1 , fe vce(cluster ea_id)
estimates store DS14_tamsat

* Plot
coefplot (DS14_chirps, label("CHIRPS") keep(DS14))          ///
         (DS14_gsmap,  label("GSMAP")  keep(DS14_G))        ///
         (DS14_mswep,  label("MSWEP")  keep(DS14_M))        ///
         (DS14_tamsat, label("TAMSAT") keep(DS14_T)),       ///
    level(90)                                                     ///
    xline(0, lcolor(red) lpattern(dash))                          ///
    coeflabels(DS14 = "CHIRPS" DS14_G = "GSMAP" DS14_M = "MSWEP" DS14_T = "TAMSAT") ///
    title("Dry Spell (14-day) Effect on Internal Migration")   ///
    subtitle("Groundnut Basin")                                       ///
    xtitle("Coefficient Estimate")                                ///
    ytitle("")                                                     ///
    mcolor(navy) ciopts(lcolor(navy))  legend(off)                    ///
    note("*90% confidence intervals")                              ///
	 grid(none)      ///
	 xscale(range(-.17 .17))            ///
     xlabel(-.15(.05).15, grid)          

graph export "$Graph/coefplot_DS14_rainfall_datasets_AEZ1.png", replace width(2000)

estimates clear



**************************************
* 1 Coefficient plot (DS30 fUll sample)
***************************************

* Same sample as twowayfeweights for consistency
xtset hhid_num year

* CHIRPS
xtreg hh_int_mig_panel DS30 temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS30_chirps_full

* GSMAP
xtreg hh_int_mig_panel DS30_G temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS30_gsmap_full

* MSWEP
xtreg hh_int_mig_panel DS30_M temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS30_mswep_full

* TAMSAT
xtreg hh_int_mig_panel DS30_T temp_anomaly i.year if panel==1, fe vce(cluster ea_id)
estimates store DS30_tamsat_full

* Plot
coefplot (DS30_chirps_full, label("CHIRPS") keep(DS30))          ///
         (DS30_gsmap_full,  label("GSMAP")  keep(DS30_G))        ///
         (DS30_mswep_full,  label("MSWEP")  keep(DS30_M))        ///
         (DS30_tamsat_full, label("TAMSAT") keep(DS30_T)),       ///
    level(90)                                                     ///
    xline(0, lcolor(red) lpattern(dash))                          ///
    coeflabels(DS30 = "CHIRPS" DS30_G = "GSMAP" DS30_M = "MSWEP" DS30_T = "TAMSAT") ///
    title("Dry Spell (30-day) Effect on Internal Migration")   ///
    subtitle("Full Sample")                                       ///
    xtitle("Coefficient Estimate")                                ///
    ytitle("")                                                     ///
    mcolor(navy) ciopts(lcolor(navy))  legend(off)                    ///
    note("*90% confidence intervals")                              ///
	 grid(none)      ///
	 xscale(range(-.17 .17))            ///
     xlabel(-.15(.05).15, grid)          
graph export "$Graph/coefplot_DS30_rainfall_datasets_full.png", replace width(2000)
estimates clear

***************************************
* 2  Coefficient plot (DS30 Groundnut)
***************************************
* CHIRPS
xtreg hh_int_mig_panel DS30 temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS30_chirps

* GSMAP
xtreg hh_int_mig_panel DS30_G temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS30_gsmap

* MSWEP
xtreg hh_int_mig_panel DS30_M temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS30_mswep

* TAMSAT
xtreg hh_int_mig_panel DS30_T temp_anomaly i.year if AEZ==1 & panel==1, fe vce(cluster ea_id)
estimates store DS30_tamsat

* Plot
coefplot (DS30_chirps, label("CHIRPS") keep(DS30))          ///
         (DS30_gsmap,  label("GSMAP")  keep(DS30_G))        ///
         (DS30_mswep,  label("MSWEP")  keep(DS30_M))        ///
         (DS30_tamsat, label("TAMSAT") keep(DS30_T)),       ///
    level(90)                                                     ///
    xline(0, lcolor(red) lpattern(dash))                          ///
    coeflabels(DS30 = "CHIRPS" DS30_G = "GSMAP" DS30_M = "MSWEP" DS30_T = "TAMSAT") ///
    title("Dry Spell (30-day) Effect on Internal Migration")   ///
    subtitle("Groundnut Basin & full sample")                                       ///
    xtitle("Coefficient Estimate")                                ///
    ytitle("")                                                     ///
    mcolor(navy) ciopts(lcolor(navy))  legend(off)                    ///
    note("*90% confidence intervals")                              ///
	 grid(none)      ///
	 xscale(range(-.17 .17))            ///
     xlabel(-.15(.05).15, grid)          

graph export "$Graph/coefplot_DS30_rainfall_datasets_AEZ1+full.png", replace width(2000)

estimates clear

