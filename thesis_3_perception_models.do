*=======================================================================
*MODEL
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

use "$data/PASSAU_THESIS_MODELO.dta" ,replace
xtset  hhid year  

**MODEL
gen rain_decrease_dummy = .
replace rain_decrease_dummy = 1 if rainfall_change_cat3 == 1
replace rain_decrease_dummy = 0 if rainfall_change_cat3 == 3
label define rain_decr_lbl 1 "Decreased" 0 "Increased"
label values rain_decrease_dummy rain_decr_lbl
label variable rain_decrease_dummy "Rainfall change over past 10 years"
drop rainfall_change_cat3 
rename rain_decrease_dummy rainfall_change_cat3 

rename tendencia_cat_nacional tendencia_cat_nacional_regional 
gen tendencia_dummy = .
replace tendencia_dummy = 1 if tendencia_cat_nacional_regional == 1
replace tendencia_dummy = 0 if tendencia_cat_nacional_regional == 2   //
label define tendencia_lbl 1 "Decreciente" 0 "Creciente"
label values tendencia_dummy tendencia_lbl
label variable tendencia_dummy "Tendencia nacional y regional (1950-2024)"
drop tendencia_cat_nacional_regional
rename tendencia_dummy tendencia_cat_nacional_regional

gen tendencia_creciente = .
replace tendencia_creciente = 1 if tendencia_cat == 1
replace tendencia_creciente = 0 if tendencia_cat == 2
label define crec_lbl 1 "Creciente" 0 "Estable"
label values tendencia_creciente crec_lbl
label variable tendencia_creciente "Tendencia rainy season village (1981-2024)"
drop tendencia_cat

gen rainfall_eval_new = .
replace rainfall_eval_new = 1 if d_rainfall_t_m1_lag == 0
replace rainfall_eval_new = 0 if d_rainfall_t_m1_lag == 1

label define rain_eval_lbl 1 "Apropiate/Good/Very good" 0 "Bad/Very bad"
label values rainfall_eval_new rain_eval_lbl
label variable rainfall_eval_new "correlacion de person rainfall"
**********************************************************************************+++

keep ea_id year hhid  region  AEZ drought_severity moist_severity wet_density spei_growing_avg tendencia_creciente tendencia_cat_nacional rain_variability l_rainfall_quality_t_m1  d_rainfall_t_m1_lag l_rainfall_problem_t_m1 bad_drought bad_irregular bad_flooding drought_binary moist_binary rainfall_eval_new land_type_own_agricultural land_type_no_ownership land_size land_irrigation irrigation_water hh_crop_irrigate_1   irrigation_dummy any_irrigation_hurdle irrigation_water_source land_fertilizer ln_income_agric_1 hh_relative_wealth adapt3cat any_adapt_strateg_past rainfall_change_cat3  any_farmingchallenge weather_source_1 trust_source_1 weather_source_own rain_quality_present hh_rainfall_problem_present  crop_seasons_1   harvest_binary hh_crop_harvest_1  

order ea_id year hhid  region  AEZ drought_severity moist_severity wet_density spei_growing_avg tendencia_creciente tendencia_cat_nacional rain_variability l_rainfall_quality_t_m1  d_rainfall_t_m1_lag l_rainfall_problem_t_m1 bad_drought bad_irregular bad_flooding drought_binary moist_binary rainfall_eval_new land_type_own_agricultural land_type_no_ownership land_size land_irrigation irrigation_water hh_crop_irrigate_1 irrigation_dummy any_irrigation_hurdle irrigation_water_source land_fertilizer ln_income_agric_1 hh_relative_wealth  adapt3cat any_adapt_strateg_past rainfall_change_cat3  any_farmingchallenge weather_source_1 trust_source_1 weather_source_own rain_quality_present hh_rainfall_problem_present  crop_seasons_1   harvest_binary hh_crop_harvest_1 

**==============================================================================**
**Descriptive continues variables (region and year)
**==============================================================================**
* Variable labels
label variable drought_severity "Drought exposure (% of dry months in growing season)"
label variable moist_severity   "Moist exposure (% of moist months in growing season)"
label variable wet_density      "Share of rainy season months wetter than 1990–2024 average"
label variable moist_binary	"Binary moist exposure (growing season)"					 
label variable ln_income_agric_1	 "HH log agri income"

