FactoryGirl.define do
  factory :taxon, class: Spree::Taxon do
    name 'Tops & Hats'
    taxonomy
    parent_id nil

    factory :multiple_nested_taxons do

      transient do
        depth 3
      end

      after :create do |child, evaluator|
        current = child
        evaluator.depth.times do |i|
          parent = FactoryGirl.create(:taxon, name: "taxon #{i}", taxonomy: child.taxonomy)
          current.move_to_child_of(parent)
          current.save
          current = parent
        end
      end
    end
  end
end
