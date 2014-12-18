module Spree
  class OrderNote < ActiveRecord::Base
    belongs_to :order
    belongs_to :user, class_name: Spree.user_class
  end
end
