module Spree
  class ProductContainerImage < Image

    has_attached_file :attachment,
      :styles        => { large: "640x900>", small: '310x396>', mini: '150x150>' },
      :default_style => :large,
      :convert_options =>  { :all => '-strip -auto-orient' },
      :keep_old_files => false

  end
end
