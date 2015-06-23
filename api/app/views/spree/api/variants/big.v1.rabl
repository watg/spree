object @variant
attributes *variant_attributes

cache [I18n.locale, @current_user_roles.include?('admin'), 'big_variant', root_object]

extends "spree/api/variants/small"

node :total_on_hand do
  root_object.total_on_hand
end

child(:stock_items => :stock_items) do
  attributes :id, :count_on_hand, :stock_location_id, :backorderable
  attribute :available? => :available

  glue(:stock_location) do
    attribute :name => :stock_location_name
  end
end

child(@object.product_parts => :product_parts) do
  node(:url) { |pp| api_product_part_variants_path(pp) }
  attributes :presentation, :name, :optional, :url
end
