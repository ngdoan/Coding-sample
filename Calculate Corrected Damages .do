*ssc install distinct
*uncomment command above and install if not already installed
clear all
set type double
pause on

* global root 

global root "[insert path]"
global dta "/[insert path]"

* Define New Subfolder
global excel "[insert path]/excel"
* Creating an empty dta file to append results
save "$excel/corrected_excess_premiums_new.dta", replace emptyok
********************************************************************************
* 
********************************************************************************
use "$dta/redacted_premiums_Feb2013_to_Feb2020.dta"
collapse (sum) amount (max) closed_dt, by(policy_no due_dt)
gen source="Feb2020"
save "$dta/redacted_premiums_Feb2020.dta", replace

clear
use "$dta/redacted_premium_new.dta"
collapse (sum) amount=monthlytotal, by(policy_no closed_dt due_dt closeddtmonth closeddtyear)
merge m:1 policy_no using "$dta/redacted_last_premiums.dta", keepusing(ph_last_closed_premium_year ph_last_closed_premium_mon ph_last_payment)
keep if _m==3
distinct policy_no 
drop if  ym(closeddtyear,closeddtmonth) <= ym(ph_last_closed_premium_year,ph_last_closed_premium_mon)
distinct policy_no 
keep policy_no due_dt closed_dt amount
gen source="June2022"
save "$dta/redacted_premiums_June2022.dta", replace

append using "$dta/redacted_premiums_Feb2020.dta"

sort policy_no due_dt closed_dt
save "$dta/redacted_premiums_Feb2013_to_June2022.dta", replace


********************************************************************************
* 
********************************************************************************

clear 
use "$dta/redacted_premiums_Feb2013_to_June2022.dta"
merge m:1 policy_no using "$dta/redacted_verified_RI.dta"
keep if _m==3 
drop _m
distinct policy_no 
merge m:1 policy_no using  "$dta/redacted_downgrades_new.dta"
drop if  _m==2 
drop _m
distinct policy_no 

sort policy_no due_dt closed_dt, stable
********************************************************************************
*
********************************************************************************
gen ri_period_1=premium_ri_date_1==due_dt 
distinct policy_no if premium_ri_date_1!=.
gen ri_period_2=premium_ri_date_2==due_dt 
distinct policy_no if premium_ri_date_2!=. 
gen ri_period_7=premium_ri_date_7==due_dt 
distinct policy_no if premium_ri_date_7!=.
egen min_excess_dt=rowmin(premium_ri_date_1 premium_ri_date_2 premium_ri_date_7)
format %td min_excess_dt
********************************************************************************
*
********************************************************************************
keep if due_dt >= min_excess_dt 

********************************************************************************
* 
********************************************************************************
order policy_no due_dt  amount  ph_first_down_dt 
gen sort_order=_n
sort policy_no due_dt closed_dt sort_order
gen ri_period=1 if premium_ri_date_1<=due_dt & premium_ri_date_1!=.
replace ri_period=2 if premium_ri_date_2<=due_dt & premium_ri_date_2!=.
replace ri_period=7 if premium_ri_date_7<=due_dt & premium_ri_date_7!=.
replace ri_period=. if (due_dt >= reduction_dt) 
order policy_no due_dt  amount  ph_first_down_dt ri_period premium_ri_date_1 premium_ri_date_2

* Calculate Damages using Mr. [redacted]'s calculated but-for premium increse 
* Rate = 80.1% or .801
gen rate = string(.801 *100) + "%"
gen     base = (1.36 - sqrt(1.801))/(1.36)   * (amount) if ri_period ==1
replace base = (0.85 - 0.801)/(1.85)   * (amount) if ri_period ==2
replace base = (0.801 - 0.79) * (.801/.85)/(1.79)   * (amount) if ri_period==7

bys policy_no: egen ph_base = sum(base)
replace base=0 if ph_base<0

egen total_base=sum(base)
egen total_base_Feb2020=sum(base) if source=="Feb2020"

gen num_days = mdy(5,15,2023) - closed_dt // Scheduled trial date
gen interest = (base * (1+0.1*(num_days/365))) - base 
egen total_interest = sum(interest) 
gen damage = total_base + total_interest

format total_base total_base_Feb2020 total_interest damage %13.0gc
order total_base total_interest damage policy_no due_dt closed_dt amount ph_first_down_dt ri_period premium_ri_date_1 premium_ri_date_2 base ph_base

* Keep necessary variables
keep rate total_base total_interest damage
keep if _n==1

* Append results to save in dta file 
*append using "$excel/corrected_excess_premiums_new.dta" 
*commented out because it uploads previously saved data on top of newly created data
save "$excel/corrected_excess_premiums_new.dta", replace

*Export results from dta to Excel
use "$excel/corrected_excess_premiums_new.dta", replace
export excel using "$excel/Exhibit 2 New Data.xlsx", firstrow(var) replace


********************************************************************************
********************************************************************************
