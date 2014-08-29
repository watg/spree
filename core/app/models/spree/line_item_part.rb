class Spree::LineItemPart < ActiveRecord::Base
  validates :quantity, numericality: true
  validates :price, numericality: true
  validates :variant_id, presence: true

  belongs_to :variant
  belongs_to :line_item, inverse_of: :line_item_parts
  belongs_to :parent_part, class_name: "Spree::LineItemPart"

  has_many :inventory_units, inverse_of: :line_item_part

  scope :optional, lambda { where(optional: true) }
  scope :required, lambda { where(optional: false) }
  scope :containers, lambda { where(container: true) }
  scope :stock_tracking, lambda { where(container: [false, nil]) }
  scope :assembled, lambda { where(assembled: true) }
  scope :without_subparts, lambda { where(parent_part_id: nil) }


  def required?
    !optional?
  end

  # Remove product default_scope `deleted_at: nil`
  def product
    variant.product
  end

  # Remove variant default_scope `deleted_at: nil`
  def variant
    Spree::Variant.unscoped { super }
  end

  def children
    Spree::LineItemPart.where(parent_part: self)
  end
end