**==============================================================================**
**Descriptive ordinal variables (region and year)
**==============================================================================**
label variable l_rainfall_quality_t_m1 "Rainfall quality (t-1)"
label variable adapt3cat          "HH adapt to env. change"
label variable d_rainfall_t_m1_lag "Rainfall quality (t-1)"
label variable rain_variability "Cv variability  of rainy season 1981-2024"

**==============================================================================**
**Descriptive nominal variables (region and year)
**==============================================================================**
label define badcat_lbl 0 "No"  1 "Yes"
label values  bad_drought bad_irregular bad_flooding  badcat_lbl
label variable land_type_own_agricultural  "Own agricultural land"
label variable land_irrigation             "Irrigates cultivated land"
label variable hh_crop_irrigate_1          "Main irrigated crop"
label variable l_rainfall_problem_t_m1     "Rainfall problem t-1"
label variable bad_drought                 "Bad rainfall + drought"
label variable bad_irregular               "Bad + irregular rainfall (dummy)"
label variable bad_flooding                "Bad rainfall + flooding"
label variable irrigation_dummy            "Land irrigated (dummy)"
label variable drought_binary   "Binary drought exposure (growing season)"
label variable moist_binary "Binary moist exposure (growing season)"

**==============================================================================**
*SPEARMAN CORRELATION
**==============================================================================**
**Annual alignment //it cannot be done, the trend does not vary

**TEST 1
spearman rainfall_eval_new tendencia_creciente, stats(rho p) // 

preserve
foreach var in rainfall_eval_new tendencia_creciente  {
    egen `var'_rank = rank(`var')
    cap label variable `var'_rank "`: var label `var''"
    drop `var'
    rename `var'_rank `var'
}
estpost corr rainfall_eval_new tendencia_creciente, matrix
esttab ., ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
	
esttab using "$res/correlation_alineacion_rainy_season.csv", ///   
    replace ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
restore


**TEST 2
*** rainfall quality * drought 

spearman d_rainfall_t_m1_lag drought_binary, stats(rho p) // solo 

preserve
foreach var in d_rainfall_t_m1_lag drought_binary {
    egen `var'_rank = rank(`var')
    cap label variable `var'_rank "`: var label `var''"
    drop `var'
    rename `var'_rank `var'
}
estpost corr d_rainfall_t_m1_lag drought_binary , matrix
esttab ., ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
	
esttab using "$res/correlation_Alineacion_badrain_drought.csv", ///   
    replace ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
restore

*TEST 3
*****Variable rainfall quality * moist 

spearman d_rainfall_t_m1_lag  moist_binary, stats(rho p) // solo 

preserve
foreach var in d_rainfall_t_m1_lag  moist_binary {
    egen `var'_rank = rank(`var')
    cap label variable `var'_rank "`: var label `var''"
    drop `var'
    rename `var'_rank `var'
}
estpost corr d_rainfall_t_m1_lag  moist_binary , matrix
esttab ., ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
	
esttab using "$res/correlation_Alineacion_badrain_moist.csv", ///   
    replace ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
restore

*TEST 4
**Irregula rainfall 
spearman bad_irregular rain_variability, stats(rho p) // 

preserve
foreach var in bad_irregular rain_variability  {
    egen `var'_rank = rank(`var')
    cap label variable `var'_rank "`: var label `var''"
    drop `var'
    rename `var'_rank `var'
}
estpost corr bad_irregular rain_variability, matrix
esttab ., ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
	
esttab using "$res/correlation_alineacion_irregular_rain.csv", ///   
    replace ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
restore

*TEST 5 
***Extreme events: drought
spearman bad_drought drought_binary, stats(rho p) // 

preserve
foreach var in bad_drought drought_binary  {
    egen `var'_rank = rank(`var')
    cap label variable `var'_rank "`: var label `var''"
    drop `var'
    rename `var'_rank `var'
}
estpost corr bad_drought drought_binary, matrix
esttab ., ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
	
