include("model_builder.jl")
using Gurobi
using Plots
#
# scenario = "National Trends"
# endtime = 24*20
# year = 2040
# CY = 1984
# VOLL = 1000
# CO2_price = 0.084
#
# m = Model(optimizer_with_attributes(Gurobi.Optimizer))
# define_sets!(m,scenario,year,CY)
# process_parameters!(m,scenario,year,CY)
# process_time_series!(m,scenario)
# build_NTC_model_DSR_shift!(m,endtime,VOLL,CO2_price,VOLL/10,0.25,VOLL/2)
# optimize!(m)
# soc_1 = JuMP.value.(m.ext[:variables][:soc])
# production = JuMP.value.(m.ext[:variables][:production])
# DSR_up = JuMP.value.(m.ext[:variables][:DSR_up])
# DSR_down = JuMP.value.(m.ext[:variables][:DSR_down])
#
#
# m2 = Model(optimizer_with_attributes(Gurobi.Optimizer))
# define_sets!(m2,scenario,year,CY)
# process_parameters!(m2,scenario,year,CY)
# process_time_series!(m2,scenario)
# remove_capacity_country(m2,"BE00")
# set_demand_country(m2,"BE00",1000)
# build_NTC_model_DSR_shift!(m2,endtime,VOLL,CO2_price,VOLL/10,0.25,VOLL/2)
# fix_soc_decisions(m2,soc_1,production,1:endtime,"BE00")
# fix_DSR_decisions(m2,DSR_up,DSR_down,1:endtime,"BE00")
# optimize!(m2)
# m2.ext[:constraints][:demand_met]["BE00",1]
# set_normalized_rhs(m2.ext[:constraints][:demand_met]["BE00",1],1500)
# country = "DE00"
# plot([sum(JuMP.value.(m.ext[:variables][:soc][country,tech,t] for tech in m.ext[:sets][:soc_technologies][country])) for t in 1:endtime])
# plot!([sum(JuMP.value.(m2.ext[:variables][:soc][country,tech,t] for tech in m2.ext[:sets][:soc_technologies][country])) for t in 1:endtime])
#
# country = "DE00"
# plot([sum(JuMP.value.(m.ext[:variables][:production][country,tech,t] for tech in m.ext[:sets][:soc_technologies][country])) for t in 1:endtime])
# plot!([sum(JuMP.value.(m2.ext[:variables][:production][country,tech,t] for tech in m2.ext[:sets][:soc_technologies][country])) for t in 1:endtime])

# plot([sum(JuMP.value.(m.ext[:variables][:DSR_up][country,t] )) for t in 1:endtime])
# plot!([sum(JuMP.value.(m2.ext[:variables][:DSR_up][country,t] )) for t in 1:endtime])
# [sum(JuMP.value.(m.ext[:variables][:DSR_up][country,t] )) for t in 1:endtime] == [sum(JuMP.value.(m2.ext[:variables][:DSR_up][country,t] )) for t in 1:endtime]
#
# country = "BE00"
# plot([JuMP.dual.(m.ext[:constraints][:demand_met][country,t]) for t in 1:endtime],right_margin = 18Plots.mm,label = "Price_ original")
# plot!([JuMP.dual.(m2.ext[:constraints][:demand_met][country,t]) for t in 1:endtime],right_margin = 18Plots.mm,label = "Price")

# JuMP.value.(m.ext[:variables][:production]["BE"])
# [sum(JuMP.value.(m2.ext[:variables][:import][country,nb,t] ) for nb in m.ext[:sets][:connections][country]) for t in 1:endtime]
# - [sum(JuMP.value.(m2.ext[:variables][:export][country,nb,t] ) for nb in m.ext[:sets][:connections][country]) for t in 1:endtime]
##
function check_equal_soc_for_all_but(m1,m2,country,endtime)
    countries = filter(e->e !=country,m1.ext[:sets][:countries])
    soc_technologies = m1.ext[:sets][:soc_technologies]
    for country in countries
        # print(country)
        for tech in m1.ext[:sets][:soc_technologies][country]
            soc_1 = [JuMP.value.(m1.ext[:variables][:soc][country,tech,t]) for t in 1:endtime]
            soc_2 = [JuMP.value.(m2.ext[:variables][:soc][country,tech,t]) for t in 1:endtime]
            @assert(soc_1 == soc_2)

            prod_soc_1  = [JuMP.value.(m1.ext[:variables][:production][country,tech,t]) for t in 1:endtime]
            prod_soc_1  = [JuMP.value.(m2.ext[:variables][:production][country,tech,t]) for t in 1:endtime]
            @assert(soc_1 == soc_2)

        end
    end
end

function check_net_import(m,country,import_level,endtime)
    net_import = [sum(JuMP.value.(m.ext[:variables][:import][country,nb,t]) - JuMP.value.(m.ext[:variables][:export][country,nb,t]) for nb in m.ext[:sets][:connections][country]) for t in 1:endtime]
    for t in 1:endtime
        @assert( round(net_import[t],digits = 5)  == import_level)
    end
end

