object @assembly_definition
cache [@assembly_definition,:out_of_stock_option_values], expires_in: 1.minute

attributes :id

node(:parts) do |ad|
  ad.selected_variants_out_of_stock_option_values
end