esttab using "$res/correlation_alineacion_extrem_drought.csv", ///   
    replace ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
restore

**TEST 6 
**Extreme events: drought
spearman bad_flooding moist_binary, stats(rho p) // 

preserve
foreach var in bad_flooding moist_binary  {
    egen `var'_rank = rank(`var')
    cap label variable `var'_rank "`: var label `var''"
    drop `var'
    rename `var'_rank `var'
}
estpost corr bad_flooding moist_binary, matrix
esttab ., ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
	
esttab using "$res/correlation_alineacion_extrem_moist.csv", ///   
    replace ///
    b(3) unstack label compress ///
    star(* 0.05) ///
    stats(N, labels("N")) ///
    nonum nomtitle not
restore


**==============================================================================**
**Dummy variables
**==============================================================================**

**NOTES: VARIABLE AND QUESTION 
*Agriculture characteristics of the hosueholds 
/*land_size	B48: Total land size in hectares of your cultivated agricultural land
land_type_own_agricultural:	Land Ownership: Own Agricultural Land--- Please select all types of land you make use of, and their mode of ownership
land_type_no_ownership: Cultivate land but no ownership

**Irrigation
land_irrigation:	Do you irrigate your cultivated agricultural land? If yes, all of it or parts of
 irrigation_dummy "Is your cultivated agricultural land irrigated?"
hh_crop_irrigate_1     Did you irrigate most important crop during this period?
irrigation_water	In the last year, did the irrigation system provide sufficient water when it was
irrigation_water_source  Which type of irrigation system(s) or method(s) do you use on your field?? If you use multiple irrigation systems, then select the one you use most often.
any_irrigation_hurdle: Why don't you irrigate?

*Adapt startegies 
land_fertilizer Do you use chemical fertilizer for farming?
any_adapt_strateg_past: Have you or your household ever carried out one of the following adaptation strategies in the last 12 months? Select all that apply.
adapt3cat: For your household, do you find it easy or difficult to adapt to environmental change?

**FARMING CHALLENGES 
any_farmingchallenge: In your opinion, what are the main challenges for farming in general? Name up to three.

**OTHERS 
crop_seasons_1:Did you grow most importan crop in the dry or rainy season or both?
hh_crop_harvest_1	Compared to previous harvests, was the harvest for the crop Nr.1 in t-1/t go

*/
**Adjusting variables for my dummy model
**Irrigation "In the last year, did the irrigation system provide sufficient water when it was"
gen irrig_water_allno = .
replace irrig_water_allno = 1 if inlist(irrigation_water, 0, 2, 3)
replace irrig_water_allno = 0 if irrigation_water == 1
label define irrig_all_lbl 1 "No" 0 "Yes"
label values irrig_water_allno irrig_all_lbl
label variable irrig_water_allno "Irrigation provide enough water (last year)" // decir 
drop irrigation_water 
rename irrig_water_allno irrigation_water 

**IRRIGATED MOST IMPORTAN CROP 
gen irrigate_new = .
replace irrigate_new = 1 if hh_crop_irrigate_1 == 0
replace irrigate_new = 0 if hh_crop_irrigate_1 == 1

label define irrig_new_lbl 1 "No" 0 "Yes"
label values irrigate_new irrig_new_lbl
label variable irrigate_new "Irrigated most importan crop"
drop hh_crop_irrigate_1
rename irrigate_new hh_crop_irrigate_1

*** Difficult to adapat 
gen adapt_difficult = .
replace adapt_difficult = 1 if adapt3cat == 3
replace adapt_difficult = 0 if inlist(adapt3cat, 1, 2)

label define adaptdiff_lbl 1 "Difficult to adapt" 0 "Easy/Neutral"
label values adapt_difficult adaptdiff_lbl
label variable adapt_difficult "Difficult to adapt (dummy)"
drop adapt3cat
rename adapt_difficult adapt3cat

*** No adaptation reported 
gen no_adapt_dummy = .
replace no_adapt_dummy = 1 if any_adapt_strateg_past == 0
replace no_adapt_dummy = 0 if any_adapt_strateg_past == 1

