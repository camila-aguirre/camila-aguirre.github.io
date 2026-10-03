************************************************
*** BUILD IRREGULAR RAIN MEASURE ***************



***********************************************************************
*** 10. BUILD IRREGULAR RAIN MEASURE WITH DAILY Rainfall Data  ***

* Project: Weather Shocks and Migration Responses in Senegal
* Author: Nils Haveresch
* Last edited: 11 April 2026
***********************************************************************

clear all
version 16.1
set more off
capture log close

////////////////////////////////
// 0. Load raw rainfall data
////////////////////////////////


global dir "."   // change to your project folder
	global data "$dir/DATA" 		// where data is saved
	global res "$dir/RESULTS" 		// where results should be saved
	global log "$dir/LOGS" 			// where Log-File should be saved
	global Graph "$dir/GRAPHS" 

**log using "$log/RWI_1.log",replace // create new Log-File
	set more off
	

* Load data
use "$data/GSMAP_Senegal_Villages_2010_2024.dta", replace


/////////////////////////////
// Prepare data
/////////////////////////////


* IF APPLICABLE: replace missing values for department and region
rename dailyprecipgc precipitation
drop longitude latitude dailyprecip gaugequalityinfo region

merge m:1 ea_id using village_sample_V0.dta

drop _merge

* [Village-specific corrections of department/region names omitted for confidentiality]

***********************************************************



*****************************************************
// Step 1: Convert and extract date components
*****************************************************

gen date_stata = date(date, "YMD")
format date_stata %td
gen year  = year(date_stata)
gen month = month(date_stata)
gen day   = day(date_stata)

* Create identifier for calendar day (e.g., "06-15")
gen day_id = string(month, "%02.0f") + "-" + string(day, "%02.0f")


********************************************************************************
* STEP 2: Define sample regions
********************************************************************************
gen smp_region = .  
replace smp_region = 1 if region == "KAOLACK"
replace smp_region = 2 if region == "SEDHIOU"
replace smp_region = 3 if region == "MATAM"
replace smp_region = 4 if region == "THIES"
replace smp_region = 5 if smp_region == .  // all others

label define smp_region_lbl ///
    1 "Focus Sample Kaolack" ///
    2 "Focus Sample Sedhiou" ///
    3 "Focus Sample Matam" ///
    4 "Irrigation Sample" ///
    5 "National Sample"
label values smp_region smp_region_lbl


/*
EXPLANATION until Step 8 (line 294)

********************************************************************************************************************************************************************************************************************
* Now work with 2010-2024 data. Identify the start of rainy season and lenght of subsequent dry spells

* Treated_1: Those villages experiencing dry spells >= 14 days  (dry spell _1: <1 mm per day)

* Preferred: Treated_5: Those villages experiencing dry spells >= 14 days  (dry spell _5: <5 mm per day) <-- seems appropriate threshold for agriculturally meaningful rainfall to induce sufficient soil moisture
***************************************************************************************************************************************************************************************************************



The code first converts the raw date variable (`date`) into a Stata date format (`date_stata`) and extracts the corresponding calendar components (`year`, `month`, `day`). It also creates a month–day identifier (`day_id`) to facilitate comparisons of the same calendar days across years.

Next, the data are restricted to the main growing season (May–October), ensuring that subsequent analysis focuses on the agriculturally relevant period. Two rainfall threshold indicators are then constructed: `rain_below_1mm`, which defines meteorological “dry days” (precipitation < 1 mm), and `rain_below_5mm`, which captures days with rainfall insufficient to meaningfully replenish soil moisture.

Using the daily rainfall data, the code identifies sequences of consecutive dry days. A binary variable (`dry`) marks days with precipitation below 1 mm. Based on this, each continuous sequence of dry days is assigned a unique identifier (`dry_spell_id`), and the length of each dry spell is calculated (`dry_spell_length`) as the number of consecutive dry days within that sequence.

The onset of the rainy season is then determined at the village-year level (`ea_id`, `year`). An onset candidate (`onset_candidate`) is defined as the first occurrence after May 1 (`after_may1`) of at least 15 mm of cumulative rainfall over three consecutive days (`rain_3day`). The earliest such event is recorded as the onset date (`first_onset` / `onset_date`), and a corresponding indicator (`is_onset`) flags this day.

Finally, the analysis is restricted to the post-onset period. A dummy variable (`rainy_season`) indicates all days on or after the onset date. The dry spell length is then redefined for this period (`dry_spell_length_r`), capturing only dry spells that occur after the start of the rainy season. This variable forms the basis for identifying agriculturally relevant early-season dry spells.



*/



