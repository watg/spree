module Spree
  module SuiteTabsHelper

    def link_to_add_suite_tab_fields(name, f, association)
      new_object = f.object.send(association).klass.new
      id = new_object.object_id
      fields = f.fields_for(association, new_object, child_index: id) do |builder|
        render(association.to_s.singularize + "_fields", f: builder)
      end
      link_to_with_icon('icon-plus', name, '#', class: 'add_tab button', data: {id: id, fields: fields.gsub("\n", "")})
    end

  end
end

