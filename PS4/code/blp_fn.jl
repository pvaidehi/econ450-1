# purpose: function for setting up model in JuMP and solving BLP model

function solve_blp_model(initial_β, initial_α, initial_σ, initial_δ, initial_η)
    model = Model(Ipopt.Optimizer)

    # define variables with initial values
    @variable(model, 0.0 <= η[1:N] <= 1.0)
    @variable(model, δ[1:n_products, 1:n_markets])
    @variable(model, 0.0 <= α <= 1.0)
    @variable(model, β[1:3] >= 0.0)
    @variable(model, σ >= 0.0)

    set_start_value.(η, initial_η)
    set_start_value.(δ, initial_δ)
    set_start_value.(α, initial_α)
    set_start_value.(β, initial_β)
    set_start_value.(σ, initial_σ)

    # define objective
    @objective(model, Min, sum(η[i] * Wt_mat[i, j] * η[j] for i in 1:N, j in 1:N))

    # define constraints
    @constraint(model, [j=1:N], blp_moments(β, α, σ, δ, η)[j] == 0)
    @constraint(model, [j=1:total_dim], share_calc(β, α, σ, δ, η)[j] == 0)

    # optimise
    optimize!(model);

    # return the estimates
    return (
        η_solution = value.(η),
        δ_solution = value.(δ),
        α_solution = value(α),
        β_solution = value.(β),
        σ_solution = value(σ)
    )
end