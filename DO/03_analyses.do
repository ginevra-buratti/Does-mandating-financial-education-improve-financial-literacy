
//----------------------------------------------------------------------------//
// 03 - Analyses
// Author: A. Antonello, G. Buratti
// Date: 2026
// Description: This do-file runs the main analyses.
//----------------------------------------------------------------------------//


* Implementation of the mandate


*** School-level data **********************************************************

* Open 2022 dataset
use "${OUT}/fl_sch_22.dta", clear

* Drop Bolzano
drop if regione == "Bolzano"

* Gen dummy for vocational and IeFP schools
gen voc_iefp = (vocational == 1 | iefp == 1)

* Gen dummy for FE in school
gen fe_sch = sc800c01ja_it
recode fe_sch (1=0) (2=1) (3=1)

* Gen dummy for FE in school for more than 2 years
gen fe_sch_m2 = sc800c01ja_it
recode fe_sch_m2 (1=0) (2=0) (3=1)

* Gen dummy for FE in school for less than 2 years
gen fe_sch_l2 = sc800c01ja_it
recode fe_sch_l2 (1=0) (2=1) (3=0)


****************
* FE provision *
****************

preserve

collapse (first) fe_sch_l2 trento private rural general technical regione, by(cntschid)

/* NOT INCLUDED IN THE PUBLIC REPLICATION

reg fe_sch_l2 trento, vce(cluster regione)
estimates store did_1

reg fe_sch_l2 trento private rural general technical, vce(cluster regione)
estimates store did_2

qui etable, estimates(did_1 did_2) novarlabel stars(.1 "*" .05 "**" .01 "***", attach(_r_b)) showstars showstarsnote mstat(N) mstat(r2_a) export(${TABFIG}/mandate_implementation.xlsx, sheet(fe_provision, replace) modify)

*/

//----------------------------------------------------------------------------//
// PUBLIC REPLICATION

* Point estimates only
reg fe_sch_l2 trento
estimates store did_1

reg fe_sch_l2 trento private rural general technical
estimates store did_2

qui etable, estimates(did_1 did_2) novarlabel cstat(_r_b) mstat(N) mstat(r2_a) export(${TABFIG}/mandate_implementation.xlsx, sheet(fe_provision, replace) modify)

//----------------------------------------------------------------------------//

restore


********************
* FE teaching time *
********************

local subj_list "sep cross econ math oth extra"

* Gen average FE teaching time for each subject
forvalues i = 1/6 {
	local s : word `i' of `subj_list'

	gen hr_`s' = .
	replace hr_`s' = 0 if sc801c0`i'ja_it == 1 
	replace hr_`s' = 2.5 if sc801c0`i'ja_it == 2
	replace hr_`s' = 12 if sc801c0`i'ja_it == 3
	replace hr_`s' = 34.5 if sc801c0`i'ja_it == 4
	replace hr_`s' = 50 if sc801c0`i'ja_it == 5
}

* Gen average FE total teaching time (excluding extra-curricular activities)
egen hr = rowtotal(hr_sep hr_cross hr_econ hr_math hr_oth), m

* Gen dummy for less than 8 hours per year
gen hr_l8 = (hr < 8)
replace hr_l8 = . if hr == .

putexcel set "${TABFIG}/mandate_implementation.xlsx", sheet(fe_hours, replace) modify // Initialize excel sheet
putexcel B1 = "Trento"
putexcel C1 = "Rest of Italy"
putexcel B2 = "FE \geq 2 yrs"
putexcel A3 = "Low intensity"
putexcel A4 = "Obs"
putexcel B5 = "FE \leq 2 yrs"
putexcel A6 = "Low intensity"
putexcel A7 = "Obs"
putexcel B8 = "All schools with FE"
putexcel A9 = "Low intensity"
putexcel A10 = "Obs"

local cells "B C"
local values "1 0"

preserve

collapse (first) hr_l8 fe_sch fe_sch_m2 fe_sch_l2 trento, by(cntschid)
	
local n : word count `cells'

forvalues i = 1/`n' {
	local c : word `i' of `cells'
	local v : word `i' of `values'
	
	sum hr_l8 if fe_sch_m2 == 1 & trento == `v'
	local b : di %3.2f r(mean)
	putexcel `c'3 = "`b'"
	putexcel `c'4 = "`r(N)'"
	
	sum hr_l8 if fe_sch_l2 == 1 & trento == `v'
	local b : di %3.2f r(mean)
	putexcel `c'6 = "`b'"
	putexcel `c'7 = "`r(N)'"
	
	sum hr_l8 if fe_sch == 1 & trento == `v'
	local b : di %3.2f r(mean)
	putexcel `c'9 = "`b'"
	putexcel `c'10 = "`r(N)'"
}

