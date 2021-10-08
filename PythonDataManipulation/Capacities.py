import pandas as pd
import os

df_gen = pd.read_excel(io = "../Input Data/TYNDP-2020-Scenario-Datafile.xlsx",engine = 'openpyxl',sheet_name= "Capacity" )
df_lines = pd.read_excel(io = "../Input Data/TYNDP-2020-Scenario-Datafile.xlsx",engine = 'openpyxl',sheet_name= "Line" )

nodes = set(df_gen["Node/Line"])
generators = set(df_gen["Generator_ID"])
connections = set(df_lines["Node/Line"])

df_gen.to_csv("../Input Data/gen_cap.csv")
df_lines.to_csv("../Input Data/lines.csv")