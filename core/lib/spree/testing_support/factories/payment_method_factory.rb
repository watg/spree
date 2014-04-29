FactoryGirl.define do
  factory :payment_method, aliases: [:check_payment_method], class: Spree::PaymentMethod::Check do
    name 'Check'
    environment 'test'
  end

  factory :credit_card_payment_method, class: Spree::Gateway::Bogus do
    name 'Credit Card'
    environment 'test'
  end

  # authorize.net was moved to spree_gateway.
  # Leaving this factory in place with bogus in case anyone is using it.
  factory :simple_credit_card_payment_method, class: Spree::Gateway::BogusSimple do
    name 'Credit Card'
    environment 'test'
  end

  # factory :adyen_payment_method, class: Spree::Gateway::AdyenGateway do
  #   name 'creditcard'
  #   environment 'test'
  #   active true
  #   preferred_test_mode true
  #   preferred_merchant_account  'WoolandtheGangECOMM'
  #   preferred_login 'ws@Company.WoolandtheGang'
  #   preferred_password '+5gFyFtM*t8qu5ctC2m{Pu8^N'
  #   preferred_public_key  '10001|850957826D7473724E70043252FC0041F8B1AB12BD1C46BB041CEC714145A17B3705D9821EB102DEC5BFEE873F8E9D3F9E44AB1A24AACE22050BA7E51C0955BB126EF6DA110586D32B71083FAEA0A3DB353F50A3ECF397C0627AF52C40BE928CD4F9786C77069CE9095A9CA89B9F15B02A7A6BBFCC9B74C0ACFF1F8A50BFAEFEB4304DA7E28EB282B031360AC62053F4D6EC24CB1867DAA7517DDA1C9EE326AC4B8A596C3BC724DAEF8DE9DC42D456525666F543E75E535E2869203171D4108B32664D92027726EA4D77439560090F417F152BFFBF4097E8E1AD022779F0D9B2D104E0B8804961EFB9F4911B1836B37740B6AFC3C556A34D1E60F601BBC85D7D'
  # end

  factory :paypal_payment_method, class: Spree::Gateway::Bogus do
    name 'paypal'
    environment 'test'
  end

  factory :test_payment_method, class: Spree::PaymentMethod::Check do
    name 'test'
    environment 'test'
    active true
  end

end
