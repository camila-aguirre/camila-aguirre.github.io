**=======================================================================**
*Descriptive analysis
* Master's thesis, University of Passau (2025) - Camila Aguirre Diaz
*========================================================================**
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

tab region d_rainfall_t_m1_lag // Quality rainfall  
tab region rain_variability //
tab region  l_rainfall_problem_t_m1

*==============================================================================**
**TABLE 11: DESCRIPTIVE TABLE
**==============================================================================**
xtset  hhid year  

*Notes
*hh_inc_agric	"How much money did the household as a whole earn as income from agricultural wor in the last 4 weeks2 
*hh_inc_nonagric	"How much money did the household as a whole earn as income from  non-agricultura"
*hh_inc_other	"How much money did the household as a whole earn as income from  any other sourc"

**Socio economic and agriculture characteristics of the household (n=xx)

label variable hh_inc_agric	         "HH  agri. income (CFA)"
label variable hh_inc_other	         "HH income from any other sources (CFA)"
label variable hh_inc_nonagric	     "HH non-agri income (CFA) "


cd "$res" 

asdoc su  hh_inc_agric hh_inc_other hh_inc_nonagric, ///
label save(descriptives_continues) varwidth(40) dec(2) replace // All sample (senegal)

asdoc su hh_inc_agric hh_inc_other hh_inc_nonagric ///
    if inlist(region, 4, 8, 10), ///
    label by(region) ///
    save(descriptives_continues_final.doc) /// just for kaolack Matam sedhiou 
    title(Descriptive statistics of the sample for continuous variables)
	
**Agriculture characteristics of the households 

recast byte land_size
label variable land_size          "Land size (ha)"
label variable land_type_own_agricultural  "Ownnership of agricultural land"
label variable land_type_no_ownership "Cultivate land but no ownership"
label variable hh_crop_harvest_1 "Crop: Comparison to previous harvest"
label variable  irrigation_dummy "Irrigated land"
label variable hh_crop_irrigate_1          "Main irrigated crop"
label variable irrigation_water      "Irrigation system provide enough water"
label variable irrigation_water_source  "Irrigation water source"
label variable land_fertilizer   "Use of fertilizer"

  
** ALL SAMPLE SENEGAL 
asdoc tab land_size , label  save(descriptives_cat_final)    
asdoc tab land_type_own_agricultural, label  save(descriptives_cat_final)    
asdoc tab land_type_no_ownership , label  save(descriptives_cat_final)    
asdoc tab hh_crop_harvest_1 , label  save(descriptives_cat_final)    
asdoc tab irrigation_dummy , label  save(descriptives_cat_final)    
asdoc tab hh_crop_irrigate_1   , label  save(descriptives_cat_final)    
asdoc tab irrigation_water    , label  save(descriptives_cat_final)    
asdoc tab irrigation_water_source   , label  save(descriptives_cat_final)    
asdoc tab land_fertilizer   , label  save(descriptives_cat_final)    

**Kaolack
asdoc tab land_size  if region== 4 , label  save(descriptives_cat_fin_Kaolack)    
asdoc tab land_type_own_agricultural if region== 4 , label  save(descriptives_cat_fin_Kaolack)    
asdoc tab land_type_no_ownership  if region== 4 , label  save(descriptives_cat_fin_Kaolack)    
asdoc tab hh_crop_harvest_1  if region== 4 , label  save(descriptives_cat_fin_Kaolack)    
asdoc tab irrigation_dummy  if region== 4 , label  save(descriptives_cat_fin_Kaolack)    
asdoc tab hh_crop_irrigate_1    if region== 4 , label  save(descriptives_cat_fin_Kaolack)    
asdoc tab irrigation_water     if region== 4 , label  save(descriptives_cat_fin_Kaolack)    
asdoc tab irrigation_water_source    if region== 4 , label  save(descriptives_cat_fin_Kaolack)    
asdoc tab land_fertilizer    if region== 4 , label  save(descriptives_cat_fin_Kaolack)     