restore


********************
* Teacher training *
********************

* Fix percentage of trained FE teachers
tab sc803q01ja_it
replace sc803q01ja_it = subinstr(sc803q01ja_it, "%", "", .)
replace sc803q01ja_it = "20" if sc803q01ja_it == "0,2"
destring sc803q01ja_it, replace

* Gen dummy for 20% or less of trained FE staff
gen train_l20 = (sc803q01ja_it <= 20)
replace train_l20 = . if sc803q01ja_it == .

putexcel set "${TABFIG}/mandate_implementation.xlsx", sheet(tch_train, replace) modify // Initialize excel sheet
putexcel B1 = "Trento"
putexcel C1 = "Rest of Italy"
putexcel B2 = "FE \geq 2 yrs"
putexcel A3 = "Limited training"
putexcel A4 = "Obs"
putexcel B5 = "FE \leq 2 yrs"
putexcel A6 = "Limited training"
putexcel A7 = "Obs"
putexcel B8 = "All schools with FE"
putexcel A9 = "Limited training"
putexcel A10 = "Obs"

local cells "B C"
local values "1 0"

preserve

collapse (first) train_l20 fe_sch fe_sch_m2 fe_sch_l2 trento, by(cntschid)

local n : word count `cells'

forvalues i = 1/`n' {
	local c : word `i' of `cells'
	local v : word `i' of `values'
	
	sum train_l20 if fe_sch_m2 == 1 & trento == `v'
	local b : di %3.2f r(mean)
	putexcel `c'3 = "`b'"
	putexcel `c'4 = "`r(N)'"
	
	sum train_l20 if fe_sch_l2 == 1 & trento == `v'
	local b : di %3.2f r(mean)
	putexcel `c'6 = "`b'"
	putexcel `c'7 = "`r(N)'"
	
	sum train_l20 if fe_sch == 1 & trento == `v'
	local b : di %3.2f r(mean)
	putexcel `c'9 = "`b'"
	putexcel `c'10 = "`r(N)'"
}

restore


*** Student-level data *********************************************************

* Open the appended dataset (2018 + 2022)
use "${OUT}/fl_sch_18_22.dta", clear

* Drop Bolzano
drop if regione == "Bolzano"

local areas `" "Trento" "Rest of Italy" "'
local values "1 0"
local letters "B C"


************
* FL score *
************

preserve

* Keep estimation sample
keep if escs != . & immig2 != . & staffshort != . & rural != .

putexcel set "${TABFIG}/mandate_implementation.xlsx", sheet(fl_score, replace) modify // Initialize excel sheet
putexcel A2 = "2018"
putexcel A4 = "2022"
putexcel A6 = "Δ"

forvalues x = 1/2 {
	local a : word `x' of `areas'
	local v : word `x' of `values'
	local l : word `x' of `letters'
	
	putexcel `l'1 = "`a'"
	
	repest PISA if trento == `v' & PISA_year == 2018, estimate(summarize pv@flit, stats(mean))
	
	local b : di %2.1f _b[pv_flit_mean]
	local se : di %2.1f _se[pv_flit_mean]
	
	putexcel `l'2 = "`b'"
	putexcel `l'3 = "(`se')"
	
	repest PISA if trento == `v' & PISA_year == 2022, estimate(summarize pv@flit, stats(mean))
	
	local b : di %2.1f _b[pv_flit_mean]
	local se : di %2.1f  _se[pv_flit_mean]
	
	putexcel `l'4 = "`b'"
	putexcel `l'5 = "(`se')"

	repest PISA if trento == `v', estimate(means pv@flit) over(y_22, test)
	
	local diff : di %2.1f r(table)[1,3]
	local se : di %2.1f r(table)[2,3]
	local p r(table)[4,3]
	
	if `p' < 0.01 {
		putexcel `l'6 = "`diff'***"
	}
	else if `p' >= 0.01 & `p' < 0.05 {
		putexcel `l'6 = "`diff'**"
	}
	else if `p' >= 0.05 & `p' < 0.1 {
		putexcel `l'6 = "`diff'*"
	}
	else {
		putexcel `l'6 = "`diff'"
	}
	
	putexcel `l'7 = "(`se')"
}

