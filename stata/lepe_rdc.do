*****************************************************************************
/*** Labour Economics and Policy Evaluation Project ***/
/*** The effects of the Introduction of Reddito di Cittadinanza in Italy ***/
*****************************************************************************

// close already opened log, programs or macro
capture log close 
capture program drop _all 
capture macro drop _all
drop _all
set more off
// ssc install outreg2
// ssc install reghdfe
// ssc install ftools
// ssc install carryforward
// ssc install parmest
// ssc install coefplot
// ssc install eclplot



*********************************
/*** Global and local ***/
*********************************
* Path switchers
global fede = 1
global fede_2= 0


*********************************
/*** Set Directory Structure ***/
*********************************
if $fede ==1 {
	global data "/Users/federicobassi/Desktop/DSE/LEPE/progetto_RdC/data"
	global tables "/Users/federicobassi/Desktop/DSE/LEPE/progetto_RdC/tables"
	global logs "/Users/federicobassi/Desktop/DSE/LEPE/progetto_RdC/logs"
	global figures = "/Users/federicobassi/Desktop/DSE/LEPE/progetto_RdC/figures"
} 
if $fede_2 ==1{
	global data = "/Users/federicobassi/Library/Mobile Documents/com~apple~CloudDocs/Desktop/DSE/LEPE/progetto_RdC/data"
	global tables = "/Users/federicobassi/Library/Mobile Documents/com~apple~CloudDocs/Desktop/DSE/LEPE/progetto_RdC/tables"
	
}

************************************************
**** ECOLOGICAL REGRESSION - Province level ****
************************************************


*********************************
/*** Data Manipulation ***/
*********************************
/* Open data file */
use "$data/dataset_provinces.dta", clear

/* Keep only data within 2015-2021 */
keep if (year>=2015)
keep if (year<=2021)

/* Declare dataset to be panel */
egen id = group(unit)
xtset id year

/* Generate new variables */
gen post = 0
replace post = 1 if (year > 2018)

gen percent_graduates = graduates/residents*100
gen percent_recipients = recipients/residents*100
gen frac_firms = registered_firms/residents


/* Labelling of the variables */
label var unit "NUTS 3 unit"
label var percent_women "percentage of women"
label var residents "number of residents"
label var percent_foreigners "percentage of resident foreigners"
label var unemployment "unemployment rate"
label var graduates "number of graduates"
label var recipients "number of recipients of Reddito Di Cittadinanza"
label var post "years after the introduction of the policy"
label var percent_graduates "percentage of graduates"
label var percent_recipients "percentage of recipients of Reddito Di Cittadinanza"
label var frac_firms "Ratio of the number of firms to the resident population"



*********************************
/*** Regression ***/
*********************************
xtreg unemployment  percent_recipients i.year percent_women percent_foreigners percent_graduates frac_firms, vce(cluster id)
outreg2 using "$tables/eco_reg_prov.tex", replace ctitle(" ") keep(percent_women percent_foreigners percent_graduates percent_recipients frac_firms) addtext(Unit FE, No, Year FE, Yes)

xtreg unemployment  percent_recipients i.year percent_women percent_foreigners percent_graduates frac_firms,fe vce(cluster id)
outreg2 using "$tables/eco_reg_prov.tex", append ctitle(" ") keep(percent_women percent_foreigners percent_graduates percent_recipients frac_firms) addtext(Unit FE, Yes, Year FE, Yes)


************************************************
**** ECOLOGICAL REGRESSION - Region level ****
************************************************


*********************************
/*** Data Manipulation ***/
*********************************

/* Open data file */
use "$data/dataset_regions.dta", clear

destring perc_poor_families, generate(n_perc_poor_families) force float
drop perc_poor_families
rename n_perc_poor_families perc_poor_families

/* Keep only data within 2015-2021 */
keep if (year>=2015)
keep if (year<=2021)

/* Declare dataset to be panel */
egen id = group(unit)
xtset id year


