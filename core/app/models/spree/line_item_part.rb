class Spree::LineItemPart < ActiveRecord::Base
  validates :quantity, numericality: true
  validates :price, numericality: true
  validates :variant_id, presence: true

  belongs_to :variant, class_name: "Spree::Variant"
  belongs_to :line_item, class_name: "Spree::LineItem", inverse_of: :line_item_parts
  belongs_to :parent_part, class_name: "Spree::LineItemPart"

  belongs_to :assembly_definition_part
  belongs_to :product_part, class_name: "Spree::AssemblyDefinitionPart",
    foreign_key: :assembly_definition_part_id

  has_many :inventory_units, inverse_of: :line_item_part

  scope :optional, lambda { where(optional: true) }
  scope :required, lambda { where(optional: false) }
  scope :containers, lambda { where(container: true) }
  scope :stock_tracking, lambda { where(container: [false, nil]) }
  scope :without_subparts, lambda { where(parent_part_id: nil) }

  scope :not_operational, lambda { joins(variant: [product: :product_type]).merge(Spree::ProductType.where(is_operational: [nil, false])) }

  delegate :position, to: :product_part
  delegate :product, to: :variant

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

  def container=(value)
    value ||= false
    write_attribute(:container, value)
  end

end
