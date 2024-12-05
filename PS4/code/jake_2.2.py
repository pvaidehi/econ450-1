
# Pre-question, loading libraries and data
from scipy.io import loadmat
import jaxopt as jaxopt
from PSET4_functions.misc import *
from PSET4_functions.shares import *
from PSET4_functions.delta import *
from PSET4_functions.moments import * 
from PSET4_functions.mpec_wrapper import *

# m100_j3 = loadmat("data/100markets3products.mat")
# dat = clean_data(m100_j3, 3)
# dat = pd.read_csv("data/100markets3products.csv")

def blp_instruments(x_3d):
    num_markets = x_3d.shape[0]
    num_prods = x_3d.shape[1]
    x_3d = np.ascontiguousarray(x_3d)
    own_chars = x_3d.reshape(num_markets*num_prods, 3)

    sum_chars = np.sum(x_3d, axis = 1)
    blp_rival = np.empty_like(x_3d)
    for i in range(x_3d.shape[0]):
        for j in range(x_3d.shape[1]):
            blp_rival[i, j] = sum_chars[i] - x_3d[i, j]

    blp_rival = blp_rival.reshape(num_markets*num_prods, 3)
    blp_rival = blp_rival[:, 1:]
    return np.concatenate((own_chars, blp_rival), axis = 1)


z_data = blp_instruments(dat[['X1jm', 'X2jm', 'X3jm']].to_numpy().reshape(100,3,3)) 
np.random.seed(456)
random_vs = np.random.lognormal(0, 1, 1000)

shares_data_long = dat[['sjm']].to_numpy()
prices_data_long = dat[['pjm']].to_numpy() 
x_data_long = dat[['X1jm', 'X2jm', 'X3jm']].to_numpy()
demand_features_data_long = dat[["X1jm", "X2jm", "X3jm", "pjm", "xijm"]].to_numpy()

shares_data_wide = shares_data_long.reshape(100,3)

prices_data_wide = prices_data_long.reshape(100,3)

x_data_3d = x_data_long.reshape(100, 3, 3)

# ESTIMATING PARAMETERS

theta_2_0 = np.array([.1]) 
delta_0 = inner_loop(theta_2_0, logit_delta(shares_data_wide).reshape(100, 3), shares_data_wide, prices_data_wide, random_vs)
dat[["delta_0"]] = delta_0.reshape(-1,1)
beta, alpha, sigma_alpha, delta_hat = full_mpec_wrapper(theta_2_0, dat, z_data, random_vs, 100, 3)

# RECOVERING ANALYTIC SEs
beta_alpha_se, sigma_alpha_se = standard_errors(sigma_alpha, delta_hat, z_data, prices_data_wide, x_data_long, x_data_3d, random_vs)


results = [["beta_1", beta[0], beta_alpha_se[0]], 
           ["beta_2", beta[1], beta_alpha_se[1]], 
           ["beta_3", beta[2], beta_alpha_se[2]], 
           ["-alpha", alpha, beta_alpha_se[3]], 
           ["sigma_alpha", sigma_alpha, sigma_alpha_se]]
headers = ["estimates", "standard errors"]
print("Results (100X3, BLP instruments)")
print(tabulate(results, headers, tablefmt="plain"))