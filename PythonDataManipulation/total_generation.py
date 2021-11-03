import pandas as pd
import csv

#This file is specifically created to include the total generation of several units as a flat generation profile in the eventual model.
#This is done by obtaining the total yearly generation from the TYNDP datafile.

#Read input data from main file
df_gen = pd.read_excel(io = "../Input Data/TYNDP-2020-Scenario-Datafile.xlsx",engine = 'openpyxl',sheet_name= "MarketRun" )


#Rename column in the generator dataframe
df_gen = df_gen.rename(columns={"Node/Line" : "Node"})
df_gen = df_gen[df_gen["Parameter"]== "Generation"]


# And create dictionaries for mapping the unit names to generator types
df_gen_dict_TYNDP = pd.read_excel(io = "../Input Data/TYNDP-2020-Scenario-Datafile.xlsx",engine = 'openpyxl',sheet_name= "Generators - Dict" )
gen_dict_TYNDP = dict(zip(df_gen_dict_TYNDP.Unit,df_gen_dict_TYNDP.Generator))


df_gen_dict_own = pd.read_excel(io = "../Input Data/Mapping_generators.xlsx",engine = 'openpyxl',sheet_name= "Mapping" )
gen_dict_own = dict(zip(df_gen_dict_own.Generator_ID,df_gen_dict_own.Mapped_to))

#First, we map the TYNDP unit names (used for total generation reporting) to TYNDP generator_ID's (used for capacities)
df_gen_mapped = df_gen.replace(gen_dict_TYNDP)
#Next, from TYNDP generator_ID's to the types used in the model
df_gen_mapped_2 = df_gen_mapped.replace(gen_dict_own)

#Finally, we add the super types
gen_dict_st = dict(zip(df_gen_dict_own.Mapped_to,df_gen_dict_own.Super_type))
df_gen_mapped_2['Super_type'] = df_gen_mapped_2['Generator_ID'].replace(gen_dict_st)

#And keep only the ones that are supposed to have a flat profile
df_gen_mapped_2 = df_gen_mapped_2[df_gen_mapped_2["Super_type"]== "Flat"]

df_gen_mapped.to_csv("../Input Data/gen_prod.csv")

