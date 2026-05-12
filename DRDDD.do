***** DRDDD *****
clear all
use "D:\Desktop\MA Econ\Econ 562\Modernization\data\depcov_dataset_ready.dta", replace

keep if age != 26
keep if mar_sep10 == 0

* keep sample with information in emphi_parent (Following Table 5)
keep if emphi_parent != .

* Construct treatment：fedelig * emphi_parent
gen treat_ddd = fedelig * emphi_parent

local covs female hispanic white mar fpl_ratio ///
           bad_hlth ft_student hsdo hsg somcol colgrd ///
           live_wparent ue emphi_parent

* pre: mean
preserve
keep if after_oct10 == 0 & mar_sep10 == 0
collapse (mean) anyhi emphi_dep indiv emphi govhi `covs' ///
         (first) fedelig fipstate p_weight, ///
         by(groupid)
gen after_oct10 = 0
tempfile pre_data
save `pre_data', replace
restore

* post: last observation
preserve
keep if after_oct10 == 1
bysort groupid (year month): keep if _n == _N
keep groupid anyhi emphi_dep indiv emphi govhi after_oct10 fedelig fipstate p_weight `covs'
tempfile post_data
save `post_data', replace
restore

* merge to panel
use `pre_data', clear
append using `post_data'
sort groupid after_oct10

* Keep observation with both pre and post 
bysort groupid: keep if _N == 2


* drdid and save
drdid emphi_dep female hispanic white mar fpl_ratio ///
    bad_hlth ft_student hsdo hsg somcol colgrd ///
    live_wparent ue ///
    if emphi_parent == 1, time(after_oct10) tr(fedelig) ///
    drimp
eststo ddd_parent1

drdid emphi_dep female hispanic white mar fpl_ratio ///
    bad_hlth ft_student hsdo hsg somcol colgrd ///
    live_wparent ue ///
    if emphi_parent == 0, time(after_oct10) tr(fedelig) ///
    drimp
eststo ddd_parent0

esttab ddd_parent1 ddd_parent0, ///
    b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    mtitles("emphi_parent=1" "emphi_parent=0") ///
    title("DR-DDD: emphi_dep") ///
    note("DRDID estimates. drimp estimator. Difference = DDD effect.")
	
foreach y in anyhi emphi_dep indiv emphi govhi {
    drdid `y' female hispanic white mar fpl_ratio ///
		bad_hlth ft_student hsdo hsg somcol colgrd ///
		live_wparent ue ///
		if emphi_parent == 1, time(after_oct10) tr(fedelig) ///
		drimp
    eststo ddd1_`y'
    
    drdid `y' female hispanic white mar fpl_ratio ///
		bad_hlth ft_student hsdo hsg somcol colgrd ///
		live_wparent ue ///
		if emphi_parent == 0, time(after_oct10) tr(fedelig) ///
		drimp
    eststo ddd0_`y'
}

esttab ddd1_anyhi ddd1_emphi_dep ddd1_indiv ddd1_emphi ddd1_govhi, ///
    b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    title("DR-DDD: emphi_parent=1") ///
    mtitles("Any HI" "Dep Coverage" "Indiv" "Own ESI" "Gov HI")	
	
esttab using "D:\Desktop\MA Econ\Econ 562\Modernization\Results\DRDDD.csv", ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    replace

	
	
	