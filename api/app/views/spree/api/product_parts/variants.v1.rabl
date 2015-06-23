object @product_part
attributes :id

child :variants => :variants do
    attributes :id, :options_text
end
