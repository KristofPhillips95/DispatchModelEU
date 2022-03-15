using Gurobi
using JSON3
##
scenario = "National Trends"
endtime = 24*10
year = 2025
CY_cap = 1984
CY_ts = 2012
VOLL = 8000
ty = 2025

m = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets!(m,scenario,year,CY_cap,[])
process_parameters!(m,scenario,year,CY_cap)
process_time_series!(m,scenario,year,CY_ts)

production_dict = JSON3.read(read(joinpath("soc_files","prod_$(ty)_$(CY_ts)_$(scenario)_8760.json"), String))


##
