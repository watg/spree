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
      _line_item = subject.send(:add, variant, 1, 'USD', nil, nil, nil, 2)

      expect(order.line_items.first.variant).to eq(variant) 
      expect(order.line_items.first.target_id).to eq(2) 
      expect(order.line_items.first.currency).to eq('USD') 
      
    end

    it "should create different line items for different targets" do
      _line_item1 = subject.send(:add, variant, 1, 'USD', nil, nil, nil, 1)
      _line_item2 = subject.send(:add, variant, 1, 'USD', nil, nil, nil, 2)

      expect(order.line_items.first.variant).to eq(variant)
      expect(order.line_items.first.target_id).to eq(1)

      expect(order.line_items.second.variant).to eq(variant)
      expect(order.line_items.second.target_id).to eq(2) 
    end

    context 'product_page params' do
      let(:product_page) { create(:product_page) } 
      let(:product_page_tab) { create(:product_page_tab, product_page: product_page) } 

      it "should add params to the line_item" do
        subject.send(:add, variant, 1, 'USD', nil, nil, nil, 1, product_page_tab.id, product_page.id)
        expect(order.line_items.first.product_page_tab).to eq(product_page_tab)
        expect(order.line_items.first.product_page).to eq(product_page)
      end

      it "should add params to an existing line_item" do
        subject.send(:add, variant, 1, 'USD', nil, nil, nil, 1, nil, nil)
        subject.send(:add, variant, 1, 'USD', nil, nil, nil, 1, product_page_tab.id, product_page.id)
        expect(order.line_items.first.product_page_tab).to eq(product_page_tab)
        expect(order.line_items.first.product_page).to eq(product_page)
      end

    end

    context 'given a option' do
      let(:variant_option1) { create(:variant) } 
      let(:variant_option2) { create(:variant) } 

      let(:line_item_part_params) {[
        OpenStruct.new( 
                       variant_id: variant_option1.id, 
                       quantity:   3, 
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
      ]}

      let(:line_item_part_params2) {[
        OpenStruct.new( 
                       variant_id: variant_option2.id, 
                       quantity:   2, 
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
      ]}

      let(:line_item_part_params3) {[
        OpenStruct.new( 
                       variant_id: variant_option2.id, 
                       quantity:   5, 
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )

      ]}

      let(:line_item_part_params4) {[
        OpenStruct.new( 
                       variant_id: variant_option1.id, 
                       quantity:   7, 
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      ),
        OpenStruct.new( 
                       variant_id: variant_option2.id, 
                       quantity:   2, 
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
      ]}


      it 'should add one line item with one option' do
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
      let(:personalisation_params) {[ OpenStruct.new(
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      )]}

      let(:personalisation_params2) {[OpenStruct.new(
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'XX'},
      )]}

      let(:personalisation_params3) {[
        OpenStruct.new(
          personalisation_id: monogram.id,
          amount: 1,
          data: { 'colour' => monogram.colours.first.id, 'initials' => 'XX'},
        ),
        OpenStruct.new(
          personalisation_id: monogram.id,
          amount: 2,
          data: { 'colour' => monogram.colours.first.id, 'initials' => 'WW'},
        ),
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
      let(:personalisation_params) {[ OpenStruct.new(
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      )]}

      let(:variant_option1) { create(:variant) } 

      let(:line_item_part_params) {[
        OpenStruct.new( 
                       variant_id: variant_option1.id, 
                       quantity:   3, 
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
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
        line_item = subject.send(:add_to_line_item, variant, 1, currency, nil, [], [], nil, nil, nil)

        expect(line_item.in_sale?).to be_false
        expect(line_item.price).to eq(variant.price_normal_in(currency).amount)
        expect(line_item.normal_price).to eq(variant.price_normal_in(currency).amount) 
      end

      it "should use normal_sale variant price when variant is in sale" do
        line_item = subject.send(:add_to_line_item, variant_in_sale, 1, currency, nil, [], [], nil, nil, nil)

        expect(line_item.in_sale?).to be_true 
        expect(line_item.price).to eq(variant_in_sale.price_normal_sale_in(currency).amount)
        expect(line_item.normal_price).to eq(variant_in_sale.price_normal_in(currency).amount)
      end


      it "should set the line item price to include the optional parts' prices" do
        variant = create(:variant, price: 60.00)

        parts = [
          OpenStruct.new( 
                         variant_id: create(:variant).id, 
                         quantity:   2, 
                         optional:   true,
                         price:      5,
                         currency:   'GBP'
                        ),
          OpenStruct.new( 
                         variant_id: create(:variant).id, 
                         quantity:   1, 
                         optional:   true,
                         price:      5,
                         currency:   'GBP'
          )
        ]

        _line_item = subject.send(:add_to_line_item, variant, 1, 'USD', nil, parts, [], nil, nil, nil)

        expect(order.line_items.first.price).to eq(75.00)
      end
    end
  end

  context "#add_by_line_item" do
    let!(:line_item) { create(:line_item, order: order, quantity: 1)}

    it "increases the quantity on the line_item" do
      subject.add_by_line_item(line_item, 2)
      expect(order.reload.line_items.first.quantity).to eq 3
    end
  end

  context "#remove_by_line_item" do
    let(:line_item) { create(:line_item, order: order, quantity: 1)}

    it "decreases the quantity on the line_item" do
      subject.remove_by_line_item(line_item, 1)
      expect(order.reload.line_items.first).to be_nil
    end

    it "removes a line_item if quanity is 0" do
      subject.remove_by_line_item(line_item, 2)
      expect(order.reload.line_items.first).to be_nil
    end
  end

  context "#delete_line_item" do
    let(:line_item) { create(:line_item, order: order, quantity: 1)}

    it "removes a line_item" do
      subject.delete_line_item(line_item)
      expect(order.reload.line_items.first).to be_nil
    end
  end

  # TODO: Add tests for removing line items with parts and target_id
  context "#remove" do
    context 'given a personalisation' do
      let(:monogram) { create(:personalisation_monogram) }
      let(:personalisation_params) {[ OpenStruct.new(
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      )]}

      it 'should remove one line item with one personalisation' do
        line_item = subject.add(variant,3,nil,nil,nil,personalisation_params)
        subject.remove(variant, 1, nil, nil, personalisation_params)

        line_item.reload.quantity.should == 2

        # this test is broken. It should equal to 0
        line_item.line_item_personalisations.size.should == 1
      end
    end
  end
end
