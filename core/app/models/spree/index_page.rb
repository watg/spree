module Spree
  class IndexPage < ActiveRecord::Base
    has_many :items, class_name: 'Spree::IndexPageItem'
    has_many :index_page_items
    has_many :taxons, as: :page

    belongs_to :taxon
    validates_presence_of :name, :title, :permalink
    validates_uniqueness_of :name, :permalink

    accepts_nested_attributes_for :items, allow_destroy: true

    before_validation :set_permalink
    validates_format_of :permalink, :with => /\A[-a-z0-9_\/]+\Z/i

    private
    def set_permalink
      if self.permalink.blank? && self.name
        self.permalink = name.downcase.split(' ').map{|e| (e.blank? ? nil : e) }.compact.join('-')
      end
    end


  end
end
