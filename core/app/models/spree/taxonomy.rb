module Spree
  class Taxonomy < ActiveRecord::Base
    acts_as_paranoid

    validates :name, presence: true

    has_many :taxons
    has_one :root, -> { where parent_id: nil }, class_name: "Spree::Taxon", dependent: :destroy

    after_save :set_name

    default_scope -> { order("#{self.table_name}.position") }

    def self.visible
      where(['name <> ?', 'HIDDEN'])
    end

    private
    def set_name
      if root
        root.update_column(:name, name)
      else
        self.root = Taxon.create!(taxonomy_id: id, name: name)
      end
    end

  end
end
