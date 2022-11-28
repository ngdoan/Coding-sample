/*******************************************************************************																							
Purpose:	Chi-squared and F-tests of disparate impact by age, gender, and race
*******************************************************************************/

* Preliminaries
clear all
set more off
set type double 

import excel "[INSERT PATH]/redacted.xlsx", sheet("Sheet1") firstrow

* File paths

global root "[INSERT PATH]"
global data "$root/Data/output"

global path "$root/Analysis"
global input "$path/input"
global output "$path/output"
global temp "$path/temp"



********************************************************************************
* 0. Program for Statistical Tests
********************************************************************************

cap program drop disp_imp
program define disp_imp, eclass

	*------------------------------- Syntax -------------------------------*
	syntax varlist(min=1 max=1) [if], by(varname) filename(string) sheet(string)
	
	*----------------------------- Frequencies ----------------------------*
	* Save frequencies
	tab `by' `varlist' `if', matcell(m_freq)
	
		// Label rows
		local by_label0: label l_`by' 0
		local by_label1: label l_`by' 1
		mat rownames m_freq = "`by_label0'" "`by_label1'"
		
		// Label columns
		local var_label0: label l_`varlist' 0
		local var_label1: label l_`varlist' 1
		mat colnames m_freq = "`var_label0'" "`var_label1'"
	
	*-------------------------- Statistical Tests -------------------------*
	* Define matrix
	matrix def Results = J(1,2,.)
	matrix colnames Results = fisher_p chi_p
	
	* Fisher-exact test
	tab `by' `varlist' `if', exact
	local fisher_p = r(p_exact)
	mat Results[1,1] = `fisher_p'
	
	* Chi-squared test
	tab `by' `varlist' `if', chi2
	local chi2_p = r(p)
	mat Results[1,2] = `chi2_p'
	
	*------------------------------- Output -------------------------------*	
	* Excel
	putexcel set "[INSERT PATH]/`filename'", sheet("`sheet'", replace) modify open
	putexcel save
	putexcel A1 = matrix(m_freq), names			
	putexcel E1 = matrix(Results), names
	putexcel close 



	
	* Macros
	ereturn mat m_freq = m_freq
	ereturn local fisher_p = `fisher_p'
	ereturn local chi2_p = `chi2_p'
	
end

********************************************************************************
* 1. Statistical Tests
********************************************************************************

/*
Counsel requests:
	1. Impact on company as a whole
	2. Impact within all the impacted functions (only 4)
	3. Impact within each individual impacted function (where applicable)

Categories of Analysis:
	1. Gender
	2. Age
		- 40+ vs. under 40
	3. Race
		- ***CHECK HOW THEY WANT TO BREAK THIS UP***
*/ 

* Opening the data from data build 00
foreach var in org { 



* Creating retained variable from impacted var
gen retained = 1-Impacted
label define l_retained 1 "Retained" 0 "Terminated"
label values retained l_retained

*----------------------------- Company as a Whole -----------------------------*
* Gender
disp_imp retained, by(Gender) filename("RIF Analysis.xlsx") sheet("raw_gender")

* Age (40+ vs. under)
disp_imp retained, by(Over40) filename("RIF Analysis.xlsx") sheet("raw_age_40plus") 

* Race (Non-white vs. white)
disp_imp retained, by(Nonwhite) filename("RIF Analysis.xlsx") sheet("raw_white")

*Race (all other races)
foreach race in asian black latino NHPI mixed {
	disp_imp retained, by(race_'race') filename("RIF Analysis.xlsx") sheet("raw_`Race'")

	

*----------------------------- Impacted Functions -----------------------------*
* Gender
if ImpactedDep == 1 disp_imp retained, by(Gender) filename("RIF Analysis.xlsx") sheet("gender_impacted")

* Age (40+ vs. under)
if ImpactedDep == 1 disp_imp retained, by(Age) filename("RIF Analysis.xlsx") sheet("40plus_impacted")

* Race (Non-white vs. white)
if ImpactedDep == 1 disp_imp retained, by(Nonwhite) filename("RIF Analysis.xlsx") sheet("white_impacted")

*Race (all other races)
if ImpactedDep == 1 {
foreach race in asian black latino NHPI mixed {
	disp_imp retained, by(race_'race') filename("RIF Analysis.xlsx") sheet("raw_`Race'")
	}
}