label define noadapt_lbl 1 "No adaptation reported" 0 "At least one adaptation"
label values no_adapt_dummy noadapt_lbl
label variable no_adapt_dummy "No adaptation reported "
drop  any_adapt_strateg_past
rename no_adapt_dummy any_adapt_strateg_past

** No fertlizer
gen fert_no_dummy = .
replace fert_no_dummy = 1 if land_fertilizer == 0
replace fert_no_dummy = 0 if land_fertilizer == 1

label define fert_no_lbl 1 "No" 0 "Yes"
label values fert_no_dummy fert_no_lbl
label variable fert_no_dummy "No fertilizer "
drop land_fertilizer
rename fert_no_dummy land_fertilizer

***Rainy season 
gen crop_rainy_dummy = .
replace crop_rainy_dummy = 1 if crop_seasons_1 == 1
replace crop_rainy_dummy = 0 if inlist(crop_seasons_1, 0, 2)

label define crop_rainy_lbl 1 "Rainy" 0 "Dry/Both"
label values crop_rainy_dummy crop_rainy_lbl
label variable crop_rainy_dummy "rainy most importan season "
drop crop_seasons_1 
rename crop_rainy_dummy crop_seasons_1 

** Controls
global I1 " i.irrigation_dummy i.irrigation_water_source i.hh_crop_irrigate_1" 
global A1 "i.adapt3cat i.any_adapt_strateg_past i.land_fertilizer"
global C1 "i.crop_seasons_1 i.harvest_binary"

**==============================================================================**
**MODEL Table 17: Rainfall Perception and Observed Moist Condition
**==============================================================================**

xtreg bad_flooding  i.moist_binary i.year, fe vce(robust)
outreg2 using "$res/model_4.doc", ///
    stats(coef se) ///
    title("Linear Probability Model of Rainfall excessive rainfall Perception and Moist exposure") ///
    ctitle("LPM") ///
    sdec(2) bdec(3) r2 ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
    addnote("Column 1: Baseline model | Column 2: Adding land irrigation| Column 3: Adding adaptation to environmental change | Column 4: Adding importan season for grow and Perception of harvest") ///
    replace
xtreg bad_flooding  i.moist_binary##($I1) i.year, fe vce(robust)
	outreg2 using "$res/model_4.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg bad_flooding  i.moist_binary##($I1 $A1) i.year, fe vce(robust)
	outreg2 using "$res/model_4.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg bad_flooding  i.moist_binary##($I1 $A1 $C1)  i.year, fe vce(robust)
	outreg2 using "$res/model_4.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append

**==============================================================================**
**MODEL Table 16: Rainfall Perception and Observed Drought Condition
**==============================================================================**	

xtreg bad_drought  i.drought_binary i.year, fe vce(robust)
outreg2 using "$res/model_5.doc", ///
    stats(coef se) ///
    title("Linear Probability Model of bad rainfall and drought Perception and Moist exposure") ///
    ctitle("LPM") ///
    sdec(2) bdec(3) r2 ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
    addnote("Column 1: Baseline model | Column 2: Adding land irrigation| Column 3: Adding adaptation to environmental change | Column 4: Adding importan season for grow and Perception of harvest") ///
    replace
xtreg bad_drought  i.drought_binary##($I1) i.year, fe vce(robust)
	outreg2 using "$res/model_5.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg bad_drought  i.drought_binary##($I1 $A1) i.year, fe vce(robust)
	outreg2 using "$res/model_5.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg bad_drought  i.drought_binary##($I1 $A1 $C1)  i.year, fe vce(robust)
	outreg2 using "$res/model_5.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append

