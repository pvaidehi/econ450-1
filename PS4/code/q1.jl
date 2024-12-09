# plots of distributions of prices, profits, consumer surplus
# question 1 
# author: vaidehi

# import data for 3 products
filename = "../data/100markets3products.mat";
include("import_data.jl");

# histogram of distribution of prices
histogram(P_opt'[:, 1], bins=20, label="Product 1", alpha=0.5, normalize=false);
histogram!(P_opt'[:, 2], bins=20, label="Product 2", alpha=0.5, normalize=false);
histogram!(P_opt'[:, 3], bins=20, label="Product 3", alpha=0.5, normalize=false);
xlabel!("Price");
ylabel!("Frequency");
title!("Distribution of Prices - 3 Products, 100 Markets");
savefig("../outputs/prices_3prods_100mkts.png");

# histogram of distribution of profits
histogram(π_jm'[:, 1], bins=20, label="Product 1", alpha=0.5, normalize=false);
histogram!(π_jm'[:, 2], bins=20, label="Product 2", alpha=0.5, normalize=false);
histogram!(π_jm'[:, 3], bins=20, label="Product 3", alpha=0.5, normalize=false);
xlabel!("Profits");
ylabel!("Frequency");
title!("Distribution of Profits - 3 Products, 100 Markets");
savefig("../outputs/profits_3prods_100mkts.png");

# histogram of distribution of consumer surplus
histogram(cs_m', bins=20, alpha=0.5, normalize=false,label=false);
xlabel!("Profits");
ylabel!("Frequency");
title!("Distribution of Consumer Surplus - 3 Products, 100 Markets");
savefig("../outputs/cs_3prods_100mkts.png");

# 5 Products 
# import data for 5 products, 100 markets 
filename = "../data/100markets5products.mat";
include("import_data.jl");

# histogram of distribution of prices
histogram(P_opt'[:, 1], bins=20, label="Product 1", alpha=0.5, normalize=false);
histogram!(P_opt'[:, 2], bins=20, label="Product 2", alpha=0.5, normalize=false);
histogram!(P_opt'[:, 3], bins=20, label="Product 3", alpha=0.5, normalize=false);
histogram!(P_opt'[:, 4], bins=20, label="Product 4", alpha=0.5, normalize=false);
histogram!(P_opt'[:, 5], bins=20, label="Product 5", alpha=0.5, normalize=false);
xlabel!("Price");
ylabel!("Frequency");
title!("Distribution of Prices - 5 Products, 100 Markets");
savefig("../outputs/prices_5prods_100mkts.png");

# histogram of distribution of profits
histogram(π_jm'[:, 1], bins=20, label="Product 1", alpha=0.5, normalize=false);
histogram!(π_jm'[:, 2], bins=20, label="Product 2", alpha=0.5, normalize=false);
histogram!(π_jm'[:, 3], bins=20, label="Product 3", alpha=0.5, normalize=false);
histogram!(π_jm'[:, 4], bins=20, label="Product 4", alpha=0.5, normalize=false);
histogram!(π_jm'[:, 5], bins=20, label="Product 5", alpha=0.5, normalize=false);
xlabel!("Profits");
ylabel!("Frequency");
title!("Distribution of Profits - 5 Products, 100 Markets");
savefig("../outputs/profits_5prods_100mkts.png");

# histogram of distribution of consumer surplus
histogram(cs_m', bins=20, alpha=0.5, normalize=false, label=false);
xlabel!("Profits");
ylabel!("Frequency");
title!("Distribution of Consumer Surplus - 5 Products, 100 Markets");
savefig("../outputs/cs_5prods_100mkts.png");