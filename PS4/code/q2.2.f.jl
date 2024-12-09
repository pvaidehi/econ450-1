# purpose: get price elasticity, profits, and consumer surplus at estimated values

# pick one of the estimates
result = results[1]
β_hat = result.β_solution
α_hat = result.α_solution
σ_hat = result.σ_solution
δ_hat = result.δ_solution
η_hat = result.η_solution

filename = "../data/100markets3products.mat"
include("import_data.jl")

# price elasticity of demand 
params = vcat(β_hat, α_hat, σ_hat, vec(δ_hat), η_hat)
est_shares = shares - reshape(share_calc(β_hat, α_hat, σ_hat, δ_hat, η_hat), 3, 100)

function share_calc_derivative(δ_vec)
    eutilities = exp.(reshape(δ_vec, n_products, n_markets) .- σ_hat .* ν_vec .* P_opt)
    choice_probs = zeros(3, 100, 100)
    choice_probs = eutilities ./ (1 .+ sum(eutilities, dims = 1))
    pred_share = (1/length(ν)) * sum(choice_probs, dims = 3)
    pred_share = reshape(pred_share, 3, 100)
    return vec(pred_share)
end
δ_hat_vec = vec(δ_hat)
jac_share_calc = ForwardDiff.jacobian(share_calc_derivative, δ_hat_vec)

est_pe = vec(P_opt ./ est_shares) .* diag(jac_share_calc) .* α_hat 

# print results
println("Price Elasticity of Demand Estimates: ", est_pe)

# consumer surplus:
α_i_hat = α_hat .+ σ_hat .* ν
α_i_hat = reshape(α_i_hat, 1, 1, 100)
est_u_ijm = β_hat[1] .* X1_jm .+ β_hat[2] .* X2_jm .+ β_hat[3] .* X3_jm .- α_i_hat .* P_opt .+ ξ_jm
est_u_ijm = max.(est_u_ijm, 0.0)
est_cs = reshape(sum(est_u_ijm, dims = 3), 3, 100)
est_cs = sum(est_cs, dims = 1)
histogram(est_cs[:], bins = 20, label="Estimated", alpha=0.5, normalize=false)
histogram!(cs_m[:], bins = 20, label="Real", alpha=0.5, normalize=false)
xlabel!("CS")
ylabel!("Frequency")
title!("Distribution of Consumer Surplus - 3 Products")

# profits
est_π_jm = (P_opt  .- mc_jm) .* est_shares
histogram(est_π_jm[:], bins=20, label="Estimated", alpha=0.5, normalize=false)
histogram!(π_jm[:], bins=20, label="Real", alpha=0.5, normalize=false)
xlabel!("Profits")
ylabel!("Frequency")
title!("Distribution of Profits - 3 Products")
