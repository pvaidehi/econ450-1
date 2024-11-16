# purpose: OP estimation: Incomeplete as of nov 16, 2024


# first-stage: ϕ non-parametric estimate as a function of k and i


using DataFrames, StatsModels

# Define the function to generate polynomial features of two variables up to a specified degree
function poly(x::Symbol, y::Symbol, data::DataFrame; degree::Int)
    poly_data = DataFrame()
    poly_data[!,:x] = data[!,:i]
    poly_data[!,:y] = data[!,:k]
    # Add each polynomial term to the new DataFrame
    for (i, j) in Iterators.product(0:degree, 0:degree)
        if i + j <= degree && (i > 0 || j > 0)
            term_name = Symbol("term_$(i)_$(j)")
            poly_data[!, term_name] = data[!, x].^i .* data[!, y].^j
        end
    end
    return poly_data
end

# Example usage
poly_data = poly(:i, :k, df, degree = 2)
combined_df = hcat(select(df, [:va_y, :l, :id]), select(poly_data, Not([:x, :y])))

term_names = names(select(poly_data, Not([:x, :y])))

model = lm(term(:va_y) ~ sum(term.(Symbol.(names(combined_df, Not(:va_y, :id))))), combined_df)
combined_df.va_y_hat = predict(model, combined_df)
combined_df.ϕ_hat = combined_df.va_y_hat - (combined_df.l .* coef(model)[2])

combined_df = transform(
    groupby(combined_df, :id),
    :ϕ_hat => (x -> [missing; x[1:end-1]]) => :ϕ_hat_lag
)

# second stage



# using Zygote

# # Define a function
# f(x) = x^2 + 3 * x + sin(x)

# # Compute the gradient
# dfdx = x -> Zygote.gradient(f, x)[1]
# println(dfdx(2.0))  # Compute the gradient at x = 2.0