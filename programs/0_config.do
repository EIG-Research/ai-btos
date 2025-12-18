
*--------------------------------------------------
* PARAMETERS
*--------------------------------------------------
* PATHS
global dataraw "../data/raw/"
global datacln "../data/clean/"
global rslt "../results/"
global xwlk "../data/crosswalks/"

* AI QUESTION NUMBERS
global ailast2wk "7"
global ainext6mo "24"

*--------------------------------------------------
* MACROS
*--------------------------------------------------
capture btosRecodeSector drop btosRecodeSector 
program define btosRecodeSector
    * recodes BTOS sector variable
    args in out
    gen `out' = "Agriculture" if `in' == "11"
    replace `out' = "Mining, Quarrying, and Oil and Gas Extraction" if `in' == "21"
    replace `out' = "Utilities" if `in' == "22"
    replace `out' = "Construction" if `in' == "23"
    replace `out' = "Manufacturing" if `in' == "31"
    replace `out' = "Wholesale Trade" if `in' == "42"
    replace `out' = "Retail Trade" if `in' == "44"
    replace `out' = "Transportation and Warehousing" if `in' == "48"
    replace `out' = "Information" if `in' == "51"
    replace `out' = "Finance and Insurance" if `in' == "52"
    replace `out' = "Real Estate and Rental and Leasing" if `in' == "53"
    replace `out' = "Professional, Scientific, and Technical Services" if `in' == "54"
    replace `out' = "Management of Companies and Enterprises" if `in' == "55"
    replace `out' = "Administrative and Support and Waste Management and Remediation Services" if `in' == "56"
    replace `out' = "Educational Services" if `in' == "61"
    replace `out' = "Health Care and Social Assistance" if `in' == "62"
    replace `out' = "Arts, Entertainment, and Recreation" if `in' == "71"
    replace `out' = "Accommodation and Food Services" if `in' == "72"
    replace `out' = "Other Services (except Public Administration)" if `in' == "81"
    replace `out' = "Multi-unit companies operating in multiple sectors" if `in' == "XX"
end

capture btosRecodeSize drop btosRecodeSize
program define btosRecodeSize
    args in out
    * recodes BTOS size variable
    gen `out' = "a) 1 to 4" if `in' == "A"
    replace `out' = "b) 5 to 9" if `in' == "B"
    replace `out' = "c) 10 to 19" if `in' == "C"
    replace `out' = "d) 20 to 49" if `in' == "D"
    replace `out' = "e) 50 to 99" if `in' == "E"
    replace `out' = "f) 100 to 249" if `in' == "F"
    replace `out' = "g) 250+" if `in' == "G"
end

capture lowecaseVars drop lowecaseVars 
program define lowecaseVars
    * convers all variable names to lower case
    qui desc, varlist
    foreach v of varlist `r(varlist)' {
        local newname = lower("`v'")
        rename `v' `newname'
    }
end

capture btosCollectTimeCols drop btosCollectTimeCols
program define btosCollectTimeCols
    * converts btos ID variables to strings
    foreach v of varlist questionid answerid {
        tostring `v', replace
    }
    * rename the time var cols, the last of which will always be biweek 2023-19
    local year = 2023
    local biweek = 19
    * figure out the time columns
    * collect the time var cols
    local timeCols = ""
    qui desc, varlist
    foreach v of varlist `r(varlist)' {
        if strlen("`v'")<=2 {
            local timeCols = "`timeCols'" + " `v'"
        }
    }
    local nvars : word count `timeCols'
    forvalues i = `nvars'(-1)1 {
        * get the variable name from the list
        local var : word `i' of `timeCols'
        * build padded biweek string (01–26)
        local bistr = string(`biweek', "%02.0f")
        * build new name
        local newname = "d`year'`bistr'"
        * rename the variable
        rename `var' `newname'
        * replace periods 
        replace `newname' = "" if `newname'=="."
        * increment biweek
        local biweek = `biweek' + 1
        if `biweek' > 26 {
            local biweek = 1
            local year = `year' + 1
        }
    }
end

capture btosMakeLong drop btosMakeLong
program define btosMakeLong
    args byvars
    * convert wide to long
    * first deal with AI question change in 202512, stitching them together
    tempfile hold
    save `hold'
    use `hold', clear
    keep if questionid=="$ailast2wk" | questionid=="$ainext6mo"
    compress
    preserve 
        keep if regexm(question,"business functions")
        tempfile new 
        save `new'
    restore
    keep if regexm(question,"goods or services")
    * the merge + update puts them on the same row
    merge 1:1 questionid answerid `byvars' using `new', update nogen
    local start = 1
    tempfile aiqs
    save `aiqs'
    * drop the AI questions, then append our fixed version
    use `hold', clear
    drop if questionid=="$ailast2wk" | questionid=="$ainext6mo"
    append using `aiqs'
    tempfile hold_aifixed
    save `hold_aifixed'
    * now we reshape
    * first long by (answerid,questionid,byvars)-date-response
    * after that we make it wide to get (questionid,byvars)-date-response1-reponse2-...
    use `hold_aifixed', clear
    destring questionid, replace force
    drop if missing(questionid) 
    tostring questionid, replace
    * collapse all of the relevant identifiers into a single string
    gen q_a = answerid+"|"+questionid+"|"+`byvars'
    keep q_a d*
    reshape long d, i(q_a) j(date)
    * clean the % variables
    replace d = subinstr(d,"%","",.)
    * flag suppressions
    gen d_s = d=="S"
    destring d, replace force
    * break the collapsed ids back apart
    split q_a, parse("|")
    destring q_a1, replace
    tostring date, replace 
    * combine questionid and the byvars
    tostring date, replace
    gen panelvar = q_a2 + "|" + q_a3 + "|" + date
    keep panelvar q_a1 d d_s
    rename q_a1 ansid
    reshape wide d d_s, i(panelvar) j(ansid)
    split panelvar, parse("|")
    rename (panelvar1 panelvar2 panelvar3) (questionid byvars date)
    drop panelvar
    order byvars questionid date d*
    * clean up date vars
    gen strdate = date
    tostring strdate, replace
    gen year = substr(strdate,1,4)
    gen biweek = real(substr(strdate, 5, 2))
    destring year, replace 
    destring biweek, replace
    * Calculate the date as the first day of the given biweekly period
    gen start_date = mdy(1, 1, year) + (biweek - 1) * 14
    format start_date %tdMon_DD_YY
    gen week = biweek *2
    gen wdate = yw(year,week)
    format wdate %tw
    drop date week strdate
    order byvars questionid year biweek start_date wdate d*
end

capture dropSectors drop dropSectors 
program define dropSectors
    * drop sectors that have time series that are mostly suppressed 
    *use if questionid=="7" using $datacln/Sector_clean.dta, clear
    *tab sector d_s1, row
    *                    |         d_s1
    *            sector |         0          1 |     Total
    *----------------------+----------------------+----------
    *        Agriculture  |        16        100 |       116 
    *                    |     13.79      86.21 |    100.00 
    *----------------------+----------------------+----------
    *Management of Compa.. |        22         94 |       116 
    *                    |     18.97      81.03 |    100.00 
    *----------------------+----------------------+----------
    *Mining, Quarrying, .. |        17         99 |       116 
    *                    |     14.66      85.34 |    100.00 
    *----------------------+----------------------+----------
    *            Utilities |        21         95 |       116 
    *                    |     18.10      81.90 |    100.00 
    *----------------------+----------------------+----------
    drop if sector == "Utilities" | sector == "Agriculture" | regexm(sector,"Management") | regexm(sector,"Mining")
end
