module Spree
  class ReferrerReport
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
        referrer
        referee
        referrer_currency
        referee_order_date
        reward_amount
        state
        reward_redeemed_date
        order_number
        order_date
        order_currency
        order_promo_total
        order_promo_total_gbp
        order_item_total
        order_item_total_gbp
        order_total
        order_total_gbp
      )
    end

    def retrieve_data
      Spree::Raf::Reward.where(:created_at => @from..@to).find_each do |reward|
        yield data_row(reward)
      end
    end

  private

    def data_row(reward)
      currency = reward.try(:rewardable).try(:beneficiary_order).try(:currency)
      [
        reward.referrer.try(:user).try(:email),
        reward.referee.email,
        reward.referrer.try(:currency),
        reward.created_at.to_date,
        reward.amount.try(:to_f),
        reward.state,
        reward.redeemed_at.try(:to_date),
        reward.try(:rewardable).try(:beneficiary_order).try(:number),
        reward.try(:rewardable).try(:beneficiary_order).try(:completed_at).try(:to_date),
        currency,
        reward.try(:rewardable).try(:beneficiary_order).try(:promo_total).try(:to_f),
        reward.try(:rewardable).try(:beneficiary_order).try(:promo_total).try(:to_f).try(:*, gbp_rate[currency]),
        reward.try(:rewardable).try(:beneficiary_order).try(:item_total).try(:to_f),
        reward.try(:rewardable).try(:beneficiary_order).try(:item_total).try(:to_f).try(:*, gbp_rate[currency]),
        reward.try(:rewardable).try(:beneficiary_order).try(:total).try(:to_f),
        reward.try(:rewardable).try(:beneficiary_order).try(:total).try(:to_f).try(:*, gbp_rate[currency])
      ]
    end


    def gbp_rate
      Helpers::CurrencyConversion::TO_GBP_RATES
    end
  end
end
