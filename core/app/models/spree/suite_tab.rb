module Spree
  class SuiteTab < ActiveRecord::Base
    acts_as_paranoid
    acts_as_list

    DEFAULT_PRESENTATION = 'GET IT!'
    DEFAULT_PARTIAL = 'default'

    # please ensure that they are url-safe
    TAB_TYPES = {
      'knit-your-own' => ['KNIT YOUR OWN', 'knit_your_own'],
      'made-by-the-gang' => ['MADE BY THE GANG',DEFAULT_PARTIAL],
      'gift-voucher' => [DEFAULT_PRESENTATION, DEFAULT_PARTIAL],
      'knitting-pattern' => [DEFAULT_PRESENTATION, DEFAULT_PARTIAL],
      'yarn-and-wool' => [DEFAULT_PRESENTATION, DEFAULT_PARTIAL],
      'knitting-supply' => [DEFAULT_PRESENTATION, DEFAULT_PARTIAL],
      'default' => [DEFAULT_PRESENTATION, DEFAULT_PARTIAL],
    }

    belongs_to :suite, inverse_of: :tabs, touch: true
    belongs_to :product, inverse_of: :suite_tabs, class_name: "Spree::Product"
    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::SuiteTabImage"

    accepts_nested_attributes_for :image, allow_destroy: true

    validates_uniqueness_of :position, scope: [:suite_id, :deleted_at]
    validates_uniqueness_of :tab_type, scope: [:suite_id, :deleted_at]

    validates :product_id, :suite_id, presence: true

    store_accessor :lowest_amounts_cache

    def self.tab_types
      TAB_TYPES.keys
    end

    def presentation
      TAB_TYPES[tab_type].first
    end

    def partial
      TAB_TYPES[tab_type].last
    end

    def set_lowest_normal_amount(amount, currency)
      key = lowest_normal_amount_key(currency)
      self.lowest_amounts_cache = self.lowest_amounts_cache.merge( { key => amount } )
    end

    def set_lowest_sale_amount(amount, currency)
      key = lowest_sale_amount_key(currency)
      self.lowest_amounts_cache = self.lowest_amounts_cache.merge( { key => amount } )
    end

    def lowest_normal_amount(currency)
      if amount = self.lowest_amounts_cache[lowest_normal_amount_key(currency)]
        BigDecimal.new amount
      end
    end

    def lowest_sale_amount(currency)
      if amount = self.lowest_amounts_cache[lowest_sale_amount_key(currency)]
        BigDecimal.new amount
      end
    end

    
    private

    def lowest_normal_amount_key(currency)
      currency + '-normal'
    end

    def lowest_sale_amount_key(currency)
      currency + '-sale'
    end

  end
end