restore


***************************
* Money management course *
***************************

putexcel set "${TABFIG}/mandate_implementation.xlsx", sheet(money_mgm, replace) modify // Initialize excel sheet

label var fl150q01ta "Specific course"
label var fl150q02ta "Cross-curricular"

forvalues x = 1/2 {
	local a : word `x' of `areas'
	local v : word `x' of `values'
	local l : word `x' of `letters'
	
	putexcel `l'1 = "`a'"
	
	foreach i of numlist 1/2 {
		local lbl : var label fl150q0`i'ta
		local i2 = 2*`i'
		local i2_1 = 2*`i' + 1
		
		putexcel A`i2' = "`lbl'"
		
		repest PISA if trento == `v', estimate(reg fl150q0`i'ta y_22)
		
		local b : di %4.3f _b[_cons]
		local d : di %4.3f _b[y_22]
		local p = r(table)[4,1]
		
		putexcel `l'`i2' = "2018: `b'"
		
		if `p' < 0.01 {
			putexcel `l'`i2_1' = "Δ: `d'***"
		}
		else if `p' >= 0.01 & `p' < 0.05 {
			putexcel `l'`i2_1' = "Δ: `d'**"
		}
		else if `p' >= 0.05 & `p' < 0.1 {
			putexcel `l'`i2_1' = "Δ: `d'*"
		}
		else {
			putexcel `l'`i2_1' = "Δ: `d'"
		}
	}
}


*****************
* FE activities *
*****************

putexcel set "${TABFIG}/mandate_implementation.xlsx", sheet(fe_activities, replace) modify // Initialize excel sheet

forvalues x = 1/2 {
	local a : word `x' of `areas'
	local v : word `x' of `values'
	local l : word `x' of `letters'
	
	putexcel `l'1 = "`a'"
	
	foreach i of numlist 1 2 3 5 6 7 {
		if `i' <= 3 {
			local y = `i'
		}
		else {
			local y = `i'-1
		}
		
		local lbl : variable label fl166q0`i'ha
		local i2 = 2*`y'
		local i2_1 = 2*`y' + 1
		
		putexcel A`i2' = "`lbl'"
		
		repest PISA if trento == `v', estimate(reg fl166q0`i'ha y_22)
		
		local b : display %6.3f _b[_cons]
		local d : display %6.3f _b[y_22]
		
		local p = r(table)[4,1]
		
		putexcel `l'`i2' = "2018: `b'"
		
		if `p' < 0.01 {
			putexcel `l'`i2_1' = "Δ: `d'***"
		}
		else if `p' >= 0.01 & `p' < 0.05 {
			putexcel `l'`i2_1' = "Δ: `d'**"
		}
		else if `p' >= 0.05 & `p' < 0.1 {
			putexcel `l'`i2_1' = "Δ: `d'*"
		}
		else {
			putexcel `l'`i2_1' = "Δ: `d'"
		}
	}
}


*******************
* Financial terms *
*******************

putexcel set "${TABFIG}/mandate_implementation.xlsx", sheet(fin_terms, replace) modify // Initialize excel sheet

label var fl164q01ha "Interest payment"
label var fl164q02ha "Compound interest"
label var fl164q03ha "Exchange rate"
label var fl164q04ha "Depreciation"
label var fl164q05ha "Shares/stocks"
label var fl164q06ha "Return on investment"
label var fl164q07ha "Dividend"
label var fl164q08ha "Diversification"
label var fl164q09ha "Debit card"
label var fl164q10ha "Bank loan"
label var fl164q11ha "Pension plan"
label var fl164q12ha "Budget"
label var fl164q13ha "Wage"
label var fl164q14ha "Entrepreneur"
label var fl164q15ha "Central bank"
label var fl164q16ha "Income tax"

