# Fix for issue with both Acts as List and Acts as Paranoid
# https://github.com/swanandp/acts_as_list/issues/158
module ActsAsListFixer
  def self.fix_all_taxon_positions!
    Spree::Taxon.find_each do |taxon|
      self.reorder_positions!(taxon.classifications)
    end
  end

  def self.reorder_positions!(objects)
    objects.each_with_index do |object, index|
      new_position = index + 1
      next if object.position == new_position
      object.update_column(:position, new_position)
    end
  end
end
