module Spree
  class Taxonomy < ActiveRecord::Base
    ORDER = { 'Men' => 1, 'Women' => 0, 'Collections' => 2, 'Knit Your Own' => 3, 'Sales' => 4 }

    validates :name, presence: true

    attr_accessible :name

    has_many :taxons
    has_one :root, conditions: { parent_id: nil }, class_name: "Spree::Taxon",
                   dependent: :destroy

    after_save :set_name
    after_save :set_order

    default_scope order: "#{self.table_name}.position"

    def self.visible
      where(['name <> ?', 'HIDDEN'])
    end

    private
      def set_name
        if root
          root.update_column(:name, name)
        else
          self.root = Taxon.create!({ taxonomy_id: id, name: name }, without_protection: true)
        end
      end

      def set_order
        ORDER.each do |n,p| 
          t = Spree::Taxonomy.find_by_name(n)
          t.update_column(:position, p) if t 
        end
      end
  end
end
