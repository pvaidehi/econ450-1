// purpose: do xtabond, xtdpdsys, opreg, levpet in stata
// things to do: export results, check that these use gross_output and not value added?

clear
set more off
version 18
log using q2_part5.log, replace

use "../data/PS3_data.dta", clear
local industry = "X10"
keep if `industry' == 1

// generate variables
gen log_output = X03
gen log_capital = X40
gen log_labour = X43
gen log_int_consumption = X44
gen log_price = X45
gen log_int_price = X49
gen exit_dummy = X61
gen log_investment = X39

label var log_output "log of gross output"
label var log_capital "log of capital"
label var log_labour "log of labour"
label var log_int_consumption "log of materials"
label var exit_dummy "exit dummy"
label var log_price "log of price"
label var log_int_price "log of materials price"
label var log_investment "log of investment"

// xtabond
xtset firm_id year
xtabond log_output log_capital log_labor log_int_consumption,  vce(robust) 
eststo AB

// xtdpdsys
xtdpdsys log_output log_capital log_labor log_int_consumption, vce(robust)
eststo BB

// opreg - get value added output
gen log_va_output = log(exp(log_output + log_price) - exp(log_int_consumption + log_int_price)) 
label var log_va_output "log of value added output"
opreg log_va_output, exit(exit_dummy) state(log_capital) proxy(log_investment) free(log_labour) vce(bootstrap, reps(100))
eststo OP

// levpet
levpet log_output, free(log_labor) proxy(log_int_consumption) capital(log_capital) valueadded reps(250) i(firm_id)
eststo LP 

// export
esttab AB BB OP LP using "../outputs/prod_est.tex", replace mtitle("AB" "BB" "OP" "LP") /// 
    b(3) se(3) label starlevels(* 0.10 ** 0.05 *** 0.01)

log close