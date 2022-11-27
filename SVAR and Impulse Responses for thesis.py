import pandas as pd
from statsmodels.tsa.api import VAR
import numpy as np
import matplotlib.pyplot as plt
#import seaborn as sns


pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

fomc = pd.read_csv('results_fomc_fixed.csv')
ipm = pd.read_csv('IPmanufacturing.csv')
ipc = pd.read_csv('IPconstruction.csv')

sectors = ipm.merge(ipc, left_on='DATE', right_on='DATE')
sectors['DATE'] = sectors.DATE.str.replace('-', '/')
sectors['DATE'] = sectors.DATE.apply(lambda x: '/'.join([x.split('/')[1], x.split('/')[2], x.split('/')[0]]))

sectors['DATE'] = pd.to_datetime(sectors['DATE'])
fomc['FOMC ANNOUNCEMENT DATE'] = pd.to_datetime(fomc['FOMC ANNOUNCEMENT DATE'])

sectors['month'], sectors['year'] = sectors['DATE'].dt.month, sectors['DATE'].dt.year
fomc['month'], fomc['year'] = fomc['FOMC ANNOUNCEMENT DATE'].dt.month, fomc['FOMC ANNOUNCEMENT DATE'].dt.year


train = fomc.merge(sectors, how='left', left_on=['month', 'year'], right_on=['month', 'year'])
train = train.rename(columns={'IPB54100S': 'IPconstruction',
                              'IPMAN': 'IPmanufacturing'})

X_train = train[['et_n3', 'et_n4', 'et_n5', 'et_n6', 'et_n7', 'IPmanufacturing', 'IPconstruction']].dropna(how='any')

X_train.to_csv('data_var_ready.csv', index=False)
# BX_T = B_0 + B_1*X_{T-1} + ... + B_k*X_{t-k} + eps


model = VAR(X_train)


def get_p(linear_model, p=7, method="AIC"):

    res = []
    for lag in range(1, 4):
        num_param = p + (p**2)*lag
        candidate = linear_model.fit(lag)
        SSR = np.square(candidate.resid.values).sum()
        res.append((lag, num_param - np.log(SSR)))
    return min(res, key=lambda x: x[1])[0]


p = get_p(model)
print(f'NUM LAGS USED FOR VAR = {p}')
results = model.fit(p)
covar_matrix = results.resid_acov(nlags=0).squeeze()


B = np.linalg.cholesky(covar_matrix)
B_inv = np.linalg.inv(B)
params_df = results.params
cols = params_df.columns.to_list()
params_df = params_df.drop('const')
params_df = params_df.set_index(pd.Index(params_df.columns.to_list()), drop=True)
name_to_idx = {params_df.index[i]: i for i in range(len(params_df))}
B_1 = params_df.values


irf = results.irf(52)
irf.plot_cum_effects(orth='False', impulse='et_n3', figsize=(7,10))
plt.savefig('cum')
print(irf.irfs)
print(irf.cum_effects)
np.savetxt("cum.csv", irf.cum_effects[:,:,2], delimiter=',')
