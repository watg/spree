module Spree
  class UpdateTaxonPositionService < Mutations::Command
    required do
      duck :data
    end

    def execute
      taxon_id, position, parent_id = parse_data(data)
      selected_taxon = Spree::Taxon.find(taxon_id)
      selected_taxon.update_attributes(data)
      insert_taxon_in_order_list(parent_id, selected_taxon, position) unless position.blank?
    rescue Exception => e
      add_error(:taxon, :could_not_update, e.message)
    end

    private

    def parse_data(inputs)
      [inputs.delete(:taxon_id).to_i, inputs.delete(:position).to_i, inputs.delete(:parent_id).to_i]
    end

    def insert_taxon_in_order_list(parent_id, taxon_id, position)
      taxons = Spree::Taxon.where(parent_id: parent_id).order('position').to_a
      selected_taxon = Spree::Taxon.find(taxon_id)

      list_without_selected_taxon = taxons.reject {|t| t.id == selected_taxon.id}
      new_taxon_order_list = list_without_selected_taxon.insert(position, selected_taxon)
      new_taxon_order_list.each_with_index do |t,i|
        lft = (i+2)
        rgt = (i+3)
        p = i
        ActiveRecord::Base.connection.execute("UPDATE spree_taxons SET position = #{p}, lft=#{lft}, rgt=#{rgt} WHERE id= #{t.id}")
      end
    end
  end
end
