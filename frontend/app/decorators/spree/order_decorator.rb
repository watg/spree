class Spree::OrderDecorator < Draper::Decorator
  delegate_all

  def linkshare_params
      {
      mid:      [LinkShare.merchant_id],
      ord:      [object.number],
      cur:      ['GBP'],
      skulist:  skulist,
      qlist:    qlist,
      amtlist:  amtlist,
      namelist: namelist
    }
  end
  
  def discounts
    @discounts ||= Spree::Adjustment.promotion.where(order_id: object.id, state: :closed, eligible: true, adjustable_type: ["Spree::LineItem", "Spree::Order"])
  end
  def line_items
    @line_items ||= object.line_items
  end
  
  def skulist
    (line_items.map(&:variant).map(&:number) + discounts.map {|d| URI.escape(d.label.gsub(' ', '-')) })
  end
  
  def qlist
    (line_items.map(&:quantity) + discounts.map {|e| 0})
  end
  
  def amtlist
    (line_items.map {|li| (100 * to_gbp(li, object.currency)).to_i } + discounts.map {|e| (100 * e.amount).to_i })
  end
  
  def namelist
    (line_items.map(&:variant).map {|v| URI.escape("#{v.name}-#{v.number}") } + discounts.map {|d| URI.escape(d.label) })
  end
  
  def to_gbp(line_item, cur)
    price_without_tax(line_item).to_f * line_item.quantity  * rates[cur].to_f
  end

  def price_without_tax(line_item)
    line_item.price - line_item.adjustments.tax.sum(:amount)
  end

  def rates
    Helpers::CurrencyConversion::TO_GBP_RATES
  end
end
