***** Age Placebo Test *****
clear
use "D:\Desktop\MA Econ\Econ 562\Modernization\data\depcov_dataset_ready.dta", replace

local lowers  17 18 19 20 21 22 23
local uppers  23 24 25 26 27 28 29
local excludes 24 25 26 27 28 29 30  
local outcome anyhi emphi_dep indiv emphi govhi

matrix results = J(35, 4, .)  // 7*5 (7 age range group, 5 outcome variables)
local row = 1

foreach y in anyhi emphi_dep indiv emphi govhi {
	forvalues i = 1/7 {
		local lo : word `i' of `lowers'
		local hi : word `i' of `uppers'
		local ex : word `i' of `excludes'
		
		cap drop fedelig_tmp elig_oct10_tmp elig_mar10_tmp
		gen fedelig_tmp  = (age >= `lo' & age < `hi')
		gen elig_oct10_tmp = fedelig_tmp * after_oct10
		gen elig_mar10_tmp = fedelig_tmp * mar_sep10
		
		quietly reghdfe `y' elig_mar10_tmp elig_oct10_tmp ///
			mar_sep10 after_oct10 fedelig_tmp ///
			c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
			c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
			c.y2009 c.y2010 month2-month12 ///
			st_trend_1-st_trend_55 ///
			[pw=p_weight] if age != `ex', ///
			absorb(fipstate) vce(cluster fipstate)
		
		matrix results[`row', 1] = `lo'
		matrix results[`row', 2] = _b[elig_oct10_tmp]
		matrix results[`row', 3] = _se[elig_oct10_tmp]
		matrix results[`row', 4] = `i'
		
		local row = `row' + 1
		estimates store model_`y'_`i'
	}
}

svmat results, names(results)

matrix list results
matrix colnames results = lo b se outcome_id
matrix list results

clear
svmat results, names(col)
set obs 35
replace outcome_id = _n - 1

gen str12 outcome = ""
replace outcome = "anyhi" if outcome_id >=0 & outcome_id<=6
replace outcome = "emphi_dep" if outcome_id >=7 & outcome_id<=13
replace outcome = "indiv" if outcome_id >=14 & outcome_id<=20
replace outcome = "emphi" if outcome_id >=21 & outcome_id<=27
replace outcome = "govhi" if outcome_id >=28 & outcome_id<=34

gen lb = b - 1.96 * se
gen ub = b + 1.96 * se

gen age_label = ""
replace age_label = "17-23" if lo == 17
replace age_label = "18-24" if lo == 18
replace age_label = "19-25" if lo == 19
replace age_label = "20-26" if lo == 20
replace age_label = "21-27" if lo == 21
replace age_label = "22-28" if lo == 22
replace age_label = "23-29" if lo == 23
gen is_true = (lo == 19)

* Encode outcome
gen yid = .
replace yid = 1 if outcome == "anyhi"
replace yid = 2 if outcome == "emphi_dep"
replace yid = 3 if outcome == "indiv"
replace yid = 4 if outcome == "emphi"
replace yid = 5 if outcome == "govhi"

gen x = lo-16 // X-axis Location

foreach o in anyhi emphi_dep indiv emphi govhi {
    twoway ///
        (rcap lb ub x if outcome == "`o'" & is_true == 0, ///
            lcolor(navy) lwidth(medium)) ///
        (rcap lb ub x if outcome == "`o'" & is_true == 1, ///
            lcolor(red) lwidth(medium)) ///
        (scatter b x if outcome == "`o'" & is_true == 0,  ///
            msymbol(circle) mcolor(navy) msize(medium)) ///
        (scatter b x if outcome == "`o'" & is_true == 1, ///
            msymbol(circle) mcolor(red) msize(large)), ///
        yline(0, lcolor(gray) lpattern(dash)) ///
        xlabel(1 "17-23" 2 "18-24" 3 "19-25*" ///
               4 "20-26" 5 "21-27" 6 "22-28" 7 "23-29", angle(45)) ///
		ylabel(, angle(0)) ///
        xtitle("Treatment Group Age Window") ///
        ytitle("ATT Estimate (pp)") ///
        title("Age Placebo: `o'") ///
        legend(off) ///
        scheme(s2color) ///
        name(placebo_`o', replace)
    
    graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\age_placebo_`o'.png", replace
}

* Combine
graph combine placebo_anyhi placebo_emphi_dep placebo_indiv placebo_emphi placebo_govhi, ///
    cols(2) ///
    imargin(tiny) ///
    xsize(40) ysize(30) ///
    title("Age Placebo Test Across All Outcomes") ///
    scheme(s2color) 

graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\placebo_all.png", replace
