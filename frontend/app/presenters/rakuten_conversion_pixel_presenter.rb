# provides a presenter for the rakuten tracking pixel
class RakutenConversionPixelPresenter
  def initialize(order)
    @order = order
  end

  def default_rakuten_params
    { ord:      order_number,
      skulist:  sku_list,
      qlist:    quantity_list,
      amtlist:  amount_list,
      cur:      currency,
      img:      1,
      namelist: name_list }
  end

  private

  attr_reader :order

  def line_items_by_variant
    order.line_items.sort_by(&:variant_id).group_by(&:variant_id)
  end

  def variant_ids
    line_items_by_variant.keys
  end

  def order_number
    order.number
  end

  def sku_list
    Spree::Variant.where(id: variant_ids).sort_by(&:id).map(&:sku).join("|")
  end

  def quantity_list
    line_items_by_variant.map{ |_k, v| v.sum(&:quantity) }.join("|")
  end

  def amount_list
    # BAD CODE ALERT, THIS SHOULD BE CHANGED AFTER DAVID COME BACK 14-07-2015
    line_items_by_variant.map{ |_k, v| (v.sum{ |li| calculate_pre_tax_amount(li) }).to_i }.join("|")
  end

  def currency
    order.currency
  end

  def name_list
    line_items_by_variant.map{ |_k, v| URI.escape(v.first.product.name) }.join("|")
  end

  private

  def calculate_pre_tax_amount(li)
    (li.price - li.adjustments.tax.sum(:amount)) * li.quantity * 100
  end
end
