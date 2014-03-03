FactoryGirl.define do
  factory :payment_method, aliases: [:check_payment_method], class: Spree::PaymentMethod::Check do
    name 'Check'
    environment 'test'
  end

  factory :bogus_payment_method, class: Spree::Gateway::Bogus do
    name 'Credit Card'
    environment 'test'
  end

  # authorize.net was moved to spree_gateway.
  # Leaving this factory in place with bogus in case anyone is using it.
  factory :bogus_simple_payment_method, class: Spree::Gateway::BogusSimple do
    name 'Credit Card'
    environment 'test'
  end

  factory :adyen_payment_method, class: Spree::Gateway::AdyenGateway do
    name 'creditcard'
    environment 'test'
    active true
    preferred_test_mode true
    preferred_merchant_account  'WoolandtheGangTEST'
    preferred_login 'ws_305254@Company.WoolandtheGang'
    preferred_password 'v{+61)Qd#^<3qDk+cc\TkR6pP'
    preferred_public_key  '10001|8B862B025C170588612821BC6085506C630CB95B38FFEDF8E280A808242196EB6401D3AC9003E09C7D4AC293303EE0AEA236A2E5670E7E1B9319CFD3F9F19362D6F9F0AA18D7032A63E15C2E002401EEEC91E7EE7327046917CCCB7D94E084C84A949B29DFD486A078DC365134D479A6BBB51994C181308F0876FD26C601B516A945F01BB5ED9B0642308BC4A8315F440ED97939FFA8243EF4FC05CD8DB950EFC5CB4CB81E06C8ED789FA6C28CE107C707DD88A4149D5CBD971A600FF14EEBCF324713395C671A590D2EA290106CF2FF9768B8A4F47A68ED57CF52E84426B7BC0E05EF095547B97C1DB82929A7D9417E3BA3066BDD8C2B0D119C5114F72A7799'
  end

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
