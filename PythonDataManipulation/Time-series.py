import pandas as pd

#Offshore wind
xls_off = pd.ExcelFile(io = "../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Solar and Wind Data/PECD_2030_Offshore.xlsx",engine = 'openpyxl')
#xls_off2 = pd.ExcelFile(io = "../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Solar and Wind Data/PECD_2025_Offshore.xlsx",engine = 'openpyxl')

df_offshore =pd.DataFrame()
for sheet_name in xls_off.sheet_names:
    df_offshore[sheet_name] = pd.read_excel(xls_off, sheet_name).iloc[10:, 4]

df_offshore.to_csv("../Input Data/time_series_output/offshore.csv")

#Onshore wind

# xls_on = pd.ExcelFile(io = "../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Solar and Wind Data/PECD_2030_Onshore.xlsx",engine = 'openpyxl')
#
#
# df_onshore =pd.DataFrame()
# for sheet_name in xls_on.sheet_names:
#     df_onshore[sheet_name] = pd.read_excel(xls_on, sheet_name).iloc[10:, 4]
#
# df_onshore.to_csv("../Input Data/time_series_output/onshore.csv")


#PV

# xls_pv = pd.ExcelFile(io = "../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Solar and Wind Data/PECD_2030_PV.xlsx",engine = 'openpyxl')
#
#
# df_pv =pd.DataFrame()
# counter = 0
# for sheet_name in xls_pv.sheet_names:
#     print(counter)
#     df_pv[sheet_name] = pd.read_excel(xls_pv, sheet_name).iloc[10:, 4]
#     counter +=1
# df_pv.to_csv("../Input Data/time_series_output/pv.csv")