function optimize_and_retain_intertemporal_decisions_DSR_shift(scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price,sheddable_fraction)
    m = Model(optimizer_with_attributes(Gurobi.Optimizer))
    define_sets!(m,scenario,year,CY)
    process_parameters!(m,scenario,year,CY)
    process_time_series!(m,scenario)
    build_NTC_model_DSR_shift!(m,endtime,VOLL,CO2_price,VOLL/10,sheddable_fraction,VOLL/2)
    optimize!(m)
    soc = JuMP.value.(m.ext[:variables][:soc])
    production = JuMP.value.(m.ext[:variables][:production])
    DSR_up = JuMP.value.(m.ext[:variables][:DSR_up])
    DSR_down = JuMP.value.(m.ext[:variables][:DSR_down])

    return m,soc,production,DSR_up,DSR_down
end

function optimize_and_retain_intertemporal_decisions_DSR_simple(scenario::String,year::Int,CY_cap::Int,CY_ts::Int,endtime::Int,VOLL::Int,DSR_price)
    #TODO This has to be implemented for DSR without shifting
    m = Model(optimizer_with_attributes(Gurobi.Optimizer))
    define_sets!(m,scenario,year,CY_cap,[])
    process_parameters!(m,scenario,year,CY_cap)
    process_time_series!(m,scenario,year,CY_ts)
    build_NTC_model_DSR!(m,endtime,VOLL,DSR_price,0.1)
    optimize!(m)
    soc = JuMP.value.(m.ext[:variables][:soc])
    production = JuMP.value.(m.ext[:variables][:production])
    return m, soc, production
end

function optimize_and_retain_intertemporal_decisions_no_DSR(scenario::String,year::Int,CY_cap::Int,CY_ts,endtime,VOLL)
    m = Model(optimizer_with_attributes(Gurobi.Optimizer))
    define_sets!(m,scenario,year,CY_cap,[])
    process_parameters!(m,scenario,year,CY_cap)
    process_time_series!(m,scenario,year,CY_ts)
    build_NTC_model!(m,endtime,VOLL,0.1)
    optimize!(m)
    soc = JuMP.value.(m.ext[:variables][:soc])
    production = JuMP.value.(m.ext[:variables][:production])

    return m,soc,production
end

function write_sparse_axis_to_dict(sparse_axis)
    dict =  Dict()
    for key in eachindex(sparse_axis)
        dict[key] = sparse_axis[key]
    end
    return dict
end

function build_model_for_import_curve_DSR_simple(m,import_level,country,endtime,soc,production,VOLL,DSR_price)
    # define_sets!(m,scenario,year,CY)
    # process_parameters!(m,scenario,year,CY)
    # process_time_series!(m,scenario)
    remove_capacity_country(m,country)
    set_demand_country(m,country,import_level)
    build_NTC_model_DSR!(m,endtime,VOLL,DSR_price,0)
    fix_soc_decisions(m,soc,production,1:endtime,country)
    optimize!(m)
    return m
end

function build_model_for_import_curve_no_DSR_from_dict(import_level,country,endtime,soc,production,transp_cost)
    m = Model(optimizer_with_attributes(Gurobi.Optimizer))
    define_sets!(m,scenario,year,CY_cap,[])
    process_parameters!(m,scenario,year,CY_cap)
    process_time_series!(m,scenario,year,CY_ts)
    remove_capacity_country(m,country)
    set_demand_country(m,country,import_level)
    build_NTC_model!(m,endtime,VOLL,transp_cost)
    fix_soc_decisions_from_dict(m,soc,production,1:endtime,country)
    #optimize!(m)
    return m
end

function build_model_for_import_curve_no_DSR(m,import_level,country,endtime,soc,production,transp_cost)
    # define_sets!(m,scenario,year,CY)
    # process_parameters!(m,scenario,year,CY)
    # process_time_series!(m,scenario)
    remove_capacity_country(m,country)
    set_demand_country(m,country,import_level)
    build_NTC_model!(m,endtime,VOLL,transp_cost)
    fix_soc_decisions(m,soc,production,1:endtime,country)
    #optimize!(m)
    return m
end

function change_import_level!(m,endtime,import_level)
    for t in 1:endtime
        set_normalized_rhs(m.ext[:constraints][:demand_met][country,t],import_level)
    end
end

function check_production_zero!(m,country,endtime)
    for t in 1:endtime
        for tech in m.ext[:sets][:technologies][country]
            @assert(JuMP.value.(m.ext[:variables][:production][country,tech,t]) == 0)
        end
    end
end

function check_convexitiy_of_prices(curve_dict, import_levels)
    levels = collect(import_levels)
    sort!(levels)
    for i in 1:length(levels)-1
        print(i)
        println(import_levels[i])
        p_low = round.(curve_dict[import_levels[i]],digits=5)
        p_high = round.(curve_dict[import_levels[i+1]],digits=5)
        bit_array = p_low .<= p_high
        @assert(sum(bit_array) == length(bit_array))
    end
end

function price_duration_curve(prices)
    levels = Set(prices)
    levels = sort(collect(levels))
    #levels = 0:10:250
    price_count_dict = Dict(level => count(x-> x >=level, prices) for level in levels)
    return price_count_dict
end

function write_prices(curve_dict,scenario,import_levels,file_name_ext)
    df_prices = DataFrame()

    for price in import_levels
        insertcols!(df_prices,1,string(price) => curve_dict[price])
    end
    CSV.write("Results\\import_price_curves$(scenario)_$(file_name_ext).csv",df_prices)
end
##

#Start by performing overall optimization
