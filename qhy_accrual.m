let
    Source = Table.NestedJoin(#"Cost Code", {"Key"}, Unit, {"Key"}, "Unit", JoinKind.FullOuter),
    #"Expanded Unit" = Table.ExpandTableColumn(Source, "Unit", #"Keep Column Form02", #"Keep Column Form02"),
    #"Added Budget Code" = Table.AddColumn(#"Expanded Unit", "Budget Code", each Record.FieldOrDefault(_,[Group], null), Text.Type),
    #"Removed Other Columns 01" = Table.SelectColumns(#"Added Budget Code",{"Budget Code", "Helper", "Unit"}),
    #"Merged Queries 01" = Table.NestedJoin(#"Removed Other Columns 01", {"Unit"}, #"Definition 01", {"Mã bộ phận"}, "Definition 01", JoinKind.LeftOuter),
    #"Expanded Definition 01" = Table.ExpandTableColumn(#"Merged Queries 01", "Definition 01", {"TTCP", "Dept", "SB/WH"}, {"Cost Center", "Dept", "SB/WH"}),
    #"Merged Queries 02" = Table.NestedJoin(#"Expanded Definition 01", {"Unit", "Helper", "Budget Code"}, Form01, {"Unit", "Attribute", "Budget Code"}, "Form01", JoinKind.LeftOuter),
    #"Expanded Form01" = Table.ExpandTableColumn(#"Merged Queries 02", "Form01", {"Value"}, {"Accrual amount this period"}),
    #"Merged Queries 03" = Table.NestedJoin(#"Expanded Form01", {"Helper"}, #"Definition 02", {"Helper"}, "Definition 02", JoinKind.LeftOuter),
    #"Expanded Definition 02" = Table.ExpandTableColumn(#"Merged Queries 03", "Definition 02", {"Tên chi phí"}, {"Tên chi phí"}),
    #"Added Description" = Table.AddColumn(#"Expanded Definition 02", "Description", each [Tên chi phí]&"_"&_m&"."&_year&"_"&[Dept]&"-"&[Unit], Text.Type),
    #"Added Sector" = Table.AddColumn(#"Added Description", "Sector", each if [#"SB/WH"] = "DHG" then "DHG" else if [#"SB/WH"] = "WH" then "KBH" else "KBH", type text),
    #"Removed Other Columns 02" = Table.SelectColumns(#"Added Sector",{"Description", "Budget Code", "Helper", "Unit", "Cost Center", "Dept", "Accrual amount this period", "Sector"}),
    #"Sorted Rows" = Table.Sort(#"Removed Other Columns 02",{{"Dept", Order.Ascending}, {"Unit", Order.Ascending}, {"Cost Center", Order.Ascending}, {"Budget Code", Order.Ascending}, {"Helper", Order.Ascending}}),
    #"Added Cost Code" = Table.AddColumn(#"Sorted Rows", "Cost Code", each Text.Start([Helper],4), Text.Type),
    #"Replaced Value" = Table.ReplaceValue(#"Added Cost Code",null,0,Replacer.ReplaceValue,{"Accrual amount this period"}),
    #"Added Index" = Table.AddIndexColumn(#"Replaced Value", "No", 1, 1, Int64.Type),
    #"Reordered Columns" = Table.ReorderColumns(#"Added Index",{"No", "Sector", "Dept", "Unit", "Budget Code", "Cost Center", "Cost Code", "Helper", "Description", "Accrual amount this period"})
in
    #"Reordered Columns"
