require 'spec_helper'

describe Spree::UpdateProductPageService do
  let(:product_page) { create(:product_page) }
  let(:target) { create(:target) }
  let(:details) { 
    {
      "name" => "New Name", 
      "title" => "The name", 
      "permalink" => "/the-name", 
      "target_id" => target.to_param, 
      "tags" => [""], 
      "accessories" => "true",
      "tabs_attributes" =>  {
        '0' => { 
          "background_color_code" => "123456",
          "id"  => product_page.tabs.first.id
        }
      }
    } 
  }
  
  context "#run" do
    let(:subject) { Spree::UpdateProductPageService }

    it "is successful" do
      result = subject.run(product_page: product_page, details: details)
      expect(result).to be_success
    end

    it "sets the product page name" do
      result = subject.run(product_page: product_page, details: details)
      expect(product_page.reload.name).to eq("New Name")
    end

    it "sets the title on the product page" do
      result = subject.run(product_page: product_page, details: details)
      expect(product_page.reload.title).to eq("The name")
    end

    it "sets the tab background color code" do
      subject.run(product_page: product_page, details: details)
      expect(product_page.tabs.first.background_color_code).to eq("123456")
    end

    it "sets the target" do
      subject.run(product_page: product_page, details: details)
      expect(product_page.reload.target).to eq(target)
    end

    it "sets accessories flag" do
      subject.run(product_page: product_page, details: details)
      expect(product_page.reload).to be_accessories
    end
  end

  context "update displayed variants" do
    subject { Spree::UpdateProductPageService }
    let(:product_in) { create(:product_with_variants) }
    let(:product_out) { create(:product_with_variants) }

    before do
      product_page.product_groups = [product_in.product_group, product_out.product_group]
      product_page.save
      product_page.reload
      product_in.variants.each {|v| create(:product_page_variant, product_page: product_page, variant: v) }
      product_out.variants.each {|v| create(:product_page_variant, product_page: product_page, variant: v) }
    end

    it "deletes variant that are not product_groups" do
      subject.run(product_page: product_page,
                  details: details.merge(product_group_ids: product_in.product_group.id.to_s))

      expect(product_page.reload.displayed_variants).to match_array(product_in.variants)
    end
  end
end
