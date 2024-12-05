# plots of distributions of prices, profits, consumer surplus


# true parameter values 
true_β = [5,1,1];
true_γ = [2,1,1];
true_α = 1;
true_σ_α = 1;

d = LogNormal(0,1)
ν = rand(d, 100)

data = matread("../data/100markets3products.mat")
array_storage = Dict()
for (key, value) in data
    array_storage[key] = value
end
Z_vector = array_storage["Z"];
Z = reshape(Z_vector, 3, 100);
η_vector = array_storage["eta"]
η = reshape(η_vector, 3, 100);
W_vector = array_storage["w"]
W = reshape(W_vector, 3, 100);
W_j = W[:,1]

shares = array_storage["shares"]
x1_vector = array_storage["x1"]
x1 = reshape(x1_vector, 3, 100, 3);
X1_jm = x1[:, :, 1]
X2_jm = x1[:, :, 2]
X3_jm = x1[:, :, 3]
P_opt = array_storage["P_opt"]

ξ_vector = array_storage["xi_all"]
ξ_jm = reshape(ξ_vector, 3, 100);

α_i = true_α .+ true_σ_α * ν
α_i = reshape(α_i, 1, 1, 100)

# marginal cost - dimension j x m
mc_jm = zeros(size(Z))
mc_jm = true_γ[1] .* ones(size(mc_jm)) .+ true_γ[2] .* W .+ true_γ[3] .* Z .+ η

# profits - dimension j x m
π_jm = zeros(size(Z))
π_jm = (P_opt  .- mc_jm) .* shares

# consumer surplus 
u_ijm = true_β[1] .* X1_jm .+ true_β[2] .* X2_jm .+ true_β[3] .* X3_jm .- α_i .* P_opt .+ ξ_jm
u_ijm = max.(u_ijm, 0.0)
cs_jm = reshape(sum(u_ijm, dims = 3), 3, 100)
cs_m = sum(cs_jm, dims = 1)

# histogram of distribution of prices
histogram(P_opt'[:, 1], bins=20, label="Product 1", alpha=0.5, normalize=false)
histogram!(P_opt'[:, 2], bins=20, label="Product 2", alpha=0.5, normalize=false)
histogram!(P_opt'[:, 3], bins=20, label="Product 3", alpha=0.5, normalize=false)
xlabel!("Price")
ylabel!("Frequency")
title!("Distribution of Prices - 3 Markets")

# histogram of distribution of profits
histogram(π_jm'[:, 1], bins=20, label="Product 1", alpha=0.5, normalize=false)
histogram!(π_jm'[:, 2], bins=20, label="Product 2", alpha=0.5, normalize=false)
histogram!(π_jm'[:, 3], bins=20, label="Product 3", alpha=0.5, normalize=false)
xlabel!("Profits")
ylabel!("Frequency")
title!("Distribution of Profits - 3 Markets")

# histogram of distribution of consumer surplus
# histogram(cs_jm', bins=20, label="Product 1", alpha=0.5, normalize=false)