/**==============================================================================**
**MODEL OTHERS: NOT FOUND IN THE THESIS 
**==============================================================================**

***Linear Probability Model of Rainfall Perception and Moist exposure
xtreg d_rainfall_t_m1_lag  i.moist_binary i.year, fe vce(robust)
estimates store M1
outreg2 using "$res/model_1.doc", ///
    stats(coef se ) ///
    title("Linear Probability Model of Rainfall Perception and Moist exposure") ///
    ctitle("LPM") ///
    sdec(2) bdec(3) r2 ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
    addnote("Column 1: Baseline model | Column 2: Adding land irrigation| Column 3: Adding adaptation to environmental change | Column 4: Adding importan season for grow and Perception of harvest") ///
    replace
xtreg d_rainfall_t_m1_lag  i.moist_binary##($I1) i.year, fe vce(robust)
estimates store M2
outreg2 using "$res/model_1.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
    append
xtreg d_rainfall_t_m1_lag  i.moist_binary##($I1 $A1) i.year , fe vce(robust)
estimates store M3
outreg2 using "$res/model_1.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg d_rainfall_t_m1_lag  i.moist_binary##($I1 $A1 $C1) i.year, fe vce(robust)
estimates store M4
outreg2 using "$res/model_1.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
	
***Linear Probability Model of Rainfall Perception and Drought exposure
xtreg d_rainfall_t_m1_lag  i.drought_binary i.year, fe vce(robust)
outreg2 using "$res/model_2.doc", ///
    stats(coef se) ///
    title("Linear Probability Model of Rainfall Perception and Drought exposure") ///
    ctitle("LPM") ///
    sdec(2) bdec(3) r2 ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
    addnote("Column 1: Baseline model | Column 2: Adding land irrigation| Column 3: Adding adaptation to environmental change | Column 4: Adding importan season for grow and Perception of harvest") ///
    replace
xtreg d_rainfall_t_m1_lag  i.drought_binary##($I1) i.year, fe vce(robust)
	outreg2 using "$res/model_2.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg d_rainfall_t_m1_lag  i.drought_binary##($I1 $A1) i.year, fe vce(robust)
	outreg2 using "$res/model_2.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg d_rainfall_t_m1_lag  i.drought_binary##($I1 $A1 $C1)  i.year, fe vce(robust)
	outreg2 using "$res/model_2.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append


***Linear Probability Model of Rainfall Perception (IRREGULAR) and moist binary
xtreg bad_irregular  i.moist_binary i.year, fe vce(robust)
outreg2 using "$res/model_3.doc", ///
    stats(coef se) ///
    title("Linear Probability Model of Rainfall irregular Perception and Moist exposure") ///
    ctitle("LPM") ///
    sdec(2) bdec(3) r2 ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
    addnote("Column 1: Baseline model | Column 2: Adding land irrigation| Column 3: Adding adaptation to environmental change | Column 4: Adding importan season for grow and Perception of harvest") ///
    replace
xtreg bad_irregular  i.moist_binary##($I1) i.year, fe vce(robust)
	outreg2 using "$res/model_3.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg bad_irregular  i.moist_binary##($I1 $A1) i.year, fe vce(robust)
	outreg2 using "$res/model_3.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
xtreg bad_irregular  i.moist_binary##($I1 $A1 $C1)  i.year, fe vce(robust)
	outreg2 using "$res/model_3.doc", ctitle("LPM") ///
	addstat("F-statistic", e(F), "p-value", e(p)) ///
	append
*/

**==============================================================================**
** Appendix P: Two-sample t-test (moist condition=1)
**==============================================================================**

* A) Detect panel and xtset time
quietly xtset
local idvar = r(panelvar)
local tvar  = r(timevar)

* B) Baseline setting: first period observed by panel
capture drop baseline
bysort `idvar' (`tvar'): gen byte baseline = (`tvar' == `tvar'[1])

local covars ///
    irrigation_dummy ///
    irrigation_water_source ///
    hh_crop_irrigate_1 ///
    adapt3cat ///
    any_adapt_strateg_past ///
    land_fertilizer ///
    crop_seasons_1 ///
    harvest_binary

* D) Initialize matrix
matrix BAL = J(1, 7, .)
local rownames

* E) Loop balance (baseline) por moist_binary
foreach v of varlist `covars' {
    cap confirm numeric var `v'
    if _rc==0 {
        quietly ttest `v' if baseline==1, by(moist_binary)
        local N0   = r(N_1)
        local mu0  = r(mu_1)
        local sd0  = r(sd_1)
        local N1   = r(N_2)
        local mu1  = r(mu_2)
        local sd1v = r(sd_2)
        local diff = r(mu_2) - r(mu_1)
        local pval = r(p)

        scalar sd_pool = .
        if (`N0' + `N1' - 2) > 0 {
            scalar sd_pool = sqrt(((`N0'-1)*`sd0'^2 + (`N1'-1)*`sd1v'^2) / (`N0'+`N1'-2))
        }
        local smd = .
        if (sd_pool<. & sd_pool>0) local smd = (`mu1' - `mu0')/sd_pool

        matrix BAL = (BAL \ `N0', `mu0', `N1', `mu1', `diff', `smd', `pval')
        local rownames `rownames' `v'
    }
}

