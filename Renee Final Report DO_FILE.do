*********************************************************************
* Author: Renee Li                                                  *
* Date Created: 22 Januardy 2020                                    *
* Date Edited: 22 January 2020   				    *
* Purpose: ECON – UH – 1410J - PSET 3 ANALYSIS   		    * 
* (0) Do File Set Up, Importing the initial dataset, Save it as .dta*
* (1) Preliminary Data Cleaning                                     *
* (2) Attrition Table And Basic Data Exploring for Context          *
* (3) Merging baseline data with the endline data                   *
* (4) Balance Table: Treatment & Baseline Characteristics           *
* (5) Main Effects Student Presence, Primary Outcomes               *
* (6) Heterogeneity Analysis                                        *   				
* Version: Stata 15                                                 *
* Data: simulateddata.dta                                           *
*********************************************************************

* (0) *************Setup***************
***************************************

*** Clear memory
	clear
	clear matrix
	
*** Here you are telling stata that it should execute all code in the do-file 
*** without asking you to continue at certain stopping points:
	set more off

*** Close any open log and start a new log:
	capture log close
	log using STATA_FINAL_REPORT_RENEE.log, replace
	
*** Move to the folder in which I'll be working:
	cd "/Users/renee.li/Desktop/RENEE_FINAL_REPORT_ANALYSIS"

****************************************************
* (1) Clean Baseline Data***************************
****************************************************
* Import excel data
	import excel "RAW_DATA/jterm_2020_baseline.xls", sheet("Sheet1") firstrow
	
* Destring gender and languages into numerical binary dummy variables
	gen BL_male=0 if BL_gender!=""
	replace BL_male=1 if BL_gender=="Male"
	gen BL_english=0 if BL_language!=""
	replace BL_english=1 if BL_language=="English"
	
*Label variables and values to maker it more reader friendly
	label var firm_id "Unique firm ID"
	label var SAMPLE "Indicator for being surveyed in January"
	label var BL_gender "Gender of business owner"
	label var BL_male "Business owner is male"
	label var BL_age "Age of business owner"
	label var BL_years_of_schooling "Years of schooling completed"
	label var BL_ravens_score "IQ score on Ravens Test (out of 12)"
	label var BL_number_adults "# adults in household at baseline"
	label var BL_children_number "# children in household at baseline"
	label var BL_income_per_capita "Household income per member at baseline, GHC"
	label var BL_liquidity_per_capita "Household liquidity per member at baseline, GHC"
	label var BL_business_age "Age of business"
	label var BL_number_workers "# Workers in business at baseline"
	label var BL_total_asset "Total value of business assetts at baseline, GHC"
	label var BL_sales "Sales last month at baseline, GHC"
	label var BL_profits "Profits last month at baseline, GHC"
	label var BL_default_orders_amount  "Defaulted garment value last month at baseline, GHC"
	label var BL_pending_payment_amount  "Pending garment value last month at baseline, GHC"
	label var BL_nonbespoke_garment_amount "Non-bespoke garment value last month at baseline, GHC"
	label var BL_willing_to_hire "Willing to hire others at baseline"
	label var BL_willing_to_be_hired "Willing to work for others at baseline"
	label var BL_language "Language of baseline survey"
	label var BL_english "Baseline survey conducted in English"

**** Save data as cleaned data
	save "CLEANED_DATA/simulateddata_cleaned.dta", replace
	
**********************************************************
*（2）Attrition Table And Basic Data exploring for context*
**********************************************************

	
******************* Exploring data for the context in Data*********************
*2-1:(Any Exploration on the Data other than Main Analysis are displayed in this seciotion)															  

	count
	count if BL_number_workers == 0
	count if BL_number_workers == 0 & BL_willing_to_hire == 1
	*context generated:while almost half of the surveyed garment makers (262) 
	///in Hohoe work on their own without hiring other workers, over 91% of these ///
	///262 independent owner-workers actually have the willingness to hire. 
	
