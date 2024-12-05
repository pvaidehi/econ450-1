# purpose: question 2 of problem set 3 in econ 450-1
# author: vaidehi 
# last updated: 11/16/2024

include("packages.jl")
include("summ_stats.jl")
include("std_models.jl")

# read in the data
raw_data = DataFrame(CSV.File("../data/PS3_data.csv"))

# get the headers
headers = names(raw_data);
println(headers);

# assign variables
df = DataFrame()
df[!,:id] = raw_data."firm_id";
df[!,:year] = raw_data."year";
df[!,:obs] = raw_data."obs";
df[!,:i] = raw_data."X39";
df[!,:y] = raw_data."X03";
df[!,:k] = raw_data."X40";
df[!,:l] = raw_data."X43";
df[!,:m] = raw_data."X44";
df[!,:p] = raw_data."X45";
df[!,:wm] = raw_data."X49";
df[!,:ind7] = raw_data."X10";
va_y = (exp.(df[!, :y] .+ df[!, :p]) .- exp.(df[!, :m] .+ df[!, :wm]));
va_y = ifelse.(va_y .< 0, missing, va_y);
df[!, :va_y] = log.(va_y);
m_share = df[!, :m] .+ df[!, :wm] - (df[!, :y] .+ df[!, :p]);
df[!, :m_share] = m_share;

data = hcat(df[!, :y], df[!, :i], df[!, :k], df[!, :l], df[!, :m]);
vars = [df.y, df.i, df.k, df.l, df.m];
variable_names = ["Output", "Investment", "Capital", "Hours", "Intermediate Consumption"];

# industry 
industry = "X10"; # industry of my choice 
df_industry7 = filter(row -> row[:ind7] == 1, df);
sort!(df_industry7, [:id, :year]);

# balanced panel
distinct_years = unique(df.year);
num_distinct_years = length(distinct_years);
df_balanced = df[df.obs .== num_distinct_years, :]
df_industry7_bal = filter(row -> row[:ind7] == 1, df_balanced);
sort!(df_industry7_bal, [:id, :year]);

# balanced panel in matrix form
raw_balanced = raw_data[raw_data.obs .== num_distinct_years, :]
vars_bal = [df_balanced.y, df_balanced.i, df_balanced.k, df_balanced.l, df_balanced.m];

# computation globals
init_params = [1.0,1.0];
err_tol = 1e-6;

# part 1
generate_stats_and_tables(raw_data, vars, variable_names, "unbalanced")

# part 2
generate_stats_and_tables(raw_balanced, vars_bal, variable_names, "balanced")

# part 3
run_std_models(df_industry7_bal, "-balanced")

# part 4
run_std_models(df_industry7, "_unbalanced")

# part 5
run(`stata-se -b do q2_part5.do`)

## ACF
include("acf.jl")

## GNR
include("gnr.jl")