class Spree::LineItemPart < ActiveRecord::Base
  validates :quantity, numericality: true
  validates :price, numericality: true
  validates :variant_id, presence: true

  belongs_to :variant, class_name: "Spree::Variant"
  belongs_to :line_item, class_name: "Spree::LineItem", inverse_of: :line_item_parts
  belongs_to :parent_part, class_name: "Spree::LineItemPart"

  belongs_to :product_part, class_name: "Spree::ProductPart", foreign_key: :product_part_id

  has_many :inventory_units, inverse_of: :line_item_part

  has_one :product, through: :variant, autosave: false

  scope :optional, lambda { where(optional: true) }
  scope :required, lambda { where(optional: false) }
  scope :without_subparts, lambda { where(parent_part_id: nil) }

  scope :not_operational, lambda { joins(variant: [product: :product_type]).merge(Spree::ProductType.where(is_operational: [nil, false])) }

  delegate :position, to: :product_part
  delegate :container?, to: :product

  def required?
    !optional?
  end

  # Remove variant default_scope `deleted_at: nil`
  def variant
    Spree::Variant.unscoped { super }
  end

  def children
    Spree::LineItemPart.where(parent_part: self)
  end
end
