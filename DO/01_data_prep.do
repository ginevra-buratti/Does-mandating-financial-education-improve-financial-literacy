
//----------------------------------------------------------------------------//
// 01 - Data preparation
// Authors: A. Antonello, G. Buratti
// Date: 2026
// Description: This do-file runs the data preparation.
//----------------------------------------------------------------------------//


* Import SPSS files from INVALSI

* Import 2018 FL dataset
qui import spss using "${DATA}/Microdati PISA 2018 FL.sav", case(lower) clear

* Save temporary file
save "${TEMP}/fl_18.dta", replace

* Import 2018 school dataset
qui import spss using "${DATA}/Microdati PISA 2018 Questionario Scuola.SAV", case(lower) clear

* Save temporary file
save "${TEMP}/sch_18.dta", replace

* Import 2022 FL dataset
qui import spss using "${DATA}/Microdati PISA 2022 Educazione Finanziaria.sav", case(lower) clear

* Save temporary file
save "${TEMP}/fl_22.dta", replace

* Import 2022 school dataset
qui import spss using "${DATA}/Microdati PISA 2022 Questionario Scuola.sav", case(lower) clear

* Save temporary file
save "${TEMP}/sch_22.dta", replace


//----------------------------------------------------------------------------//


/* NOT INCLUDED IN THE PUBLIC REPLICATION

* Import school location data

* Import 2018 school location dataset
qui import excel "${DATA}/reg_prov_18.xlsx", firstrow clear

* Fix regione
replace regione = strproper(regione)
replace regione = "Bolzano" if regione == "Bolzano (Prov. Autonoma)"
replace regione = "Trento" if regione == "Trento (Prov. Autonoma)"
replace regione = "Friuli-Venezia Giulia" if regione == "Friuli-Venezia-Giulia"
replace regione = "Valle d'Aosta" if regione == "Valle D'Aosta"

* Save temporary file
save "${TEMP}/sch_loc_18.dta", replace
	
* Import 2022 school location dataset
qui import excel "${DATA}/reg_prov_22.xlsx", firstrow clear

* Fix regione
replace regione = strproper(regione)
replace regione = "Bolzano" if regione == "Bolzano (Prov. Autonoma)"
replace regione = "Trento" if regione == "Trento (Prov. Autonoma)"
replace regione = "Valle d'Aosta" if regione == "Valle d'Aosta"

* Save temporary file
save "${TEMP}/sch_loc_22.dta", replace

*/


//----------------------------------------------------------------------------//


* Build 2018 dataset

* Open 2018 FL dataset
use "${TEMP}/fl_18.dta", clear

* Fix school ID to successfully merge school dataset
replace fcntschid = fcntschid - 50000

* Merge 2018 school dataset
merge m:1 fcntschid using "${TEMP}/sch_18.dta"
	
* Drop unmatched schools
drop if _merge == 2
drop _merge

* Rename IDs
rename fcntstuid cntstuid
rename fcntschid cntschid

* Rename Invalsi school ID to successfully merge regions
rename codice_scuola_1718 cod_scuola

/* NOT INCLUDED IN THE PUBLIC REPLICATION

* Merge to retrieve regions
merge m:1 cod_scuola using "${TEMP}/sch_loc_18.dta", keepusing(regione)

* Drop obs with missing location
drop if _merge != 3
drop _merge

*/

//----------------------------------------------------------------------------//
// PUBLIC REPLICATION

* Drop schools with missing region IDs
drop if inlist(cod_scuola, 30304018, 30411102, 30502009, 31402012, 31606135, 32008001, 32008003, 32008004, 71401024)

* Identify Trento and Bolzano
tab regionid langtest // regionid = 1 identifies Bolzano based on test language
tab regionid areageo_5 // then regionid = 5 identifies Trento based on geographical area

* Identify Invalsi school ID pattern for Trento and Bolzano
tab cod_scuola regionid if inlist(regionid, 1, 5)

* Gen region IDs for Trento and Bolzano
gen regione = ""
replace regione = "Bolzano" if regionid == 1
replace regione = "Trento" if regionid == 5

