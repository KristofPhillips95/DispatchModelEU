import pandas as pd

scenario = "DistributedEnergy"
year = 2040
CY = 1984
df_demand = pd.DataFrame()

#xls_dem = pd.ExcelFile(io = f"../Input Data/Demand_time_series/Demand_TimeSeries_{year}_{scenario}.xlsx",engine = 'openpyxl')
xls_dem = pd.ExcelFile(io = f"../Input Data/Demand_time_series/WeTransfer Dante load 14.10.2020/Demand_TimeSeries_{year}_{scenario} (Complete 15-08-2019).xlsx",engine = 'openpyxl')
counter = 0
for sheet_name in xls_dem.sheet_names:
    print(counter)
    df_sheet = pd.read_excel(xls_dem, sheet_name)
    row_number = df_sheet[df_sheet.iloc[:, 0] == "Date"].first_valid_index()
    date_row = df_sheet.iloc[row_number].reset_index(drop = True)
    col_index_for_CY = date_row[date_row == CY].first_valid_index()
    df_demand[sheet_name] = df_sheet.iloc[row_number+1:row_number+8761,col_index_for_CY]
    counter += 1

df_demand.to_csv(f"../Input Data/time_series_output/Demand_{year}_{scenario}_{CY}.csv")

