# provides a presenter for the rakuten tracking pixel
class RakutenConversionPixelPresenter
  MID = 40_554 # provided by rakuten

  def initialize(order)
    @order = order
  end

  def default_rakuten_params
    { mid:      mid,
      ord:      order_number,
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

  def mid
    MID
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
    if line_items_by_variant.all?{|_k, v| v.all?{ |li| li.pre_tax_amount > 0 || li.price == li.pre_tax_amount } }
      line_items_by_variant.map{ |_k, v| (v.sum(&:pre_tax_amount) * 100).to_i }.join("|")
    else
      line_items_by_variant.map{ |_k, v| (v.sum{ |li| li.price * li.quantity } * 100).to_i }.join("|")
    end
  end

  def currency
    order.currency
  end

  def name_list
    line_items_by_variant.map{ |_k, v| URI.escape(v.first.product.name) }.join("|")
  end
end
