module Spree
  class AddIndexPageItemService < Mutations::Command
    
    required do
      integer :item_id
      string  :item_type
      duck    :index_page
    end
    
    def execute
      item = item_klass.find(item_id)
      index_page.items.create(item: item)
    rescue Exception => error
      add_error(:item, :item_error, error)
    end


    private
    def item_klass
      if item_type == "Spree::ProductPage"
        Spree::ProductPage
      else
        Spree::Variant
      end
    end
  end
end
