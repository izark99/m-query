let
    Source = Table.NestedJoin(#"Cost Code", {"Key"}, Unit, {"Key"}, "Unit", JoinKind.FullOuter),
    #"Expanded Unit" = Table.ExpandTableColumn(Source, "Unit", #"Keep Column Form02", #"Keep Column Form02"),
    #"Added Budget Code" = Table.AddColumn(#"Expanded Unit", "Budget Code", each Record.FieldOrDefault(_,[Group], null), Text.Type),
    #"Removed Other Columns 01" = Table.SelectColumns(#"Added Budget Code",{"Budget Code", "Helper", "Unit"}),
    #"Merged Queries 01" = Table.NestedJoin(#"Removed Other Columns 01", {"Unit"}, #"Definition 01", {"Mã bộ phận"}, "Definition 01", JoinKind.LeftOuter),
    #"Expanded Definition 01" = Table.ExpandTableColumn(#"Merged Queries 01", "Definition 01", {"TTCP", "Dept"}, {"Cost Center", "Dept"}),
    #"Merged Queries 02" = Table.NestedJoin(#"Expanded Definition 01", {"Unit", "Helper", "Budget Code"}, Form01, {"Unit", "Attribute", "Budget Code"}, "Form01", JoinKind.LeftOuter),
    #"Expanded Form01" = Table.ExpandTableColumn(#"Merged Queries 02", "Form01", {"Value"}, {"Accrual amount this period"}),
    #"Merged Queries 03" = Table.NestedJoin(#"Expanded Form01", {"Helper"}, #"Definition 02", {"Helper"}, "Definition 02", JoinKind.LeftOuter),
    #"Expanded Definition 02" = Table.ExpandTableColumn(#"Merged Queries 03", "Definition 02", {"Tên chi phí"}, {"Tên chi phí"}),
    #"Added Type" = Table.AddColumn(#"Expanded Definition 02", "Type", each Text.Middle([Helper],4,1), Text.Type),
    #"Replaced Value" = Table.ReplaceValue(#"Added Type","","M",Replacer.ReplaceValue,{"Type"}),
    #"Added Item" = Table.AddColumn(#"Replaced Value", "Item", each if [Type] = "H" then _h &"."&_year else 
if [Type] = "Q" then _q &"."&_year else 
if [Type] = "M" then _m &"."&_year else ""),
    #"Added Description" = Table.AddColumn(#"Added Item", "Description", each [Tên chi phí]&"_"&[Item]&"_"&[Dept]&"-"&[Unit], Text.Type),
    #"Removed Other Columns 02" = Table.SelectColumns(#"Added Description",{"Description", "Budget Code", "Helper", "Unit", "Cost Center", "Dept", "Accrual amount this period"}),
    #"Sorted Rows" = Table.Sort(#"Removed Other Columns 02",{{"Dept", Order.Ascending}, {"Unit", Order.Ascending}, {"Cost Center", Order.Ascending}, {"Budget Code", Order.Ascending}, {"Helper", Order.Ascending}}),
    #"Added Cost Code" = Table.AddColumn(#"Sorted Rows", "Cost Code", each Text.Start([Helper],4), Text.Type),
    #"Replaced Value null" = Table.ReplaceValue(#"Added Cost Code",null,0,Replacer.ReplaceValue,{"Accrual amount this period"}),
    #"Added Check" = Table.AddColumn(#"Replaced Value null", "Check", each if [Accrual amount this period] = 0 then 
true else false, type logical),
    #"Filtered Rows" = Table.SelectRows(#"Added Check", each ([Check] = false)),
    #"Added Index" = Table.AddIndexColumn(#"Filtered Rows", "No", 1, 1, Int64.Type),
    #"Added adjusted amount last period" = Table.AddColumn(#"Added Index", "Adjusted amount last period", each 0, Int64.Type),
    #"Added actual accrual amount this period" = Table.AddColumn(#"Added adjusted amount last period", "Actual accrual amount this period", each [Accrual amount this period]-[Adjusted amount last period], Int64.Type),
    #"Removed Columns" = Table.RemoveColumns(#"Added actual accrual amount this period",{"Check"}),
    #"Merged Queries" = Table.NestedJoin(#"Removed Columns", {"Unit"}, #"Definition 01", {"Mã bộ phận"}, "Definition 01", JoinKind.LeftOuter),
    #"Expanded Definition 1" = Table.ExpandTableColumn(#"Merged Queries", "Definition 01", {"SB/WH"}, {"SB/WH"}),
    #"Added Sector" = Table.AddColumn(#"Expanded Definition 1", "Sector", each if [#"SB/WH"] = "DHG" then "DHG" else if [#"SB/WH"] = "WH" then "KBH" else "KBH", type text),
    #"Removed Columns SB/WH" = Table.RemoveColumns(#"Added Sector",{"SB/WH"}),
    #"Reordered Columns" = Table.ReorderColumns(#"Removed Columns SB/WH",{"No", "Sector", "Dept", "Unit", "Budget Code", "Cost Center", "Cost Code", "Helper", "Description", "Accrual amount this period", "Adjusted amount last period", "Actual accrual amount this period"})
in
    #"Reordered Columns"
