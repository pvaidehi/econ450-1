using Ipopt

model = Model(Ipopt.Optimizer)
N = dim(W)
tot_dim = n_products * n_markets
@variable(model, 0.0 <= η[1:N] <= 1.0) 
@objective(model, Min, sum(η[i] * W[i, j] * η[j] for i in 1:N, j in 1:N))


@variable(model, β[1:3]) 
@variable(model, α) 
@variable(model, δ[1:n_products, 1:n_markets]) 


@variable(model, δ[1:n_products, 1:n_markets])        # 3×100 matrix of δ values
@variable(model, 0.0 <= α <= 1.0)      # Bound for α
@variable(model, β[1:3] >= 0.0)        # Bounds for β (non-negative)
@variable(model, σ >= 0.0) 

function blp_moments(β, δ, α, η, σ)
    ξ = δ .- β[1] .* X1_jm .- β[2] .* X2_jm .- β[3] .* X3_jm .+ α .* P_opt
    moms_long = [Z_i .* ξ for Z_i in Z]
    mean_mom = [mean(mom) for mom in moms_long]
    gerr = mean_mom - η
    return gerr
end
@constraint(model, [j=1:N], blp_moments(β, δ, α, η, σ)[j] == 0)


function share_calc(δ, α, σ)
    eutilities = exp.(δ .- σ .* ν_vec .* P_opt)
    choice_probs = zeros(3, 100, 100)
    choice_probs = eutilities ./ (1 .+ sum(eutilities, dims = 1))
    pred_share = (1/length(ν)) * sum(choice_probs, dims = 3)
    pred_share = reshape(pred_share, 3, 100)
    share_diff = shares .- pred_share
    return vec(share_diff)
end
@constraint(model, [j=1:tot_dim], share_calc(δ, α, σ)[j] == 0)
optimize!(model)
η_solution = value.(η)
δ_solution = value.(δ)
α_solution = value(α)
β_solution = value.(β)

