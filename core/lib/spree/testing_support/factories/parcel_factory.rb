FactoryGirl.define do
  factory :parcel, class: "Spree::Parcel" do
    order
    box_id 1
    weight 0.3
    height 15.0
    width 23.0
    depth 10
    after(:create) do |p|
      box = create(:box)
      box_id = box.id
      p.save
    end
  end

end
