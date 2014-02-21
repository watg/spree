FactoryGirl.define do
  factory :mailchimp do
    email  'tester@woolandthegang.com'
    action 'subscribe'
    request_params '{"signupEmail": "tester@woolandthegang.com", "listname": "newsletter"}'
  end
end
