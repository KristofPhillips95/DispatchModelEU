import pandas as pd

CY = 1984
def getIndexes(dfObj, value):
    ''' Get index positions of value in dataframe i.e. dfObj.'''
    listOfPos = list()
    # Get bool dataframe with True at positions where the given value exists
    result = dfObj.isin([value])
    # Get list of columns that contains the value
    seriesObj = result.any()
    columnNames = list(seriesObj[seriesObj == True].index)
    # Iterate over list of columns and fetch the rows indexes where value exists
    for col in columnNames:
        rows = list(result[col][result[col] == True].index)
        for row in rows:
            listOfPos.append((row, col))
    # Return a list of tuples indicating the positions of value in the dataframe
    return listOfPos

#Offshore wind
# xls_off = pd.ExcelFile(io = "../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Solar and Wind Data/PECD_2030_Offshore.xlsx",engine = 'openpyxl')
#xls_off2 = pd.ExcelFile(io = "../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Solar and Wind Data/PECD_2025_Offshore.xlsx",engine = 'openpyxl')

# df_offshore = pd.DataFrame()
# for sheet_name in xls_off.sheet_names:
#     sheet_frame = pd.read_excel(xls_off, sheet_name)
#     year_selection = sheet_frame.loc[getIndexes(sheet_frame, CY)[0][0] + 1:, getIndexes(sheet_frame, CY)[0][1]]
#     df_offshore[sheet_name] = year_selection
#
# df_offshore.to_csv(f"../Input Data/time_series_output/offshore_{CY}.csv")

#Onshore wind

# xls_on = pd.ExcelFile(io = "../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Solar and Wind Data/PECD_2030_Onshore.xlsx",engine = 'openpyxl')
#
#
# df_onshore =pd.DataFrame()
# for sheet_name in xls_on.sheet_names:
#     sheet_frame = pd.read_excel(xls_on, sheet_name)
#     year_selection = sheet_frame.loc[getIndexes(sheet_frame, CY)[0][0] + 1:, getIndexes(sheet_frame, CY)[0][1]]
#     df_onshore[sheet_name] = year_selection
#
# df_onshore.to_csv(f"../Input Data/time_series_output/onshore_{CY}.csv")


#PV

xls_pv = pd.ExcelFile(io = "../Input Data/Pan-European Climate Database (1)/Pan-European Climate Database/Solar and Wind Data/PECD_2030_PV.xlsx",engine = 'openpyxl')


df_pv =pd.DataFrame()
counter = 0
for sheet_name in xls_pv.sheet_names:
    print(counter)
    sheet_frame = pd.read_excel(xls_pv, sheet_name)

    year_selection = sheet_frame.loc[getIndexes(sheet_frame, CY)[0][0] + 1:, getIndexes(sheet_frame, CY)[0][1]]
    df_pv[sheet_name] = year_selection
    counter +=1
df_pv.to_csv(f"../Input Data/time_series_output/pv_{CY}.csv")