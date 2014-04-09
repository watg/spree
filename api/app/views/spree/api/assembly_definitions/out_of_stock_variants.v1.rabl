object @assembly_definition
cache @assembly_definition, expires_in: 1.minute

attributes :id

node(:parts) do |ad|
  ad.selected_variants_out_of_stock
end
#
