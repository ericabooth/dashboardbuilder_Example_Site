*! build_site.do — regenerate the dashboardbuilder demo dashboards for the
*! GitHub Pages site: https://ericabooth.github.io/dashboardbuilder_Example_Site/
*! Run from the site folder:  do build_site.do   (writes *.html next to index.html)
*! Requires dashboardbuilder (+ a Python 3 visible to Stata). The county map
*! example additionally needs sparkta2.
version 16
clear all
set more off

* ── 1. Minimal (auto) ───────────────────────────────────────────────────────
sysuse auto, clear
collapse (mean) price mpg weight, by(foreign)
dashboardbuilder init , title("Auto quick look") ///
    subtitle("mean price, mileage, and weight by origin (1978 autos)")
dashboardbuilder panel bar , x(foreign) y(price) ///
    title("Domestic cars cost less on average") ytitle("mean price (USD)")
dashboardbuilder panel table , title("The numbers behind the chart")
dashboardbuilder build using "auto_quick.html", replace noopen

* ── 2. Selector + reference unit (state explorer) ───────────────────────────
sysuse census, clear
gen double death_rt = 1000 * death    / pop
gen double marr_rt  = 1000 * marriage / pop
gen double div_rt   = 1000 * divorce  / pop
label var pop      "Population"
label var medage   "Median age (years)"
label var death_rt "Deaths per 1,000"
label var marr_rt  "Marriages per 1,000"
label var div_rt   "Divorces per 1,000"
preserve
    * no [aw=pop] here: it would weight the (sum) totals and ~2x the US population
    collapse (sum) pop death marriage divorce (mean) medage
    gen double death_rt = 1000 * death / pop
    gen double marr_rt  = 1000 * marriage / pop
    gen double div_rt   = 1000 * divorce / pop
    gen str28 state = "United States"
    tempfile us
    save `us'
restore
append using `us'
tempfile censusplus
save `censusplus'

dashboardbuilder init , title("State explorer") ///
    subtitle("every state against the national picture (1980 census)") ///
    tx2036 selector(state) sellabel("Choose a state") refvalue("United States")
dashboardbuilder tab , name(today) label("Where states stand")
dashboardbuilder tab , name(rank)  label("Rankings")
use `censusplus', clear
keep state pop medage death_rt
dashboardbuilder panel kpi , tab(today) values(pop medage death_rt) ///
    title("Headline numbers") ///
    interp("Pick a state above; tiles and bars update. 'United States' is the reference.")
use `censusplus', clear
keep state death_rt marr_rt div_rt
rename (death_rt marr_rt div_rt) (v1 v2 v3)
reshape long v, i(state) j(metric)
label define metric 1 "Deaths per 1,000" 2 "Marriages per 1,000" 3 "Divorces per 1,000"
label values metric metric
dashboardbuilder panel compare , tab(today) x(metric) y(v) ///
    title("Vital rates vs. the United States") ///
    note("Bar = selected state; | marker = United States.") ytitle("per 1,000 residents")
use `censusplus', clear
drop if state == "United States"
gsort -medage
keep in 1/10
rename state stname
dashboardbuilder panel hbar , tab(rank) x(stname) y(medage) ///
    title("Ten oldest states by median age") ytitle("median age (years)")
dashboardbuilder build using "state_explorer.html", replace pdf noopen ///
    callout("A teaching example on 1980 census extracts; the point is the layout, not the vintage.") ///
    sourcenote("Source: sysuse census (1980 US census extract shipped with Stata).")

* ── 3. Time series across tabs (life expectancy) ────────────────────────────
sysuse uslifeexp, clear
dashboardbuilder init , title("A century of US life expectancy") ///
    subtitle("1900-1999, from the National Center for Health Statistics")
dashboardbuilder tab , name(overview) label("Overview")
dashboardbuilder tab , name(gaps)     label("Gaps")
dashboardbuilder panel line , tab(overview) x(year) y(le) ///
    title("Life expectancy rose about 30 years in one century") ///
    interp("The 1918 flu pandemic is the sharp notch; everything after 1950 is a slower grind.") ///
    ytitle("years at birth")
dashboardbuilder panel line , tab(gaps) x(year) y(le_male le_female) ///
    title("The male-female gap opened, then narrowed") ytitle("years at birth")
dashboardbuilder build using "lifeexp.html", replace pdf noopen ///
    sourcenote("Source: sysuse uslifeexp (NCHS life tables shipped with Stata).")

* ── 4. Map embed (needs sparkta2) ───────────────────────────────────────────
capture which sparkta2
if _rc {
    di as txt "(skipping county_map_dashboard.html — sparkta2 is not installed)"
}
else {
    capture findfile texas_counties.csv
    if _rc {
        di as txt "(skipping county_map_dashboard.html — texas_counties.csv not found in this folder)"
    }
    else {
        import delimited "`r(fn)'", varnames(1) stringcols(2) clear   // real fips + county names
        set seed 2036
        gen double readiness = 100*runiform()
        gen double income    = 40000 + 35000*runiform()
        label var readiness "Workforce readiness index (0-100, synthetic)"
        label var income    "Median household income (USD, synthetic)"
        tempfile counties
        save `counties'
        tempfile mapfile
        sparkta2 readiness, id(fips) name(county) geo(texas) type(choropleth) ///
            scheme(blues) title("Workforce readiness by county") ///
            offline noopen export("`mapfile'.html")
        use `counties', clear
        dashboardbuilder init , title("Texas county readiness explorer") ///
            subtitle("a sparkta2 map embedded inside a dashboardbuilder dashboard (synthetic demo)") tx2036
        dashboardbuilder tab , name(map)     label("Map")
        dashboardbuilder tab , name(numbers) label("The numbers")
        dashboardbuilder panel html , tab(map) file("`mapfile'.html") height(760) ///
            title("Readiness index by county") ///
            interp("Darker counties score higher. A live sparkta2 D3 map embedded in the card below.") ///
            note("Map: sparkta2 (D3 + Texas geography). Values are synthetic for illustration.")
        preserve
            collapse (mean) readiness income
            dashboardbuilder panel kpi , tab(numbers) values(readiness income) title("Statewide averages")
        restore
        gsort -readiness
        keep in 1/30
        dashboardbuilder panel hbar , tab(numbers) x(county) y(readiness) ///
            title("Thirty highest-readiness counties") ytitle("readiness index (synthetic)")
        dashboardbuilder build using "county_map_dashboard.html", replace pdf corner noopen ///
            callout("Values are synthetic; the point is the pattern of embedding a map in a dashboard.") ///
            sourcenote("Demo data are synthetic. Map by sparkta2; dashboard by dashboardbuilder.")
    }
}

di as res _n "site dashboards rebuilt: auto_quick, state_explorer, lifeexp" ///
    cond(_rc==0,", county_map_dashboard","") ".html"
