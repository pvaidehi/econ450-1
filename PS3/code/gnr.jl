
# first stage

function calculate_num_interactions(num_vars::Int, degree::Int)
    return binomial(num_vars + degree, degree) - 1 # Subtract 1 to exclude constant
end
num_vars = 3
num_interactions = calculate_num_interactions(num_vars, deg)


deg = 3;
init_params = ones(num_interactions+1);
poly_data = poly(:m, :k, :l, df_industry7, degree = deg)
interactions = select(poly_data, Not([:m, :k, :l]))
interactions_matrix = hcat(ones(size(interactions, 1)), Matrix(interactions)) 
k = df_industry7.k
l = df_industry7.l
m = df_industry7.m

m_share = df_industry7.m_share
function residuals(mat::Matrix{Float64}, γ::Vector{Float64}, m::Vector{Float64})
    predicted = log.(mat * γ .+ 1e-8)
    error = m .- predicted
    return error
end
residuals(interactions_matrix, init_params, m_share);

function residuals(mat::Matrix{Float64}, γ::Vector{Float64}, m::Vector{Float64})
    predicted = log.(max.(mat * γ .+ 1e-8, 1e-10)) 
    error = m .- predicted
    return error
end

# get gradient of gnr using zygote 
function compute_gradient1_gnr(γ::Vector{Float64}, mat::Matrix{Float64}, m_share::Vector{Float64})
    # Ensure grad_fn is consistent with the residuals function
    grad_fn = (params) -> residuals(mat, params, m_share)  # 'mat' is the interactions matrix (k)
    jacobian_result = Zygote.jacobian(grad_fn, γ)  # Compute jacobian w.r.t. gammas
    return jacobian_result
end
res = compute_gradient1_gnr(init_params, interactions_matrix, m_share)


function objective_function(γ::Vector{Float64}, mat::Matrix{Float64}, m_share::Vector{Float64})
    residuals_val = residuals(mat, γ, m_share)
    return sum(residuals_val.^2)  # Objective is the sum of squared residuals
end
objective_function(init_params, interactions_matrix, m_share)

function f(params)
    return objective_function(params, interactions_matrix, m_share)
end
function g!(params::Array, storage::Array) 
    storage[:] = compute_gradient1_gnr(params, interactions_matrix, m_share)[1]
end
results = optimize(f, g!, init_params, NelderMead())
opt_γ = Optim.minimizer(results)