//----------------------------------------------------------------------------//

* Flag year
gen PISA_year = 2018

* Drop middle school students
drop if tfgrade < 9

* Fix macroarea var
rename areageo_5 area5
label define labels_area5 1 "Nord-Ovest" 2 "Nord-Est" 3 "Centro" 4 "Sud" 5 "Sud-Isole"
label values area5 labels_area5
decode area5, gen(tmp)
drop area5
rename tmp area5

* Gen dummy for Trento
gen trento = (regione == "Trento")

* Gen dummy for female
gen female = .
replace female = 1 if st004d01t == 1
replace female = 0 if st004d01t == 2

* Gen dummy for immigrant
gen immig2 = immig
recode immig2 (1=0) (2=1) (3=1)

* Gen dummy for private school
gen private = .
replace private = 1 if sc013q01ta == 2
replace private = 0 if sc013q01ta == 1

* Gen dummy for rural school (N.B.: sc001q01ta has incorrect labels in this dataset)
gen rural = .
replace rural = 1 if (sc001q01ta >= 1 & sc001q01ta <= 3) // Town
replace rural = 0 if (sc001q01ta >= 4 & sc001q01ta <= 5) // City

* Gen dummies for school type
gen general = (tfstudyprog == 1)
gen technical = (tfstudyprog == 2)
gen vocational = (tfstudyprog == 3)
gen iefp = (tfstudyprog == 5)

* Fix Sidi
replace sidi_invalsi = "" if sidi_invalsi == "NON DISPONIBILE"
destring sidi_invalsi, replace

* Save 2018 dataset
save "${OUT}/fl_sch_18.dta", replace

* Erase unnecessary files
erase "${TEMP}/fl_18.dta"
erase "${TEMP}/sch_18.dta"
* erase "${TEMP}/sch_loc_18.dta"


//----------------------------------------------------------------------------//


* Build 2022 dataset

* Open 2022 FL dataset
use "${TEMP}/fl_22.dta", clear

* Merge 2022 school dataset
merge m:1 fcntschid using "${TEMP}/sch_22.dta"
drop if _merge != 3 // We lose 2 observations that cannot be matched to school data
drop _merge

* Rename IDs
rename fcntschid cntschid
rename fcntstuid cntstuid

* Rename Invalsi school ID to successfully merge school location info
rename codice_scuola_invalsi cod_scuola

/* NOT INCLUDED IN THE PUBLIC REPLICATION
	
* Merge to retrieve regions
merge m:1 cod_scuola using "${TEMP}/sch_loc_22.dta", keepusing(regione)

* Drop unmatched schools
drop if _merge == 2
drop _merge

*/

//----------------------------------------------------------------------------//
// PUBLIC REPLICATION

* Gen region IDs for Trento and Bolzano based on Invalsi school ID pattern
tostring cod_scuola, gen(cod_scuola_str)
gen regione = ""
replace regione = "Bolzano" if inlist(substr(cod_scuola_str, 2, 4), "0501", "0502", "0503")
replace regione = "Trento" if substr(cod_scuola_str, 2, 4) == "0504"
drop cod_scuola_str

//----------------------------------------------------------------------------//

* Flag year
gen PISA_year = 2022

* Drop middle school students
drop if tfgrade < 9

* Fix macroarea var
rename macroarea area5
replace area5 = strproper(area5)
replace area5 = "Nord-Est" if area5 == "Nord Est"
replace area5 = "Nord-Ovest" if area5 == "Nord Ovest"
replace area5 = "Sud-Isole" if area5 == "Sud E Isole"

* Gen dummy for Trento
gen trento = (regione == "Trento")

* Gen dummy for female
gen female = .
replace female = 1 if st004d01t == 1
replace female = 0 if st004d01t == 2

* Gen dummy for immigrant
gen immig2 = immig
recode immig2 (1=0) (2=1) (3=1)

* Gen dummy for private school
gen private = .
replace private = 1 if privatesch == "private"
replace private = 0 if privatesch == "public"

