class Spree::LineItemPart < ActiveRecord::Base
  validates :quantity, numericality: true
  validates :price, numericality: true
  validates :variant_id, presence: true

  belongs_to :variant
  belongs_to :line_item

  scope :optional, lambda { where(optional: true) }
  scope :required, lambda { where(optional: false) }

  def self.generate_uuid( options_with_qty )
    options_with_qty = [] if options_with_qty.blank?
    uuid = options_with_qty.sort{|a,b| a[0].id <=> b[0].id }.map do |e|
      "#{e[0].id}-#{e[1]}"
    end
    uuid.join(':')
  end

end
