
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
log using "btos_ai_`dt'.log", replace
di c(current_date) " " c(current_time)

include 0_config.do

*--------------------------------------------------
* BTOS AI FIGURES
*--------------------------------------------------

local vtg1 = "20251208"
local vtg2 = "20251215"

* FIGURE 1: COMPARING OLD AND NEW QUESTIONS BY SECTOR
* CENSUS REMOVED THE HISTORICAL DATA FROM THE 202525 RELEASE
use if questionid=="7" & year==2025 & biweek==25 using $datacln/Sector_`vtg2'_clean.dta, clear
tempfile temp1
save `temp1'
use if questionid=="7" using $datacln/Sector_`vtg1'_clean.dta, clear
append using `temp1'
sort sector wdate
dropSectors
gen post = .
replace post = 0 if year==2025 & biweek>=19 & biweek<=20
replace post = 1 if year==2025 & biweek>=24 & biweek<=25
drop if missing(post)
collapse (mean) d1, by(sector post)
reshape wide d1, i(sector) j(post)
rename (d10 d11) (yes2wk_old yes2wk_new)
gsort - yes2wk_new
drop if missing(yes2wk_old) | missing(yes2wk_new) 
export delimited using $rslt/fig1.csv, replace noq 

* FIGURE 2: EVALUATING PREDICTIONS
use if questionid=="24" using $datacln/National_`vtg1'_clean.dta, clear
drop if (year==2025 & biweek>=24) | (year>2025)
egen panelvar = group(questionid)
tsset panelvar wdate
gen yes6mo_old_lagged = L24.d1 
keep wdate yes6mo_old_lagged
tempfile guesses
save `guesses'
use if questionid=="7" using $datacln/National_`vtg1'_clean.dta, clear
drop if (year==2025 & biweek>=24) | (year>2025)
rename (d1) (yes2wk_old )
merge 1:1 wdate using `guesses', nogen
keep wdate yes2wk_old yes6mo_old_lagged
export delimited using $rslt/fig2.csv, replace noq 

* FIGURE 3: COMPARING CURRENT AND EXPECTED USE
use if questionid=="24" & year==2025 & biweek>=24 using $datacln/Sector_`vtg2'_clean.dta, clear
dropSectors
collapse (mean) yes6mo_new = d1, by(sector)
tempfile sectoryes6mo
save `sectoryes6mo'
use if questionid=="7" & year==2025 & biweek>=24 using $datacln/Sector_`vtg2'_clean.dta, clear
dropSectors
collapse (mean) yes2wk_new = d1, by(sector)
merge 1:1 sector using `sectoryes6mo', nogen
drop if missing(yes2wk_new) | missing(yes6mo_new) 
gsort - yes6mo_new
export delimited using $rslt/fig3.csv, replace noq 

* OTHER FACTS IN THE TEXT
* CHANGE IN NATIONAL USE RATES
use if questionid=="7" using $datacln/National_`vtg1'_clean.dta, clear
list d1 if year==2024 & biweek==1
list d1 if year==2025 & biweek==20

* NEW AND OLD QUESTION NATIONAL USE RATES
use if questionid=="7" using $datacln/National_`vtg1'_clean.dta, clear
list d1 if year==2025 & biweek==20
use if questionid=="7" using $datacln/National_`vtg2'_clean.dta, clear
list d1 if year==2025 & biweek>=24

* HISTORY OF CURRENT/EXPECTED GAP IN INFORAMTION SECTOR
use if questionid=="24" using $datacln/Sector_`vtg1'_clean.dta, clear
dropSectors
drop if (year==2025 & biweek>=24) | (year>2025)
keep wdate year sector d1
rename d1 yes6mo_old
tempfile p1
save `p1'
use if questionid=="7" using $datacln/Sector_`vtg1'_clean.dta, clear
dropSectors
drop if (year==2025 & biweek>=24) | (year>2025)
keep wdate year sector d1
rename d1 yes2wk_old
merge 1:1 sector wdate using `p1', nogen
gen gap = yes6mo_old - yes2wk_old
sum gap if sector=="Information"


di c(current_date) " " c(current_time)
log close
