class Spree::AssemblyDefinitionPartDecorator < Draper::Decorator
  delegate_all

  def variant_options
    @variant_options ||= Spree::VariantOptions.new(object.variants, current_currency)
  end

  def current_currency
    context[:current_currency] || Spree::Config[:currency]
  end

  def target
    context[:target]
  end

  def memoized_variant_options_tree
    @variant_options_tree ||= variant_options.tree
  end

  def memoized_grouped_option_values
    @grouped_option_values ||= variant_options.grouped_option_values_in_stock
  end

  def url
     #api_assembly_definition_part_variants_path(id: self.id)
    "/api/assembly_definition_parts/#{self.id}/variants"
  end

end


