module Spree
  class AssemblyDefinitionImage < Image

    has_attached_file :attachment,
      :styles        => { large: "640x900>", small: '310x396>', mini: '150x150>' },
      :default_style => :large,
      :url           => "/spree/assembly_definitions/:id/:style/:basename.:extension",
      :path          => ":rails_root/public/spree/assembly_definitions/:id/:style/:basename.:extension",
      :convert_options =>  { :all => '-strip -auto-orient' },
      :keep_old_files => false

    supports_s3 :attachment

  end
end