********************************************************************************
* STEP 3: Keep growing season months (May–October)
********************************************************************************
keep if inlist(month, 5, 6, 7, 8, 9, 10)

********************************************************************************
* STEP 4: Basic rainfall dummies
********************************************************************************
gen rain_below_1mm = precipitation < 1
gen rain_below_5mm = precipitation < 5

label variable rain_below_1mm "Rainfall < 1mm (trace/negligible)"
label variable rain_below_5mm "Rainfall < 5mm (below soil moisture threshold)"

********************************************************************************
* STEP 5: Dry spell (<1mm) detection
********************************************************************************
sort ea_id year date_stata
gen dry = precipitation < 1
bysort ea_id year (date_stata): gen dry_spell_id = sum(dry == 0) + 1
gen dry_spell_length = .
bysort ea_id year dry_spell_id (date_stata): replace dry_spell_length = sum(dry == 1) if dry == 1
replace dry_spell_length = 0 if dry == 0

label var dry "Day with rainfall <1mm"
label var dry_spell_length "Consecutive days with rainfall <1mm"



********************************************************************************
* STEP 7: Identify rainy season onset
********************************************************************************
sort ea_id date_stata
xtset ea_id date_stata

gen after_may1 = (date_stata >= mdy(5,1,year))
gen rain_3day = precipitation + L1.precipitation + L2.precipitation
gen onset_candidate = (rain_3day >= 15 & after_may1 == 1) if !missing(rain_3day)
replace onset_candidate = 0 if missing(onset_candidate)

gen onset_date_candidate = .
replace onset_date_candidate = date_stata if onset_candidate == 1

bysort ea_id year (date_stata): egen first_onset = min(onset_date_candidate)

gen onset_date = .
replace onset_date = date_stata if date_stata == first_onset
gen is_onset = (date_stata == onset_date)

format onset_date_candidate onset_date first_onset %td
label var rain_3day "3-day rainfall sum"
label var first_onset "Start of rainy season (≥15mm in 3 days)"
label var is_onset "Rainy season onset flag"

********************************************************************************
* STEP 8: Restrict dry spell lengths to rainy season only
********************************************************************************
gen rainy_season = 0
bysort ea_id year (date_stata): replace rainy_season = 1 if !missing(first_onset) & date_stata >= first_onset

label var rainy_season "Dummy = 1 after onset"

gen dry_spell_length_r   = dry_spell_length   if rainy_season == 1
label var dry_spell_length_r   "Dry spell length <1mm during rainy season"





********************************************************************************
* LABEL VARIABLES THAT DO NOT HAVE LABELS YET
********************************************************************************

* From STEP 1
label var date_stata "Survey date (Stata date format)"
label var year       "Calendar year"
label var month      "Calendar month"
label var day        "Calendar day"
label var day_id     "Month-day identifier (MM-DD)"

* From STEP 2
label var smp_region "Sample region classification"


* From STEP 5
label var dry_spell_id "ID of each dry spell sequence"

* From STEP 7
label var after_may1          "Dummy: date is on/after May 1"
label var rain_3day           "3-day cumulative rainfall"
label var onset_candidate     "Dummy: meets onset criteria (≥15mm in 3 days)"
label var onset_date_candidate "Date flagged as possible rainy-season onset"
label var onset_date          "Final rainy-season onset date"
label var first_onset         "Earliest onset date per year"
label var is_onset            "Dummy: date is rainy-season onset"

