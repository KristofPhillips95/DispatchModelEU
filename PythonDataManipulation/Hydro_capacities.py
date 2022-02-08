import pandas as pd
import os
import calendar
import datetime
list_of_files = os.listdir("../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/")

# df_energy_capacities = pd.DataFrame()
#
# ##Hydro energy capacities
# for file in list_of_files:
#     xls_hydro = pd.ExcelFile(io = f"../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/{file}",engine = 'openpyxl')
#     node = file[11:15]
#     df_row = pd.DataFrame()
#     df_info = pd.read_excel(xls_hydro,"General Info")
#
#     reservoir =  df_info[df_info["Technology"]== "Reservoir"]["Hydro Storage Size (GWh)"].iloc[0]
#     PS_O =  df_info[df_info["Technology"] == "Pump storage - Open Loop"]["Hydro Storage Size (GWh)"].iloc[0]
#     PS_C =  df_info[df_info["Technology"] == "Pump Storage - Closed Loop"]["Hydro Storage Size (GWh)"].iloc[0]
#     ROR =  df_info[df_info["Technology"] == "Run-of-River and pondage"]["Hydro Storage Size (GWh)"].iloc[0]
#     df_row = pd.DataFrame({"Node":[node],"ROR" : [ROR],"RES" : [reservoir], "PS_O" : [PS_O], "PS_C":[PS_C] })
#     df_energy_capacities = df_energy_capacities.append(df_row)
# df_energy_capacities = df_energy_capacities.multiply([1,1000,1000,1000,1000])
# df_energy_capacities.to_csv("../Input Data/hydro_capacities/energy_caps.csv")

CY = 2009
#CY = 1984
col_index_year = CY - 1981
# # # ROR flows
# counter = 0
# df_ror_flows = pd.DataFrame()
# for file in list_of_files[0:44]:
#     print(counter)
#     counter+=1
#     xls_hydro = pd.ExcelFile(io = f"../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/{file}",engine = 'openpyxl')
#     node = file[11:15]
#     df_flows = pd.read_excel(xls_hydro,"Run-of-River and pondage")
#     assert (df_flows.iloc[:,col_index_year].iloc[0] == CY)
#     column = df_flows.iloc[1:,col_index_year]
#
#     df_ror_flows[node] = column
# daily_range = pd.date_range(start=f"1/1/{CY}",end=f"31/12/{CY}",freq="d")
# df_ror_flows = df_ror_flows.iloc[0:len(daily_range)]
# df_ror_flows["Time_index"] = daily_range
# df_ror_flows = df_ror_flows.set_index("Time_index")
# df_ror_flows = df_ror_flows.resample("H").ffill().divide(24).multiply(1000).fillna(0)
# df_ror_flows = df_ror_flows.append( df_ror_flows.iloc[[-1]*23] ).fillna(0)
# df_ror_flows.to_csv(f"../Input Data/time_series_output/ROR_{CY}.csv")

#
# # #Reservoir flows
# counter = 0
# df_res_flows = pd.DataFrame()
# for file in list_of_files[0:44]:
#     print(counter)
#     counter+=1
#     xls_hydro = pd.ExcelFile(f"../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/{file}",engine = 'openpyxl')
#     node = file[11:15]
#     df_flows = pd.read_excel(xls_hydro,"Reservoir")
#     assert (df_flows.iloc[:,col_index_year].iloc[0] == CY)
#     column = df_flows.iloc[1:,col_index_year]
#
#     df_res_flows[node] = column
# #df_res_flows = df_res_flows.drop(54)
# weekly_range = pd.date_range(start=f"01/01/{CY}",periods=53,freq=pd.tseries.offsets.DateOffset(weeks=1))
# df_res_flows["Time_index"] = weekly_range
# df_res_flows = df_res_flows.set_index("Time_index")
# df_res_flows = df_res_flows.resample("H").ffill().divide(24*7).multiply(1000)
# if calendar.isleap(CY):
#     df_res_flows.drop(df_res_flows.tail(1).index, inplace=True)
#     df_res_flows = df_res_flows.append(df_res_flows.iloc[[-1] * ((24*2))]).fillna(0)
# else:
#     df_res_flows.drop(df_res_flows.tail(1).index, inplace=True)
#     df_res_flows = df_res_flows.append( df_res_flows.iloc[[-2]*(24)] ).fillna(0)
# df_res_flows.to_csv(f"../Input Data/time_series_output/RES_{CY}.csv")

#################
#PS open flows
#################
counter = 0
df_ps_flows = pd.DataFrame()
for file in list_of_files[0:44]:
    print(counter)
    counter+=1
    xls_hydro = pd.ExcelFile(f"../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/{file}",engine = 'openpyxl')
    node = file[11:15]
    df_flows = pd.read_excel(xls_hydro,"Pump storage - Open Loop")
    assert (df_flows.iloc[:,col_index_year].iloc[0] == CY)
    column = df_flows.iloc[1:,col_index_year]

    df_ps_flows[node] = column
weekly_range = pd.date_range(start=f"01/01/{CY}",periods=53,freq=pd.tseries.offsets.DateOffset(weeks=1))
df_ps_flows["Time_index"] = weekly_range
df_ps_flows = df_ps_flows.set_index("Time_index")
df_ps_flows = df_ps_flows.resample("H").ffill().divide(24*7).multiply(1000)
if calendar.isleap(CY):
    df_ps_flows.drop(df_ps_flows.tail(1).index, inplace=True)
    df_ps_flows = df_ps_flows.append(df_ps_flows.iloc[[-1] * ((24*2))]).fillna(0)
else:
    df_ps_flows.drop(df_ps_flows.tail(1).index, inplace=True)
    df_ps_flows = df_ps_flows.append( df_ps_flows.iloc[[-2]*(24)] ).fillna(0)
df_ps_flows.to_csv(f"../Input Data/time_series_output/PS_O_{CY}.csv")

# #PS closed flows
# counter = 0
# df_ps_flows = pd.DataFrame()
# for file in list_of_files[0:44]:
#     print(counter)
#     counter+=1
#     xls_hydro = pd.ExcelFile(io = f"../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/{file}",engine = 'openpyxl')
#     node = file[11:15]
#     df_flows = pd.read_excel(xls_hydro,"Pump Storage - Closed Loop")
#     assert (df_flows.iloc[:,col_index_year].iloc[0] == CY)
#     column = df_flows.iloc[1:,col_index_year]
#
#     df_ps_flows[node] = column
# df_ps_flows = df_ps_flows.drop(54)
# weekly_range = pd.date_range(start=f"1/1/{CY}",end=f"31/12/{CY}",freq="w")
# df_ps_flows["Time_index"] = weekly_range
# df_ps_flows = df_ps_flows.set_index("Time_index")
# df_ps_flows = df_ps_flows.resample("H").ffill().divide(24*7).multiply(1000)
# df_ps_flows = df_ps_flows.append(df_ps_flows.iloc[[-1]*24] ).fillna(0)
#
# df_ps_flows.to_csv(f"../Input Data/time_series_output/PS_C_{CY}.csv")