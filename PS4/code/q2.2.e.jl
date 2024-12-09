# purpose: blp estimation (rn for 3 product, 100 market case, probably generalisable)
# author: vaidehi

include("blp_fn.jl")

# import data for 3 products
filename = "../data/100markets3products.mat"
include("import_data.jl")

# X and Z arrays 
X = hcat(X1_jm, X2_jm, X3_jm, P_opt)
Z = (X1_jm, X2_jm, X3_jm, lo_X2_jm, lo_X3_jm)
N = length(Z)
Wt_mat = Matrix{Float64}(I, length(Z), length(Z)) 

# constraint functions
# blp moments constraint
function blp_moments(β, α, σ, δ, η)   
    ξ = δ .- β[1] .* X1_jm .- β[2] .* X2_jm .- β[3] .* X3_jm .+ α .* P_opt
    moms_long = [Z_i .* ξ for Z_i in Z]
    mean_mom = [mean(mom) for mom in moms_long]
    gerr = mean_mom - η
    return gerr
end

# shares constraint
function share_calc(β, α, σ, δ, η)
    utilities = exp.(δ .- σ .* ν_vec .* P_opt)
    choice_probs = zeros(n_products, n_markets, 100)
    choice_probs = utilities ./ (1 .+ sum(utilities, dims = 1))
    pred_share = (1/length(ν)) * sum(choice_probs, dims = 3)
    pred_share = reshape(pred_share, n_products, n_markets)
    share_diff = shares .- pred_share
    return vec(share_diff)
end

# try a few different starting values and see how results differ
results = []

for i in 1:5
    initial_β = rand(3)
    initial_α = rand()
    initial_σ = rand()
    initial_δ = rand(n_products, n_markets)
    initial_η = rand(N)
    push!(results, solve_blp_model(initial_β, initial_α, initial_σ, initial_δ, initial_η))
end

# get bias 
biases = []
for result in results
    β_solution = result.β_solution
    α_solution = result.α_solution
    σ_solution = result.σ_solution
    est_θ = vcat(β_solution, [α_solution], [σ_solution])
    bias = est_θ .- true_θ
    push!(biases, bias)
end
for (i, bias) in enumerate(biases)
    println("Bias for Run $i: ", bias)
end

# gradient is easy for objective function
function blp_obj_fn(η)
    return η' * Wt_mat * η
end

grad_obj = ForwardDiff.gradient(blp_obj_fn, η_solution)
grad_obj_analytical = 2 * Wt_mat * η_solution
@assert (grad_obj .- grad_obj_analytical .< 1e-6) == ones(N)

# i am able to use forward auto diff to give me jacobians and i didn't need to supply them for my optimisation routine anyway but lmk if i'm making a grave error :) 
# jacobian for share constraints
params = vcat(β_solution, α_solution, σ_solution, vec(δ_solution), η_solution)
function wrapped_share_calc(params)
    β = params[1:3]      
    α = params[4]
    σ = params[5]
    δ = reshape(params[θ_size + 1:tot_dim + θ_size], n_products, n_markets)
    return share_calc(β, α, σ, δ, η)
end
jac_share_calc = ForwardDiff.jacobian(wrapped_share_calc, params)

# jacobian for blp_moments
function wrapped_blp_moments(params)
    β = params[1:3]   
    α = params[4]    
    σ = params[5] 
    δ = reshape(params[θ_size + 1:tot_dim + θ_size], n_products, n_markets)
    η = params[tot_dim + θ_size+1:end]
    return vec(blp_moments(β, α, σ, δ, η))
end
jac_blp_moms = ForwardDiff.jacobian(wrapped_blp_moments, params)


# bootstrap
B = 100
β_bootstrap = zeros(B, length(true_β))
α_bootstrap = zeros(B)
σ_bootstrap = zeros(B)

for b in 1:B
    # Resample indices with replacement
    resample_idx = rand(1:n_markets, n_markets)
    X1_jm_bs, X2_jm_bs, X3_jm_bs, lo_X2_jm_bs, lo_X3_jm_bs = X1_jm[:, resample_idx], X2_jm[:, resample_idx], X3_jm[:, resample_idx], lo_X2_jm[:, resample_idx], lo_X3_jm[:, resample_idx]
    Z_bs = (X1_jm_bs, X2_jm_bs, X3_jm_bs, lo_X2_jm_bs, lo_X3_jm_bs);
    P_opt_bs = P_opt[:,resample_idx]

    function blp_moments_bs(β, α, σ, δ, η)   
        ξ = δ .- β[1] .* X1_jm_bs .- β[2] .* X2_jm_bs .- β[3] .* X3_jm_bs .+ α .* P_opt_bs
        moms_long = [Z_i .* ξ for Z_i in Z_bs]
        mean_mom = [mean(mom) for mom in moms_long]
        gerr = mean_mom - η
        return gerr
    end
    
    # shares constraint
    function share_calc_bs(β, α, σ, δ, η)
        utilities = exp.(δ .- σ .* ν_vec .* P_opt_bs)
        choice_probs = zeros(n_products, n_markets, 100)
        choice_probs = utilities ./ (1 .+ sum(utilities, dims = 1))
        pred_share = (1/length(ν)) * sum(choice_probs, dims = 3)
        pred_share = reshape(pred_share, n_products, n_markets)
        share_diff = shares .- pred_share
        return vec(share_diff)
    end

    model_bs = Model(Ipopt.Optimizer)

    # define variables with initial values
    @variable(model_bs, 0.0 <= η[1:N] <= 1.0)
    @variable(model_bs, δ[1:n_products, 1:n_markets])
    @variable(model_bs, 0.0 <= α <= 1.0)
    @variable(model_bs, β[1:3] >= 0.0)
    @variable(model_bs, σ >= 0.0)

    @objective(model_bs, Min, sum(η[i] * Wt_mat[i, j] * η[j] for i in 1:N, j in 1:N))
    @constraint(model_bs, [j=1:N], blp_moments_bs(β, α, σ, δ, η)[j] == 0)
    @constraint(model_bs, [j=1:total_dim], share_calc_bs(β, α, σ, δ, η)[j] == 0)
    optimize!(model_bs);
    
    # Store bootstrap estimates
    β_bootstrap[b, :] =  value.(β)
    α_bootstrap[b] = value(α)
    σ_bootstrap[b] = value(σ)
end