* Gen dummy for rural school (slightly different definition compared to 2018)
gen rural = .
replace rural = 1 if (sc001q01ta >= 1 & sc001q01ta <= 3)
replace rural = 0 if (sc001q01ta >= 4 & sc001q01ta <= 6)

* Gen dummies for school type
gen general = (tfstudyprog == 1)
gen technical = (tfstudyprog == 2)
gen vocational = (tfstudyprog == 3)
gen iefp = (tfstudyprog == 5)

* Gen var for impact of Covid
gen covid = sc213q01ja
replace covid = . if sc213q01ja > 365 // Remove 1 outlier

* Save dataset
save "${OUT}/fl_sch_22.dta", replace

* Erase unnecessary files
erase "${TEMP}/fl_22.dta"
erase "${TEMP}/sch_22.dta"
* erase "${TEMP}/sch_loc_22.dta"


//----------------------------------------------------------------------------//


* Merge 2018 and 2022 datasets

* Open 2018 dataset
use "${OUT}/fl_sch_18.dta", clear

* Append 2022 dataset
qui append using "${OUT}/fl_sch_22.dta"

* Generate year dummy
gen y_22 = (PISA_year == 2022)

* Recode and relabel values of vars on money management courses
label define yes_no 0 "No" 1 "Yes"

foreach i of numlist 1/2 {
	qui recode fl150q0`i'ta (2=0) // Recode (0: No; 1: Yes)
	qui label values fl150q0`i'ta yes_no
}

* Recode and relabel values of vars on financial terms
label define heard_learnt 0 "Never heard of it" 1 "Heard of or learnt about it"

foreach i of numlist 1/16 {
	if `i' < 10 {
		local y = "0`i'"
	}
	else {
		local y = "`i'"
	}
	qui recode fl164q`y'ha (1=0) (2=1) (3=1) // Recode (0: Never heard of; 1: Heard of or learnt about)
	qui label values fl164q`y'ha heard_learnt
}

* Recode and relabel values of vars on FE activities
label define never_often 0 "Never" 1 "Sometimes or often"

foreach i of numlist 1/3 5/7 {
	qui recode fl166q0`i'ha (1=0) (2=1) (3=1) // Recode (0: Never; 1: Sometimes or Often)
	qui label values fl166q0`i'ha never_often
}

* Recode var for responsible internet behaviour
replace sc190q08ja = sc156q05ha if PISA_year == 2018 // Make vars uniform
recode sc190q08ja (2=0) // Recode (0: No; 1: Yes)
label values sc190q08ja yes_no

* Relabel vars
label var fl150q01ta "Learned to manage money in school (course)"
label var fl150q02ta "Learned to manage money in school (cross-curricular)"
label var fl164q01ha "Financial terms in school: Interest payment"
label var fl164q02ha "Financial terms in school: Compound interest"
label var fl164q03ha "Financial terms in school: Exchange rate"
label var fl164q04ha "Financial terms in school: Depreciation"
label var fl164q05ha "Financial terms in school: Shares/stocks"
label var fl164q06ha "Financial terms in school: Return on investment"
label var fl164q07ha "Financial terms in school: Dividend"
label var fl164q08ha "Financial terms in school: Diversification"
label var fl164q09ha "Financial terms in school: Debit card"
label var fl164q10ha "Financial terms in school: Bank loan"
label var fl164q11ha "Financial terms in school: Pension plan"
label var fl164q12ha "Financial terms in school: Budget"
label var fl164q13ha "Financial terms in school: Wage"
label var fl164q14ha "Financial terms in school: Entrepreneur"
label var fl164q15ha "Financial terms in school: Central bank"
label var fl164q16ha "Financial terms in school: Income tax"
label var fl166q01ha "Describe uses of money"
label var fl166q02ha "Explore needs vs wants"
label var fl166q03ha "Explore expenses planning"
label var fl166q05ha "Discuss consumer rights"
label var fl166q06ha "Discuss stock market prices"
label var fl166q07ha "Understand advertisements"
label var sc190q08ja "School has a programme to prepare students for responsible internet behaviour"

* Save dataset
save "${OUT}/fl_sch_18_22.dta", replace


//----------------------------------------------------------------------------//