** Matam
asdoc tab land_size  if region== 8, label  save(descriptives_cat_fin_Matam)    
asdoc tab land_type_own_agricultural if region== 8, label  save(descriptives_cat_fin_Matam)
asdoc tab land_type_no_ownership  if region== 8, label  save(descriptives_cat_fin_Matam)   
asdoc tab hh_crop_harvest_1  if region== 8, label  save(descriptives_cat_fin_Matam)    
asdoc tab irrigation_dummy  if region== 8, label  save(descriptives_cat_fin_Matam)    
asdoc tab hh_crop_irrigate_1    if region== 8, label  save(descriptives_cat_fin_Matam)    
asdoc tab irrigation_water     if region== 8, label  save(descriptives_cat_fin_Matam)    
asdoc tab irrigation_water_source    if region== 8, label  save(descriptives_cat_fin_Matam)
asdoc tab land_fertilizer    if region== 8, label  save(descriptives_cat_fin_Matam)    
 
* Sedhiou
asdoc tab land_size  if region== 10, label  save(descriptives_cat_fin_Sedhiou)    
asdoc tab land_type_own_agricultural if region== 10, label  save(descriptives_cat_fin_Sedhiou)    
asdoc tab land_type_no_ownership  if region== 10, label  save(descriptives_cat_fin_Sedhiou)    
asdoc tab hh_crop_harvest_1  if region== 10, label  save(descriptives_cat_fin_Sedhiou)    
asdoc tab irrigation_dummy  if region== 10, label  save(descriptives_cat_fin_Sedhiou)    
asdoc tab hh_crop_irrigate_1    if region== 10, label  save(descriptives_cat_fin_Sedhiou) 
asdoc tab irrigation_water     if region== 10, label  save(descriptives_cat_fin_Sedhiou)   
asdoc tab irrigation_water_source    if region== 10, label  save(descriptives_cat_fin_Sedhiou)    
asdoc tab land_fertilizer    if region== 10, label  save(descriptives_cat_fin_Sedhiou)     

/* NOTES: Varibles
land_size	B48: Total land size in hectares of your cultivated agricultural land
land_type_own_agricultural	Land Ownership: Own Agricultural Land--- Please select all types of land you make use of, and their mode of ownership
land_type_no_ownership Cultivate land but no ownership
hh_crop_harvest_1	Compared to previous harvests, was the harvest for the crop Nr.1 in t-1/t go
land_irrigation	Do you irrigate your cultivated agricultural land? If yes, all of it or parts of
 irrigation_dummy "Is your cultivated agricultural land irrigated?"
hh_crop_irrigate_1     Did you irrigate most important crop during this period?
irrigation_water	In the last year, did the irrigation system provide sufficient water when it was
irrigation_water_source  Which type of irrigation system(s) or method(s) do you use on your field?? If you use multiple irrigation systems, then select the one you use most often.
land_fertilizer Do you use chemical fertilizer for farming?
*/


*------------------------------------------------------------------------------*
*BAR GRAPHS 
*------------------------------------------------------------------------------*

clear all
	set more off
	*Set directory and record session
		
		global dir "."   // change to your project folder
		
		global data "$dir/DATA" 		// where data is saved
		global res "$dir/RESULTS" 		// where results should be saved
		global res_des "$dir/RESULTS_DESC" 		// where results should be saved
		set more off
	

use "$data/PASSAU_THESIS_MODELO.dta" , clear
xtset  hhid year  

**==============================================================================*
*Remove observations of variables that have 2021 but shouldn't / IN THE MODEL I HAVE TO WORK WITH 2021 AGAIN
**==============================================================================*

* * List of variables to be cleaned in 2021
local cleanvars "land_type_residential land_type_own_agricultural land_type_no_land land_size land_irrigation hh_crop_id_1 hh_crop_irrigate_1 hh_electricity hh_env_change_2 hh_crop_harvest_1 walls hh_ethnicity no_income_agric ln_income_agric no_income_other ln_income_other noagri_income ln_income_nonagr irrigation_dummy any_irrigation_hurdle adapt3cat roof_quality wall_quality housing_quality  hh_inc_agric hh_inc_nonagric hh_inc_other ln_income_other_1 ln_income_nonagr_1 ln_income_agric_1  income_total pobre_365_hh  harvest_binary"
 

