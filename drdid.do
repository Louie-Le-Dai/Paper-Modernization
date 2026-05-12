******* DRDID *******
clear all
use "D:\Desktop\MA Econ\Econ 562\Modernization\data\depcov_dataset.dta", clear

gen pre = (year < 2010) | (year == 2010 & month <= 2) // Pre-enactment
gen fedelig = (age >= 19 & age < 26) // Treatment
gen after_oct10 = ((year == 2010 & month >= 10) | year >= 2011) // Implementation Post
gen mar_sep10 = (year == 2010 & month >= 3 & month <= 9) // Enactment Post
gen ue_treat = ue * fedelig // UE Trend

* Enactment Effect
preserve
    keep if pre == 1|mar_sep10 == 1
    gen post_a = mar_sep10
	gen pre_trim = (year == 2009 & month >= 10) | (year == 2010 & month <= 2)
	keep if pre_trim == 1 |mar_sep10 == 1
	replace pre_trim= 0 if mar_sep10 == 1 
    collapse (mean) anyhi emphi_dep indiv emphi govhi  ///
                    female ue hispanic white black asian other ///
                    student mar fpl_ratio fpl_ratio_2 ue_treat  ///
             (first) fipstate fedelig age, by(groupid post_a)

    bys groupid: gen nobs = _N
    keep if nobs==2
    drop nobs

    xtset groupid post_a
    eststo clear
    local outcomes anyhi emphi_dep indiv emphi govhi
    local labels   "Any source" "Emp dep" "Indiv" "Emp own" "Gov"
    local i = 1
    foreach y of local outcomes {
        local lbl : word `i' of `labels'
        eststo enact_`y': drdid `y'  ///
            female ue hispanic white black asian other ///
            student mar fpl_ratio fpl_ratio_2 ue_treat ///
            , ivar(groupid) time(post_a) treatment(fedelig) ///
            dripw
    }
restore

esttab enact_anyhi enact_emphi_dep enact_indiv enact_emphi enact_govhi  ///
        , b(4) se(4) star(* 0.10 ** 0.05 *** 0.01)   ///
        title("Panel A: Enactment Effect (Mar-Sep 2010)")  ///
        mtitles("Any source" "Emp dep" "Indiv" "Emp own" "Gov") ///
        nocons
	
esttab using "D:\Desktop\MA Econ\Econ 562\Modernization\Results\DRDID_enactment_effect.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("DRDID Regression Results (Enactment Effect)") ///
    label stats(N r2, fmt(0 4) labels("N" "R2"))	

	
	
** Implementation Effect
preserve
    keep if pre == 1 | after_oct10 == 1
    gen post_b = after_oct10

    collapse (mean) anyhi emphi_dep indiv emphi govhi    ///
                    female ue hispanic white black asian other ///
                    student mar fpl_ratio fpl_ratio_2 ue_treat  ///
             (first) fipstate fedelig age, by(groupid post_b)

    bys groupid: gen nobs = _N
    keep if nobs == 2
    drop nobs

    xtset groupid post_b
    eststo clear
    local outcomes anyhi emphi_dep indiv emphi govhi
    local labels   "Any source" "Emp dep" "Indiv" "Emp own" "Gov"
    local i = 1
    foreach y of local outcomes {
        local lbl : word `i' of `labels'
        eststo impl_`y': drdid `y' ///
            female ue hispanic white black asian other  ///
            student mar fpl_ratio fpl_ratio_2 ue_treat  ///
            , ivar(groupid) time(post_b) treatment(fedelig)  ///
            dripw wboot reps(999)
        local ++i
    }
restore

esttab impl_anyhi impl_emphi_dep impl_indiv impl_emphi impl_govhi,  ///
		b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
        title("Panel A: Implementation Effect (Mar-Sep 2010)")   ///
        mtitles("Any source" "Emp dep" "Indiv" "Emp own" "Gov")  ///
        nocons

esttab using "D:\Desktop\MA Econ\Econ 562\Modernization\Results\DRDID_implemetation_effect.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("DRDID Regression Results (Implementation Effect)") ///
    label stats(N r2, fmt(0 4) labels("N" "R2"))	
