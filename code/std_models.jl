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
                            Δy = diff(data.y),
                            Δk = diff(data.k),
                            Δl = diff(data.l),
                            Δm = diff(data.m),
                            Δyear = diff(data.year))
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
        :Δyear_5y = :year .- lag(:year, 5)  # This helps to confirm year gaps
    )
    model_ld = lm(@formula(Δy_5y ~ Δk_5y + Δl_5y + Δm_5y), df_long_diff)
    println(model_ld, "\n")

    ## Random Effects
    println("5. Random Effects (RE) Model:")
    model_re = fit!(LinearMixedModel(@formula(y ~ k + l + m + (1 | id)), data))
    println(model_re, "\n")

    ## Note: Hausman Test implementation can go here if needed

    println("All models processed successfully.\n")

    # Return models as a dictionary for further use
    return Dict(
        "OLS" => model_ols,
        "FE" => model_fe,
        "FD" => model_fd,
        "LD" => model_ld,
        "RE" => model_re
    )
end