* Replace with missing if year == 2021
foreach var of local cleanvars {
    replace `var' = . if year == 2021
}

save  "$data/PASSAU_THESIS_SINVAR2021_ONLYLAGED_SPEI_1.dta" ,replace

use  "$data/PASSAU_THESIS_SINVAR2021_ONLYLAGED_SPEI_1.dta" ,clear  // all sample 


** NATIONAL LEVEL 
/*
replace l_rainfall_quality_t_m1 = . if l_rainfall_quality_t_m1 == 6
tab region year if l_rainfall_quality_t_m1 == 1
tab region l_rainfall_quality_t_m1 if year == 2021

putexcel set "$res/results_descrip.xlsx", sheet("AAA") modify

quietly tab l_rainfall_quality_t_m1 year, matcell(freq)

local nrows = rowsof(freq)
local ncols = colsof(freq)

forval c = 1/`ncols' {
    local year = 2020 + `c'
    local colletter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `c'+1, 1) // B, C, D, E
    putexcel `colletter'1 = "`year'"
}

forval r = 1/`nrows' {
    local cat = `r'
    local label : label rainqual `cat'
    local row = `r' + 1
    putexcel A`row' = "`label'"
}

forval r = 1/`nrows' {
    forval c = 1/`ncols' {
        local val = freq[`r', `c']
        local colletter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `c'+1, 1)
        local row = `r' + 1
        putexcel `colletter'`row' = `val'
    }
}


*/

*------------------------------------------------------------------------------*
*Figure 18:Ranking the ongoing harvest in compare to previous one; Senegal 2022-2024
*------------------------------------------------------------------------------*

putexcel set "$res/results_descrip.xlsx", sheet("A.4") modify

quietly tab hh_crop_harvest_1 year, matcell(freq) matrow(cat)

local nrows = rowsof(freq)
local ncols = colsof(freq)

* Encabezados de años (asumiendo que empiezan en 2020)
forval c = 1/`ncols' {
    local year = 2020 + `c'
    local colletter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `c'+1, 1)  // B, C, D, E
    putexcel `colletter'1 = "`year'"
}

* Primera columna: labels de categorías
forval r = 1/`nrows' {
    local catval = cat[`r',1]
    local label : label harvest_label_2 `catval'
    local row = `r' + 1
    putexcel A`row' = "`label'"
}

* Rellenar las frecuencias
forval r = 1/`nrows' {
    forval c = 1/`ncols' {
        local val = freq[`r', `c']
        local colletter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `c'+1, 1)
        local row = `r' + 1
        putexcel `colletter'`row' = `val'
    }
}


**NOTE: in the excel I sum the variable good and average 

*------------------------------------------------------------------------------*
*Figure 14:Farmers' perception of rainfall ; Senegal 2021-2024
*------------------------------------------------------------------------------*
putexcel set "$res/results_descrip.xlsx", sheet("BBB") modify

* Create a cross-tabulation and save actual frequencies and categories
quietly tab d_rainfall_t_m1_lag year, matcell(freq) matrow(cat)

* Obtain dimensions
local nrows = rowsof(freq)
local ncols = colsof(freq)

* Write column headings (years: 2021 to 2024)
forval c = 1/`ncols' {
    local year = 2020 + `c'
    local colletter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `c'+1, 1)  // B, C, D, E
    putexcel `colletter'1 = "`year'"
}

* Write labels for the actual categories in column A
forval r = 1/`nrows' {
    local catval = cat[`r',1]  // valor real de la categoría
    local label : label rainqual_bin_lbl `catval'
    local row = `r' + 1
    putexcel A`row' = "`label'"
}

*  Write the values ​​from the cross-tabulation
forval r = 1/`nrows' {
    forval c = 1/`ncols' {
        local val = freq[`r', `c']
        local colletter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `c'+1, 1)
        local row = `r' + 1
        putexcel `colletter'`row' = `val'
    }
}

*------------------------------------------------------------------------------*
*Figure 16:Main rainfall‑related problems; Senegal 2021-2024
*------------------------------------------------------------------------------*

