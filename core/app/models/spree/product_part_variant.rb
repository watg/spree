class Spree::ProductPartVariant < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :variant, class_name: "Spree::Variant", foreign_key: "variant_id"
  belongs_to :product_part, touch: true, class_name: "Spree::ProductPart", foreign_key: "product_part_id"

  validates_presence_of :variant_id, :product_part_id

  # Return variant, even if deleted
  # Fixes admin errors on assembly definition.
  def variant
    Spree::Variant.unscoped { super }
  end

end
