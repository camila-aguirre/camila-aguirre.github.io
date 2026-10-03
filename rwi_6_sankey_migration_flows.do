clear all
set more off

* ================================================================
* Sankey diagrams of internal migration episodes (origin -> area -> destination)
* Uses sankey_plot by Fernando Rios-Avila (SSC); install once:
*   ssc install sankey_plot
*   ssc install palettes
*   ssc install colrspace
* ================================================================

* ================================================================
* DIAGRAM : Sankey
* ================================================================
global dir "."   // change to your project folder		
global Graph "$dir\GRAPHS" 
global data "$dir\DATA" 	
set more off

use "$data\temp_migration_2022_4_LONG_episodes_real_merge.dta" ,replace

keep hhid member episode ea_id intern_12m_ region department year intern_index2__ intern_region2__ intern_rural2__  i_mig_episodes ea_type

drop if intern_12m_ == 0 

gen ea_type_new = ""
replace ea_type_new = "NATIONAL SAMPLE" if strpos(ea_type, "National")
replace ea_type_new = "KAOLACK" if strpos(ea_type, "Kaolack")
replace ea_type_new = "MATAM" if strpos(ea_type, "Matam")
replace ea_type_new = "SEDHIOU" if strpos(ea_type, "Sedhiou")
replace ea_type_new = "THIES" if strpos(ea_type, "Eclosio villages")

rename ea_type_new region_from
drop region ea_type 
label variable region_from "Grouped origin regions"
tab region_from, missing
rename region_from region

destring intern_rural2__, replace
**** urban rural 
gen area_type = . 
replace area_type = 1 if inlist(intern_rural2__, 1, 2, 3)   
replace area_type = 2 if intern_rural2__ == 4   
drop if area_type == .            

label define area_lbl 1 "Urban" 2 "Rural"
label values area_type area_lbl
drop intern_rural2__

***Delete -88
replace intern_region2__ = upper(intern_region2__)
drop if intern_region2__ == "-88"

**SEE MISSING 
tabulate area_type, missing
tabulate intern_12m_ , missing
tabulate intern_region2__, missing
tabulate region, missing

gen region_cat = intern_region2__    
replace region_cat = "NATIONAL SAMPLE" ///
    if region_cat != "DAKAR" ///
    & region_cat != "MATAM" ///
    & region_cat != "SEDHIOU" ///
    & region_cat != "KAOLACK" ///
    & region_cat != "THIES"

label variable region_cat "Grouped destination regions"
drop intern_region2__ 
rename region_cat intern_region2__ 

**Generate Agroecological zone
gen AEZ = ""
replace AEZ = "GROUNDNUT BASIN" if department == "BAMBEY" | department == "DIOURBEL" | department == "FATICK" | department == "FOUNDIOUGNE" | department == "GOSSAS" | department == "KAFFRINE" | department == "KAOLACK" | department == "KEBEMER" | department == "KOUNGHEUL" | department == "KOUPENTOUM" | department == "M'BACKE" | department == "NIORO" | department == "THIES" | department == "TIVAOUANE"

replace AEZ = "VALLEY RIVER" if department == "DAGANA" | department == "KANEL"

replace AEZ = "CASAMANCE" if department == "GOUDOMP" | department == "KOLDA" | department == "OUSSOUYE" | department == "SEDHIOU" | department == "VELINGARA"

replace AEZ = "CENTRAL AND SOUTHEAST" if department == "KEDOUGOU" | department == "TAMBACOUNDA"

replace AEZ = "PASTORAL ZONE" if department == "LINGUERE" | department == "MATAM" | department == "PODOR"

label var AEZ "Agricultural Zone according to FAO"


* ================================================================
* Graph Sankey : ORIGIN -> U/R -> DESTINATION (normalized by region)
* ================================================================
*====== start : region (origin), intern_region2__ (destination), area_type (1/2 with labels) ======
preserve

