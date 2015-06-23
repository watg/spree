module Admin
  class SuiteCategoryPresenter < Spree::BasePresenter
    presents :suite_category
    delegate :id, :name, to: :suite_category

    def self.model_name
      SuiteCategory.model_name
    end
  end
end
