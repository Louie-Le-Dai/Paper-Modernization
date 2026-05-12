import pandas as pd
import numpy as np

# Read Stata
df = pd.read_stata(r'D:\Desktop\MA Econ\Econ 562\Modernization\data\depcov_dataset_ready.dta')

# Basic Variables
df["year"] = pd.to_numeric(df["year"])
month_map = {
    "January": 1, "February": 2, "March": 3, "April": 4,
    "May": 5, "June": 6, "July": 7, "August": 8,
    "September": 9, "October": 10, "November": 11, "December": 12
}

df["month_num"] = df["month"].map(month_map).astype(int)
df['age'] = df['age'].astype(float)
# df['treat'] = ((df['age'] >= 19) & (df['age'] <= 25)).astype(float)
df["implement"] = (
    ((df["year"] == 2010) & (df["month_num"] >= 10)) |
    (df["year"] == 2011)
).astype(int)


df['pre'] = ((df['year'] < 2010) | ((df['year'] == 2010) & (df['month_num'] < 3)))
df['groupid'].astype(int)


# Divide into 2 types: change over time/ baseline characteristics
outcome_vars = ['emphi_dep', 'anyhi', 'indiv', 'emphi', 'govhi']
change_vars = ['mar', 'student', 'live_wparent']

cov_vars = [
    'female', 'white', 'black', 'hispanic',
    'fpl_ratio', 'ue',  'hsg', 'somcol', 'colgrd',
    'st_with_law', 'ctrl'
]

id_vars = ['fipstate', 'p_weight']

impl_df = df[df['implement'] == 1].copy()

# Take mean of numerical variable
impl_mean = (
    impl_df.groupby('groupid')[outcome_vars + cov_vars]
    .mean()
    .reset_index()
)

# take first observation of id
impl_id = (
    impl_df.groupby('groupid')[id_vars]
    .first()
    .reset_index()
)

# Time-varying (pick last observation)
impl_last = (
    impl_df.groupby('groupid')[change_vars]
    .last()
    .reset_index()
)


impl = impl_mean.merge(impl_id, on='groupid', how='left')
impl = impl.merge(impl_last, on='groupid', how='left')


# Treat
impl_df['fedelig_month'] = (
    (impl_df['age'] >= 19) & (impl_df['age'] <= 25)
).astype(float)

exposure = (
    impl_df.groupby('groupid')['fedelig_month']
    .mean()
    .reset_index()
    .rename(columns={'fedelig_month': 'exposure'})
)

impl['treat_binary'] = 1-((exposure['exposure'] <= 0.5)).astype(int)

impl.columns

import seaborn as sns
sns.kdeplot(exposure['exposure'])

# pre-policy: baseline
pre_base = (
    df.sort_values(['groupid', 'year', 'month'])
    .groupby('groupid')[['emphi_dep', 'anyhi', 'emphi']]
    .last()
    .rename(columns=lambda c: c + '_pre_mean')
    .reset_index()
)

impl = impl.merge(pre_base, on='groupid', how='left')
impl['exposure'] = exposure['exposure']


for c in ['emphi_dep_pre_mean', 'anyhi_pre_mean', 'emphi_pre_mean']:
    impl[c] = impl[c].fillna(impl[c].mean())


impl['fpl_group'] = pd.cut(
    impl['fpl_ratio'],
    bins   = [-np.inf, 1.0, 1.33, 2.0, 3.0, 4.0, np.inf],
    labels = [1, 2, 3, 4, 5, 6]
).astype(int)
# 1=<100%FPL  2=100-133%  3=133-200%  4=200-300%  5=300-400%  6=>400%

impl['ue_disc'] = pd.qcut(impl['ue'], q=10, labels=False, duplicates='drop') + 1


X_vars = [
    'female', 'white', 'black', 'hispanic', 'mar', 'student',
    'fpl_group', 'st_with_law', 'ue_disc', 'live_wparent',
    'hsg', 'somcol', 'colgrd',
    'emphi_dep_pre_mean', 'anyhi_pre_mean',   # pre期baseline
]

keep = X_vars + [
    'treat_binary', 'emphi_dep', 'anyhi', 'indiv', 'emphi',
    'p_weight', 'fipstate', 'groupid', 'exposure', 'fedelig'
]

out = impl[keep].dropna()

out.to_csv('D:\Desktop\MA Econ\Econ 562\Modernization\data\cross-sectional_mean.csv', index=False)