putexcel set "$res/results_descrip.xlsx", sheet("CCC") modify
quietly tab l_rainfall_problem_t_m1 year, matcell(freq) matrow(cat)
local nrows = rowsof(freq)
local ncols = colsof(freq)
forval c = 1/`ncols' {
    local year = 2020 + `c'
    local colletter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `c'+1, 1)  // B, C, D, E
    putexcel `colletter'1 = "`year'"
}

forval r = 1/`nrows' {
    local catval = cat[`r',1]  // 
    local label : label rainprob_lbl `catval'
    local row = `r' + 1
    putexcel A`row' = "`label'"
}

forval r = 1/`nrows' {
    forval c = 1/`ncols' {
        local val = freq[`r', `c']
        local colletter = substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", `c'+1, 1)
        local row = `r' + 1
        putexcel `colletter'`row' = `val'
    }
}


*------------------------------------------------------------------------------*
*Figure 15:Farmers' perception of rainfall; regions 2021-2024
*------------------------------------------------------------------------------*

** Just principal regions
keep if inlist(region, 4, 8, 10) //   4 "KAOLACK"  8 "MATAM" 10 "SEDHIOU" 

putexcel set "$res/results_descrip.xlsx", sheet("E") modify

* Starting row
local row = 1

* Loop by years 2021 to 2024
forval y = 2021/2024 {

	* Write title
    putexcel A`row' = "Año `y'", bold
    local row = `row' + 1

    * * Create table region x rainfall quality (binary)
    quietly tab region d_rainfall_t_m1_lag if year == `y', matcell(freq) row col

    * Table dimensions
    local nrows = rowsof(freq)
    local ncols = colsof(freq)

    * Get a list of categories for that year
    levelsof d_rainfall_t_m1_lag if year == `y', local(categorias)

    * Write headings (categories with names)
    local col = 2
    foreach c of local categorias {
        local cname : label rainqual_bin_lbl `c'
        putexcel `=char(64+`col')'`row' = "`cname'"
        local col = `col' + 1
    }

    * Add "Total" header
    putexcel `=char(64+`ncols'+2)'`row' = "Total"

    * Get list of regions
    levelsof region if year == `y', local(regiones)

    * Write rows
    local r = 1
    foreach reg of local regiones {
        local rowwrite = `row' + `r'
        local regname : label region_lbl `reg'
        putexcel A`rowwrite' = "`regname'"

        local total_fila = 0
        forval c = 1/`ncols' {
            local val = freq[`r', `c']
            putexcel `=char(64 + `c' + 1)'`rowwrite' = `val'
            local total_fila = `total_fila' + `val'
        }

        * Write total per row
        putexcel `=char(64 + `ncols' + 2)'`rowwrite' = `total_fila'

        local r = `r' + 1
    }

    * Totals by column
    local rowtotal = `row' + `nrows' + 1
    putexcel A`rowtotal' = "Total"

    forval c = 1/`ncols' {
        local sumcol = 0
        forval rindex = 1/`nrows' {
            local sumcol = `sumcol' + freq[`rindex', `c']
        }
        putexcel `=char(64 + `c' + 1)'`rowtotal' = `sumcol'
    }

    * Total 
    local totalglobal = 0
    forval rindex = 1/`nrows' {
        forval c = 1/`ncols' {
            local totalglobal = `totalglobal' + freq[`rindex', `c']
        }
    }
    putexcel `=char(64 + `ncols' + 2)'`rowtotal' = `totalglobal'

    local row = `rowtotal' + 3
}
*------------------------------------------------------------------------------*
*Figure 17:Main rainfall‑related problems;regions 2021-2024
*------------------------------------------------------------------------------*
putexcel set "$res/results_descrip.xlsx", sheet("G") modify
local row = 1
forval y = 2021/2024 {
    putexcel A`row' = "Año `y'", bold
    local row = `row' + 1
    quietly tab region l_rainfall_problem_t_m1 if year == `y', matcell(freq) row col
    local nrows = rowsof(freq)
    local ncols = colsof(freq)
    levelsof l_rainfall_problem_t_m1 if year == `y', local(categorias)
    local col = 2
    foreach c of local categorias {
        local cname : label rainprob_lbl `c'
        putexcel `=char(64+`col')'`row' = "`cname'"
        local col = `col' + 1
    }
    putexcel `=char(64+`ncols'+2)'`row' = "Total"
    levelsof region if year == `y', local(regiones)
    local r = 1
    foreach reg of local regiones {
        local rowwrite = `row' + `r'
        local regname : label region_lbl `reg'
        putexcel A`rowwrite' = "`regname'"

        local total_fila = 0
        forval c = 1/`ncols' {
            local val = freq[`r', `c']
            putexcel `=char(64 + `c' + 1)'`rowwrite' = `val'
            local total_fila = `total_fila' + `val'
        }

        putexcel `=char(64 + `ncols' + 2)'`rowwrite' = `total_fila'

        local r = `r' + 1
    }
    local rowtotal = `row' + `nrows' + 1
    putexcel A`rowtotal' = "Total"

    forval c = 1/`ncols' {
        local sumcol = 0
        forval rindex = 1/`nrows' {
            local sumcol = `sumcol' + freq[`rindex', `c']
        }
        putexcel `=char(64 + `c' + 1)'`rowtotal' = `sumcol'
    }
    local totalglobal = 0
    forval rindex = 1/`nrows' {
        forval c = 1/`ncols' {
            local totalglobal = `totalglobal' + freq[`rindex', `c']
        }
    }
    putexcel `=char(64 + `ncols' + 2)'`rowtotal' = `totalglobal'
    local row = `rowtotal' + 3
}



*------------------------------------------------------------------------------*
**Figure 19:Household capacity to adapt to environmental change (2022-2024)
*------------------------------------------------------------------------------*
 
putexcel set "$res/results_descrip.xlsx", sheet("U") modify
local row = 1
forval y = 2021/2024 {
    count if year == `y' & !missing(region, adapt3cat)
    if r(N) == 0 {
        putexcel A`row' = "Año `y' (Sin datos para adapt3cat)", italic
        local row = `row' + 3
        continue
    }
    putexcel A`row' = "Año `y'", bold
    local row = `row' + 1
    quietly tab region adapt3cat if year == `y', matcell(freq) row col
    local nrows = rowsof(freq)
    local ncols = colsof(freq)
    levelsof adapt3cat if year == `y', local(categorias)
    local col = 2
    foreach c of local categorias {
        local cname : label adapt3_lbl `c'
        putexcel `=char(64+`col')'`row' = "`cname'"
        local col = `col' + 1
    }
    putexcel `=char(64+`ncols'+2)'`row' = "Total"
    levelsof region if year == `y', local(regiones)
    local r = 1
    foreach reg of local regiones {
        local rowwrite = `row' + `r'
        local regname : label region_lbl `reg'
        putexcel A`rowwrite' = "`regname'"

        local total_fila = 0
        forval c = 1/`ncols' {
            local val = freq[`r', `c']
            putexcel `=char(64 + `c' + 1)'`rowwrite' = `val'
            local total_fila = `total_fila' + `val'
        }
        putexcel `=char(64 + `ncols' + 2)'`rowwrite' = `total_fila'
        local r = `r' + 1
    }
    local rowtotal = `row' + `nrows' + 1
    putexcel A`rowtotal' = "Total"
    forval c = 1/`ncols' {
        local sumcol = 0
        forval rindex = 1/`nrows' {
            local sumcol = `sumcol' + freq[`rindex', `c']
        }
        putexcel `=char(64 + `c' + 1)'`rowtotal' = `sumcol'
    }
    local totalglobal = 0
    forval rindex = 1/`nrows' {
        forval c = 1/`ncols' {
            local totalglobal = `totalglobal' + freq[`rindex', `c']
        }
    }
    putexcel `=char(64 + `ncols' + 2)'`rowtotal' = `totalglobal'
    local row = `rowtotal' + 3
}

*------------------------------------------------------------------------------*
**Appendix N: Distribution of main crops by region
*------------------------------------------------------------------------------*

putexcel set "$res/results_descrip.xlsx", sheet("JJ") modify
local row = 1
forval y = 2021/2024 {
    count if year == `y' & !missing(region, village_crop_1)
    if r(N) == 0 {
        putexcel A`row' = "Año `y' (Sin datos para village_crop_1)", italic
        local row = `row' + 3
        continue
    }
    putexcel A`row' = "Año `y'", bold
    local row = `row' + 1
    quietly tab region village_crop_1 if year == `y', matcell(freq) row col
    local nrows = rowsof(freq)
    local ncols = colsof(freq)
    levelsof village_crop_1 if year == `y', local(categorias)
    local col = 2
    foreach c of local categorias {
        capture local cname : label crop_lbl_eng `c'
        if "`cname'" == "" {
            local cname = "Cultivo `c'"
        }
        putexcel `=char(64+`col')'`row' = "`cname'"
        local col = `col' + 1
    }
    putexcel `=char(64+`ncols'+2)'`row' = "Total"
    levelsof region if year == `y', local(regiones)
    local r = 1
    foreach reg of local regiones {
        local rowwrite = `row' + `r'
        capture local regname : label region_lbl `reg'
        if "`regname'" == "" {
            local regname = "Región `reg'"
        }
        putexcel A`rowwrite' = "`regname'"

        local total_fila = 0
        forval c = 1/`ncols' {
            local val = freq[`r', `c']
            putexcel `=char(64 + `c' + 1)'`rowwrite' = `val'
            local total_fila = `total_fila' + `val'
        }
        putexcel `=char(64 + `ncols' + 2)'`rowwrite' = `total_fila'
        local r = `r' + 1
    }
    local rowtotal = `row' + `nrows' + 1
    putexcel A`rowtotal' = "Total"
    forval c = 1/`ncols' {
        local sumcol = 0
        forval rindex = 1/`nrows' {
            local sumcol = `sumcol' + freq[`rindex', `c']
        }
        putexcel `=char(64 + `c' + 1)'`rowtotal' = `sumcol'
    }
    local totalglobal = 0
    forval rindex = 1/`nrows' {
        forval c = 1/`ncols' {
            local totalglobal = `totalglobal' + freq[`rindex', `c']
        }
    }
    putexcel `=char(64 + `ncols' + 2)'`rowtotal' = `totalglobal'
    local row = `rowtotal' + 3
}


**==============================================================================*
*For table 12,13,14
**==============================================================================*

clear all
	set more off
	*Set directory and record session
		
		global dir "."   // change to your project folder
		global data "$dir/DATA" 		// where data is saved
		global res "$dir/RESULTS" 		// where results should be saved
		

use "$data/Panel_SMP_SPE_THESIS_clean_july.dta" ,clear // creada en do file panel model 
xtset  hhid year  
keep if inlist(region, 4, 8, 10) //  4 "KAOLACK"  8 "MATAM" 10 "SEDHIOU" 

**==============================================================================*
*Remove observations of variables that have 2021 but shouldn't / IN THE MODEL I HAVE TO WORK WITH 2021 AGAIN
**==============================================================================*

local cleanvars "land_type_residential land_type_own_agricultural land_type_no_land land_size land_irrigation hh_crop_id_1 hh_crop_irrigate_1 hh_electricity hh_env_change_2 hh_crop_harvest_1 walls hh_ethnicity     hh_inc_agric hh_inc_nonagric hh_inc_other  "
 
* Replace with missing if year == 2021
foreach var of local cleanvars {
    replace `var' = . if year == 2021
}

