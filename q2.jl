# purpose: question 2 of problem set 3 in econ 450-1
include("main.jl")
include("summ_stats.jl")
include("std_models.jl")

# read in the data
df = DataFrame(CSV.File("PS3_data.csv"))

# get the headers
headers = names(df);
println(headers);

# assign variables
inv = df."X39";
output = df."X03";
capital = df."X40";
hours = df."X43";
int_consumption = df."X44";
data = [output, inv, capital, hours, int_consumption]
variable_names = ["Output", "Investment", "Capital", "Hours", "Intermediate Consumption"]
industry = "X10"; # industry of my choice 

# part 1
generate_stats_and_tables(df, data, variable_names, "unbalanced")

# part 2
distinct_years = unique(df.year);
num_distinct_years = length(distinct_years);
df_balanced = df[df.obs .== num_distinct_years, :]

generate_stats_and_tables(df_balanced, data, variable_names, "balanced")

# part 3
df_balanced[!, :log_output] = log.(df_balanced.X03)
df_balanced[!, :log_capital] = log.(df_balanced.X40)
df_balanced[!, :log_hours] = log.(df_balanced.X43)
df_balanced[!, :log_int_consumption] = log.(df_balanced.X44)
df_industry7_bal = filter(row -> row[Symbol(industry)] == 1, df_balanced)
sort!(df_industry7_bal, [:firm_id, :year])
run_std_models(df_industry7, "-balanced")

# part 4
df_industry7 = filter(row -> row[Symbol(industry)] == 1, df)
sort!(df_industry7, [:firm_id, :year])
run_std_models(df_industry7, "_unbalanced")

# part 5
run(`stata-se -b do q2_part5.do`)

## OP
