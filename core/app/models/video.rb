class Video < ActiveRecord::Base
  has_and_belongs_to_many :products, class_name: %[Spree::Product], join_table: 'products_videos'
end
