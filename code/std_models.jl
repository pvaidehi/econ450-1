function run_std_models(data, suffix)

    println("Running models with suffix: $suffix\n")

    ## OLS
    println("1. OLS Model:")
    model_ols = lm(@formula(y ~ k + l + m), data)
    println(model_ols, "\n")

    ## FE Model
    println("2. Fixed Effects (FE) Model:")
    model_fe = reg(data, @formula(y ~ k + l + m + fe(year) + fe(id)))
    println(model_fe, "\n")

    ## First Differences
    println("3. First Differences Model:")
    df_differenced = DataFrame(id = data.id[2:end],
                            Δy = Base.diff(data.y),
                            Δk = Base.diff(data.k),
                            Δl = Base.diff(data.l),
                            Δm = Base.diff(data.m),
                            Δyear = Base.diff(data.year))
    dropmissing!(df_differenced)
    model_fd = lm(@formula(Δy ~ Δk + Δl + Δm), df_differenced)
    println(model_fd, "\n")

    ## Long Differences
    println("4. Long Differences Model:")
    df_long_diff = @transform(groupby(data, :id),
        :Δy_5y = :y .- lag(:y, 5),
        :Δk_5y = :k .- lag(:k, 5),
        :Δl_5y = :l .- lag(:l, 5),
        :Δm_5y = :m .- lag(:m, 5),
        :Δyear_5y = :year .- lag(:year, 5)
    )
    model_ld = lm(@formula(Δy_5y ~ Δk_5y + Δl_5y + Δm_5y), df_long_diff)
    println(model_ld, "\n")

    ## Random Effects
    println("5. Random Effects (RE) Model:")
    model_re = fit!(LinearMixedModel(@formula(y ~ k + l + m + (1 | id)), data))
    println(model_re, "\n")

    # Extract coefficients
    b_fe = coef(model_fe)
    b_re = coef(model_re)[2:end]

    # Compute covariance matrices
    v_fe = vcov(model_fe)
    v_re = vcov(model_re)[2:end, 2:end]

    # Hausman Test Statistic
    Δ = b_fe - b_re
    h_stat = dot(Δ, inv(v_fe - v_re) * Δ)

    # p-value
    p_value = 1 - cdf(Chisq(length(Δ)), h_stat)

    println("Hausman Test Statistic: $h_stat")
    println("p-value: $p_value")

    println("All models processed successfully.\n")

    # Return models as a dictionary for further use
    return Dict(
        "OLS" => model_ols,
        "FE" => model_fe,
        "FD" => model_fd,
        "LD" => model_ld,
        "RE" => model_re,
        "Hausman" => h_stat,
        "p_value" => p_value
    )
end