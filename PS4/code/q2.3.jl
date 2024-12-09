# purpose: blp estimation with price included in instrument set
# author: vaidehi

include("blp_fn.jl")

# import data for 3 products
true_β = [5,1,1];
true_γ = [2,1,1];
true_α = 1;
true_σ_α = 1;
true_θ = [true_β; true_α; true_σ_α]
θ_size = length(true_θ);

filename = "../data/100markets3products.mat"
include("import_data.jl")

# X and Z arrays 
X = hcat(X1_jm, X2_jm, X3_jm, P_opt)
Z = (X1_jm, X2_jm, X3_jm, lo_X2_jm, lo_X3_jm, P_opt)
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
results_wp = []

for i in 1:5
    initial_β = rand(3)
    initial_α = rand()
    initial_σ = rand()
    initial_δ = rand(n_products, n_markets)
    initial_η = rand(N)
    push!(results_wp, solve_blp_model(initial_β, initial_α, initial_σ, initial_δ, initial_η))
end

# get bias 
biases_wp = []
for result in results_wp
    β_solution = result.β_solution
    α_solution = result.α_solution
    σ_solution = result.σ_solution
    est_θ = vcat(β_solution, [α_solution], [σ_solution])
    bias = est_θ .- true_θ
    push!(biases_wp, bias)
end
for (i, bias) in enumerate(biases_wp)
    println("Bias for Run $i: ", bias)
end
