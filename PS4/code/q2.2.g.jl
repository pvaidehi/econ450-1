# repeat for M = 10 
filename = "../data/10markets3products.mat"
include("import_data.jl")
include("blp_fn.jl")

# X and Z arrays 
X = hcat(X1_jm, X2_jm, X3_jm, P_opt)
Z = (X1_jm, X2_jm, X3_jm, lo_X2_jm, lo_X3_jm)

N = length(Z)
W = Matrix{Float64}(I, length(Z), length(Z)) 

# estimate the model
results_10m = []
for i in 1:5
    initial_β = rand(3)
    initial_α = rand()
    initial_σ = rand()
    initial_δ = rand(n_products, n_markets)
    initial_η = rand(N)
    push!(results_10m, solve_blp_model(initial_β, initial_α, initial_σ, initial_δ, initial_η))
end

# get bias 
biases_10m = []
for result in results_10m
    β_solution = result.β_solution
    α_solution = result.α_solution
    σ_solution = result.σ_solution
    est_θ = vcat(β_solution, [α_solution], [σ_solution])
    bias = est_θ .- true_θ
    push!(biases_10m, bias)
end
for (i, bias) in enumerate(biases_10m)
    println("Bias for Run $i: ", bias)
end