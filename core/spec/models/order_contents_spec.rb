require 'spec_helper'

describe Spree::OrderContents do
  let(:order)   { create(:order) }
  let(:variant) { create(:variant) }
  let(:subject) { Spree::OrderContents.new(order) }
  let(:currency){ 'USD' }

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

      it "should update order totals" do
        subject.add(variant,1,nil,nil,nil,personalisation_params)
        subject.add(variant,1,nil,nil,nil,personalisation_params)
        subject.add(variant,1,nil,nil,nil,personalisation_params2)

        # 62.97 = 3 * 19.99
        order.item_total.to_f.should == 62.97 
        order.total.to_f.should == 62.97
      end
    end
  end


  context "#add_to_line_item" do
    let(:variant_in_sale) { FactoryGirl.create(:variant_in_sale) }

    context "prices" do
      it "should use normal variant price by default" do
        line_item = subject.send(:add_to_line_item, nil, 'uuid', variant, 1, currency)

        expect(line_item.in_sale?).to be_false
        expect(line_item.price).to eq(variant.price_normal_in(currency).amount)
        expect(line_item.normal_price).to eq(variant.price_normal_in(currency).amount) 
      end

      it "should use normal_sale variant price when variant is in sale" do
        line_item = subject.send(:add_to_line_item, nil, 'uuid', variant_in_sale, 1, currency)

        expect(line_item.in_sale?).to be_true 
        expect(line_item.price).to eq(variant_in_sale.price_normal_sale_in(currency).amount)
        expect(line_item.normal_price).to eq(variant_in_sale.price_normal_in(currency).amount)
      end


      it "should set the line item price to include the optional parts' prices" do
        variant = create(:variant, price: 60.00)
        
        part1 = create(:part)
        create(:price, variant: part1, amount: 9.99, is_kit: true)
        part2 = create(:part)
        create(:price, variant: part2, amount: 8.00, is_kit: true)
        
        options = [ [part1, 2], [part2, 1] ]
        line_item = subject.send(:add_to_line_item, nil, 'uuid', variant, 1, 'USD', nil, options)

        expect(order.line_items.first.price).to eq(87.98)
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

      it 'should add one line item with one personalisation' do
        line_item = subject.add(variant,3,nil,nil,nil,personalisation_params)
        subject.remove(variant)

        line_item.reload.quantity.should == 2
        line_item.line_item_personalisations.size.should == 1
      end
    end
  end

  context "Class Methods" do

    it "should generate  uuid" do
      personalisations = []
      options_with_qty = [
        [FactoryGirl.create(:variant), 1],
        [FactoryGirl.create(:variant), 1],
      ]

      expected_uuid = "#{variant.id}__#{options_with_qty[0][0].id}-#{options_with_qty[0][1]}:#{options_with_qty[1][0].id}-#{options_with_qty[1][1]}"
      actual_uuid = subject.send( :generate_uuid, variant, options_with_qty, personalisations )

      expect(actual_uuid).to eq(expected_uuid)
    end
  end

end