forvalues x = 1/2 {
	local a : word `x' of `areas'
	local v : word `x' of `values'
	local l : word `x' of `letters'
	
	putexcel `l'1 = "`a'"
	
	foreach i of numlist 1/16 {
		if `i' < 10 {
			local y = "0`i'"
		}
		else {
			local y = "`i'"
		}
		
		local lbl : variable label fl164q`y'ha
		local i2 = 2*`i'
		local i2_1 = 2*`i' + 1
		
		putexcel A`i2' = "`lbl'"
		
		repest PISA if trento == `v', estimate(reg fl164q`y'ha y_22)
		
		local b : display %6.3f _b[_cons]
		local d : display %6.3f _b[y_22]
		
		local p = r(table)[4,1]
		
		putexcel `l'`i2' = "2018: `b'"
		
		if `p' < 0.01 {
			putexcel `l'`i2_1' = "Δ: `d'***"
		}
		else if `p' >= 0.01 & `p' < 0.05 {
			putexcel `l'`i2_1' = "Δ: `d'**"
		}
		else if `p' >= 0.05 & `p' < 0.1 {
			putexcel `l'`i2_1' = "Δ: `d'*"
		}
		else {
			putexcel `l'`i2_1' = "Δ: `d'"
		}
	}
}


//----------------------------------------------------------------------------//


* DiD-by-subject analyses 

* Define ctrl vars
global ctrl_stu female escs immig2
global ctrl_sch staffshort private rural general technical


*** Open 2022 dataset **********************************************************

use "${OUT}/fl_sch_22.dta", clear

* Drop Bolzano
drop if regione == "Bolzano"
	
* Compute Z-scores
foreach s in "flit" "math" "read" {	
	repest PISA, estimate(summarize pv@`s', stats(mean sd))
	
	local b = e(b)[1,1]
	local sd = e(b)[1,2]
	
	forvalues i = 1/10 {
		gen pv`i'`s'_z = (pv`i'`s' - `b') / `sd'	
	}	
}

* Generate differences of Z-scores
forvalues i = 1/10 {
	gen pv`i'diff_math_z = pv`i'flit_z - pv`i'math_z
	gen pv`i'diff_read_z = pv`i'flit_z - pv`i'read_z
}

* Keep estimation sample
keep if escs != . & immig2 != . & staffshort != . & rural != .


/* NOT INCLUDED IN THE PUBLIC REPLICATION

************************
* Clustering by region *
************************

* Number of clusters: 18
tab regione

* OLS flit
pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(flit_z) pv(10) cluster(regione)
estimates store ols_flit
	
foreach s in "math" "read" {
	
	* OLS math/read
	pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(`s'_z) pv(10) cluster(regione)
	estimates store ols_`s'

	* DiD by math/read
	pvreg trento [aweight=w_fstuwt], subject(diff_`s'_z) pv(10) cluster(regione)
	estimates store did_`s'_1

	pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(diff_`s'_z) pv(10) cluster(regione)
	estimates store did_`s'_2

	qui etable, estimates(ols_flit ols_`s' did_`s'_1 did_`s'_2) novarlabel stars(.1 "*" .05 "**" .01 "***", attach(_r_b)) showstars showstarsnote mstat(N) mstat(r2_a) column(estimates) export(${TABFIG}/DiD_clust_reg.xlsx, sheet(22_`s', replace) modify)
}

*/

//----------------------------------------------------------------------------//
// PUBLIC REPLICATION

* Point estimates only
pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(flit_z) pv(10)
estimates store ols_flit
	
foreach s in "math" "read" {
	
	* OLS math/read
	pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(`s'_z) pv(10)
	estimates store ols_`s'

	* DiD by math/read
	pvreg trento [aweight=w_fstuwt], subject(diff_`s'_z) pv(10)
	estimates store did_`s'_1

	pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(diff_`s'_z) pv(10)
	estimates store did_`s'_2

	qui etable, estimates(ols_flit ols_`s' did_`s'_1 did_`s'_2) novarlabel cstat(_r_b) mstat(N) mstat(r2_a) column(estimates) export(${TABFIG}/DiD_coeff_estimates.xlsx, sheet(22_`s', replace) modify)
}

//----------------------------------------------------------------------------//

/* NOT INCLUDED IN THE PUBLIC REPLICATION

**************************
* Wild cluster bootstrap *
**************************

* Use command "wildbootstrap" to compute wild cluster bootstrap-t p-values

set seed 2042668367

forvalues i = 1/10 {
	
	di `i'
		
	* OLS flit
	qui wildbootstrap regress pv`i'flit_z trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], cluster(regione)
	estimates store ols_flit
		
	foreach s in "math" "read" {

		* OLS math/read
		qui wildbootstrap regress pv`i'`s'_z trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], cluster(regione)
		estimates store ols_`s'

		* DiD by math/read
		qui wildbootstrap regress pv`i'diff_`s'_z trento [aweight=w_fstuwt], cluster(regione)
		estimates store did_`s'_1
	
		qui wildbootstrap regress pv`i'diff_`s'_z trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], cluster(regione)
		estimates store did_`s'_2
	
		qui etable, estimates(ols_flit ols_`s' did_`s'_1 did_`s'_2) novarlabel keep(wb_cns1 wb_cns2 wb_cns3 wb_cns4 wb_cns5 wb_cns6 wb_cns7 wb_cns8 wb_cns9) cstat(_r_b) cstat(_r_p) mstat(N) mstat(r2_a) column(estimates) export(${TABFIG}/DiD_wcb_`s'_22.xlsx, sheet(`i', replace) modify)	
	}
	
}


**********************
* Rearrangement test *
**********************

* Define ctrl vars
global ctrl_sch_no_priv staffshort rural general technical

* School type by region
tab regione tfstudyprog

* Aggregate regions to achieve at least 40 obs and avoid zero obs for any school type
gen id_cluster = .
replace id_cluster = 1 if regione == "Piemonte" | regione == "Liguria"
replace id_cluster = 2 if regione == "Lombardia"
replace id_cluster = 3 if regione == "Veneto" 
replace id_cluster = 4 if regione == "Friuli-Venezia Giulia"
replace id_cluster = 5 if regione == "Emilia-Romagna"
replace id_cluster = 6 if regione == "Toscana"
replace id_cluster = 7 if regione == "Umbria" | regione == "Marche"
replace id_cluster = 8 if regione == "Lazio" 
replace id_cluster = 9 if regione == "Campania" | regione == "Abruzzo"
replace id_cluster = 10 if regione == "Puglia" 
replace id_cluster = 11 if regione == "Basilicata"
replace id_cluster = 12 if regione == "Calabria"
replace id_cluster = 13 if regione == "Sicilia" | regione == "Sardegna"
replace id_cluster = 14 if regione == "Trento"

* Private schools by cluster
tab id_cluster private
    // Some ctrl clusters have no private schools! "private" must be excluded from ctrl vars

putexcel set "${TABFIG}/hgmn_test.xlsx", sheet(hgmn_test, replace) modify // Initialize excel sheet	
putexcel A1 = "math_22"
putexcel B1 = "read_22"

local cell_math = "A"
local cell_read = "B"
	
foreach s in "math" "read" {	
local c = "`cell_`s''"
	
	* Run separate regressions for each cluster
	forvalues i = 1/14 {
		local i2 = `i' + 1
		
		pvreg $ctrl_stu $ctrl_sch_no_priv if id_cluster == `i' [aweight=w_fstuwt], subject(diff_`s'_z) pv(10)
		putexcel `c'`i2' = _b[_cons]
	}
}

