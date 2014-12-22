module Spree
  class MarketingType < ActiveRecord::Base
    belongs_to :product, touch: true, class_name: 'Spree::Product', inverse_of: :marketing_types

  end
end