/* Generate new variables */
gen perc_recipients = num_recipients/resident * 100


/* Labelling of the variables */
label var unit "NUTS 2 unit"
label var perc_poor_families "percentage families living in (relative) poverty conditions"
label var perc_poor_individuals "percentage of poor individuals living in (relative) poverty conditions"
label var gdp "Inflation-adjusted GDP of the region"
label var residents "number of residents"
label var num_recipients "number of recipients of Reddito di Cittadinanza"
label var perc_applicants "percentage of residents applying for Reddito di Cittadinanza"

*********************************
/*** Descriptive Statistics ***/
*********************************
graph dot (mean) perc_recipients, over(unit, sort(1)) title("Mean percentage of residents receiving the income", span) subtitle(" ") ytitle("") note("Note: Averages computed over the years 2019-2021", span) saving("$figures/perc_recipients_reg")

graph dot (mean) perc_applicants, over(unit, sort(1)) title("Mean percentage of households applying for the income", span) subtitle(" ") ytitle("") marker(1, mcolor("red")) note("Note: Averages computed over the years 2019-2021", span) saving("$figures/perc_applicants_reg")

gr combine "$figures/perc_recipients_reg" "$figures/perc_applicants_reg", ysize(9) xsize(5) col(1) saving("$figures/descriptive_statistics")


*********************************
/*** Regression ***/
*********************************
xtreg unemployment i.year perc_recipients gdp, vce(cluster id)
outreg2 using "$tables/eco_reg_reg.tex", replace ctitle(No controls on poor) keep(perc_recipients gdp) addtext(Unit FE, No, Year FE, Yes)

xtreg unemployment i.year perc_recipients gdp,fe vce(cluster id)
outreg2 using "$tables/eco_reg_reg.tex", append ctitle(" ") keep(perc_recipients gdp) addtext(Unit FE, Yes, Year FE, Yes)

xtreg unemployment i.year perc_recipients gdp perc_poor_families, vce(cluster id)
outreg2 using "$tables/eco_reg_reg.tex", append ctitle(Poor families (%)) keep(perc_recipients perc_poor_families gdp) addtext(Unit FE, No, Year FE, Yes)

xtreg unemployment i.year perc_recipients gdp perc_poor_families,fe vce(cluster id)
outreg2 using "$tables/eco_reg_reg.tex", append ctitle(" ") keep(perc_recipients perc_poor_families gdp) addtext(Unit FE, Yes, Year FE, Yes)

xtreg unemployment i.year perc_poor_individuals gdp perc_recipients, vce(cluster id)
outreg2 using "$tables/eco_reg_reg.tex", append ctitle(Poor individuals(%)) keep(perc_recipients perc_poor_individuals gdp) addtext(Unit FE, No, Year FE, Yes)

xtreg unemployment i.year perc_poor_individuals gdp perc_recipients,fe vce(cluster id)
outreg2 using "$tables/eco_reg_reg.tex", append ctitle(" ") keep(perc_recipients perc_poor_individuals gdp) addtext(Unit FE, Yes, Year FE, Yes) 


**********************************
**** CASE EVENT STUDY ****
*********************************

/* Generate new variables */
gen perc_poor_families_t0 = perc_poor_families if year == 2018
gen perc_poor_individuals_t0 = perc_poor_individuals if year == 2018

/* Carry forward */ 
bys unit: replace perc_poor_families_t0 = perc_poor_families_t0[_n-1] if missing(perc_poor_families_t0)

bys unit: replace perc_poor_individuals_t0 = perc_poor_individuals_t0[_n-1] if missing(perc_poor_individuals_t0)


/* Carry backward */ 
gsort unit -year
bys unit: replace perc_poor_families_t0 = perc_poor_families_t0[_n-1] if missing(perc_poor_families_t0)

bys unit: replace perc_poor_individuals_t0 = perc_poor_individuals_t0[_n-1] if missing(perc_poor_individuals_t0)

