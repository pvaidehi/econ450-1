model2 = Model(Ipopt.Optimizer)
@variable(model2, 0.0 <= η[1:N] <= 1.0) 
@variable(model2, δ[1:n_products, 1:n_markets])
@variable(model2, 0.0 <= α <= 1.0)
@variable(model2, β[1:3] >= 0.0)
@variable(model2, σ >= 0.0)

@NLobjective(model2, Min, sum(η[i] * W[i, j] * η[j] for i in 1:N, j in 1:N))
@NLconstraint(model2, [j=1:N], blp_moments(β, δ, α, η, σ)[j] == 0)
@NLconstraint(model2, [j=1:total_dim], share_calc(δ, α, σ)[j] == 0)
optimize!(model2)
η_solution2 = value.(η)
δ_solution2 = value.(δ)
α_solution2 = value(α)
β_solution2 = value.(β)
σ_solution2 = value.(σ)

est_θ2 = [β_solution2; α_solution2; σ_solution2]
bias2 = est_θ2 .- true_θ