module Spree
  class AssemblyDefinitionImage < Image

    has_attached_file :attachment,
      :styles => { mini: '66x84>', :listing => '150x192>', small: '310x396>', product: '470x600>', large: '940x1200>' },
      :default_style => :product,
      :convert_options =>  { :all => '-strip -auto-orient' },
      :keep_old_files => false

  end

  def self.with_target(target)
    target_id = target ? target.id : nil 
    where(target_id: [nil, target_id])
  end

end
