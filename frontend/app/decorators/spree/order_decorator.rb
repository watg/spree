class Spree::OrderDecorator < Draper::Decorator
  delegate_all

  def linkshare_params
      {
      mid:      [LinkShare.merchant_id],
      ord:      [object.number],
      cur:      [object.currency],
      skulist:  skulist,
      qlist:    qlist,
      amtlist:  amtlist,
      namelist: namelist
    }
  end
  
  def discounts
    @discounts ||= object.adjustments.where(originator_type: "Spree::PromotionAction")
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
    (line_items.map {|li| (100 * li.quantity * li.price).to_i } + discounts.map {|e| (100 * e.amount).to_i })
  end
  
  def namelist
    (line_items.map(&:variant).map {|v| URI.escape("#{v.name}-#{v.number}") } + discounts.map {|d| URI.escape(d.label) })
  end
  
end
