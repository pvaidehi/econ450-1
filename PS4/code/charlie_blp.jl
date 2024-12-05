# using Random, LinearAlgebra, Optim, ForwardDiff

# # Simulate data
# normal_values4 = zeros(100, 100)

# for m in 1:100
#     lognormal_mean = 0
#     lognormal_sigma = 1
#     d = LogNormal(0,1)
#     normal_values4[m, :] = rand(d, 100)
# end

# normal_values_long4 = vcat(normal_values4, normal_values4, normal_values4)

# # Define functions
# function blp_g_new3(choice, args...)
#     sigma = choice[1]
#     beta1, beta2, beta3 = choice[2:4]
#     alpha = choice[5]
#     eta = choice[6:11]
#     delta = reshape(choice[12:end], 300, 1)

#     x1, x2, x3, lx2, lx3, w, p, W = args
#     p, x1, x2, x3, lx2, lx3, w = map(x -> reshape(x, 300, 1), (p, x1, x2, x3, lx2, lx3, w))
    
#     x = hcat(x1, x2, x3, p)
#     z = hcat(x1, x2, x3, lx2, lx3, w)
    
#     xi = delta .- beta1 .* x1 .- beta2 .* x2 .- beta3 .* x3 .+ alpha .* p
#     moms_long = z .* xi
    
#     err = mean(moms_long, dims=1)
#     gerr = err - eta
#     return gerr
# end

# function blp_objective_new3(choice, args...)
#     eta = choice[6:11]
#     _, _, _, _, _, _, _, W = args
    
#     return eta' * W * eta
# end

# function share_calc_new3(choice, args...)
#     sigma = choice[1]
#     beta1, beta2, beta3 = choice[2:4]
#     alpha = choice[5]
#     eta = choice[6:11]
#     delta = reshape(choice[12:end], 300, 1)

#     x1, x2, x3, lx2, lx3, w, p, W = args

#     eutilities = zeros(300, 100)
#     prices_long = reshape(p, 300, 1)

#     for m in 1:300
#         eutilities[m, :] .= exp(delta[m] - sigma * normal_values_long4[m, :] .* prices_long[m])
#     end

#     choice_probs = zeros(300, 100)
#     for m in 1:100
#         m2, m3 = 100 + m, 200 + m

#         denom = 1 .+ eutilities[m, :] .+ eutilities[m2, :] .+ eutilities[m3, :]
#         choice_probs[m, :] .= eutilities[m, :] ./ denom
#         choice_probs[m2, :] .= eutilities[m2, :] ./ denom
#         choice_probs[m3, :] .= eutilities[m3, :] ./ denom
#     end

#     pred_shares = mean(choice_probs, dims=2)
#     miss = mkt_shares_3prod_long .- pred_shares
#     return miss
# end

# function constraint_new3(choice, args...)
#     c1 = share_calc_new3(choice, args...)
#     c2 = blp_g_new3(choice, args...)
#     return vcat(c1, c2)
# end

# Compute gradients
function compute_gradient_blp_new3(choice, args...)
    grad_fn = ForwardDiff.gradient(c -> blp_objective_new3(c, args...), choice)
    return grad_fn
end

function constraint_jac_new3(choice, args...)
    jac_fn = ForwardDiff.jacobian(c -> constraint_new3(c, args...), choice)
    return jac_fn
end

# Precompute variables
# W = I(6)

# sum_x2s_3prod_v1 = zeros(100, 1)
# sum_x3s_3prod_v1 = zeros(100, 1)

# x2_3prod_long = reshape(x2_3prod_long, 300, 1)
# x3_3prod_long = reshape(x3_3prod_long, 300, 1)

# for m in 1:100
#     m2, m3 = 100 + m, 200 + m
#     sum_x2s_3prod_v1[m] = x2_3prod_long[m] + x2_3prod_long[m2] + x2_3prod_long[m3]
#     sum_x3s_3prod_v1[m] = x3_3prod_long[m] + x3_3prod_long[m2] + x3_3prod_long[m3]
# end

# sum_x2s_3prod_long = reshape(vcat(sum_x2s_3prod_v1, sum_x2s_3prod_v1, sum_x2s_3prod_v1), 300, 1)
# sum_x3s_3prod_long = reshape(vcat(sum_x3s_3prod_v1, sum_x3s_3prod_v1, sum_x3s_3prod_v1), 300, 1)

# leave_out_x2_3prod = (sum_x2s_3prod_long .- x2_3prod_long) ./ 2
# leave_out_x3_3prod = (sum_x3s_3prod_long .- x3_3prod_long) ./ 2

# args = (x1_3prod_long, x2_3prod_long, x3_3prod_long, leave_out_x2_3prod, leave_out_x3_3prod, w_3prod_long, prices_3prod_long, W)

# choice_init = zeros(311)

# Constraints
cons = OptimizationFunction((x, args) -> constraint_new3(x, args), constraints_eq=length(mkt_shares_3prod_long) + 6)

# Solve optimization problem
results = optimize(Optim.Fminbox(blp_objective_new3), choice_init, Optim.Options(; tol=1e-14))
println(results.minimizer)
println(results)
