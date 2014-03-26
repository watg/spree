require 'spec_helper'

describe Spree::OrderContents do
  let(:order)   { create(:order) }
  let(:variant) { create(:variant) }
  let(:subject) { Spree::OrderContents.new(order) }
  let(:currency){ 'USD' }

  let!(:price) { create(:price, is_kit: true, amount: 5) }

  before do
    Spree::Variant.any_instance.stub(:price_part_in => price)
  end

  context "#add" do    
    it "should set the correct attributes to the line item" do
      line_item = subject.send(:add, variant, 1, 'USD', nil, nil, nil, 2)

      expect(order.line_items.first.variant).to eq(variant) 
      expect(order.line_items.first.target_id).to eq(2) 
      expect(order.line_items.first.currency).to eq('USD') 
      
    end

    it "should create different line items for different targets" do
      line_item1 = subject.send(:add, variant, 1, 'USD', nil, nil, nil, 1)
      line_item2 = subject.send(:add, variant, 1, 'USD', nil, nil, nil, 2)

      expect(order.line_items.first.variant).to eq(variant)
      expect(order.line_items.first.target_id).to eq(1)

      expect(order.line_items.second.variant).to eq(variant)
      expect(order.line_items.second.target_id).to eq(2) 
    end

    context 'given a option' do
      let(:variant_option1) { create(:variant) } 
      let(:variant_option2) { create(:variant) } 

      let(:line_item_part_params) {[
        [variant_option1, 3, true]
      ]}

      let(:line_item_part_params2) {[
        [variant_option2, 2, true]
      ]}

      let(:line_item_part_params3) {[
        [variant_option2, 5, true]
      ]}

      let(:line_item_part_params4) {[
        [variant_option1, 7, true],
        [variant_option2, 5, true]
      ]}

      it 'should add one line item with one option' do
        puts 
        line_item = subject.add(variant,1,nil,nil,line_item_part_params,nil)
        line_item.quantity.should == 1
        order.line_items.size.should == 1
        line_item.line_item_parts.size.should == 1
        line_item.line_item_parts.first.variant == variant_option1 
        line_item.line_item_parts.first.quantity == 3 
      end

      it 'should only have one line item with same option' do
        line_item = subject.add(variant,1,nil,nil,line_item_part_params,nil)
        line_item2 = subject.add(variant,1,nil,nil,line_item_part_params,nil)
        line_item.reload
        line_item.quantity.should == 2
        line_item.should == line_item2
        order.line_items.size.should == 1
        line_item.line_item_parts.size.should == 1
      end

      it 'should only have multiple line item with different options' do
        line_item = subject.add(variant,1,nil,nil,line_item_part_params,nil)
        line_item2 = subject.add(variant,1,nil,nil,line_item_part_params2,nil)
        line_item.quantity.should == 1
        line_item2.quantity.should == 1
        order.line_items.size.should == 2
        line_item.line_item_parts.size.should == 1
        line_item2.line_item_parts.size.should == 1
      end

      it 'should only have multiple line item with different same options difference qauntities' do
        line_item = subject.add(variant,1,nil,nil,line_item_part_params2,nil)
        line_item2 = subject.add(variant,1,nil,nil,line_item_part_params3,nil)
        line_item.quantity.should == 1
        line_item2.quantity.should == 1
        order.line_items.size.should == 2
        line_item.line_item_parts.size.should == 1
        line_item2.line_item_parts.size.should == 1
      end

      it 'should only have one line item with same option when multiple options' do
        line_item = subject.add(variant,1,nil,nil,line_item_part_params4,nil)
        line_item2 = subject.add(variant,1,nil,nil,line_item_part_params4,nil)
        line_item.reload
        line_item.quantity.should == 2
        line_item.should == line_item2
        order.line_items.size.should == 1
        line_item.line_item_parts.size.should == 2
      end

      it "should update order totals" do
        subject.add(variant,1,nil,nil,line_item_part_params,nil)
        subject.add(variant,1,nil,nil,line_item_part_params,nil)
        subject.add(variant,1,nil,nil,line_item_part_params2,nil)

        # 99.97 = 3 * 19.99 + 5*3 + 5*3 + 5*2
        order.item_total.to_f.should == 99.97 
        order.total.to_f.should == 99.97
      end
    end

    context 'given a personalisation' do
      let(:monogram) { create(:personalisation_monogram) }
      let(:personalisation_params) {[{
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      }]}

      let(:personalisation_params2) {[{
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'XX'},
      }]}

      let(:personalisation_params3) {[
        {
          personalisation_id: monogram.id,
          amount: 1,
          data: { 'colour' => monogram.colours.first.id, 'initials' => 'XX'},
        },
        {
          personalisation_id: monogram.id,
          amount: 2,
          data: { 'colour' => monogram.colours.first.id, 'initials' => 'WW'},
        },
      ]}

      it 'should add one line item with one personalisation' do
        line_item = subject.add(variant,1,nil,nil,nil,personalisation_params)
        line_item.quantity.should == 1
        order.line_items.size.should == 1
        line_item.line_item_personalisations.size.should == 1
        line_item.line_item_personalisations.first.name == 'monogram'
        line_item.line_item_personalisations.first.amount == BigDecimal.new('1') 
      end

      it 'should only have one line item with same personalisations' do
        line_item = subject.add(variant,1,nil,nil,nil,personalisation_params)
        line_item2 = subject.add(variant,1,nil,nil,nil,personalisation_params)
        line_item.reload
        line_item.quantity.should == 2
        line_item.should == line_item2
        order.line_items.size.should == 1
        line_item.line_item_personalisations.size.should == 1
      end

      it 'should only have multiple line item with different personalisations' do
        line_item = subject.add(variant,1,nil,nil,nil,personalisation_params)
        line_item2 = subject.add(variant,1,nil,nil,nil,personalisation_params2)
        line_item.quantity.should == 1
        line_item2.quantity.should == 1
        order.line_items.size.should == 2
        line_item.line_item_personalisations.size.should == 1
        line_item2.line_item_personalisations.size.should == 1
      end

      it 'should only have one line item with multiple personalisations in same line item' do
        line_item = subject.add(variant,1,nil,nil,nil,personalisation_params3)
        line_item2 = subject.add(variant,1,nil,nil,nil,personalisation_params3)
        line_item.reload
        line_item.quantity.should == 2
        line_item.should == line_item2
        order.line_items.size.should == 1
        line_item.line_item_personalisations.size.should == 2
      end

      it "should update order totals" do
        subject.add(variant,1,nil,nil,nil,personalisation_params)
        subject.add(variant,1,nil,nil,nil,personalisation_params)
        subject.add(variant,1,nil,nil,nil,personalisation_params2)

        # 62.97 = 3 * 19.99
        order.item_total.to_f.should == 62.97 
        order.total.to_f.should == 62.97
      end
    end

    context 'given a combination of personalisation and option' do
      let(:monogram) { create(:personalisation_monogram) }
      let(:personalisation_params) {[{
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      }]}

      let(:variant_option1) { create(:variant) } 

      let(:line_item_part_params) {[
        [variant_option1, 3]
      ]}

      it 'should only have one line item with same personalisations and option' do
        line_item = subject.add(variant,1,nil,nil,line_item_part_params,personalisation_params)
        line_item2 = subject.add(variant,1,nil,nil,line_item_part_params,personalisation_params)
        line_item.reload
        line_item.quantity.should == 2
        line_item.should == line_item2
        order.line_items.size.should == 1
        line_item.line_item_personalisations.size.should == 1
        line_item.line_item_parts.size.should == 1
      end

      it 'should only have multiple line item with different personalisations' do
        line_item = subject.add(variant,1,nil,nil,nil,personalisation_params)
        line_item2 = subject.add(variant,1,nil,nil,line_item_part_params,nil)
        line_item.quantity.should == 1
        line_item2.quantity.should == 1
        order.line_items.size.should == 2
        line_item.line_item_personalisations.size.should == 1
        line_item2.line_item_parts.size.should == 1
      end
    end
  end

  context "#add_to_line_item" do
    let(:variant_in_sale) { FactoryGirl.create(:variant_in_sale) }

    context "prices" do
      it "should use normal variant price by default" do
        line_item = subject.send(:add_to_line_item, nil, variant, 1, currency)

        expect(line_item.in_sale?).to be_false
        expect(line_item.price).to eq(variant.price_normal_in(currency).amount)
        expect(line_item.normal_price).to eq(variant.price_normal_in(currency).amount) 
      end

      it "should use normal_sale variant price when variant is in sale" do
        line_item = subject.send(:add_to_line_item, nil, variant_in_sale, 1, currency)

        expect(line_item.in_sale?).to be_true 
        expect(line_item.price).to eq(variant_in_sale.price_normal_sale_in(currency).amount)
        expect(line_item.normal_price).to eq(variant_in_sale.price_normal_in(currency).amount)
      end


      it "should set the line item price to include the optional parts' prices" do
        variant = create(:variant, price: 60.00)
        
        part1 = create(:part)
        part2 = create(:part)
        
        options = [ [part1, 2, true], [part2, 1, true] ]
        line_item = subject.send(:add_to_line_item, nil, variant, 1, 'USD', nil, options)

        expect(order.line_items.first.price).to eq(75.00)
      end
    end
  end

  context "#remove" do
    context 'given a personalisation' do
      let(:monogram) { create(:personalisation_monogram) }
      let(:personalisation_params) {[{
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      }]}

      it 'should remove one line item with one personalisation' do
        line_item = subject.add(variant,3,nil,nil,nil,personalisation_params)
        subject.remove(variant)

        line_item.reload.quantity.should == 2
        line_item.line_item_personalisations.size.should == 1
      end
    end
  end
end
