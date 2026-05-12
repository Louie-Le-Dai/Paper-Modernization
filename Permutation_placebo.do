* Permutation-based Placebo Test
clear all
use "D:\Desktop\MA Econ\Econ 562\Modernization\data\depcov_dataset_ready.dta", replace
keep if mar_sep10 == 0

* Replicate Original Paper
reghdfe emphi_dep ///
    elig_mar10 elig_oct10 ///
    mar_sep10 after_oct10 fedelig ///
    c.age17 c.age18 c.age20 c.age21 c.age22 c.age23 c.age24 c.age25 ///
    c.age27 c.age28 c.age29 ///
    c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
    c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
    c.y2009 c.y2010 month2-month12 ///
    st_trend_1-st_trend_55 [pw=p_weight], ///
    absorb(fipstate) vce(cluster fipstate)
scalar true_emphi_dep = _b[elig_oct10]

reghdfe anyhi ///
    elig_mar10 elig_oct10 ///
    mar_sep10 after_oct10 fedelig ///
    c.age17 c.age18 c.age20 c.age21 c.age22 c.age23 c.age24 c.age25 ///
    c.age27 c.age28 c.age29 ///
    c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
    c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
    c.y2009 c.y2010 month2-month12 ///
    st_trend_1-st_trend_55 [pw=p_weight], ///
    absorb(fipstate) vce(cluster fipstate)
scalar true_anyhi = _b[elig_oct10]

reghdfe emphi ///
    elig_mar10 elig_oct10 ///
    mar_sep10 after_oct10 fedelig ///
    c.age17 c.age18 c.age20 c.age21 c.age22 c.age23 c.age24 c.age25 ///
    c.age27 c.age28 c.age29 ///
    c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
    c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
    c.y2009 c.y2010 month2-month12 ///
    st_trend_1-st_trend_55 [pw=p_weight], ///
    absorb(fipstate) vce(cluster fipstate)
scalar true_emphi = _b[elig_oct10]

reghdfe indiv ///
    elig_mar10 elig_oct10 ///
    mar_sep10 after_oct10 fedelig ///
    c.age17 c.age18 c.age20 c.age21 c.age22 c.age23 c.age24 c.age25 ///
    c.age27 c.age28 c.age29 ///
    c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
    c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
    c.y2009 c.y2010 month2-month12 ///
    st_trend_1-st_trend_55 [pw=p_weight], ///
    absorb(fipstate) vce(cluster fipstate)

scalar true_indiv = _b[elig_oct10]

reghdfe govhi ///
    elig_mar10 elig_oct10 ///
    mar_sep10 after_oct10 fedelig ///
    c.age17 c.age18 c.age20 c.age21 c.age22 c.age23 c.age24 c.age25 ///
    c.age27 c.age28 c.age29 ///
    c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
    c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
    c.y2009 c.y2010 month2-month12 ///
    st_trend_1-st_trend_55 [pw=p_weight], ///
    absorb(fipstate) vce(cluster fipstate)

scalar true_govhi = _b[elig_oct10]

* Placebo Iteration：Rotation Cutoff
* Real Window: 19-25 (lb:19, ub25)
* Placebo Window：lb: 13~29 (Except for Real Window)
tempfile results_emphi results_anyhi

local n_placebo = 0
foreach lb of numlist 13/29 {
    if `lb'!=19 local n_placebo = `n_placebo' + 1
}

matrix placebo_emphi_dep = J(16, 2, .)
matrix placebo_anyhi = J(16, 2, .)
matrix placebo_emphi = J(16, 2, .)
matrix placebo_indiv = J(16, 2, .)
matrix placebo_govhi = J(16, 2, .)

