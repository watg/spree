object @assembly_definition
attributes :id

node(:parts) do |ad|
  ad.selected_variants_out_of_stock
end
