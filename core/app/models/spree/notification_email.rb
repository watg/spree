module Spree
  class NotificationEmail < ActiveRecord::Base
    belongs_to :order
  end
end