*  Clean and string 
replace region = upper(region)
replace intern_region2__ = upper(intern_region2__)
capture confirm numeric variable area_type
if _rc==0 {
    decode area_type, gen(urb)
}
else {
    rename area_type urb
}
replace urb = upper(urb)
drop if missing(region) | missing(intern_region2__) | missing(urb) | intern_region2__=="-88"

* Count flows for the three levels 
bysort hhid member episode: keep if _n == 1   // eliminate duplicates but keeps multiple episodes per member
gen flow = 1
collapse (sum) flow, by(region urb intern_region2__)


* ================================================================
* NORMALIZATION BY ORIGIN REGION
* Each flow is divided by the total episodes in its origin region
* so flows sum to 1 (or 100) within each origin region
* ================================================================
bysort region: egen total_region = total(flow)
gen flow_norm = flow / total_region        // proportion [0,1]
* gen flow_norm = (flow / total_region)*100  // percentage [0,100] — uncomment if preferred
drop total_region

* Build the edges in long format
tempfile e1 e2

* Segment 1: ORIGIN -> URB/RUR
gen x0 = 1
gen y0 = region
gen x1 = 2
gen y1 = urb
keep x0 y0 x1 y1 flow_norm region urb intern_region2__
save `e1'

* Segment 2: URB/RUR -> DESTINATION
use `e1', clear
rename (x0 y0 x1 y1) (xA yA xB yB)
gen x0 = 2
gen y0 = yB
gen x1 = 3
gen y1 = intern_region2__
keep x0 y0 x1 y1 flow_norm
save `e2'

* Link 2 segments
use `e1', clear
keep x0 y0 x1 y1 flow_norm
append using `e2'

* ================================================================
* Sankey plot with normalized flows
* ================================================================
sankey_plot x0 y0 x1 y1, ///
    width0(flow_norm) ///
    extra adjust gap(0.1) noline ///
	colorpalette(viridis, opacity(40)) ///
    xlabel(1 "Origin" 2 "Area(Rural/Urban)" 3 "Destination", nogrid noticks) ///
    xscale(lcolor(none)) ///
    yscale(lcolor(none)) ///
    graphregion(color(white) lcolor(none)) ///
	plotregion(lcolor(none) margin(r+2)) ///
    labcolor(black) labsize(2) ///
    xsize(18) ysize(8)

    
graph export "$Graph\GRAPH 1_episodes_normalized.png", replace

restore


* ================================================================
* Graph Sankey : AEZ -> AREA -> DESTINATION (normalized by AEZ)
* ================================================================
preserve

* Clean
replace intern_region2__ = upper(intern_region2__)
capture confirm numeric variable area_type
if _rc==0 {
    decode area_type, gen(urb)
}
else {
    rename area_type urb
}
replace urb = upper(urb)
drop if missing(AEZ) | missing(intern_region2__) | missing(urb) | intern_region2__=="-88"

* One row per episode (removes within-episode duplicates across rounds, keeps multiple episodes per member)
bysort hhid member episode: keep if _n == 1
gen flow = 1
collapse (sum) flow, by(AEZ urb intern_region2__)

* ================================================================
* Normalization by AEZ
* Each flow divided by total episodes in its origin AEZ
* so flows sum to 1 within each AEZ
* ================================================================
bysort AEZ: egen total_AEZ = total(flow)
gen flow_norm = flow / total_AEZ       // proportion [0,1]
* gen flow_norm = (flow / total_AEZ)*100  // percentage [0,100]
drop total_AEZ

* Build edges
tempfile e1 e2

* Stage 1: AEZ -> URBAN/RURAL
gen x0 = 1
gen y0 = AEZ
gen x1 = 2
gen y1 = urb
keep x0 y0 x1 y1 flow_norm AEZ urb intern_region2__
save `e1'

* Stage 2: URBAN/RURAL -> DESTINATION
use `e1', clear
rename (x0 y0 x1 y1) (xA yA xB yB)
gen x0 = 2
gen y0 = yB
gen x1 = 3
gen y1 = intern_region2__
keep x0 y0 x1 y1 flow_norm
save `e2'

