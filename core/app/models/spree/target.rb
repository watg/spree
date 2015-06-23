module Spree
  class Target < ActiveRecord::Base
    validates :name, presence: true

    has_many :images
    has_many :product_parts_images

    def self.not_in(object)
      target_ids = object.targets.pluck(:target_id)
      where.not(id: target_ids)
    end
  end
end
