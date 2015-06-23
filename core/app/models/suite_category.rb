class SuiteCategory < Spree::Base
  has_many :suites, class: Spree::Suite, foreign_key: :category_id
end
