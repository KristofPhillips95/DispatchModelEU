import pandas as pd
import csv

import os
#Read input data from main file
df_gen = pd.read_excel(io = "../Input Data/TYNDP-2020-Scenario-Datafile.xlsx",engine = 'openpyxl',sheet_name= "Capacity" )
df_lines = pd.read_excel(io = "../Input Data/TYNDP-2020-Scenario-Datafile.xlsx",engine = 'openpyxl',sheet_name= "Line" )

#Rename column in the generator dataframe
df_gen = df_gen.rename(columns={"Node/Line" : "Node"})

###
#Creating file with all generator present in dataset, and their total capacities
####
generators = set(df_gen["Generator_ID"])
gen_cap_dict = {generator : sum(df_gen[ (df_gen["Generator_ID"] == generator) & (df_gen["Year"] == 2030) ].Value)/1000 for generator in generators}
df_generator_id = pd.DataFrame.from_dict(gen_cap_dict, orient= 'index')
df_generator_id.to_csv("../Input Data/list_of_generators_2030.csv")
######

df_gen_dict = pd.read_excel(io = "../Input Data/Mapping_generators.xlsx",engine = 'openpyxl',sheet_name= "Mapping" )

gen_dict = dict(zip(df_gen_dict.Generator_ID,df_gen_dict.Mapped_to))
gen_dict_st = dict(zip(df_gen_dict.Mapped_to,df_gen_dict.Super_type))

df_gen_mapped = df_gen.replace(gen_dict)

df_gen_mapped = df_gen_mapped[df_gen_mapped["Generator_ID"]!= "NI"]
df_gen_mapped['Super_type'] = df_gen_mapped['Generator_ID'].replace(gen_dict_st)


df_gen['Super_type'] = df_gen['Generator_ID'].replace(gen_dict_st)


#Create sets of nodes, lines, and generators
nodes_all = set(df_gen["Node"])
nodes = set(df_gen_mapped["Node"])
connections = set(df_lines["Node/Line"])


df= df_lines['Node/Line'].apply(lambda x: pd.Series(x.split('-')))
df = df.rename(columns={0: "Node1",1: "Node2"})
df_lines["Node1"] = df.Node1
df_lines["Node2"] = df.Node2


df_lines = df_lines[(df_lines["Node1"].isin(nodes_all)) & (df_lines["Node2"].isin(nodes_all))]
df_lines_mapped = df_lines[(df_lines["Node1"].isin(nodes)) & (df_lines["Node2"].isin(nodes))]

df_gen.to_csv("../Input Data/gen_cap_all.csv")
df_gen_mapped.to_csv("../Input Data/gen_cap.csv")

df_lines.to_csv("../Input Data/lines_all.csv")
df_lines_mapped.to_csv("../Input Data/lines.csv")