*2-2: ttests for the sample selection table (mean, diff, p-value) 
	
	foreach var in BL_male BL_age BL_years_of_schooling ///
	BL_ravens_score BL_number_adults BL_children_number BL_income_per_capita ///
	BL_liquidity_per_capita BL_business_age BL_number_workers BL_total_asset ///
	BL_sales BL_profits BL_default_orders_amount BL_pending_payment_amount ///
	BL_nonbespoke_garment_amount BL_willing_to_hire BL_willing_to_be_hired ///
	BL_english {
	
	display "*"
	display "*"
	display "*********************************************************************"
	display "*** `var'"
	display "*********************************************************************"

	ttest `var', by(SAMPLE)
	
	}
**** reggression between sampling and all other baseline variables
	reg SAMPLE BL_male BL_age BL_years_of_schooling BL_ravens_score BL_number_adults BL_children_number BL_income_per_capita ///
	BL_liquidity_per_capita BL_business_age BL_number_workers BL_total_asset BL_sales BL_profits BL_default_orders_amount BL_pending_payment_amount ///
	BL_nonbespoke_garment_amount BL_willing_to_hire BL_willing_to_be_hired BL_english
	
	*******************************************************************
	*******************************************************************
	****************Day 1 work ends, Day 2 work starts ****************
	*******************************************************************
	*******************************************************************
	
********************************************************
** (3)Merge Jan. endline Dataset with Baseline dataset**
** Generate new variable, then new Cleaned Dataset    **
********************************************************

*** Sorted by the variable Firm ID on which you are merging
	sort firm_id	
	merge 1:1 firm_id using "RAW_DATA/jterm_2020.dta"
*** Tabulate the _merge variable to see how your merge went:
	tab _merge
*** generate new data on final total bids on all information lists
	gen total_abcd = beans_a + beans_b + beans_c + beans_d
*** generate new data on final total bids on all hiring information lists (A and B)
	gen total_ab = beans_a + beans_b
*** generate average worker payments level 
	replace piece_rate_pay = 0 if piece_rate_pay == .
	replace fixed_wage_pay = 0 if fixed_wage_pay == .
    gen average_worker_pay = ((piece_rate_pay + fixed_wage_pay) / (unpaid + piece_rate + fixed_wage))
*** Save your merged and organized data
	save "CLEANED_DATA/simulateddata_cleaned.dta", replace

*****************************************************************************************
** (4)Making Balance Tables (Treatment:Studnent Presence balanced by Baseline variables**
** Mulitples ttests, reg treatment with respect to other  baseline variables           **
*****************************************************************************************

*** Filling in the Balance Table through a loop:
	
	foreach element in  BL_male BL_age BL_years_of_schooling BL_ravens_score BL_number_adults ///
	BL_children_number BL_income_per_capita BL_liquidity_per_capita BL_business_age ///
	BL_number_workers BL_total_asset BL_sales BL_profits BL_default_orders_amount ///
	BL_pending_payment_amount BL_nonbespoke_garment_amount BL_willing_to_hire ///
	BL_willing_to_be_hired BL_english {

		display "******************** Treatment Variable Balance Test for `element' *********************"

		ttest `element', by(student_pres)
	}
	
*** Reg treatment with respect to all the baseline variables to get the F statistic
 
	reg student_pres BL_male BL_age BL_years_of_schooling BL_ravens_score BL_number_adults ///
	BL_children_number BL_income_per_capita BL_liquidity_per_capita BL_business_age ///
	BL_number_workers BL_total_asset BL_sales BL_profits BL_default_orders_amount ///
	BL_pending_payment_amount BL_nonbespoke_garment_amount BL_willing_to_hire ///
	BL_willing_to_be_hired BL_english

*** Fill in the Balance Table 2 with numbers generated from t-test and regression above***

********************************************************************************************************
** (5)Main Effects section: with loop, run reg (primary outcome variables of interest) (student presence)**
********************************************************************************************************
	ssc install outreg2
	
*** 1. We first run regression on the 4 primary outcomes with effects
	***Business liquidity***
	reg business_liquidity student_pres
	outreg2 using OUTPUT/main_effects.xls, replace
	
	***Total beans in final round***
	reg total_abcd student_pres
	outreg2 using OUTPUT/main_effects.xls, append
					
   /* We might want to check this regression in the future, if it only influences the bids on hiring information
	reg total_ab student_pres
	outreg2 using OUTPUT/main_effects.xls, append
   */
    ***Note:We checked on this total beans invested in information list about 
	***people willing to work for you, and the significance of effect of students/
	***presence on bids is even weaker than that of total beans in abcd
	reg total_ab student_pres
	
	***Average worker payment***
	reg average_worker_pay student_pres
	outreg2 using OUTPUT/main_effects.xls, append
	
	***Expected sales***
	reg feb_expected_sales student_pres
	outreg2 using OUTPUT/main_effects.xls, append
	
	******************************************************************************************
	*Get distribution and regression graphs for these primary outcome variables and treatment*
	*Try to find some interesting patterns here												 *
	******************************************************************************************
	
	***Business liquidity***
	twoway (hist business_liquidity if student_pres ==0 , frac lcolor(gs12) fcolor(gs12))  ///
	(hist business_liquidity if student_pres ==1, frac fcolor(none) lcolor(red)),        ///
	legend(label ( 1 "Control") label (2 "Treatment")) title("Business Liquidity Distribution")
	graph export OUTPUT/Business_Liquidity_by_Treatment.pdf, replace
	
	twoway (scatter business_liquidity student_pres) (lfit business_liquidity student_pres), ///
	title("Business Liquidity Scatter")
	graph export OUTPUT/Business_Liquidity_by_Treatment_Scatter.pdf, replace
	
	****************************************************************************************************************
	********Total beans in final round (This is the one that we find interesting pattern of hidden heterogeniety)***
	****************************************************************************************************************
	
	twoway (hist total_abcd if student_pres ==0 , frac lcolor(gs12) fcolor(gs12))  ///
	(hist total_abcd if student_pres ==1, frac fcolor(none) lcolor(red)),        ///
	legend(label ( 1 "Control") label (2 "Treatment")) title("Total Bids in Final Round Distribution")
	graph export OUTPUT/Total_Bids_by_Treatment.pdf, replace
	
	twoway (scatter total_abcd student_pres) (lfit total_abcd student_pres), ///
	title("Total Bids in Final Round Scatter")
	graph export OUTPUT/Total_Bids_by_Treatment_Scatter.pdf, replace
	
	***Average worker payment***
	twoway (hist average_worker_pay if student_pres ==0 , frac lcolor(gs12) fcolor(gs12))  ///
	(hist average_worker_pay if student_pres ==1, frac fcolor(none) lcolor(red)),        ///
	legend(label ( 1 "Control") label (2 "Treatment")) title("Average Worker Payment Distribution")
	graph export OUTPUT/Average_Worker_Pay_by_Treatment.pdf, replace
	
	twoway (scatter average_worker_pay student_pres) (lfit average_worker_pay student_pres), ///
	title("Average Worker Payment Scatter")
	graph export OUTPUT/Average_Worker_Pay_by_Treatment_Scatter.pdf, replace
	
	***Expected sales***
	twoway (hist feb_expected_sales if student_pres ==0 , frac lcolor(gs12) fcolor(gs12))  ///
	(hist feb_expected_sales if student_pres ==1, frac fcolor(none) lcolor(red)),        ///
	legend(label ( 1 "Control") label (2 "Treatment")) title("Expected Sales of Feb Distribution")
	graph export OUTPUT/Expected_Sales_by_Treatment.pdf, replace
	
	twoway (scatter feb_expected_sales student_pres) (lfit feb_expected_sales student_pres), ///
	title("Expected Sales of Feb Scatter")
	graph export OUTPUT/Expected_Sales_by_Treatment_Scatter.pdf, replace
	
*** 2. We then run regression on the 4 primary outcomes without detectable effects
	
	reg children student_pres
	outreg2 using OUTPUT/main_effects.xls, append
	
	reg liquidity_household student_pres
	outreg2 using OUTPUT/main_effects.xls, append
	
	reg default_amount student_pres
	outreg2 using OUTPUT/main_effects.xls, append
	
	reg pending_amount student_pres
	outreg2 using OUTPUT/main_effects.xls, append
	
*Note：We find that there is a significant negative impacts of students presence on
* defaulted payment, now lets make the graphs on this to see the distribution and regression model.
	
	***Defaulted Payment***
	
	twoway (hist default_amount if student_pres ==0 , frac lcolor(gs12) fcolor(gs12))  ///
	(hist default_amount if student_pres ==1, frac fcolor(none) lcolor(red)),        ///
	legend(label ( 1 "Control") label (2 "Treatment")) title("Defaulted Order Report Distribution")
	graph export OUTPUT/Default_Amount_by_Treatment.pdf, replace
	
	twoway (scatter default_amount student_pres) (lfit default_amount student_pres), ///
	title("Defaulted Order Report Scatter")
	graph export OUTPUT/Default_Amount_by_Treatment_Scatter.pdf, replace
*** To be continued with Heterogeniety*** 
 
	*******************************************************************
	*******************************************************************
	****************Day 2 work ends，Day 3 work starts ****************
	*******************************************************************
	*******************************************************************
	
*********************************	
****(6)Heterogeneous Analysis****
*********************************

*0.Change our baseline variables of interest into binary ones
*0-1.Business Age Cut-off
     *we decide our cut-off on business age by looking at the distribution of business age first
	 tab BL_business_age 
	 *The program started from 2014 (6 yrs).Let's try cut-off of 5 years, according to the tab outcome, cut-off at 6 yrs will leave us 
	 gen BusinessAge = 0
	 replace BusinessAge = 1 if BL_business_age >= 6 | BL_business_age == 6	
*Do it in reverse direction to see the p value and confidence interval of the effects on older business 	
	
*0-2. BL_years_of_schooling Cut-off
	 tab BL_years_of_schooling
	 /*observe the data cumulative levels to decide the cut-off*/
	 gen schooling = 0
	 replace schooling = 1 if BL_years_of_schooling >= 10 | BL_years_of_schooling == 10

*0-3.generate both dummy varibles by Treatment and BLCs

*** Generate dummy variables: multiply TREATMENT times BINARY BASELINE CHARACTERISTIC, repeat 
	gen both = student_pres*BusinessAge
	gen bothS = student_pres*schooling
	save "CLEANED_DATA/simulateddata_cleaned.dta", replace
	
*1-1. Run regreesion by treatment and BLC1: Business Age	 
*** Regress
	reg business_liquidity student_pres BusinessAge both
	outreg2 using "OUTPUT/FINAL.xls", replace
	
	reg total_abcd student_pres BusinessAge both
	outreg2 using "OUTPUT/FINAL.xls", append
	
	reg feb_expected_sales student_pres BusinessAge both
	outreg2 using "OUTPUT/FINAL.xls", append
	
	reg average_worker_pay student_pres BusinessAge both
	outreg2 using "OUTPUT/FINAL.xls", append
	
/*  Of interest since we find this significant main effect in the above section: 
	reg default_amount student_pres BusinessAge both
	outreg2 using "OUTPUT/FINAL.xls", append*/
	
	
*1-2. Run regression by treatment and BLC2: Schooling
*** Regress
	reg business_liquidity student_pres schooling bothS
	outreg2 using "OUTPUT/FINAL.xls", append
	
	reg total_abcd student_pres schooling bothS
	outreg2 using "OUTPUT/FINAL.xls", append
	
	reg feb_expected_sales student_pres schooling bothS
	outreg2 using "OUTPUT/FINAL.xls", append
	
	reg average_worker_pay student_pres schooling bothS
	outreg2 using "OUTPUT/FINAL.xls", append
	
	
*1-3. To get more detailed on the p-value and confidence interval of old business, reverse the definition from "old" to "young".
	  *Note: This column is not included in our final heterogenous effects table in the paper. We run it just to generate more analytical data.
	gen BusinessYoung = 0
	replace BusinessYoung = 1 if BL_business_age < 6
	gen bothY = student_pres*BusinessYoung
	reg total_abcd student_pres BusinessYoung bothY
	outreg2 using "OUTPUT/FINAL.xls", append
	
	log close	
