# purpose: question 2.1 
# author: vaidehi

# import data for 3 products
filename = "../data/100markets3products.mat"
include("import_data.jl")

# 2.1 
E_ξ_X1 = sum(ξ_jm .* X1_jm)/total_dim
E_ξ_X2 = sum(ξ_jm .* X2_jm)/total_dim
E_ξ_X3 = sum(ξ_jm .* X3_jm)/total_dim

println("E[ξX1]: ", E_ξ_X1)
println("E[ξX2]: ", E_ξ_X2)
println("E[ξX3]: ", E_ξ_X3)

E_ξ_P = sum(ξ_jm .* P_opt)/total_dim
println("E[ξP]: ", E_ξ_P)

hausman_Z = similar(P_opt)
for j in 1:n_markets
    for i in 1:n_products
        mean_price = (sum(P_opt, dims = 2) .- P_opt[i, j]) ./ (n_markets-1)
        hausman_Z[:, j] = mean_price
    end
end
E_ξ_P_c = sum(ξ_jm .* hausman_Z)/total_dim
println("E[ξ P']: ", E_ξ_P_c)