save  "$data/PASSAU_THESIS_irr_adap_chall.dta" ,replace

use  "$data/PASSAU_THESIS_irr_adap_chall.dta" ,clear // 

	
*------------------------------------------------------------------------------*
**A.irrigation_hurdle_1 /table 12
*------------------------------------------------------------------------------*	
*Counting which ones were marked the most by single household and by year and region 4,8,10: I only make a ranking and calculate the percentage

gen any_irrigation_hurdle = 0
replace any_irrigation_hurdle = 1 if ///
    irrigation_hurdle_1 == 1 | ///
    irrigation_hurdle_2 == 1 | ///
    irrigation_hurdle_3 == 1 | ///
    irrigation_hurdle_4 == 1 | ///
    irrigation_hurdle_5 == 1 | ///
    irrigation_hurdle_6 == 1 | ///
    irrigation_hurdle_7 == 1 | ///
    irrigation_hurdle_8 == 1 | ///
	irrigation_hurdle_66 ==1

label define hurdle_any_lbl 0 "No barrier reported" 1 "At least one barrier reported"
label values any_irrigation_hurdle hurdle_any_lbl
label variable any_irrigation_hurdle "Reports any irrigation hurdle (multiple choice)"

replace any_irrigation_hurdle = . if inlist(year, 2021, 2022)