* F) Clean and label
matrix BAL = BAL[2..., 1..7]
matrix rownames BAL = `rownames'
matrix colnames BAL = "N control" "Mean control" "N treatment" "Mean treatment" ///
                      "Mean diff (T-C)" "SMD" "P-Value"

* G)Preview
matrix list BAL, format(%9.3f)

* H) Export DOCX
putdocx begin
putdocx paragraph, style(Title)
putdocx text ("Balance at baseline by moist_binary"), bold
putdocx paragraph
putdocx text ("Notes: baseline = first observed year per household; diff = treatment - control; SMD = standardized mean difference.")
putdocx table T1 = matrix(BAL), rownames colnames nformat(%9.3f)
putdocx save "$res/balance_moist_baseline.docx", replace

**==============================================================================**
** Appendix Q: Two-sample t-test (drought condition=1)
**==============================================================================**
	
* --- Balance at baseline by drought_binary ---

* A) Detect panel and xtset time
quietly xtset
local idvar = r(panelvar)
local tvar  = r(timevar)

* B) Baseline setting: first period observed by panel
capture drop baseline
bysort `idvar' (`tvar'): gen byte baseline = (`tvar' == `tvar'[1])

* C) List of covariates (numeric)
local covars ///
    irrigation_dummy ///
    irrigation_water_source ///
    hh_crop_irrigate_1 ///
    adapt3cat ///
    any_adapt_strateg_past ///
    land_fertilizer ///
    crop_seasons_1 ///
    harvest_binary

* (Optional, recommended) keep only those that exist and are numeric
capture unab COVARS : `covars'
quietly ds `COVARS', has(type numeric)
local COVARS_NUM `r(varlist)'

* D) Initialize matrix
matrix BAL_D = J(1, 7, .)
local rownamesD

* E) Loop balance (baseline) by drought_binary
foreach v of local COVARS_NUM {
    cap noisily ttest `v' if baseline==1, by(drought_binary)
    if _rc==0 {
        local N0   = r(N_1)
        local mu0  = r(mu_1)
        local sd0  = r(sd_1)
        local N1   = r(N_2)
        local mu1  = r(mu_2)
        local sd1v = r(sd_2)
        local diff = r(mu_2) - r(mu_1)   // (Tratado - Control)
        local pval = r(p)

        * SMD (pooled SD)
        scalar sd_pool = .
        if (`N0' + `N1' - 2) > 0 {
            scalar sd_pool = sqrt(((`N0'-1)*`sd0'^2 + (`N1'-1)*`sd1v'^2) / (`N0'+`N1'-2))
        }
        local smd = .
        if (sd_pool<. & sd_pool>0) local smd = (`mu1' - `mu0')/sd_pool

        matrix BAL_D = (BAL_D \ `N0', `mu0', `N1', `mu1', `diff', `smd', `pval')
        local rownamesD `rownamesD' `v'
    }
}

* F) Clean and label
matrix BAL_D = BAL_D[2..., 1..7]
matrix rownames BAL_D = `rownamesD'
matrix colnames BAL_D = "N control" "Mean control" "N treatment" "Mean treatment" ///
                        "Mean diff (T-C)" "SMD" "P-Value"

* G) Preview
matrix list BAL_D, format(%9.3f)

* H) Export DOCX
putdocx begin
putdocx paragraph, style(Title)
putdocx text ("Balance at baseline by drought_binary"), bold
putdocx paragraph
putdocx text ("Notes: baseline = first observed year per household; diff = treatment - control; SMD = standardized mean difference.")
putdocx table T2 = matrix(BAL_D), rownames colnames nformat(%9.3f)
putdocx save "$res/balance_drought_baseline.docx", replace
























 