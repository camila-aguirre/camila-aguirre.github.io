*==============================================================================
* Master's thesis, Universitat Oberta de Catalunya (UOC), 2022 - Camila Aguirre Diaz
* Dynamics and structure of the Ecuadorian labour market, 2007-2019 (ENEMDU, INEC)
* Set the global below to your project folder. ENEMDU panel data are not included.
*==============================================================================
global dir "."   // change to your project folder
global data "$dir/DATA"
global res  "$dir/RESULTS"

*====Matriz de transicion 2007-2008====
use "$data/2007-2008 CONDACTN.dta", clear
tab condact_nt_07 condact_nt_08  [iw= fexpmatc], row nofreq // crear matriz de transicion 
**** Matriz de transicion 2009-2010
use "$data/2009-2010 CONDACTN.dta", clear
tab condact_nt_09 condact_nt_10  [iw= fexpmatch],row nofreq  // crear matriz de transicion 
**** Matriz de transicion 2011-2012
use "$data/2011-2012 CONDACTN.dta", clear
tab condact_nt_11 condact_nt_12  [iw= fexpmatch],row nofreq // crear matriz de transicion 
*=== Matriz de transicion 2013-2014====*
use "$data/A14.CONDACT_15 años y más dic13_dic14.dta", clear
numlabel,  add
tab CONDACTN_42
tab CONDACTN_46
* Crear la variable condact_t para cada panel
***2013
recode CONDACTN_42 (0 6 = .) (1 = 0 "Adecuado") ( 2 = 1 "Sub por tiempo") (3 = 2 "Sub por ingresos")(4 = 3 "Otro Inadec") ///
 (5 = 4 "No remunerado") (7/8 = 5 "Desempleo") (9 = 6 "Inactividad"), gen(condact_nt_13) label(condact_nt_13)
recast byte condact_nt_13
**2014
recode CONDACTN_46 (0 6 = .) (1 = 0 "Adecuado") ( 2 = 1 "Sub por tiempo") (3 = 2 "Sub por ingresos")(4 = 3 "Otro Inadec") ///
 (5 = 4 "No remunerado") (7/8 = 5 "Desempleo") (9 = 6 "Inactividad"), gen(condact_nt_14) label(condact_nt_14)
recast byte condact_nt_14
tab condact_nt_13 condact_nt_14 [iw= fexpmatc],row nofreq // crear matriz de transicion 
*=====Matriz de transicion 2015-2016======*-
use "$data/A19.CONDACT_15 años y más_dic15_dic16.dta", clear
numlabel,  add
tab CONDACTN_50
tab CONDACTN_54
* Crear la variable condact_t para cada panel
***2015
recode CONDACTN_50 (0 6 = .) (1 = 0 "Adecuado") ( 2 = 1 "Sub por tiempo") (3 = 2 "Sub por ingresos")(4 = 3 "Otro Inadec") ///
 (5 = 4 "No remunerado") (7/8 = 5 "Desempleo") (9 = 6 "Inactividad"), gen(condact_nt_15) label(condact_nt_15)
recast byte condact_nt_15
**2016
recode CONDACTN_54 (0 6 = .) (1 = 0 "Adecuado") ( 2 = 1 "Sub por tiempo") (3 = 2 "Sub por ingresos")(4 = 3 "Otro Inadec") ///
 (5 = 4 "No remunerado") (7/8 = 5 "Desempleo") (9 = 6 "Inactividad"), gen(condact_nt_16) label(condact_nt_16)
recast byte condact_nt_16
tab condact_nt_15 condact_nt_16 [iw= fexpmatch],row nofreq // crear matriz de transicion 
*====== Matriz de transicion 2018-2019======**-
use "$data/Base_Match_dic18_dic19.dta", clear
numlabel,  add
tab CONDACT_dic18
tab CONDACT_dic19
//debe estar en formato wide 
**2018
recode CONDACT_dic18 (0 6 = .) (1 = 0 "Adecuado") ( 2 = 1 "Sub por tiempo") (3 = 2 "Sub por ingresos")(4 = 3 "Otro Inadec") ///
 (5 = 4 "No remunerado") (7/8 = 5 "Desempleo") (9 = 6 "Inactividad"), gen(condact_nt_18) label(condact_nt_18)
recast byte condact_nt_18
**2019
recode CONDACT_dic19 (0 6 = .) (1 = 0 "Adecuado") ( 2 = 1 "Sub por tiempo") (3 = 2 "Sub por ingresos")(4 = 3 "Otro Inadec") ///
 (5 = 4 "No remunerado") (7/8 = 5 "Desempleo") (9 = 6 "Inactividad"), gen(condact_nt_19) label(condact_nt_19)
recast byte condact_nt_19

tab condact_nt_18 condact_nt_19 [iw= fexpmatch], row nofreq // crear matriz de transicion 

// luego saco las tasas como porcentaje dividendo la categoria por el valor total final en forma de filas