local row = 0
foreach lb of numlist 13/29 {

    * Skip the real window
    if `lb' == 19 continue
    local ub = `lb' + 6
    local row = `row' + 1
    
    di "Running placebo: age [`lb', `ub']"
    
    * placebo treatment
    cap drop fedelig_p elig_mar10_p elig_oct10_p
    gen fedelig_p=(age >= `lb' & age <= `ub')
    gen elig_mar10_p= fedelig_p * mar_sep10
    gen elig_oct10_p = fedelig_p * after_oct10

    cap drop age_ctrl_*
    foreach a of numlist 16/30 {
        if `a' < `lb' | `a' > `ub' {
            cap gen age_ctrl_`a' = (age == `a')
        }
    }
    
    * emphi_dep
    cap reghdfe emphi_dep ///
        elig_mar10_p elig_oct10_p ///
        mar_sep10 after_oct10 fedelig_p ///
        age_ctrl_* ///
        c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
        c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
        c.y2009 c.y2010 month2-month12 ///
        st_trend_1-st_trend_55 [pw=p_weight], ///
        absorb(fipstate) vce(cluster fipstate)
    
    if _rc == 0 {
        matrix placebo_emphi_dep[`row', 1] = `lb'
        matrix placebo_emphi_dep[`row', 2] = _b[elig_oct10_p]
    }
    
    * anyhi
    cap reghdfe anyhi ///
        elig_mar10_p elig_oct10_p ///
        mar_sep10 after_oct10 fedelig_p ///
        age_ctrl_* ///
        c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
        c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
        c.y2009 c.y2010 month2-month12 ///
        st_trend_1-st_trend_55 [pw=p_weight], ///
        absorb(fipstate) vce(cluster fipstate)
    
    if _rc == 0 {
        matrix placebo_anyhi[`row', 1] = `lb'
        matrix placebo_anyhi[`row', 2] = _b[elig_oct10_p]
    }
    
	* indiv
    cap reghdfe indiv ///
        elig_mar10_p elig_oct10_p ///
        mar_sep10 after_oct10 fedelig_p ///
        age_ctrl_* ///
        c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
        c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
        c.y2009 c.y2010 month2-month12 ///
        st_trend_1-st_trend_55 [pw=p_weight], ///
        absorb(fipstate) vce(cluster fipstate)
    
    if _rc == 0 {
        matrix placebo_indiv[`row', 1] = `lb'
        matrix placebo_indiv[`row', 2] = _b[elig_oct10_p]
    }
	
	* emphi
    cap reghdfe emphi ///
        elig_mar10_p elig_oct10_p ///
        mar_sep10 after_oct10 fedelig_p ///
        age_ctrl_* ///
        c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
        c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
        c.y2009 c.y2010 month2-month12 ///
        st_trend_1-st_trend_55 [pw=p_weight], ///
        absorb(fipstate) vce(cluster fipstate)
    
    if _rc == 0 {
        matrix placebo_emphi[`row', 1] = `lb'
        matrix placebo_emphi[`row', 2] = _b[elig_oct10_p]
    }
	
	
	* govhi
    cap reghdfe govhi ///
        elig_mar10_p elig_oct10_p ///
        mar_sep10 after_oct10 fedelig_p ///
        age_ctrl_* ///
        c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
        c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
        c.y2009 c.y2010 month2-month12 ///
        st_trend_1-st_trend_55 [pw=p_weight], ///
        absorb(fipstate) vce(cluster fipstate)
    
    if _rc == 0 {
        matrix placebo_govhi[`row', 1] = `lb'
        matrix placebo_govhi[`row', 2] = _b[elig_oct10_p]
    }
	
    cap drop fedelig_p elig_mar10_p elig_oct10_p age_ctrl_*
}

* Draw anyhi emphi_dep emphi indiv govhi
preserve
clear
svmat placebo_emphi_dep, names(col)
rename (c1 c2) (cutoff coef_emphi_dep)

twoway ///
    (bar coef_emphi_dep cutoff, ///
        color(navy%50) lcolor(navy) lwidth(thin) barwidth(0.6)) ///
    (scatteri `=scalar(true_emphi_dep)' 19 ///
        (12) "True effect (19-25)", ///
        msymbol(D) mcolor(maroon) msize(large)), ///
    yline(0, lcolor(black) lwidth(thin)) ///
    xline(19, lcolor(maroon) lpattern(dash)) ///
    xlabel(13(1)29, angle(45) labsize(small)) ///
    xtitle("Lower bound of placebo age window [lb, lb+6]") ///
    ytitle("Coefficient on elig_oct10") ///
    title("Permutation Placebo Test: Employer Dependent Coverage") ///
    subtitle("True window = [19, 25]; all other 6-year windows shown as placebo") ///
    legend(off) scheme(s2color)

graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\permu_placebo_emphi_dep.png", replace width(1200)
restore


preserve
clear
svmat placebo_anyhi, names(col)
rename (c1 c2) (cutoff coef_anyhi)

twoway ///
    (bar coef_anyhi cutoff, ///
        color(teal%50) lcolor(teal) lwidth(thin) barwidth(0.6)) ///
    (scatteri `=scalar(true_anyhi)' 19 ///
        (12) "True effect (19-25)", ///
        msymbol(D) mcolor(maroon) msize(large)), ///
    yline(0, lcolor(black) lwidth(thin)) ///
    xline(19, lcolor(maroon) lpattern(dash)) ///
    xlabel(13(1)29, angle(45) labsize(small)) ///
    xtitle("Lower bound of placebo age window [lb, lb+6]") ///
    ytitle("Coefficient on elig_oct10") ///
    title("Permutation Placebo Test: Any Source") ///
    subtitle("True window = [19, 25]; all other 6-year windows shown as placebo") ///
    legend(off) scheme(s2color)

graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\permu_placebo_anyhi.png", replace width(1200)
restore


preserve
clear
svmat placebo_emphi, names(col)
rename (c1 c2) (cutoff coef_emphi)

twoway ///
    (bar coef_emphi cutoff, ///
        color(teal%50) lcolor(teal) lwidth(thin) barwidth(0.6)) ///
    (scatteri `=scalar(true_emphi)' 19 ///
        (12) "True effect (19-25)", ///
        msymbol(D) mcolor(maroon) msize(large)), ///
    yline(0, lcolor(black) lwidth(thin)) ///
    xline(19, lcolor(maroon) lpattern(dash)) ///
    xlabel(13(1)29, angle(45) labsize(small)) ///
    xtitle("Lower bound of placebo age window [lb, lb+6]") ///
    ytitle("Coefficient on elig_oct10") ///
    title("Permutation Placebo Test: Employer Own Coverage") ///
    subtitle("True window = [19, 25]; all other 6-year windows shown as placebo") ///
    legend(off) scheme(s2color)

graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\permu_placebo_emphi.png", replace width(1200)
restore

preserve
clear
svmat placebo_indiv, names(col)
rename (c1 c2) (cutoff coef_indiv)

twoway ///
    (bar coef_indiv cutoff, ///
        color(teal%50) lcolor(teal) lwidth(thin) barwidth(0.6)) ///
    (scatteri `=scalar(true_indiv)' 19 ///
        (12) "True effect (19-25)", ///
        msymbol(D) mcolor(maroon) msize(large)), ///
    yline(0, lcolor(black) lwidth(thin)) ///
    xline(19, lcolor(maroon) lpattern(dash)) ///
    xlabel(13(1)29, angle(45) labsize(small)) ///
    xtitle("Lower bound of placebo age window [lb, lb+6]") ///
    ytitle("Coefficient on elig_oct10") ///
    title("Permutation Placebo Test: Individually Purchase") ///
    subtitle("True window = [19, 25]; all other 6-year windows shown as placebo") ///
    legend(off) scheme(s2color)

graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\permu_placebo_indiv.png", replace width(1200)
restore

preserve
clear
svmat placebo_govhi, names(col)
rename (c1 c2) (cutoff coef_govhi)

twoway ///
    (bar coef_govhi cutoff, ///
        color(teal%50) lcolor(teal) lwidth(thin) barwidth(0.6)) ///
    (scatteri `=scalar(true_govhi)' 19 ///
        (12) "True effect (19-25)", ///
        msymbol(D) mcolor(maroon) msize(large)), ///
    yline(0, lcolor(black) lwidth(thin)) ///
    xline(19, lcolor(maroon) lpattern(dash)) ///
    xlabel(13(1)29, angle(45) labsize(small)) ///
    xtitle("Lower bound of placebo age window [lb, lb+6]") ///
    ytitle("Coefficient on elig_oct10") ///
    title("Permutation Placebo Test: Government Provided") ///
    subtitle("True window = [19, 25]; all other 6-year windows shown as placebo") ///
    legend(off) scheme(s2color)

graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\permu_placebo_govhi.png", replace width(1200)
restore

* Randomization p-value
preserve
clear
svmat placebo_emphi, names(col)
rename (c1 c2) (cutoff coef_emphi)
count if coef_emphi >= scalar(true_emphi)
di "Randomization p-value (emphi_dep): " r(N)/_N

svmat placebo_anyhi, names(col)
rename (c1 c2) (cutoff2 coef_anyhi)
count if coef_anyhi >= scalar(true_anyhi)
di "Randomization p-value (anyhi): " r(N)/_N
restore