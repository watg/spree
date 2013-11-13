module Spree
  class Personalisation < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :product, class_name: 'Spree::Product'
    has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::Image"
    has_many :line_item_personalisations, class_name: "Spree::LineItemPersonalisation"

    def name
      self.class.name.split('::').last.downcase
    end

    def price_in(currency)
      BigDecimal prices[currency]
    end

    def subunit_price_in(currency)
      price_in(currency) * 100
    end

  end
end
 
