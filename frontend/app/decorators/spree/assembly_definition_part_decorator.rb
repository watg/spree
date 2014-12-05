class Spree::AssemblyDefinitionPartDecorator < Draper::Decorator
  delegate_all

  def product_options
    @product_options ||= Spree::ProductOptionsPresenter.new(object, h, {currency: current_currency, target: target})
  end

  def current_currency
    context[:current_currency] || Spree::Config[:currency]
  end

  def target
    context[:target]
  end

  def memoized_variant_options_tree
    @variant_options_tree ||= product_options.variant_tree.to_json
  end

  def memoized_simple_variant_options_tree
    @memoized_simple_variant_options_tree ||= product_options.simple_variant_tree.to_json
  end

  def memoized_grouped_option_values
    @targeted_grouped_option_values ||= product_options.grouped_option_values_in_stock
  end

  def url
     #api_assembly_definition_part_variants_path(id: self.id)
    "/api/assembly_definition_parts/#{self.id}/variants"
  end

end


