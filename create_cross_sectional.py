import pandas as pd
import numpy as np

# Read Stata
df = pd.read_stata(r'D:\Desktop\MA Econ\Econ 562\Modernization\data\depcov_dataset.dta')


# Basic Variable
df["year"] = pd.to_numeric(df["year"])
month_map = {
    "January": 1, "February": 2, "March": 3, "April": 4,
    "May": 5, "June": 6, "July": 7, "August": 8,
    "September": 9, "October": 10, "November": 11, "December": 12
}


df["month_num"] = df["month"].map(month_map).astype(int)
df['age'] = df['age'].astype(int)
df['treat'] = ((df['age'] >= 19) & (df['age'] <= 25)).astype(float)
df["implement"] = (
    ((df["year"] == 2010) & (df["month_num"] >= 10)) |
    (df["year"] == 2011)
).astype(int)

df['pre'] = ((df['year'] < 2010) | ((df['year'] == 2010) & (df['month_num'] < 3)))


# Post-policy: Get the last observation
impl = (
    df[df['implement'] == 1]
    .sort_values(['groupid', 'year', 'month'])  
    .groupby('groupid')
    .last()
    .reset_index()
)


# Make outcome_pre_mean a control variable
'''
They are added to control for pre-treatment insurance levels, 
absorbing baseline differences across individuals 
that would otherwise confound the CATE estimates.

'''

pre_base = (
    df[df['pre'] == 1]
    .groupby('groupid')[['emphi_dep', 'anyhi', 'emphi']]
    .mean()
    .rename(columns=lambda c: c + '_pre_mean')
    .reset_index()
)
impl = impl.merge(pre_base, on='groupid', how='left')


# Fill in the gaps with the full sample mean for those without prior observation
for c in ['emphi_dep_pre_mean', 'anyhi_pre_mean', 'emphi_pre_mean']:
    impl[c] = impl[c].fillna(impl[c].mean())


# fpl_ratio: 6 Groups (According ACA policy threshold)
impl['fpl_group'] = pd.cut(
    impl['fpl_ratio'],
    bins   = [-np.inf, 1.0, 1.33, 2.0, 3.0, 4.0, np.inf],
    labels = [1, 2, 3, 4, 5, 6]
).astype(int)  # 1=<100%FPL  2=100-133%  3=133-200%  4=200-300%  5=300-400%  6=>400%

impl['ue_disc'] = pd.qcut(impl['ue'], q=10, labels=False, duplicates='drop') + 1


# Step 4: Choose columns
X_vars = [
    'age', 'female', 'white', 'black', 'asian',  'hispanic', 'mar', 'student',
    'fpl_group', 'st_with_law', 'ue_disc', 'live_wparent', 'fpl_ratio', 'bad_hlth',
    'hsg', 'somcol', 'colgrd', 'hsdo',
    'emphi_dep_pre_mean', 'anyhi_pre_mean', 'ue'
]

keep = X_vars + [
    'treat', 'emphi_dep', 'anyhi', 'indiv', 'emphi',
    'p_weight', 'fipstate', 'groupid'
]

# Save
out = impl[keep].dropna()
out.to_csv('D:\Desktop\MA Econ\Econ 562\Modernization\data\cross-sectional.csv', index=False)


