import pandas as pd
import os
import datetime
list_of_files = os.listdir("../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/")

df_energy_capacities = pd.DataFrame()

##Hydro energy capacities
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
#     df_row = pd.DataFrame({"Node":[node],"ROR" : [ROR],"Reservoir" : [reservoir], "PS_O" : [PS_O], "PS_C":[PS_C] })
#     df_energy_capacities = df_energy_capacities.append(df_row)
# df_energy_capacities.to_csv("../Input Data/hydro_capacities/energy_caps.csv")

#ROR flows
# counter = 0
# df_ror_flows = pd.DataFrame()
# for file in list_of_files:
#     print(counter)
#     counter+=1
#     xls_hydro = pd.ExcelFile(io = f"../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/{file}",engine = 'openpyxl')
#     node = file[11:15]
#     df_flows = pd.read_excel(xls_hydro,"Run-of-River and pondage")
#     assert (df_flows.iloc[:,3].iloc[0] == 1984)
#     column = df_flows.iloc[1:,3]
#
#     df_ror_flows[node] = column
# daily_range = pd.date_range(start="1/1/1984",end="31/12/1984",freq="d")
# df_ror_flows["Time_index"] = daily_range
# df_ror_flows = df_ror_flows.set_index("Time_index")
# df_ror_flows = df_ror_flows.resample("H").ffill().divide(24).multiply(1000)
# df_ror_flows.to_csv("../Input Data/time_series_output/ROR.csv")


#Reservoir flows
# counter = 0
# df_res_flows = pd.DataFrame()
# for file in list_of_files:
#     print(counter)
#     counter+=1
#     xls_hydro = pd.ExcelFile(io = f"../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/{file}",engine = 'openpyxl')
#     node = file[11:15]
#     df_flows = pd.read_excel(xls_hydro,"Reservoir")
#     assert (df_flows.iloc[:,3].iloc[0] == 1984)
#     column = df_flows.iloc[1:,3]
#
#     df_res_flows[node] = column
# df_res_flows = df_res_flows.drop(54)
# weekly_range = pd.date_range(start="1/1/1984",end="31/12/1984",freq="w")
# df_res_flows["Time_index"] = weekly_range
# df_res_flows = df_res_flows.set_index("Time_index")
# df_res_flows = df_res_flows.resample("H").ffill().divide(24*7).multiply(1000)
# df_res_flows = df_res_flows.append( df_res_flows.iloc[[-1]*24] )
# df_res_flows.to_csv("../Input Data/time_series_output/RES.csv")

#PS open flows
counter = 0
df_ps_flows = pd.DataFrame()
for file in list_of_files:
    print(counter)
    counter+=1
    xls_hydro = pd.ExcelFile(io = f"../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Hydro data/{file}",engine = 'openpyxl')
    node = file[11:15]
    df_flows = pd.read_excel(xls_hydro,"Pump storage - Open Loop")
    assert (df_flows.iloc[:,3].iloc[0] == 1984)
    column = df_flows.iloc[1:,3]

    df_ps_flows[node] = column
df_ps_flows = df_ps_flows.drop(54)
weekly_range = pd.date_range(start="1/1/1984",end="31/12/1984",freq="w")
df_ps_flows["Time_index"] = weekly_range
df_ps_flows = df_ps_flows.set_index("Time_index")
df_ps_flows = df_ps_flows.resample("H").ffill().divide(24*7).multiply(1000)
df_ps_flows = df_ps_flows.append( df_ps_flows.iloc[[-1]*24] )
df_ps_flows.to_csv("../Input Data/time_series_output/PS.csv")