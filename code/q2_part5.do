// purpose: do xtabond, xtdpdsys, opreg, levpet in stata
// things to do: export results, check that these use gross_output and not value added?
clear
set more off
log using q2_part5.log, replace

use "../data/PS3_data.dta", clear
local industry = "X10"
keep if `industry' == 1

// generate log variables
gen log_output =X03
gen log_capital = X40
gen log_labor = X43
gen log_int_consumption = X44

// xtabond
xtset firm_id year
xtabond log_output log_capital log_labor log_int_consumption,  vce(robust) 

// xtdpdsys
xtdpdsys log_output log_capital log_labor log_int_consumption, vce(robust)

// opreg
opreg log_output log_capital log_labor log_int_consumption

// levpet
levpet log_output, free(log_labor) proxy(log_int_consumption) capital(log_capital) valueadded reps(250)
