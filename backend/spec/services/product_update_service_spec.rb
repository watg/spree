require 'spec_helper'

describe Spree::UpdateProductService do
  let(:product) { FactoryGirl.create(:product_with_variants) }
  let(:taxons)  {[FactoryGirl.create(:taxon, name: "loner"), FactoryGirl.create(:multiple_nested_taxons) ]}
  let(:option_types) { [FactoryGirl.create(:option_type, name: "onte"), FactoryGirl.create(:option_type, name: "deux")]}
   
  let(:valid_params) { {taxon_ids: taxons.map(&:id).join(','), option_type_ids: option_types.map(&:id).join(','),  visible_option_type_ids: [option_types[0]].join(','), name: 'test product'} }

  let(:prices) { {
    :normal=>{"GBP"=>"£39.00", "USD"=>"$49.00", "EUR"=>"€47.00"}, 
    :normal_sale=>{"GBP"=>"£111.00", "USD"=>"$12.00", "EUR"=>"€0.00"}, 
    :part=>{"GBP"=>"£22.00", "USD"=>"$0.00", "EUR"=>"€0.00"}, 
    :part_sale=>{"GBP"=>"£0.00", "USD"=>"$0.00", "EUR"=>"€0.00"}
  } }


  context "#run" do
    let(:subject) { Spree::UpdateProductService }
    
    it "should invoke success callback when all is good" do
      outcome = subject.run(product: product, details: valid_params, prices: prices)
      expect(outcome).to be_success
    end

    it "should invoke failure callback on any error" do
      outcome = subject.run(product: product, details: "wrong params!", prices: prices)
      expect(outcome).not_to be_success
    end

    it "should comply to definition" do
      instance = subject.any_instance
      instance.should_receive(:assign_taxons)
      instance.should_receive(:update_details)
      instance.should_receive(:option_type_visibility)
      
      subject.run(product: product, details: {}, prices: prices)
    end
    
    it "should update product and displayable variant" do
      add_taxon_to(product, taxons[0])
      create_existing_displayble_variant_for_taxon(product.variants.first, taxons[0])

      expected_attrs = all_taxons_with_parents([taxons[1]]).map do |t|
        [product.variants.first].map do |v|
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
      hash = {product: product, details: { taxon_ids: taxons.map(&:id).join(',') }, prices: prices}
      subject.run(hash)
    end

    it "sets the prices on the master" do
      Spree::UpdateProductService.any_instance.should_receive(:update_prices).once.with(hash_including(prices) ,product.master)
      subject.run(product: product, details: valid_params, prices: prices)
    end

    it "allow nil for prices on the master" do
      outcome = subject.run(product: product, details: valid_params, prices: nil)
      expect(outcome).to be_success
    end

  end

  context "#option_type_visibility" do
    let(:product) { FactoryGirl.create(:product_with_option_types) }
    let(:pot) { Spree::ProductOptionType.new }
    
    it "should update product_option_type with visibility selection " do
      color, lang_id = [product.option_types[0], 99]

      subject.should_receive(:make_visible).once
      
      subject.option_type_visibility(product, [color.id, lang_id].join(','))
    end

    it "should remove unselected visible option type"do
      subject.should_receive(:reset_visible_option_types).with(product.id, product.option_types.map(&:id))

      subject.option_type_visibility(product, '')
    end
  end

  context "#assign_taxon" do
    it "should not create any displayable variant by default" do
      Spree::DisplayableVariant.should_not_receive(:create!)
      Spree::DisplayableVariant.should_not_receive(:destroy_all)
      subject.assign_taxons(product, to_list(taxons))
    end

    it "should be effectless when taxons has not changed" do
      product = FactoryGirl.create(:product_with_one_taxon)

      Spree::DisplayableVariant.should_not_receive(:create!)
      Spree::DisplayableVariant.should_not_receive(:destroy_all)
      subject.assign_taxons(product, to_list(product.taxons))      
    end
    
    it "should create displayable variants for new taxons added to product with existing displayable_variants" do
      add_taxon_to(product, taxons[0])
      create_existing_displayble_variant_for_taxon(product.variants.first, taxons[0])

      expected_attrs = all_taxons_with_parents([taxons[1]]).map do |t|
        [product.variants.first].map do |v|
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
      subject.assign_taxons(product, to_list(taxons))
    end

    it "should delete displayable_variants when taxons removed" do
      product = FactoryGirl.create(:product_with_one_taxon)

      taxon_to_remove = product.taxons.map(&:id)
      Spree::DisplayableVariant.should_receive(:destroy_all).with(product_id: product.id, taxon_id: taxon_to_remove)
      subject.assign_taxons(product, '')
    end

  end

  context "#current_visible_variants" do
    let(:product) { FactoryGirl.create(:product_with_variants_displayable) }

    it "should find all the displayable variants" do
      expected = product.variants.map(&:id)
      actual = subject.send :current_displayable_variants, product 

      expect(actual).to match_array(expected)
    end
  end


  context "update properties" do
    let(:subject) { Spree::UpdateProductService }
    it "should not delete product detais" do
      add_taxon_to(product, taxons[0])
      add_option_type_to(product, option_types[0])
      create_existing_displayble_variant_for_taxon(product.variants.first, taxons[0])

      product_options = product.option_types.dup
      product_taxons = product.taxons.dup
      product_id = product.id
 
      outcome = subject.run({product: product, details: properties_params, prices: prices})
      product  = Spree::Product.find(product_id)

      expect(outcome).to be_success
      product.option_types.should == product_options
      product.taxons.should       == product_taxons
    end

  end

  # ----------------------
  def to_list(array=[])
    array.map(&:id).join(',')
  end

  def all_taxons_with_parents(taxo)
    taxo.map { |t| t.self_and_parents }.flatten.sort
  end

  def create_existing_displayble_variant_for_taxon(variant, taxon)
    Spree::DisplayableVariant.create(
                                     product_id: variant.product.id,
                                     variant_id: variant.id,
                                     taxon_id: taxon.id)
  end

  def add_taxon_to(p, t)
    p.update_attributes(taxon_ids: [t.id])
  end
  def add_option_type_to(p, opt_type)
    p.update_attributes(option_type_ids: [opt_type.id])
  end

  def properties_params
    {
      product_properties_attributes:{
        "0"=>{id: '', property_name: "gender", value: "Women"},
        "1"=>{id: "",  property_name: "",       value: ""}}
    }
  end
end
