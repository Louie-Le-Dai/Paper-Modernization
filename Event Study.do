***** Event Study *****
clear
use "D:\Desktop\MA Econ\Econ 562\Modernization\data\depcov_dataset_ready.dta", replace

local outcomes anyhi emphi_dep indiv emphi govhi

eststo clear
foreach y in anyhi emphi_dep indiv emphi govhi {
    eststo: quietly reghdfe `y' ///
        elig_mar10 elig_oct10 ///
        mar_sep10 after_oct10 fedelig ///
        c.age17 c.age18 c.age20 c.age21 c.age22 c.age23 c.age24 c.age25 ///
        c.age27 c.age28 c.age29 c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
        c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
        c.y2009 c.y2010 ///
        month2-month12 st_trend_1-st_trend_55 [pw=p_weight], ///
        absorb(fipstate) ///
        vce(cluster fipstate)
}

esttab, ///
    keep(elig_mar10 elig_oct10) ///
    b(4) se(4) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of ACA on Coverage of Young Adults 19-25 Years") ///
    mtitles("Any source" "Emp dep (parents)" "Indiv purchased" "Emp own" "Gov provided") ///
    nocons
	
* Event Study
clear
use "D:\Desktop\MA Econ\Econ 562\Modernization\data\depcov_dataset_ready.dta", replace

gen qtr_rel = .

* Generate year-quarter id
gen yq = yq(year, quarter(dofm(ym(year, month))))
summ yq
tab year month if fedelig == 1, sum(anyhi)
levelsof yq, local(yqlist)
di "`yqlist'"

gen rel_q = yq - yq(2010, 1)
tab rel_q
replace rel_q = -5 if rel_q < -5

foreach q of local yqlist {
    gen inter_yq`q' = (yq == `q') * fedelig
}

drop inter_yq200

foreach Y in anyhi emphi_dep emphi indiv govhi {
	quietly reghdfe `Y' inter_yq* fedelig ///
		age17 age18 age20-age25 age27-age29 ///
		c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
		c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
		y2009 y2010 month2-month12 ///
		st_trend_1-st_trend_55 [pw=p_weight], absorb(fipstate) ///
		vce(cluster fipstate)

	coefplot, keep(inter_yq*) vertical ///
		yline(0, lcolor(gray) lpattern(dash)) ///
		xline(6 8, lcolor(red) lpattern(dash)) ///
		title("Event Study: `Y'") ///
		xtitle("Quarter") ///
		ytitle("Coefficient (pp)") ///
		xlabel(1 "2008Q3" 2 "2008Q4" 3 "2009Q1" 4 "2009Q2" ///
			   5 "2009Q3" 6 "2009Q4" 7 "2010Q2" 8 "2010Q3" ///
			   9 "2010Q4" 10 "2011Q1" 11 "2011Q2" 12 "2011Q3" ///
			   13 "2011Q4", angle(45)) ///
		scheme(s2color)
	
	graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\event_study_`Y'.png", as(png) name("Graph")
}
	
	
// Prepare for Honest DiD
* Longer Pre-period (pre1+post1)
reghdfe emphi_dep inter_yq* fedelig ///
		age17 age18 age20-age25 age27-age29 ///
		c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
		c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
		y2009 y2010 month2-month12 ///
		st_trend_1-st_trend_55 [pw=p_weight], ///
		absorb(fipstate) ///
		vce(cluster fipstate)

matrix list e(b)

* Obtain event study coefficient
matrix b_es = e(b)[1, 1..13]
matrix V_es = e(V)[1..13, 1..13]

* Save
preserve
clear
svmat b_es
export delimited using ///
    "D:\Desktop\MA Econ\Econ 562\Modernization\Results\eventstudy.csv", ///
    replace
restore

preserve
clear
svmat V_es
export delimited using ///
    "D:\Desktop\MA Econ\Econ 562\Modernization\Results\eventstudy_vcv.csv", ///
    replace
restore

* Longer Pre-period
reghdfe emphi_dep inter_yq197 inter_yq198 inter_yq199 inter_yq201 inter_yq202 inter_yq203 inter_yq204 inter_yq205 inter_yq206 inter_yq207  fedelig ///
		age17 age18 age20-age25 age27-age29 ///
		c.trend c.female c.ue c.hispanic c.white c.asian c.other ///
		c.student c.mar c.fpl_ratio c.fpl_ratio_2 c.ue_treat ///
		y2009 y2010 month2-month12 ///
		st_trend_1-st_trend_55 ///
		[pw=p_weight], ///
		absorb(fipstate) ///
		vce(cluster fipstate)
		
coefplot, keep(inter_yq197 inter_yq198 inter_yq199 inter_yq201 inter_yq202 inter_yq203 inter_yq204 inter_yq205 inter_yq206 inter_yq207) vertical ///
		yline(0, lcolor(gray) lpattern(dash)) ///
		xline(6 8, lcolor(red) lpattern(dash)) ///
		title("Event Study: emphi_dep (Shorter Pre-policy Periods)") ///
		xtitle("Quarter") ///
		ytitle("Coefficient (pp)") ///
		xlabel(1 "2009Q2" ///
			   2 "2009Q3" 3 "2009Q4" 4 "2010Q2" 5 "2010Q3" ///
			   6 "2010Q4" 7 "2011Q1" 8 "2011Q2" 9 "2011Q3" ///
			   10 "2011Q4", angle(45)) ///
		scheme(s2color)
graph export "D:\Desktop\MA Econ\Econ 562\Modernization\Results\event_study_emphi_dep-short.png", as(png)
		
		
matrix list e(b)

* Event study coefficient
matrix b_es = e(b)[1, 1..10]
matrix V_es = e(V)[1..10, 1..10]

* Save
preserve
clear
svmat b_es
export delimited using ///
    "D:\Desktop\MA Econ\Econ 562\Modernization\Results\eventstudy_short.csv", ///
    replace
restore

preserve
clear
svmat V_es
export delimited using ///
    "D:\Desktop\MA Econ\Econ 562\Modernization\Results\eventstudy_vcv_short.csv", ///
    replace
restore
