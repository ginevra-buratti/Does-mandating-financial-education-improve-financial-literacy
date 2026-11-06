
//----------------------------------------------------------------------------//
// 02 - Descriptive stats
// Author: A. Antonello, G. Buratti
// Date: 2026
// Description: This do-file runs descriptive statistics.
//----------------------------------------------------------------------------//


foreach y in "22" "18" {
	
	* Open dataset
	use "${OUT}/fl_sch_`y'.dta", clear
	
	* Drop Bolzano
	drop if regione == "Bolzano"
	
	* Keep estimation sample
	keep if escs != . & immig2 != . & staffshort != . & rural != .
	
	* Gen dummy for vocational and IeFP schools
	gen voc_iefp = (vocational == 1 | iefp == 1)

	* Initialize excel table
	putexcel set "${TABFIG}/descr_stats.xlsx", sheet(`y', replace) modify
	putexcel A2 = "Variable"
	putexcel B1 = "Trento"
	putexcel B2 = "Obs"
	putexcel C2 = "Mean"
	putexcel D2 = "SD"
	putexcel E2 = "Range"
	putexcel F1 = "Rest of Italy"
	putexcel F2 = "Obs"
	putexcel G2 = "Mean"
	putexcel H2 = "SD"
	putexcel I2 = "Range"
	putexcel J2 = "Mean diff"
	putexcel K2 = "SE"

	
	***************
	* Test scores *
	***************
	
	local vars1 flit math read
	local cells1 "3 4 5"
	local labs1 `" "Financial literacy" "Mathematics" "Reading" "'
	
	local n : word count `vars1'

	forvalues i = 1/`n' {
		local v : word `i' of `vars1'
		local c : word `i' of `cells1'
		local x : word `i' of `labs1'

		putexcel A`c' =  "`x'"
	
		repest PISA, estimate(summarize pv@`v', stats(N mean sd min max)) over(trento)
		
		local obs1 : di e(b)[1,6]
		local b1 : di %2.1f e(b)[1,7]
		local sd1 : di %2.1f e(b)[1,8]
		local min1 : di %2.1f e(b)[1,9]
		local max1 : di %2.1f e(b)[1,10]
		putexcel B`c' = "`obs1'"
		putexcel C`c' = "`b1'"
		putexcel D`c' = "`sd1'"
		putexcel E`c' = "[`min1', `max1']"	
	
		local obs0 : di e(b)[1,1]
		local b0 : di %2.1f e(b)[1,2]
		local sd0 : di %2.1f e(b)[1,3]
		local min0 : di %2.1f e(b)[1,4]
		local max0 : di %2.1f e(b)[1,5]
		putexcel F`c' = "`obs0'"
		putexcel G`c' = "`b0'"
		putexcel H`c' = "`sd0'"
		putexcel I`c' = "[`min0', `max0']"
	
		repest PISA, estimate(means pv@`v') over(trento, test)
		local diff : di %2.1f r(table)[1,3]
		local se : di %2.1f r(table)[2,3]
		local p r(table)[4,3]
		if `p' < 0.01 {
			putexcel J`c' = "`diff'***"
		}
		else if `p' >= 0.01 & `p' < 0.05 {
			putexcel J`c' = "`diff'**"
		}
		else if `p' >= 0.05 & `p' < 0.1 {
			putexcel J`c' = "`diff'*"
		}
		else {
			putexcel J`c' = "`diff'"
		}
		putexcel K`c' = "`se'"
	}

	
	*******************
	* Background vars *
	*******************
	
	local vars2 female escs immig2 general technical voc_iefp private rural staffshort
	local cells2 "6 7 8 9 10 11 12 13 14"

	label var female "Female"
	label var escs "ESCS"
	label var immig2 "Immigrant"
	label var general "General"
	label var technical "Technical"
	label var voc_iefp "Vocational and Iefp"
	label var private "Private"
	label var rural "Rural"
	label var staffshort "Staff shortage"

	local n : word count `vars2'

	forvalues i = 1/`n' {
		local v : word `i' of `vars2'
		local c : word `i' of `cells2'

		putexcel A`c' =  `"`: var label `v''"'
	    
		repest PISA, estimate(summarize `v', stats(N mean sd min max)) over(trento)
		
		local obs1 : di e(b)[1,6]
		local b1 : di %4.3f e(b)[1,7]
		local sd1 : di %4.3f e(b)[1,8]
		local min1 : di %3.2f e(b)[1,9]
		local max1 : di %3.2f e(b)[1,10]
		putexcel B`c' = "`obs1'"
		putexcel C`c' = "`b1'"
		putexcel D`c' = "`sd1'"
		putexcel E`c' = "[`min1', `max1']"	
	
		local obs0 : di e(b)[1,1]
		local b0 : di %4.3f e(b)[1,2]
		local sd0 : di %4.3f e(b)[1,3]
		local min0 : di %3.2f e(b)[1,4]
		local max0 : di %3.2f e(b)[1,5]
		putexcel F`c' = "`obs0'"
		putexcel G`c' = "`b0'"
		putexcel H`c' = "`sd0'"
		putexcel I`c' = "[`min0', `max0']"
	
		repest PISA, estimate(means `v') over(trento, test)
		local diff : di %4.3f r(table)[1,3]
		local se : di %4.3f r(table)[2,3]
		local p r(table)[4,3]
		if `p' < 0.01 {
			putexcel J`c' = "`diff'***"
		}
		else if `p' >= 0.01 & `p' < 0.05 {
			putexcel J`c' = "`diff'**"
		}
		else if `p' >= 0.05 & `p' < 0.1 {
			putexcel J`c' = "`diff'*"
		}
		else {
			putexcel J`c' = "`diff'"
		}
		putexcel K`c' = "`se'"
	}
	
}


