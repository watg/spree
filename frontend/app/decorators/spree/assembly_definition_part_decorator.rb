class Spree::AssemblyDefinitionPartDecorator < Draper::Decorator
  delegate_all

  def current_currency
    context[:current_currency] || Spree::Config[:currency]
  end

  def target
    context[:target]
  end

  def memoized_variant_options_tree
    @_variant_options_tree ||= {}
    @_variant_options_tree[current_currency] ||= object.variant_options_tree_for(current_currency)
  end

  def memoized_grouped_option_values
    @_memoized_grouped_option_values ||= object.grouped_option_values
  end

  def url
     #api_assembly_definition_part_variants_path(id: self.id)
    "/shop/api/assembly_definition_parts/#{self.id}/variants"
  end 

end