* From STEP 8
label var rainy_season        "Dummy: inside rainy season period"
label var dry_spell_length_r  "Length of dry spell during rainy season (<1mm)"


/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

/*
EXPLANATION for code line 319-390


The code constructs measures of dry spells after the onset of the rainy season using daily precipitation data (`precipitation`) at the level of `ea_id` and `year`, and does so for multiple rainfall thresholds (`mm = 1,…,5`).

First, for each threshold `mm`, it defines a dry day indicator `dry_`mm'`, which equals 1 if daily rainfall is below the threshold (`precip_below_`mm'mm = precipitation < mm`) and the day occurs after the start of the rainy season (`after_onset_`mm' = date_stata > first_onset`). Thus, `dry_`mm'` identifies all days with insufficient rainfall following the onset of the rainy season.

Next, the code groups consecutive dry days (`dry_`mm' = 1`) into dry spells. This is done by assigning a unique identifier `dry_spell_id_`mm'` to each continuous sequence of dry days within a given `ea_id` and `year`. Using this grouping, it then calculates the length of each dry spell, stored in `dry_spell_length_`mm'`, which gives the total number of consecutive dry days in that spell.

The analysis then focuses on the first dry spell after the onset of the rainy season. For this purpose, the variable `first_dry_spell_length_`mm'`is created, which records the length of the dry spell with`dry_spell_id_`mm' = 1`, i.e. the first occurrence of a dry spell after `first_onset`.

To move from the daily level to the unit-year level, the data are collapsed by `ea_id`, `year`, and `smp_region`. This produces the variable `dry_spell_first_`mm'`, which captures the length of the first dry spell after onset for each unit-year. Based on this measure, a treatment indicator `treated_`mm'` is defined, which equals 1 if the first dry spell lasts more than 13 days (`dry_spell_first_`mm' > 13), and 0 otherwise.

Finally, both the unit-year treatment variables (`treated_`mm'`, `dry_spell_first_`mm'`) and the daily dry spell variables (`dry_`mm'`, `dry_spell_id_`mm'`, `dry_spell_length_`mm'`) are merged back into the full dataset, ensuring that each observation contains information on dry spell dynamics as well as the treatment status of its corresponding `ea_id`–`year`.


*/


preserve

