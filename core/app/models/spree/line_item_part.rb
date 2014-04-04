class Spree::LineItemPart < ActiveRecord::Base
  validates :quantity, numericality: true
  validates :price, numericality: true
  validates :variant_id, presence: true

  belongs_to :variant
  belongs_to :line_item, inverse_of: :line_item_parts

  scope :optional, lambda { where(optional: true) }
  scope :required, lambda { where(optional: false) }

end
