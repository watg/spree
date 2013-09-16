module Spree
  class UpdateTaxonPositionService < Mutations::Command
    required do
      integer :taxon_id
      integer :parent_id
      integer :position
    end

    def execute
      insert_taxon_in_order_list(parent_id, taxon_id, position)
    rescue Exception => e
      add_error(:taxon, :could_not_update, e.message)
    end

    private
    def insert_taxon_in_order_list(parent_id, taxon_id, position)
      taxons = Spree::Taxon.where(parent_id: parent_id).order('position').all
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