label var perc_poor_individuals_t0 "percentage of poor individuals the year before the introduction of RdC (2018)"
label var perc_poor_families_t0 "percentage of poor families the year before the introduction of RdC (2018)"


**** PERC_POOR_INDIVIDUALS ****
xtreg unemployment c.perc_poor_individuals_t0##i.year ib2018.year gdp, fe vce (cluster id)
parmest, frame() saving("$logs/results_1", replace)
outreg2 using "$tables/case_event.tex",keep(c.perc_poor_individuals_t0##i.year) addtext(Unit FE, Yes, Year FE, Yes) replace ctitle(total_unemployment)

xtreg unemployment_no_degree c.perc_poor_individuals_t0##i.year ib2018.year gdp, fe vce (cluster id)
parmest, frame() saving("$logs/results_2", replace)
outreg2 using "$tables/case_event.tex", keep(c.perc_poor_individuals_t0##i.year) addtext(Unit FE, Yes, Year FE, Yes) append ctitle(unemployment_no_degree)

xtreg unemployment_25_34 c.perc_poor_individuals_t0##i.year ib2018.year gdp, fe vce (cluster id)
parmest, frame() saving("$logs/results_3", replace)
outreg2 using "$tables/case_event.tex", keep(c.perc_poor_individuals_t0##i.year) addtext(Unit FE, Yes, Year FE, Yes) append ctitle(unemployment_25_34)


use "$logs/results_1", clear
replace parm = "2015" in 9
replace parm = "2016" in 10
replace parm = "2017" in 11
replace parm = "2019" in 13
replace parm = "2020" in 14
replace parm = "2021" in 15
keep in 9/15
drop in 4
encode parm, generate(parm2)
drop parm
rename parm2 parm
label variable estimate "Regression Coefficient"
label variable min95 "Lower 95% CI "
label variable max95 " Upper 95% CI"
twoway (scatter estimate parm, mcolor(black) msymbol(square) msize(small)) (rcap min95 max95 parm, lcolor(black)), xlabel(, valuelabels angle(0) ) yline(0) xtitle("") title("Total unemployment") saving("$figures/total_unemployment")


use "$logs/results_2", clear
replace parm = "2015" in 9
replace parm = "2016" in 10
replace parm = "2017" in 11
replace parm = "2019" in 13
replace parm = "2020" in 14
replace parm = "2021" in 15
keep in 9/15
drop in 4
list
encode parm, generate(parm2)
drop parm
rename parm2 parm
label variable estimate "Regression Coefficient"
label variable min95 "Lower 95% CI "
label variable max95 " Upper 95% CI"
twoway (scatter estimate parm, mcolor(black) msymbol(square) msize(small)) (rcap min95 max95 parm, lcolor(black)), xlabel(, valuelabels angle(0) ) yline(0) xtitle("") title("Unemployment among people with no degree") saving("$figures/unemployment_no_degree")


use "$logs/results_3", clear
replace parm = "2015" in 9
replace parm = "2016" in 10
replace parm = "2017" in 11
replace parm = "2019" in 13
replace parm = "2020" in 14
replace parm = "2021" in 15
keep in 9/15
drop in 4
encode parm, generate(parm2)
drop parm
rename parm2 parm
label variable estimate "Regression Coefficient"
label variable min95 "Lower 95% CI "
label variable max95 " Upper 95% CI"
twoway (scatter estimate parm, mcolor(black) msymbol(square) msize(small)) (rcap min95 max95 parm, lcolor(black)), xlabel(, valuelabels angle(0) ) yline(0) xtitle("") title("Unemployment among 25-34 years olds") saving("$figures/unemployment_25_34")


gr combine "$figures/total_unemployment.gph" "$figures/unemployment_no_degree.gph""$figures/unemployment_25_34.gph", col(1) ysize(9) xsize(5) saving("$figures/event_study_plot")

