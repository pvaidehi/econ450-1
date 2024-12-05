# stuff that i wrote that couldn't be used

function compute_moments(init_params::Vector{Float64}, data::DataFrame)
    """
    Computes objective function for ACF second stage

    Args:
    - init_params: A vector of initial parameter values [β_k, β_l].
    - data: relevant dataframe, the product of the first stage in ACF

    Returns:
    - A tuple containing the fitted coefficients and the moments.

    Issues:
    - function is not auto differentiable because of the lm function
    """
    
    # Extract initial parameters
    β_k, β_l = init_params

    # Calculate residuals
    data.ω = data.ϕ_hat .- β_k .* data.k .- β_l .* data.l
    data.ω_lag = data.ϕ_hat_lag .- β_k .* data.k_lag .- β_l .* data.l_lag

    # Create squared and cubed lagged residuals
    data.ω_lag_sq = data.ω_lag .^ 2
    data.ω_lag_cube = data.ω_lag .^ 3

    # Fit a linear model
    model = lm(@formula(ω ~ ω_lag + ω_lag_sq + ω_lag_cube), data)
    
    # Predict values and compute ξ
    data.ω_hat = predict(model, data)
    data.ξ = data.ω .- data.ω_hat

    # Define instruments and calculate moments
    # Z = [:k, :l_lag]
    # moments = Float64[]
    # Define instruments and calculate moments
    Z = [:k, :l_lag]
    moments = [mean(data[:, z] .* data[:, :ξ]) for z in Z]  # Collect moments in a non-mutating way

    # for z in Z
    #     z_moment_col = data[:, z] .* data[:, :ξ]  # Element-wise multiplication
    #     z_moment = mean(z_moment_col)  # Calculate the mean of the moment
    #     #push!(moments, z_moment)  # Append the moment to the array
    #     moments = vcat(moments, z_moment)
    # end

    return moments' * I(length(moments)) * moments

end