*/


*** Open 2018 dataset **********************************************************

use "${OUT}/fl_sch_18.dta", clear

* Drop Bolzano
drop if regione == "Bolzano"

* Compute Z-scores
foreach s in "flit" "math" "read" {	
	repest PISA, estimate(summarize pv@`s', stats(mean sd))
		
	local b = e(b)[1,1]
	local sd = e(b)[1,2]
		
	forvalues i = 1/10 {
		gen pv`i'`s'_z = (pv`i'`s' - `b') / `sd'
	}
}

* Generate differences of Z-scores
forvalues i = 1/10 {
	gen pv`i'diff_math_z = pv`i'flit_z - pv`i'math_z
	gen pv`i'diff_read_z = pv`i'flit_z - pv`i'read_z
}

* Keep estimation sample
keep if escs != . & immig2 != . & staffshort != . & rural != .


/* NOT INCLUDED IN THE PUBLIC REPLICATION

************************
* Clustering by region *
************************

* OLS flit
pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(flit_z) pv(10) cluster(regione)
estimates store ols_flit
	
foreach s in "math" "read" {
	
	* OLS math/read
	pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(`s'_z) pv(10) cluster(regione)
	estimates store ols_`s'

	* DiD by math/read
	pvreg trento [aweight=w_fstuwt], subject(diff_`s'_z) pv(10) cluster(regione)
	estimates store did_`s'_1

	pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(diff_`s'_z) pv(10) cluster(regione)
	estimates store did_`s'_2

	qui etable, estimates(ols_flit ols_`s' did_`s'_1 did_`s'_2) novarlabel stars(.1 "*" .05 "**" .01 "***", attach(_r_b)) showstars showstarsnote mstat(N) mstat(r2_a) column(estimates) export(${TABFIG}/DiD_clust_reg.xlsx, sheet(18_`s', replace) modify)
}

*/

//----------------------------------------------------------------------------//
// PUBLIC REPLICATION

* Point estimates only
pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(flit_z) pv(10)
estimates store ols_flit
	
foreach s in "math" "read" {
	
	* OLS math/read
	pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(`s'_z) pv(10)
	estimates store ols_`s'

	* DiD by math/read
	pvreg trento [aweight=w_fstuwt], subject(diff_`s'_z) pv(10)
	estimates store did_`s'_1

	pvreg trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], subject(diff_`s'_z) pv(10)
	estimates store did_`s'_2

	qui etable, estimates(ols_flit ols_`s' did_`s'_1 did_`s'_2) novarlabel cstat(_r_b) mstat(N) mstat(r2_a) column(estimates) export(${TABFIG}/DiD_coeff_estimates.xlsx, sheet(18_`s', replace) modify)
}

//----------------------------------------------------------------------------//

/* NOT INCLUDED IN THE PUBLIC REPLICATION

**************************
* Wild cluster bootstrap *
**************************

set seed 1246664098

forvalues i = 1/10 {
	
	di `i'
		
	* OLS flit
	qui wildbootstrap regress pv`i'flit_z trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], cluster(regione)
	estimates store ols_flit
		
	foreach s in "math" "read" {

		* OLS math/read
		qui wildbootstrap regress pv`i'`s'_z trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], cluster(regione)
		estimates store ols_`s'

		* DiD by math/read
		qui wildbootstrap regress pv`i'diff_`s'_z trento [aweight=w_fstuwt], cluster(regione)
		estimates store did_`s'_1
	
		qui wildbootstrap regress pv`i'diff_`s'_z trento $ctrl_stu $ctrl_sch [aweight=w_fstuwt], cluster(regione)
		estimates store did_`s'_2
	
		qui etable, estimates(ols_flit ols_`s' did_`s'_1 did_`s'_2) novarlabel keep(wb_cns1 wb_cns2 wb_cns3 wb_cns4 wb_cns5 wb_cns6 wb_cns7 wb_cns8 wb_cns9) cstat(_r_b) cstat(_r_p) mstat(N) mstat(r2_a) column(estimates) export(${TABFIG}/DiD_wcb_`s'_18.xlsx, sheet(`i', replace) modify)	
	}
	
}


**********************
* Rearrangement test *
**********************

* Define ctrl vars
global ctrl_sch_no_priv staffshort rural general technical

* School type by region
tab regione tfstudyprog

* Aggregate regions to achieve at least 40 obs and avoid zero obs for any school type
gen id_cluster = .
replace id_cluster = 1 if regione == "Piemonte" | regione == "Valle d'Aosta"
replace id_cluster = 2 if regione == "Liguria"  
replace id_cluster = 3 if regione == "Lombardia"
replace id_cluster = 4 if regione == "Veneto"
replace id_cluster = 5 if regione == "Friuli-Venezia Giulia"
replace id_cluster = 6 if regione == "Emilia-Romagna"
replace id_cluster = 7 if regione == "Toscana"
replace id_cluster = 8 if regione == "Umbria" | regione == "Marche"
replace id_cluster = 9 if regione == "Abruzzo" | regione == "Molise"
replace id_cluster = 10 if regione == "Lazio" 
replace id_cluster = 11 if regione == "Campania"
replace id_cluster = 12 if regione == "Puglia" | regione == "Basilicata" | regione == "Calabria"
replace id_cluster = 13 if regione == "Sicilia" 
replace id_cluster = 14 if regione == "Sardegna"
replace id_cluster = 15 if regione == "Trento"

* Private schools by cluster
tab id_cluster private
    // Some ctrl clusters have no private schools! We exclude private school status from ctrl vars
	
putexcel set "${TABFIG}/hgmn_test.xlsx", sheet(hgmn_test) modify // Initialize excel sheet	
putexcel C1 = "math_18"
putexcel D1 = "read_18"

local cell_math = "C"
local cell_read = "D"

foreach s in "math" "read" {	
	local c = "`cell_`s''"
	
	* Run separate regressions for each cluster
	forvalues i = 1/15 {
		local i2 = `i' + 1
		
		pvreg $ctrl_stu $ctrl_sch_no_priv if id_cluster == `i' [aweight=w_fstuwt], subject(diff_`s'_z) pv(10)
		putexcel `c'`i2' = _b[_cons]
	}
}

*/


//----------------------------------------------------------------------------//
