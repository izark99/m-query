let
    Source = Table.NestedJoin(#"Cost Code", {"Key"}, Unit, {"Key"}, "Unit", JoinKind.FullOuter),
    #"Expanded Unit" = Table.ExpandTableColumn(Source, "Unit", #"Keep Column Form02", #"Keep Column Form02"),
    #"Added Budget Code" = Table.AddColumn(#"Expanded Unit", "Budget Code", each Record.FieldOrDefault(_,[Group], null), Text.Type),
    #"Removed Other Columns 01" = Table.SelectColumns(#"Added Budget Code",{"Budget Code", "Helper", "Unit"}),
    #"Merged Queries 01" = Table.NestedJoin(#"Removed Other Columns 01", {"Unit"}, #"Definition 01", {"Mã bộ phận"}, "Definition 01", JoinKind.LeftOuter),
    #"Expanded Definition 01" = Table.ExpandTableColumn(#"Merged Queries 01", "Definition 01", {"TTCP", "Dept"}, {"Cost Center Temp", "Dept"}),
    #"Merged Queries 02" = Table.NestedJoin(#"Expanded Definition 01", {"Unit", "Helper", "Budget Code"}, Form01, {"Unit", "Helper", "Budget Code"}, "Form01", JoinKind.LeftOuter),
    #"Expanded Form01" = Table.ExpandTableColumn(#"Merged Queries 02", "Form01", {"Attribute", "Value"}, {"Attribute", "Value"}),
    #"Filtered Rows Cost" = Table.SelectRows(#"Expanded Form01", each ([Attribute] <> null)),
    #"Merged Queries 03" = Table.NestedJoin(#"Filtered Rows Cost", {"Helper"}, #"Definition 02", {"Helper"}, "Definition 02", JoinKind.LeftOuter),
    #"Expanded Definition 02" = Table.ExpandTableColumn(#"Merged Queries 03", "Definition 02", {"Tên chi phí"}, {"Tên chi phí"}),
    #"Added Type" = Table.AddColumn(#"Expanded Definition 02", "Type", each Text.Middle([Helper],4,1), Text.Type),
    #"Replaced Value" = Table.ReplaceValue(#"Added Type","","M",Replacer.ReplaceValue,{"Type"}),
    #"Added Item" = Table.AddColumn(#"Replaced Value", "Item", each if [Type] = "H" then _h &"."&_year else 
if [Type] = "Q" then _q &"."&_year else 
if [Type] = "M" then _m &"."&_year else _year, type text),
    #"Added Description" = Table.AddColumn(#"Added Item", "Description", each if [Helper] = "0407M_SC" then
"Chi "&_vn&"_"&[Item]&"_"&[Dept]&"-"&[Unit]&" (SCIC)" 
else if [Unit] ="HRD" then 
"Chi "&_vn&"_"&[Item]&"_"&[Dept]&"-"&[Unit]&" (TV HĐQT không điều hành)" 
else
"Chi "&_vn&"_"&[Item]&"_"&[Dept]&"-"&[Unit], type text),
    #"Pivoted Column" = Table.Pivot(#"Added Description", List.Distinct(#"Added Description"[Attribute]), "Attribute", "Value", List.Sum),
    #"Renamed Columns" = Table.RenameColumns(#"Pivoted Column",{{"Tổng lãnh", "Total Gross Amount Received"}, {"Thuế TN", "PIT"}, {"Trừ khác", "Other Deduction"}, {"Thực lãnh", "Total Net Amount Received"}}),
    #"Removed Other Columns 02" = Table.SelectColumns(#"Renamed Columns",{"Description", "Budget Code", "Helper", "Unit", "Cost Center Temp", "Dept", "Total Gross Amount Received", "PIT", "Other Deduction", "Total Net Amount Received"}),
    #"Sorted Rows" = Table.Sort(#"Removed Other Columns 02",{{"Dept", Order.Ascending}, {"Unit", Order.Ascending}, {"Cost Center Temp", Order.Ascending}, {"Budget Code", Order.Ascending}, {"Helper", Order.Ascending}}),
    #"Added Cost Code" = Table.AddColumn(#"Sorted Rows", "Cost Code", each Text.Start([Helper],4), Text.Type),
    #"Replaced Value null" = Table.ReplaceValue(#"Added Cost Code",null,0,Replacer.ReplaceValue,{"Total Gross Amount Received"}),
    #"Added Check" = Table.AddColumn(#"Replaced Value null", "Check", each if [Total Gross Amount Received] = 0 then true else false, type logical),
    #"Filtered Rows" = Table.SelectRows(#"Added Check", each ([Check] = false)),
    #"Removed Columns" = Table.RemoveColumns(#"Filtered Rows",{"Check"}),
    #"Added Cost Center" = Table.AddColumn(#"Removed Columns", "Cost Center", each if [Helper] = "0407M_BD" or [Helper] = "0407M_SC" then "BD" else
if [Helper] = "0614" then "LSF" else [Cost Center Temp]),
    #"Removed Columns Cost Center Temp" = Table.RemoveColumns(#"Added Cost Center",{"Cost Center Temp"}),
    #"Merged Queries" = Table.NestedJoin(#"Removed Columns Cost Center Temp", {"Unit"}, #"Definition 01", {"Mã bộ phận"}, "Definition 01", JoinKind.LeftOuter),
    #"Expanded Definition 1" = Table.ExpandTableColumn(#"Merged Queries", "Definition 01", {"SB/WH"}, {"SB/WH"}),
    #"Added Sector" = Table.AddColumn(#"Expanded Definition 1", "Sector", each if [#"SB/WH"] = "DHG" then "DHG" else if [#"SB/WH"] = "WH" then "KBH" else "KBH", type text),
    #"Removed Columns SB/WH" = Table.RemoveColumns(#"Added Sector",{"SB/WH"}),
    #"Added Index" = Table.AddIndexColumn(#"Removed Columns SB/WH", "No", 1, 1, Int64.Type),
    #"Reordered Columns" = Table.ReorderColumns(#"Added Index",{"No", "Sector", "Dept", "Unit", "Budget Code", "Cost Center", "Cost Code", "Helper", "Description", "Total Gross Amount Received", "PIT", "Other Deduction", "Total Net Amount Received"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Reordered Columns",{{"No", Int64.Type}, {"Dept", type text}, {"Unit", type text}, {"Budget Code", type text}, {"Cost Center", type text}, {"Cost Code", type text}, {"Helper", type text}, {"Description", type text}, {"Total Gross Amount Received", Int64.Type}, {"PIT", Int64.Type}, {"Other Deduction", Int64.Type}, {"Total Net Amount Received", Int64.Type}})
in
    #"Changed Type"
