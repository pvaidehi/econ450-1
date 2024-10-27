// purpose: do xtabond, xtdpdsys, opreg, levpet in stata

clear
set more off

use PS3_data.dta, clear
local industry = "X10"
keep if `industry' == 1

// generate log variables
gen log_output = log(X03)
gen log_capital = log(X40)
gen log_labor = log(X43)
gen log_int_consumption = log(X44)

// xtabond
xtset firm_id year
xtabond log_output log_capital log_labor log_int_consumption,  vce(robust) 

// xtdpdsys
xtdpdsys log_output log_capital log_labor log_int_consumption, vce(robust)

// opreg
opreg log_output log_capital log_labor log_int_consumption

// levpet
levpet log_output, free(log_labor) proxy(log_int_consumption) capital(log_capital) valueadded reps(250)
