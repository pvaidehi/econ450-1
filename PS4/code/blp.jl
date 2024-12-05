ν = rand(d, 100)
W = Matrix{Float64}(I, 6, 6) #weighting matrix

σ_init_vals = 0.0
β_init_vals = [0.0, 0.0, 0.0]
η_init_vals = zeros(6)
α_init_vals = 0.0
δ_init_vals = zeros(300)

σ_init_vals = 0.6
β_init_vals = [0.2, 0.3, 0.65]
η_init_vals = zeros(6)
α_init_vals = 0.3
δ_init_vals = reshape(rand(300), 3, 100)


lo_X2_jm = repeat(sum(X2_jm, dims = 1), inner=(size(X2_jm, 1), 1)).- X2_jm
lo_X3_jm = repeat(sum(X3_jm, dims = 1), inner=(size(X3_jm, 1), 1)) .- X3_jm

W_vector = W_j .* ones(3,100)

X = hcat(X1_jm, X2_jm, X3_jm, P_opt)
Z = (X1_jm, X2_jm, X3_jm, lo_X2_jm, lo_X3_jm, W_vector)

ν_vec = reshape(ν, 1, 1, 100)

# moment function 
function blp_moments(β1, β2, β3, δ, α, η, σ)
    ξ = δ .- β1 .* X1_jm .- β2 .* X2_jm .- β3 .* X3_jm .+ α .* P_opt
    moms_long = [Z_i .* ξ for Z_i in Z]
    mean_mom = [mean(mom) for mom in moms_long]
    gerr = mean_mom - η
    return gerr
end

function blp_obj_fn(η)
    return η' * W * η
end

function share_calc(δ, α, σ)
    eutilities = exp.(δ .- σ .* ν_vec .* P_opt)
    choice_probs = zeros(3, 100, 100)
    choice_probs = eutilities ./ (1 .+ sum(eutilities, dims = 1))
    pred_share = (1/length(ν)) * sum(choice_probs, dims = 3)
    pred_share = reshape(pred_share, 3, 100)
    share_diff = shares .- pred_share
    return vec(share_diff)
end

function constraint(β_vals, δ_vals, α_vals, η_vals, σ_vals)
    c1 = share_calc(δ_vals, α_vals,σ_vals)
    c2 = blp_moments(β_vals, δ_vals, α_vals, η_vals, σ_vals)
    return vcat(c1, c2)
end


using JuMP
using Ipopt

# Define the JuMP model
model = Model(Ipopt.Optimizer)

# Define variables
@variable(model, 0.0 <= η_vals[1:6] <= 1.0)  # Adjust bounds as appropriate
@variable(model, δ_vals[1:3, 1:100])        # 3×100 matrix of δ values
@variable(model, 0.0 <= α_vals <= 1.0)      # Bound for α
@variable(model, β_vals[1:3] >= 0.0)        # Bounds for β (non-negative)


function share_calc_wrapped(α::Real, δ_flat::AbstractVector{<:Real})
    # Reconstruct δ_flat as a matrix
    δ_vals = reshape(collect(δ_flat), 3, 100)  # Reconstruct δ_flat as a matrix
    share_diff = share_calc(δ_vals, α, σ_init_vals)
    return share_diff  # Return share_diff as a flattened vector
end


register(model, :share_calc_wrapped, 2, share_calc_wrapped; autodiff = true)



# function blp_moments_wrapped(β::Vector{<:Real},  η::Vector{<:Real}, α::Real, δ_flat::Vector{<:Real},)
#     δ_vals = reshape(δ_flat, 3, 100)  
#     return blp_moments(β, δ_vals, η, α)
# end

# register(model, :blp_moments_wrapped, 4, blp_moments_wrapped; autodiff = true)

function scalar_eq(x, y)
    return x == y ? 1.0 : 0.0  # Return 1.0 for true, 0.0 for false (JuMP expects Float64)
end

# Register the function with autodiff
register(model, :scalar_eq, 2, scalar_eq, autodiff=true)

# Add constraints to the model
δ_flat = vec(δ_init_vals)

share_diff = share_calc_wrapped(real(α_init_vals), δ_flat)  # This returns a vector

for i in 1:length(share_diff)
    @NLconstraint(model, share_diff[i] == 0.0)
end

@NLconstraint(model, blp_moments_wrapped(β_vals, δ_vals, α_vals, η_vals) .== 0.0)

# Define the objective function
register(model, :blp_obj_fn, N, blp_obj_fn, autodiff=true)
@NLobjective(model, Min, blp_obj_fn(value(η_vals)))

# Set the initial values (optional)
set_start_value.(η_vals, zeros(6))        # Initial guess for η
set_start_value.(δ_vals, zeros(3, 100))  # Initial guess for δ
set_start_value.(α_vals, 0.3)            # Initial guess for α
set_start_value.(β_vals, [0.2, 0.3, 0.65])

# Solve the optimization problem
optimize!(model)

# Extract the solution
η_solution = value.(η_vals)
δ_solution = value.(δ_vals)
α_solution = value(α_vals)
β_solution = value.(β_vals)

println("Optimal η: ", η_solution)
println("Optimal δ: ", δ_solution)
println("Optimal α: ", α_solution)
println("Optimal β: ", β_solution)





function blp_moments_wrapped(args::T...) where {T<:Real}
    # Extract inputs
    β, η, α, δ_flat = args[1], args[2], args[3], args[4]
    
    # Ensure inputs are vectors
    β = collect(β)
    η = collect(η)
    δ_flat = collect(δ_flat)
    
    # Reshape δ_flat while preserving the element type
    δ_vals = reshape(δ_flat, 3, 100)
    
    # Call the underlying function
    return blp_moments(β, δ_vals, η, α)
end
register(model, :.==, 2, .==, autodiff=true)

register(model, :blp_moments_wrapped, 4, blp_moments_wrapped; autodiff = true)
