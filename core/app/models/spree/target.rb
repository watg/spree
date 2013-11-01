module Spree
  class Target < ActiveRecord::Base
    has_many :variant_targets
    has_many :variants, :through => :variant_targets
    validates :name, presence: true
  end
end
