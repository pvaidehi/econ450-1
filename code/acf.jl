
# generate polynomial terms, up to desired order
# OLS estimate; predicted values are Phi! 
# return data set with Phi values

using Zygote 

function ACF_firststage(data::DataFrame, degree::Int)
    poly_data = poly(:m, :k, :l, data, degree = degree) 
    ACF_df = hcat(select(data, [:va_y, :id]), select(poly_data, Not([:term_0_0_1, :term_0_1_0, :term_1_0_0])))
    term_names = names(select(poly_data, Not([:m, :l, :k])))
    
    model = lm(term(:va_y) ~ sum(term.(Symbol.(names(ACF_df, Not(:va_y, :id))))), ACF_df)
    ACF_df.va_y_hat = predict(model, ACF_df)
    ACF_df.ϕ_hat = ACF_df.va_y_hat 
    
    ACF_df = transform(
        groupby(ACF_df, :id),
        :ϕ_hat => (x -> [missing; x[1:end-1]]) => :ϕ_hat_lag,
        :k => (x -> [missing; x[1:end-1]]) => :k_lag,
        :l => (x -> [missing; x[1:end-1]]) => :l_lag
    )
    
    # Filter out rows with missing lagged l
    ACF_df = filter(row -> !ismissing(row.ϕ_hat) && !ismissing(row.k_lag) && !ismissing(row.l_lag), ACF_df)
    
    ACF_df.ϕ_hat = Vector{Float64}(ACF_df.ϕ_hat)
    ACF_df.ϕ_hat_lag = Vector{Float64}(ACF_df.ϕ_hat_lag)
    ACF_df.k_lag = Vector{Float64}(ACF_df.k_lag)
    ACF_df.l_lag = Vector{Float64}(ACF_df.l_lag)
    
    return ACF_df
end

ACF_df = ACF_firststage(df_industry7, 2)

## ACF objective function
function compute_moments(init_params::Vector{Float64}, ϕ_hat::Vector{Float64}, k::Vector{Float64}, l::Vector{Float64}, 
    ϕ_hat_lag::Vector{Float64}, k_lag::Vector{Float64}, l_lag::Vector{Float64})
    """
    Computes objective function for ACF second stage

    Args:
    - init_params: A vector of initial parameter values [β_k, β_l].
    - ϕ_hat, k, l, ϕ_hat_lag, k_lag, l_lag: Vectors containing relevant data columns.

    Returns:
    - A scalar representing the moments calculated from the fitted model.
    """

    # Extract initial parameters
    β_k, β_l = init_params

    # Calculate residuals
    ω = ϕ_hat .- β_k .* k .- β_l .* l
    ω_lag = ϕ_hat_lag .- β_k .* k_lag .- β_l .* l_lag

    # Create squared and cubed lagged residuals
    ω_lag_sq = ω_lag .^ 2
    ω_lag_cube = ω_lag .^ 3

    # Fit a linear model
    # Construct a DataFrame-like design matrix for GLM
    X = hcat(ones(length(ω)), ω_lag, ω_lag_sq, ω_lag_cube)
    coef = X \ ω  

    # Predict values and compute ξ
    ω_hat = X * coef
    ξ = ω .- ω_hat

    # Define instruments and calculate moments
    # Here, we use the arrays `k` and `l_lag` as instruments
    moments = [sum(z .* ξ) / length(z) for z in (k, l_lag)]  # Alternative to mean

    # Instead of matrix multiplication, calculate the scalar of moments
    return sum(moments .^ 2)  # This will give a scalar value
end

# extract variables from ACF_df
ϕ_hat = ACF_df.ϕ_hat
k = ACF_df.k
l = ACF_df.l
ϕ_hat_lag = ACF_df.ϕ_hat_lag
k_lag = ACF_df.k_lag
l_lag = ACF_df.l_lag

# test out objective function calculation
moment_result = compute_moments(init_params, ϕ_hat, k, l, ϕ_hat_lag, k_lag, l_lag)

# plot objective function 
x = range(0.0, stop=0.7, length=25)
y = range(0.0, stop=0.7, length=25)
## create meshgrid
X = reshape([xi for xi in x for yi in y], length(x), length(y))
Y = reshape([yi for xi in x for yi in y], length(x), length(y))
Z = zeros(Float64, length(x), length(y))

## compute values over the meshgrid
for i in 1:size(X, 1)
    for j in 1:size(X, 2)
        Z[i, j] = compute_moments([X[i, j], Y[i, j]], ϕ_hat, k, l, ϕ_hat_lag, k_lag, l_lag)
    end
end
fig = Plots.plot(X, Y, Z, st=:surface, xlabel="β_k", ylabel="β_l", zlabel="Objective Function", title="Surface plot of compute_moments", size=(800, 600))
display(fig)

# auto gradient with zygote
function compute_gradient_with_zygote!(arg_vals::Vector{Float64}, ϕ_hat::Vector{Float64}, k::Vector{Float64}, l::Vector{Float64}, 
    ϕ_hat_lag::Vector{Float64}, k_lag::Vector{Float64}, l_lag::Vector{Float64})
    grad_fn = (params) -> compute_moments(params, ϕ_hat, k, l, ϕ_hat_lag, k_lag, l_lag)
    grad = Zygote.gradient(grad_fn, arg_vals)
    return grad
end
compute_gradient_with_zygote!(init_params, ϕ_hat, k, l, ϕ_hat_lag, k_lag, l_lag)

# optimisation 
## define the objective function `f`
function f(params)
    return compute_moments(params, ϕ_hat, k, l, ϕ_hat_lag, k_lag, l_lag)
end

## define the gradient function `g!`
function g!(params::Array, storage::Array) 
    storage[:] = compute_gradient_with_zygote!(params, ϕ_hat, k, l, ϕ_hat_lag, k_lag, l_lag)[1]
end

# initial parameters
params = [0.5, 0.5]

# run BFGS optimization, passing both the objective `f` and gradient `g!`
result_NM = optimize(f, g!, params, NelderMead())
result_BFGS = optimize(f, g!, params, BFGS())
# extract the optimized parameters (β_k, β_l)
β_k_NM, β_l_NM = Optim.minimizer(result_NM)
β_k_BFGS, β_l_BFGS = Optim.minimizer(result_BFGS)

println("Nelder-Mead Optimized β_k: ", β_k_NM)
println("Nelder-Mead Optimized β_l: ", β_l_NM)

println("BFGS Optimized β_k: ", β_k_BFGS)
println("BFGS Optimized β_l: ", β_l_BFGS)

# try a grid search
β_k_range = LinRange(-0.1, 1.0, 100)  # Range for β_k from -0.1 to 1.0 with 100 values
β_l_range = LinRange(-0.1, 1.0, 100)  # Range for β_l from -0.1 to 1.0 with 100 values

## initialize best parameters and best objective value
best_params = params
best_objective = Inf

## loop through all combinations of β_k and β_l
for β_k in β_k_range
    for β_l in β_l_range
        params = [β_k, β_l]
        
        # Compute the objective function value
        objective_value = f(params)
        
        # If we find a new minimum, update best_params
        if objective_value < best_objective
            best_objective = objective_value
            best_params = params
        end
    end
end

# print the best parameters and corresponding objective value
println("Best parameters by grid search (β_k, β_l): ", best_params)
