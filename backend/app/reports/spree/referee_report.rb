module Spree
  class RefereeReport
    include BaseReport

    def initialize(params={})
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])
    end

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def header
      %w(
        referee
        referrer
        referee_sign_up_date
        source
        percentage_discount
        applied_to_order
        order_number
        order_date
        order_currency
        order_promo_total
        order_item_total
        order_total
      )
    end

    def retrieve_data
      Spree::Raf::Referee.where(:created_at => @from..@to).find_each do |referee|
        yield data_row(referee)
      end
    end

  private

    def data_row(referee)
      [
        referee.email,
        referee.referrer.try(:user).try(:email),
        referee.created_at.to_date,
        referee.source,
        referee.promotion.actions.first.calculator.preferred_flat_percent.to_f,
        referee.promotion.credits_count,
        referee.try(:referrer_reward).try(:order).try(:number),
        referee.try(:referrer_reward).try(:order).try(:completed_at).try(:to_date),
        referee.try(:referrer_reward).try(:order).try(:currency),
        referee.try(:referrer_reward).try(:order).try(:promo_total).try(:to_f),
        referee.try(:referrer_reward).try(:order).try(:item_total).try(:to_f),
        referee.try(:referrer_reward).try(:order).try(:total).try(:to_f)
      ]
    end
  end
end
