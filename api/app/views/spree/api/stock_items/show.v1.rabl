object @stock_item
attributes *stock_item_attributes
child(:supplier) do
  extends "spree/api/suppliers/show"
end
child(:variant) do
  extends "spree/api/variants/small"
end
