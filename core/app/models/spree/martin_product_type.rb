module Spree
  class MartinProductType < ActiveRecord::Base
    validates :name, uniqueness: true
  end
end
