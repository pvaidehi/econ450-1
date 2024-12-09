# purpose: import data based on file path and read

# true parameter values 
true_β = [5,1,1];
true_γ = [2,1,1];
true_α = 1;
true_σ_α = 1;
true_θ = [true_β; true_α; true_σ_α]
θ_size = length(true_θ);

data = matread(filename)
markets_match = match(r"(\d+)markets", filename);
products_match = match(r"(\d+)products", filename);
n_markets = parse(Int, markets_match.captures[1]);
n_products = parse(Int, products_match.captures[1]);
total_dim = n_markets * n_products;
array_storage = Dict();
for (key, value) in data
    array_storage[key] = value
end
Z_vector = array_storage["Z"];
Z = reshape(Z_vector, n_products, n_markets);
η_vector = array_storage["eta"];
η = reshape(η_vector, n_products, n_markets);
W_vector = array_storage["w"];
W = reshape(W_vector, n_products, n_markets);
W_j = W[:,1];
W_vector = W_j .* ones(n_products,n_markets)

shares = array_storage["shares"];
x1_vector = array_storage["x1"];
x1 = reshape(x1_vector, n_products, n_markets, 3);
X1_jm = x1[:, :, 1];
X2_jm = x1[:, :, 2];
X3_jm = x1[:, :, 3];
P_opt = array_storage["P_opt"];

ξ_vector = array_storage["xi_all"];
ξ_jm = reshape(ξ_vector,  n_products, n_markets);

# construct leave out X's
lo_X2_jm = repeat(sum(X2_jm, dims = 1), inner=(size(X2_jm, 1), 1)).- X2_jm;
lo_X3_jm = repeat(sum(X3_jm, dims = 1), inner=(size(X3_jm, 1), 1)) .- X3_jm;

# simulate consumer shocks
d = LogNormal(0,1);
ν = rand(d, 100);
ν_vec = reshape(ν, 1, 1, 100);

# generate alphas
α_i = true_α .+ true_σ_α * ν;
α_i = reshape(α_i, 1, 1, 100);

# marginal cost - dimension j x m
mc_jm = zeros(size(Z))
mc_jm = true_γ[1] .* ones(size(mc_jm)) .+ true_γ[2] .* W .+ true_γ[3] .* Z .+ η

# profits - dimension j x m
π_jm = zeros(size(Z))
π_jm = (P_opt  .- mc_jm) .* shares

# consumer surplus 
u_ijm = true_β[1] .* X1_jm .+ true_β[2] .* X2_jm .+ true_β[3] .* X3_jm .- α_i .* P_opt .+ ξ_jm
u_ijm = max.(u_ijm, 0.0)
cs_jm = reshape(sum(u_ijm, dims = 3), n_products, n_markets)
cs_m = sum(cs_jm, dims = 1)
