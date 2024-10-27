# function do parts 3 and 4 of q2

function run_std_models(data, suffix)

    ## OLS
    model_ols = lm(@formula(log_output ~ log_capital + log_hours + log_int_consumption), data)

    ## FE model
    model_fe = reg(data, @formula(log_output ~ log_capital + log_hours + log_int_consumption + fe(year) + fe(firm_id)))

    ## First differences 
    df_differenced = DataFrame(id = data.firm_id[2:end],
                            Δlog_output = diff(data.log_output),
                            Δlog_capital = diff(data.log_capital),
                            Δlog_hours = diff(data.log_hours),
                            Δlog_int_consumption = diff(data.log_int_consumption),
                            Δyear = diff(data.year))
    dropmissing!(df_differenced)
    model_fd = lm(@formula(Δlog_output ~ Δlog_capital + Δlog_hours + Δlog_int_consumption), df_differenced)

    ## Long differences
    df_long_diff = @transform(groupby(data, :firm_id),
    :Δlog_output_5y = :log_output .- lag(:log_output, 5),
    :Δlog_capital_5y = :log_capital .- lag(:log_capital, 5),
    :Δlog_hours_5y = :log_hours .- lag(:log_hours, 5),
    :Δlog_int_consumption_5y = :log_int_consumption .- lag(:log_int_consumption, 5),
    :Δyear_5y = :year .- lag(:year, 5)  # This helps to confirm year gaps
    )
    model_ld = lm(@formula(Δlog_output_5y ~ Δlog_capital_5y + Δlog_hours_5y + Δlog_int_consumption_5y), df_long_diff)

    ## Random effects
    model_re = fit!(LinearMixedModel(@formula(log_output ~ log_capital + log_hours + log_int_consumption + (1 | firm_id)), data))

    ## Hausman test

end 