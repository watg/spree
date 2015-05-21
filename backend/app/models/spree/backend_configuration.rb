module Spree
  class BackendConfiguration < Preferences::Configuration
    preference :locale, :string, default: Rails.application.config.i18n.default_locale

    ORDER_TABS         ||= [:orders, :payments, :creditcard_payments,
                            :shipments, :credit_cards, :return_authorizations,
                            :customer_returns, :adjustments, :customer_details]
    PRODUCT_TABS       ||= [:products, :option_types, :properties, :prototypes,
                            :variants, :product_properties, :taxonomies,
                            :taxons, :suites, :suppliers, :product_groups]
    VIDEO_TABS         ||= [:videos]
    REPORT_TABS        ||= [:reports]
    CONFIGURATION_TABS ||= [:configurations, :general_settings, :tax_categories,
                            :tax_rates, :zones, :countries, :states,
                            :payment_methods, :shipping_methods,
                            :shipping_categories, :stock_transfers,
                            :stock_locations, :trackers, :refund_reasons,
                            :reimbursement_types, :return_authorization_reasons,
                            :hosts]
    PROMOTION_TABS     ||= [:promotions, :promotion_categories, :raf_settings, :gift_cards]
    USER_TABS          ||= [:users]
  end
end