* Combine
use `e1', clear
keep x0 y0 x1 y1 flow_norm
append using `e2'

* Plot
sankey_plot x0 y0 x1 y1, ///
    width0(flow_norm) ///
    extra adjust gap(0.1) noline ///
    colorpalette(viridis, opacity(40)) ///
    xlabel(1 "Agro-Zone" 2 "Area (Rural/Urban)" 3 "Destination", nogrid noticks) ///
    xscale(lcolor(none)) ///
    yscale(lcolor(none)) ///
    graphregion(color(white) lcolor(none)) ///
    plotregion(lcolor(none) margin(r+2)) ///
    labcolor(black) labsize(2) ///
    xsize(18) ysize(8)

graph export "$Graph/GRAPH_1_AEZ_area_episodes_normalized.png", replace
restore


* ================================================================
* Graph Sankey : ORIGIN -> AEZ -> URBAN/RURAL -> DESTINATION
* (normalized by origin region)
* ================================================================
preserve

*========================
* CLEAN
*========================
replace region = upper(region)
replace intern_region2__ = upper(intern_region2__)
capture confirm numeric variable area_type
if _rc==0 {
    decode area_type, gen(urb)
}
else {
    rename area_type urb
}
replace urb = upper(urb)
drop if missing(region) | missing(AEZ) | missing(urb) | missing(intern_region2__) | intern_region2__=="-88"

*========================
* COUNT BY EPISODE
*========================
* One row per episode (removes within-episode duplicates across rounds, keeps multiple episodes per member)
bysort hhid member episode: keep if _n == 1
gen flow = 1
collapse (sum) flow, by(region AEZ urb intern_region2__)

*========================
* NORMALIZATION BY ORIGIN REGION
* Each flow divided by total episodes in its origin region
* so flows sum to 1 within each origin region
*========================
bysort region: egen total_region = total(flow)
gen flow_norm = flow / total_region
drop total_region
save "$Graph/norm_region.dta", replace

*========================
* BUILD EDGES
*========================
tempfile e1 e2 e3

* Segment 1: ORIGIN -> AEZ
use "$Graph/norm_region.dta", clear
collapse (sum) flow_norm, by(region AEZ)
gen x0=1
gen y0=region
gen x1=2
gen y1=AEZ
keep x0 y0 x1 y1 flow_norm
save `e1'

* Segment 2: AEZ -> URBAN/RURAL
use "$Graph/norm_region.dta", clear
collapse (sum) flow_norm, by(region AEZ urb)
bysort region: egen tot = total(flow_norm)
replace flow_norm = flow_norm / tot
drop tot
gen x0=2
gen y0=AEZ
gen x1=3
gen y1=urb
keep x0 y0 x1 y1 flow_norm
save `e2'

* Segment 3: URBAN/RURAL -> DESTINATION
use "$Graph/norm_region.dta", clear
collapse (sum) flow_norm, by(region urb intern_region2__)
bysort region: egen tot = total(flow_norm)
replace flow_norm = flow_norm / tot
drop tot
gen x0=3
gen y0=urb
gen x1=4
gen y1=intern_region2__
keep x0 y0 x1 y1 flow_norm
save `e3'

*========================
* COMBINE & PLOT
*========================
use `e1', clear
append using `e2'
append using `e3'

sankey_plot x0 y0 x1 y1, ///
    width0(flow_norm) ///
    labgap(2) extra adjust gap(0.1) noline ///
    colorpalette(viridis, opacity(40)) ///
    xlabel(1 "Origin" 2 "Agro-Zone" 3 "Area (Rural/Urban)" 4 "Destination", nogrid noticks) ///
    xscale(lcolor(none)) yscale(lcolor(none)) ///
    graphregion(color(white) lcolor(none)) ///
    plotregion(lcolor(none) margin(r+2)) ///
    labcolor(black) labsize(1.8) ///
    xsize(18) ysize(8)

graph export "$Graph/GRAPH_4levels_norm_region.png", replace
restore