preserve
tempname memhold
tempfile resultfile

postfile `memhold' str30 variable int year byte region int count using `resultfile'
foreach y in 2023 2024 {
    keep if year == `y'
    duplicates drop hhid, force
    foreach r in 4 8 10 {
        foreach var in irrigation_hurdle_1 irrigation_hurdle_2 irrigation_hurdle_3 irrigation_hurdle_4 ///
                      irrigation_hurdle_5 irrigation_hurdle_6 irrigation_hurdle_66 ///
                      irrigation_hurdle_7 irrigation_hurdle_8 irrigation_hurdle_other {

            quietly count if region == `r' & `var' == 1
            local n = r(N)
            post `memhold' ("`var'") (`y') (`r') (`n')
        }
    }
    restore
	preserve
}

postclose `memhold'
use `resultfile', clear

export excel using "$res/results_descrip.xlsx", ///
    sheet("A.1", modify) firstrow(variables) 	
restore

*------------------------------------------------------------------------------*
*B.adapt_strateg_past_xx /TABLE 14
*------------------------------------------------------------------------------*	
*Counting which ones were marked the most by single household and by year and region 4,8,10: I only make a ranking and calculate the percentage

preserve
tempname memhold
tempfile resultfile

postfile `memhold' str30 variable int year byte region int count using `resultfile'
foreach y in 2023 2024 { 
    keep if year == `y'
    duplicates drop hhid, force
    foreach r in 4 8 10 {
        foreach var in adapt_strateg_past_crop_variety adapt_strateg_past_croprotation ///
                  adapt_strateg_past_diversify_liv adapt_strateg_past_fertilizer_ap ///
                  adapt_strateg_past_land_amount adapt_strateg_past_none ///
                  adapt_strateg_past_other_employm adapt_strateg_past_planting_date ///
                  adapt_strateg_past_temporal_migr adapt_strateg_past_use_irrigatio {
            quietly count if region == `r' & `var' == 1
            local n = r(N)

            post `memhold' ("`var'") (`y') (`r') (`n')
        }
    }
    restore
	preserve
}
postclose `memhold'
* Abrir y exportar resultados
use `resultfile', clear
export excel using "$res/results_descrip.xlsx", ///
    sheet("B.1", modify) firstrow(variables) 	
