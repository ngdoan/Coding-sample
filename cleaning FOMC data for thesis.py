import pandas as pd
import numpy as np

def f(file_path, num_horizons=7):
    df = pd.read_csv(file_path)
    df_with_exp_rates = pd.concat([df.copy(),
                                  pd.DataFrame(
                                      np.full((df.shape[0], num_horizons+1), np.nan),
                                      columns=[f'et_n{i}' for i in range(num_horizons+1)])],
                                  axis=1)
    months_with_30_days = {'2', '4', '6', '9', '11'}

    for horizon in range(num_horizons+1):
        for i in range(df.shape[0]):
            if i + horizon >= df.shape[0]:
                continue
            month, day, year = df.loc[i + horizon, 'FOMC ANNOUNCEMENT DATE'].split('/')
            m0 = 30 if month in months_with_30_days else 31
            ft, ft_1 = df_with_exp_rates.loc[i + horizon, 'RATE 1-DAY AFTER'], df.loc[i + horizon, 'RATE 1-DAY BEFORE']

            if horizon == 0:
                df_with_exp_rates.loc[i, 'et_n0'] = (ft-ft_1)*(m0/(m0-int(day)+1))
            else:
                df_with_exp_rates.loc[i, f'et_n{horizon}'] = (ft-ft_1-(int(day)/m0)*df_with_exp_rates.loc[i, f'et_n{horizon-1}']) * (
                            m0 / (m0 - int(day) + 1))
    return df_with_exp_rates
x = f('~/Downloads/fomc_data.csv')
x.to_csv('~/Downloads/results_fomc.csv', index=False)
print(x.head)

def add(x, y):
    return x+y

add(3,2)
