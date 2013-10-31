module Spree
  class Target < ActiveRecord::Base
    validates :name, presence: true
  end
end