restore
 
*------------------------------------------------------------------------------*
*C.Farmingchallenge_x TABLE 13
*------------------------------------------------------------------------------*

**Counting which ones were marked the most by single household and by year and region 4,8,10: I only make a ranking and calculate the percentage
preserve
tempname memhold
tempfile resultfile
postfile `memhold' str30 variable int year byte region int count using `resultfile'
foreach y in 2023 2024 {
    keep if year == `y'
    duplicates drop hhid, force
    foreach r in 4 8 10 {
      foreach var in farmingchallenge_0 farmingchallenge_1 farmingchallenge_10 farmingchallenge_11 ///
                  farmingchallenge_12 farmingchallenge_13 farmingchallenge_14 farmingchallenge_15 ///
                   farmingchallenge_2 farmingchallenge_3 farmingchallenge_4 ///
                  farmingchallenge_5 farmingchallenge_6 farmingchallenge_66 farmingchallenge_7 ///
                  farmingchallenge_8 farmingchallenge_9 farmingchallenge_other {
            quietly count if region == `r' & `var' == 1
            local n = r(N)

            post `memhold' ("`var'") (`y') (`r') (`n')
        }
    }
    restore
	preserve
}
postclose `memhold'
use `resultfile', clear
export excel using "$res/results_descrip.xlsx", ///
    sheet("C.1", modify) firstrow(variables) 	
restore





