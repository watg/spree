module Admin
  # controller for suite categories
  class SuiteCategoriesController < Spree::Admin::ResourceController
    def model_class
      ::SuiteCategory
    end
  end
end