foreach mm in 1 2 3 4 5 {
    restore
    preserve

    * Step 1: Mark dry days for threshold
    gen precip_below_`mm'mm = precipitation < `mm'
    gen after_onset_`mm' = date_stata > first_onset
    gen dry_`mm' = precip_below_`mm'mm & after_onset_`mm'

    * Step 2: Dry spell ID
    gen dry_spell_id_`mm' = .
    bysort ea_id year (date_stata): gen tag_`mm' = dry_`mm' != dry_`mm'[_n-1]
    bysort ea_id year (date_stata): replace dry_spell_id_`mm' = sum(tag_`mm') if dry_`mm'
    drop tag_`mm'

    * Step 3: Dry spell length
    gen dry_spell_length_`mm' = .
    bysort ea_id year dry_spell_id_`mm' (date_stata): gen _dslen_`mm' = cond(_n == 1, _N, .)
    bysort ea_id year dry_spell_id_`mm' (date_stata): replace dry_spell_length_`mm' = _dslen_`mm'[1] if dry_`mm'
    drop _dslen_`mm'

    * Step 4: First dry spell after onset
    gen first_dry_spell_length_`mm' = .
    bysort ea_id year (date_stata): replace first_dry_spell_length_`mm' = dry_spell_length_`mm' if dry_spell_id_`mm' == 1

    * Step 5: Save full daily data
    tempfile dsfull_`mm'
    save `dsfull_`mm'', replace

    * Step 6: Collapse to unit-year level for treatment dummy
    collapse (max) dry_spell_first_`mm' = first_dry_spell_length_`mm', by(ea_id year smp_region)
    gen treated_`mm' = dry_spell_first_`mm' > 13
    tempfile ds_`mm'
    save `ds_`mm'', replace
}

* Step 7: Restore and merge collapsed treatment indicators
restore
foreach mm in 1 2 3 4 5 {
    merge m:1 ea_id year smp_region using `ds_`mm''
    drop _merge
}

* Step 8: Merge back daily-level dry spell variables
foreach mm in 1 2 3 4 5 {
    merge 1:1 ea_id year date_stata using `dsfull_`mm''
    drop _merge
}



********************************************************************************
* LABEL VARIABLES CREATED IN DRY-SPELL LOOP (mm = 1–5)
********************************************************************************

foreach mm in 1 2 3 4 5 {

    label var precip_below_`mm'mm      "Rainfall < `mm' mm"
    label var after_onset_`mm'         "Dummy: day after rainy-season onset (`mm' mm threshold)"
    label var dry_`mm'                 "Dry day (<`mm' mm) after onset"

    label var dry_spell_id_`mm'        "ID of dry-spell sequence (<`mm' mm) after onset"
    label var dry_spell_length_`mm'    "Length of dry spell (<`mm' mm) after onset"

    label var first_dry_spell_length_`mm'  "Length of first dry spell (<`mm' mm) after onset"

    label var dry_spell_first_`mm'     "First dry-spell length (<`mm' mm), unit-year"

    label var treated_`mm'             "Treatment dummy: first dry spell > 13 days (<`mm' mm threshold)"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




***************************************************************************************

/*
EXPLANATION line 431-470

The code constructs several **dry spell indicators (DS14, DS20, DS21, DS28, DS30)** that measure whether the early part of the rainy season was unusually dry at the village level (`ea_id`) in a given year.

First, the variable `days_since_onset` is created as the difference between each observation date (`date_stata`) and the estimated start of the rainy season (`first_onset`). This variable tracks how many days have passed since the onset of rains.

For each time window ( w \in {14, 20, 21, 28, 30} ), the code then performs the following steps:

1. It defines the variable `in_ds`w'_window`, which equals 1 for all days that fall within the first `w`days after the onset (i.e., when`days_since_onset`is between 1 and`w`). This isolates the early growing period.

2. It computes cumulative rainfall over this period. The variable `rain_ds`w'` stores the running sum of daily precipitation (`precipitation`) within the `w`-day window for each village-year (`ea_id`, `year`). This gives the total rainfall received in the first `w` days after onset.

3. To avoid duplicate values across multiple days, the variable `ds`w'_flag`identifies the final day of the window (i.e., when`days_since_onset == w`). The dry spell indicator will only be assigned on this day.

4. Finally, the dry spell dummy `DS`w'`is created. It takes the value 1 if total rainfall in the first`w` days (`rain_ds`w'`) is less than `w` millimeters, and 0 otherwise. This corresponds to a threshold of less than 1 mm of rainfall per day on average during the early growing season.

Each of these variables is labeled clearly, so that `DS14`, `DS20`, `DS21`, `DS28`, and `DS30` represent different definitions of early-season dryness based on progressively longer time windows.

---

**Intuition:**
The code captures whether crops experience insufficient moisture immediately after the rains begin. Instead of looking at total seasonal rainfall, it focuses on the **critical early period after onset**, where sustained low rainfall (below ~1 mm/day) can harm germination and early growth. By varying the window length (14 to 30 days), the code allows testing how sensitive results are to different definitions of early-season dry spells.


*/


*------------------------------------------------------------
* Days since onset (create only once)
*------------------------------------------------------------
capture confirm variable days_since_onset
if _rc {
    gen days_since_onset = date_stata - first_onset
    label var days_since_onset "Days since rainy season onset"
}

*------------------------------------------------------------
* Loop over windows: 14, 21, 28, 30 days
*------------------------------------------------------------
foreach w in 14 20 21 28 30 {

    * Window indicator
    gen in_ds`w'_window = days_since_onset >= 1 & days_since_onset <= `w'
    label var in_ds`w'_window ///
        "Within first `w' days after onset"

    * Rainfall sum placeholder
    gen rain_ds`w' = .
    label var rain_ds`w' ///
        "Cumulative rainfall in first `w' days after onset (mm)"

    * Cumulative rainfall over window
    bysort ea_id year (date_stata): ///
        replace rain_ds`w' = sum(precipitation * in_ds`w'_window)

    * Flag only the final day to avoid duplicates
    gen ds`w'_flag = in_ds`w'_window & days_since_onset == `w'
    label var ds`w'_flag ///
        "Indicator: day `w' after onset"

    * Dry-spell dummy (1 mm/day threshold)
    gen DS`w' = .
    replace DS`w' = 1 if rain_ds`w' < `w' & ds`w'_flag == 1
    replace DS`w' = 0 if rain_ds`w' >= `w' & ds`w'_flag == 1

    label var DS`w' ///
        "Dry spell: <`w'mm rainfall in first `w' days after onset"
}


/*
EXPLANATION: line 492-550

This code computes three measures of dry spell length after the onset of the rainy season at the EA-year level.

For each location and year, it iterates over the first 60 days after season onset and checks, day by day, whether rainfall conditions still qualify as “dry.” The dry spell duration is defined as the maximum number of consecutive initial days after onset that still meet the dryness criteria.

Three versions are constructed:

dry_spell_duration: length of the period where the average daily rainfall over the first 
d
d days remains below 1 mm.
dry_spell_duration_cont: same definition as above, but the dry spell can only increase sequentially (i.e., it must be continuous from day to day without gaps).
dry_spell_duration_5mm: stricter version that, in addition to the average rainfall condition (<1 mm/day), requires that no single day in the period exceeds 5 mm of rainfall.

In short, the code translates daily rainfall data into different definitions of early-season dry spell persistence.

*/



* --- BLOCK 1: dry_spell_duration ---
gen dry_spell_duration = 0
sort ea_id year date_stata

forvalues d = 1/60 {
    tempvar running_total avg_rain
    
    bysort ea_id year: egen `running_total' = total(precipitation) ///
        if days_since_onset >= 1 & days_since_onset <= `d'
    
    bysort ea_id year: egen `avg_rain' = max(`running_total')
    
    replace dry_spell_duration = `d' if (`avg_rain' / `d') < 1 & !missing(`avg_rain')
    
    * CRITICAL FIX: Added back-ticks here
    drop `running_total' `avg_rain'
}

* --- BLOCK 2: dry_spell_duration_cont ---
gen dry_spell_duration_cont = 0

forvalues d = 1/60 {
    tempvar running_total avg_rain
    
    bysort ea_id year: egen `running_total' = total(precipitation) ///
        if days_since_onset >= 1 & days_since_onset <= `d'
    
    bysort ea_id year: egen `avg_rain' = max(`running_total')
    
    replace dry_spell_duration_cont = `d' if (`avg_rain' / `d') < 1 ///
                                         & dry_spell_duration_cont == (`d' - 1) ///
                                         & !missing(`avg_rain')
    
    drop `running_total' `avg_rain'
}

* --- BLOCK 3: dry_spell_duration_5mm ---
gen dry_spell_duration_5mm = 0

forvalues d = 1/60 {
    tempvar running_total max_daily
    
    bysort ea_id year: egen `running_total' = total(precipitation) ///
        if days_since_onset >= 1 & days_since_onset <= `d'
        
    bysort ea_id year: egen `max_daily' = max(precipitation) ///
        if days_since_onset >= 1 & days_since_onset <= `d'
    
    bysort ea_id year: egen temp_avg_rain = max(`running_total')
    bysort ea_id year: egen temp_peak_rain = max(`max_daily')
    
    replace dry_spell_duration_5mm = `d' if (temp_avg_rain / `d') < 1 ///
                                         & temp_peak_rain < 5 ///
                                         & dry_spell_duration_5mm == (`d' - 1) ///
                                         & !missing(temp_avg_rain)
    
    drop `running_total' `max_daily' temp_avg_rain temp_peak_rain
	
}

/*
Faster way for lines above 490-550

****************************************************
* PREPARATION
****************************************************

sort ea_id year days_since_onset

* cumulative rainfall (computed once)
by ea_id year: gen cum_rain = sum(precipitation)

****************************************************
* BLOCK 1: dry_spell_duration
* avg rainfall over first d days < 1 mm
****************************************************

gen dry_spell_duration = 0

forvalues d = 1/60 {

    by ea_id year: gen rain_d = ///
        cum_rain - cond(_n > `d', cum_rain[_n-`d'], 0)

    gen avg_rain_d = rain_d / `d'

    replace dry_spell_duration = `d' if ///
        avg_rain_d < 1 & dry_spell_duration == (`d' - 1)

    drop rain_d avg_rain_d
}

****************************************************
* BLOCK 2: dry_spell_duration_cont
* same, but strictly sequential extension
****************************************************

gen dry_spell_duration_cont = 0

forvalues d = 1/60 {

    by ea_id year: gen rain_d = ///
        cum_rain - cond(_n > `d', cum_rain[_n-`d'], 0)

    gen avg_rain_d = rain_d / `d'

    replace dry_spell_duration_cont = `d' if ///
        avg_rain_d < 1 & dry_spell_duration_cont == (`d' - 1)

    drop rain_d avg_rain_d
}

****************************************************
* BLOCK 3: dry_spell_duration_5mm
* adds constraint: no daily rainfall > 5mm
****************************************************

gen dry_spell_duration_5mm = 0

forvalues d = 1/60 {

    * rolling sum
    by ea_id year: gen rain_d = ///
        cum_rain - cond(_n > `d', cum_rain[_n-`d'], 0)

    gen avg_rain_d = rain_d / `d'

    * max daily rainfall in window
    by ea_id year: egen max_rain_d = max(precipitation) ///
        if inrange(days_since_onset, 1, `d')

    by ea_id year: egen max_rain_window = max(max_rain_d)

    replace dry_spell_duration_5mm = `d' if ///
        avg_rain_d < 1 & max_rain_window < 5 ///
        & dry_spell_duration_5mm == (`d' - 1)

    drop rain_d avg_rain_d max_rain_d max_rain_window
}

****************************************************
* CLEANUP (optional)
****************************************************

drop cum_rain

*/



/*
EXPLANATION for code line 661-713

This code constructs village-level measures of **early-season rainfall conditions and shocks** based on rainfall in the first 30 days after the onset of the rainy season.

First, it defines a 30-day post-onset window using the variable `days_since_onset` and creates an indicator `in_window` equal to 1 for observations where `days_since_onset` is between 0 and 29. Within this window, it sums precipitation to obtain `total_rain_30` for each village-year (`ea_id` × `year`). This value is then aggregated to a single village-year level measure called `village_year_total`, representing total rainfall in the first 30 days of the rainy season.

Second, the code constructs a long-term benchmark by collapsing the data across years at the village level, computing `ltm_30`, which is the average of `village_year_total` over all years for each village (`ea_id`). This captures the typical or “normal” early-season rainfall for each location.

Using this baseline, the code computes two measures of rainfall deviation. The first is the absolute anomaly `rainfall_anomaly_30`, defined as `village_year_total - ltm_30`, which indicates whether a given year is wetter (positive values) or drier (negative values) than the long-term average. The second is a relative measure: `rain_ratio = village_year_total / ltm_30`, which is transformed into a percentage deviation `rain_pct_deviation = (rain_ratio - 1) * 100`. This expresses rainfall in percentage terms relative to normal conditions, where 0 indicates average rainfall, positive values indicate wetter-than-normal conditions, and negative values indicate drier-than-normal conditions.

Overall, the code produces a standardized measure of early-season rainfall shocks by comparing observed rainfall (`village_year_total`) to village-specific historical norms (`ltm_30`), and expressing deviations both in absolute terms (`rainfall_anomaly_30`) and percentage terms (`rain_pct_deviation`).




*/


* --- 1. Identify the 30-day window after onset ---
* Ensure your dates are in Stata format
*gen days_since_onset = date_stata - onset_date

* Keep only the 30-day window (0 is the day of onset, up to 29 days after)
gen in_window = (days_since_onset >= 0 & days_since_onset < 30)

* --- 2. Calculate Total Rainfall per Village per Year in that window ---
bysort ea_id year: egen total_rain_30 = total(precipitation) if in_window == 1

* Since 'total' only fills the rows where in_window==1, 
* we spread that value to all rows for that village-year to avoid missing values
bysort ea_id year: egen village_year_total = max(total_rain_30)

* --- 3. Calculate the Long-Term Mean (LTM) per Village ---
* This collapses the years to find the average "normal" for each village
preserve
    collapse (mean) ltm_30 = village_year_total, by(ea_id)
    tempfile village_norms
    save `village_norms'
restore

* Merge the Long-Term Mean back into the main data
merge m:1 ea_id using `village_norms', nogenerate

* --- 4. Calculate the Deviation (Anomaly) ---
gen rainfall_anomaly_30 = village_year_total - ltm_30

* Optional: Label the variables for clarity
label var ltm_30 "Long-term mean rainfall (first 30 days after onset)"
label var rainfall_anomaly_30 "Deviation from long-term mean (Anomaly)"

sort year ea_id date_stata

* --- 1. Calculate the Ratio and the Percent Deviation ---
* village_year_total: Total rain in the first 30 days of 2022
* ltm_30: The historical average for those same 30 days

gen rain_ratio = (village_year_total / ltm_30)
gen rain_pct_deviation = (rain_ratio - 1) * 100

* --- 2. Interpret the Values ---
* 0   : Exactly the Long Term Mean
* +50  : 50% more rain than usual
* -50  : 50% less rain than usual

label var rain_pct_deviation "Rainfall % Deviation from Long-Term Mean"

* --- 3. Compare your two villages again ---
* Village 1: (139 / 153 - 1) * 100 = -9.1%  (Slightly below normal)
* Village 2: (30 / 97 - 1) * 100 = -69.1%  (Major dry spell shock)

list ea_id year village_year_total ltm_30 rain_pct_deviation if year == 2022



*The following code computes a 30-day rainfall surplus/deficit measure by comparing observed rainfall (total_30) to a fixed benchmark of 30 mm and defining rainfall_balance_30 as the deviation from this expected level.


* 1. Calculate the total rain for the first 30 days
tempvar total_rain_30
bysort ea_id year: egen `total_rain_30' = total(precipitation) ///
    if days_since_onset >= 1 & days_since_onset <= 30

* 2. Spread the total to the whole year group
bysort ea_id year: egen total_30 = max(`total_rain_30')

* 3. Calculate the Balance (Actual - Target)
* Target for 30 days is 30mm (1mm/day)
gen rainfall_balance_30 = total_30 - 30

* 4. Handle missing data (If no rain recorded, balance is -30)
replace rainfall_balance_30 = -30 if missing(total_30)

label var rainfall_balance_30 "Rainfall surplus/deficit relative to 1mm/day at Day 30 (mm)"



//////////////////////////////////
// save treatment rainfall data
//////////////////////////////////


save XY



////
preserve
collapse ///
    (firstnm) smp_region region department  ///
    (firstnm) first_onset ///
    (max) treated_1 treated_2 treated_3 treated_4 treated_5 ///
    (max) dry_spell_first_1 dry_spell_first_2 dry_spell_first_3 dry_spell_first_4 dry_spell_first_5 ///
    (max) DS14 DS20 DS21 DS28 DS30 ///
    (max) dry_spell_duration dry_spell_duration_cont dry_spell_duration_5mm ///
    (max) village_year_total ltm_30 rainfall_anomaly_30 rain_ratio rain_pct_deviation rainfall_balance_30 ///
    , by(ea_id year)

save "$data/GSMAP_villageyear_irregular_rain_2010_2024.dta", replace
restore

save "$data/ALLvariables_GSMAP_villageyear_irregular_rain_2010_2024.dta", replace




