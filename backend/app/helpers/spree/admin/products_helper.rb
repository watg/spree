module Spree
  module Admin
    module ProductsHelper
      def taxon_options_for(product)
        options = @taxons.map do |taxon|
          selected = product.taxons.include?(taxon)
          content_tag(:option,
                      :value    => taxon.id,
                      :selected => ('selected' if selected)) do
            (taxon.ancestors.pluck(:name) + [taxon.name]).join(" -> ")
          end
        end.join("").html_safe
      end

      def option_types_options_for(product)
        options = @option_types.map do |option_type|
          selected = product.option_types.include?(option_type)
          content_tag(:option,
                      :value    => option_type.id,
                      :selected => ('selected' if selected)) do
            option_type.name
          end
        end.join("").html_safe
      end

      def link_to_add_description_fields(name, f, association)
        new_object = f.object.send(association).klass.new
        id = new_object.object_id
        fields = f.fields_for(association, new_object, child_index: id) do |builder|
          render(association.to_s.singularize + "_fields", f: builder)
        end
        link_to_with_icon('icon-plus', name, '#', class: 'add_fields button', data: {id: id, fields: fields.gsub("\n", "")})
      end

    end
  end
end
