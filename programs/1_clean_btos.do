
*--------------------------------------------------
* PROGRAM SETUP
*--------------------------------------------------
capture log close
set more off
set linesize 80
set type double
local dt="`c(current_date)' `c(current_time)'"
local dt=subinstr("`dt'",":","",.)
local dt=subinstr("`dt'"," ","",.)
log using "1_clean_btos_`dt'.log", replace
di c(current_date) " " c(current_time)

include 0_config.do

*--------------------------------------------------
* LOAD DATA
*--------------------------------------------------
* get NAICS descriptions
import excel using "$xwlk/naics17_2_6.xlsx", clear
drop if _n<3
rename (A B C) (seq naics desc)
keep naics desc
duplicates drop 
tempfile ndesc
save `ndesc'

foreach vtg in 20251208 20251215 { 
    * NATIONAL 
    import excel using "$dataraw/`vtg'/National.xlsx", clear first
    * lower case all vars
    lowecaseVars
    btosCollectTimeCols
    gen state = "National"
    btosMakeLong state
    rename byvars state
    save "$datacln/National_`vtg'_clean.dta", replace 

    * STATE 
    import excel using "$dataraw/`vtg'/State.xlsx", clear first
    * lower case all vars
    lowecaseVars
    btosCollectTimeCols
    btosMakeLong state
    rename byvars state
    save "$datacln/State_`vtg'_clean.dta", replace 

    * SECTOR 
    import excel using "$dataraw/`vtg'/Sector.xlsx", clear first
    * lower case all vars
    lowecaseVars
    btosRecodeSector sector sec
    drop sector 
    rename sec sector
    btosCollectTimeCols
    btosMakeLong sector
    rename byvars sector
    save "$datacln/Sector_`vtg'_clean.dta", replace 

    * SUBSECTOR 
    import excel using "$dataraw/`vtg'/Subsector.xlsx", clear first
    * lower case all vars
    lowecaseVars
    rename subsector naics
    btosCollectTimeCols
    btosMakeLong naics
    rename byvars naics
    merge m:1 naics using `ndesc', keepusing(desc) keep(1 3)
    order naics desc
    save "$datacln/Subsector_`vtg'_clean.dta", replace 

    * SIZE 
    import excel using "$dataraw/`vtg'/Employment Size Class.xlsx", clear first
    * lower case all vars
    lowecaseVars
    btosRecodeSize empsize size
    drop empsize 
    btosCollectTimeCols
    btosMakeLong size
    rename byvars size
    order size
    save "$datacln/Employment Size Class_`vtg'_clean.dta", replace

    * SECTOR SIZE 
    import excel using "$dataraw/`vtg'/Sector by Employment Size Class.xlsx", clear first
    * lower case all vars
    lowecaseVars
    btosRecodeSize empsize size
    drop empsize 
    btosRecodeSector sector sec
    drop sector 
    rename sec sector
    btosCollectTimeCols
    gen sizesector = size + "#" + sector
    drop size sector
    btosMakeLong sizesector
    split byvars, parse("#")
    rename (byvars1 byvars2) (size sector) 
    order size sector
    drop byvars
    save "$datacln/Sector by Employment Size Class_`vtg'_clean.dta", replace 

    * TOP MSA 
    import excel using "$dataraw/`vtg'/Top 25 MSA.xlsx", clear first
    * lower case all vars
    lowecaseVars
    btosCollectTimeCols
    btosMakeLong msa
    rename byvars msa
    order msa
    save "$datacln/Top 25 MSA_`vtg'_clean.dta", replace 
}

di c(current_date) " " c(current_time)
log close
