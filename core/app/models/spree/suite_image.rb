module Spree
  class SuiteImage < Image

    has_attached_file :attachment,
      :styles        => { large: "640x900>", small: '310x396>', mobile: '150x192>' },
      :default_style => :large,
      :convert_options =>  {
        :all => '-strip -auto-orient',
        :large => "-quality 80"
      },
      :keep_old_files => false

  end
end
