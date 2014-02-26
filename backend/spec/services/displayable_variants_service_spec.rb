require 'spec_helper'


describe Spree::DisplayableVariantsService do
  context "#run" do
    let(:subject) { Spree::DisplayableVariantsService }
    let(:product) {FactoryGirl.create(:product_with_variants)}
        
    it "should invoke success callback when all is good" do
      outcome = subject.run(product_id: product.id, variant_ids: [])
      expect(outcome).to be_success
    end

    
    it "should invoke failure callback on any error" do
      outcome = subject.run(product_id: 1, variant_ids: "i am not an array")
      expect(outcome).not_to be_success
    end
  end

  context "#update_displayable_variants" do
    let(:product) {FactoryGirl.create(:product_with_variants)}
    let(:taxons) {[FactoryGirl.create(:taxon, name: "loner"), FactoryGirl.create(:multiple_nested_taxons) ]}

    before do
      product.taxons << taxons
      product.save
    end

    it "should find all taxons and their ancestors for a product " do

      all_taxons = taxons.map { |t| t.self_and_parents }.flatten.sort
      expected_attrs = all_taxons.map do |t|
        product.variants.map do |v|
          {
            product_id: product.id,
            variant_id: v.id,
            taxon_id:   t.id
          }
        end
      end.flatten

      expected_attrs.each do |attr|
        Spree::DisplayableVariant.should_receive(:create!).with(attr)
      end
      subject.send(:update_displayable_variants, product, product.variants.map(&:id) )      
    end
  end

  
  context "#variant_selection" do
    it "should find the variant ids to remove" do
      current_visible_variants = [605, 599, 609]
      selected_variants        = [609]
      expected_to_remove       = [605, 599]

      actual = subject.send :variants_to_remove, current_visible_variants, selected_variants

      expect(actual).to eq(expected_to_remove)
    end

    it "should find variant to add" do
      current_visible_variants = [401, 605, 599]
      selected_variants        = [609, 401]
      expected_to_add          = [609]

      actual = subject.send :variants_to_add, current_visible_variants, selected_variants

      expect(actual).to eq(expected_to_add)
    end


    it "should remove all variants if nothing selected" do
      current_visible_variants = [605, 599, 609]
      selected_variants        = nil 
      expected_to_remove       = [605, 599, 609]

      actual = subject.send :variants_to_remove, current_visible_variants, selected_variants
      expect(actual).to eq(expected_to_remove)
    end


    it "should create no variants if nothing selected" do
      current_visible_variants = [605, 599, 609]
      selected_variants        = nil 
      expected_to_add       = []

      actual = subject.send :variants_to_add, current_visible_variants, selected_variants
      expect(actual).to eq(expected_to_add)
    end

  end

end