* Add descriptive stats for Covid
use "${OUT}/fl_sch_22.dta", clear

* Drop Bolzano
drop if regione == "Bolzano"

* Keep estimation sample
keep if escs != . & immig2 != . & staffshort != . & rural != .

putexcel set "${TABFIG}/descr_stats.xlsx", sheet(22) modify
putexcel A15 =  "Covid-19"
local c "15"
	
repest PISA, estimate(summarize covid, stats(N mean sd min max)) over(trento)
		
local obs1 : di e(b)[1,6]
local b1 : di %2.1f e(b)[1,7]
local sd1 : di %2.1f e(b)[1,8]
local min1 : di %2.1f e(b)[1,9]
local max1 : di %2.1f e(b)[1,10]
putexcel B`c' = "`obs1'"
putexcel C`c' = "`b1'"
putexcel D`c' = "`sd1'"
putexcel E`c' = "[`min1', `max1']"	
	
local obs0 : di e(b)[1,1]
local b0 : di %2.1f e(b)[1,2]
local sd0 : di %2.1f e(b)[1,3]
local min0 : di %2.1f e(b)[1,4]
local max0 : di %2.1f e(b)[1,5]
putexcel F`c' = "`obs0'"
putexcel G`c' = "`b0'"
putexcel H`c' = "`sd0'"
putexcel I`c' = "[`min0', `max0']"
	
repest PISA, estimate(means covid) over(trento, test)
local diff : di %2.1f r(table)[1,3]
local se : di %2.1f r(table)[2,3]
local p r(table)[4,3]
if `p' < 0.01 {
	putexcel J`c' = "`diff'***"
}
else if `p' >= 0.01 & `p' < 0.05 {
	putexcel J`c' = "`diff'**"
}
else if `p' >= 0.05 & `p' < 0.1 {
	putexcel J`c' = "`diff'*"
}
else {
	putexcel J`c' = "`diff'"
}
putexcel K`c' = "`se'"

