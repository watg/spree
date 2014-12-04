module Spree
  class SuiteTabImage < Image

    has_attached_file :attachment,
      :styles        => { large: "3200x520>", small: '250x250>', mobile: '450x200#' },
      :default_style => :large,
      :convert_options =>  {
        :all => '-strip -auto-orient',
        :large => "-quality 80"
      },
      :keep_old_files => false

  end
end
