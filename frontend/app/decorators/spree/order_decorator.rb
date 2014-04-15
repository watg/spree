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
    @discounts ||= object.adjustments.eligible.promotion.select {|e| e.originator.type != "Spree::Promotion::Actions::CreateShippingAdjustment"}
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
    (line_items.map {|li| (100 * to_gbp(li.price, li.quantity,  object.currency)).to_i } + discounts.map {|e| (100 * e.amount).to_i })
  end

  def namelist
    (line_items.map(&:variant).map {|v| URI.escape("#{v.name}-#{v.number}") } + discounts.map {|d| URI.escape(d.label) })
  end

  def to_gbp(p, qtty, cur)
    qtty.to_i * p.to_f  * rates[cur].to_f
  end

  def rates
    Helpers::CurrencyConversion::TO_GBP_RATES
  end

end
