require 'spec_helper'

describe Spree::AnalyticsReport do

  let(:gang) { create(:user, email: 'gang')}
  let(:peru) { create(:user, email: 'peru')}
  let(:kit) { create(:user, email: 'kit')}
  let(:peru_gang) { create(:user, email: 'peru_gang')}
  let(:peru_gang_kit) { create(:user, email: 'peru_gang_kit')}

  let!(:gang_marketing_type) { create(:marketing_type, name: 'gang') }
  let!(:peru_marketing_type) { create(:marketing_type, name: 'peru') }
  let!(:kit_marketing_type) { create(:marketing_type, name: 'kit') }

  let!(:gang_product) { create(:base_product, marketing_type: gang_marketing_type) }
  let!(:gang_variant) { create(:base_variant, product: gang_product) }

  let!(:peru_product) { create(:base_product, marketing_type: peru_marketing_type) }
  let!(:peru_variant) { create(:base_variant, product: peru_product) }

  let!(:kit_product) { create(:base_product, marketing_type: kit_marketing_type) }
  let!(:kit_variant) { create(:base_variant, product: kit_product) }

  let!(:order_peru_and_gang) { create(:order, user: peru_gang) }
  let!(:gang_line_item) { create(:line_item, variant: gang_variant, order: order_peru_and_gang) }
  let!(:peru_line_item) { create(:line_item, variant: peru_variant, order: order_peru_and_gang) }

  let!(:order_peru_and_gang_and_kit) { create(:order, user: peru_gang_kit) }
  let!(:kit_line_item_2) { create(:line_item, variant: kit_variant, order: order_peru_and_gang_and_kit) }
  let!(:gang_line_item_2) { create(:line_item, variant: gang_variant, order: order_peru_and_gang_and_kit) }
  let!(:peru_line_item_2) { create(:line_item, variant: peru_variant, order: order_peru_and_gang_and_kit) }

  let!(:order_gang_only) { create(:order, user: gang) }
  let!(:gang_line_item_3) { create(:line_item, variant: gang_variant, order: order_gang_only) }

  let!(:order_peru_only) { create(:order, user: peru) }
  let!(:peru_line_item_3) { create(:line_item, variant: peru_variant, order: order_peru_only) }

  let!(:order_kit_only) { create(:order, user: kit) }
  let!(:kit_line_item) { create(:line_item, variant: kit_variant, order: order_kit_only) }

  subject { Spree::AnalyticsReport.new([gang_marketing_type, peru_marketing_type]) }

  before do
    order_peru_and_gang_and_kit.update_column(:completed_at, '2014-01-01')
    order_peru_and_gang.update_column(:completed_at, '2014-01-01')
    order_peru_only.update_column(:completed_at, '2014-01-01')
    order_gang_only.update_column(:completed_at, '2014-01-01')
    order_kit_only.update_column(:completed_at, '2014-01-01')
    Spree::AnalyticsReport.create_views
  end

  describe "email_marketing_types_sql" do
    it "returns the correct emails for a given marketing types" do
      subject.marketing_types = [gang_marketing_type, peru_marketing_type]
      sql = subject.send(:email_marketing_types_sql)
      records = ActiveRecord::Base.connection.execute(sql).to_a
      expect(records.size).to eq 3
      expect(records.map { |r| r['email']}).to match_array [ peru_gang.email, peru.email, gang.email ]
    end

    context "Multiple orders from same user" do
      let!(:order_peru_and_gang_2) { create(:order, user: kit) }
      let!(:order_kit_2) { create(:order, user: peru_gang) }
      before do
        create(:line_item, variant: gang_variant, order: order_peru_and_gang_2)
        create(:line_item, variant: peru_variant, order: order_peru_and_gang_2)
        create(:line_item, variant: kit_variant, order: order_kit_2)
        order_peru_and_gang_2.update_column(:completed_at, '2014-01-02')
        order_kit_2.update_column(:completed_at, '2014-01-02')
      end

      it "returns the correct emails for a given marketing types" do
        subject.marketing_types = [gang_marketing_type, peru_marketing_type]
        sql = subject.send(:email_marketing_types_sql)
        records = ActiveRecord::Base.connection.execute(sql).to_a

        expect(records.size).to eq 3
        expect(records.map { |r| r['email']}).to match_array [ peru_gang.email, peru.email, gang.email ]
      end
    end

    describe "life_time_value_sql" do

      it "returns the correct emails for a given marketing types" do
        subject.marketing_types = [gang_marketing_type, peru_marketing_type]
        data = subject.send(:fetch_data_for_life_time_value)
        expect(data.size).to eq 1
        expected = [{"first_purchase_date"=>"2014-01-01 00:00:00", "count"=>"3"}]
        expected = [{
          "currency" => "USD",
          "first_purchase_date" => "2014-01-01 00:00:00",
          "purchase_date" => "2014-01-01 00:00:00",
          "total_purchases" => "3",
          "total_spend" => "0.00"
        }]
        expect(data).to eq expected
      end


      context "Multiple orders from multiple users" do

        before do
          2.times do
            create_first_order
          end
        end

        it "returns the correct emails for a given marketing types" do
          subject.marketing_types = [gang_marketing_type, peru_marketing_type]
          data = subject.send(:fetch_data_for_life_time_value)
          expect(data.size).to eq 5

          # The first one is from the setup, the next 4 entries are from the create_first_order
          expected = [{
            "currency" => "USD",
            "first_purchase_date" => "2014-01-01 00:00:00",
            "purchase_date" => "2014-01-01 00:00:00",
            "total_purchases" => "3",
            "total_spend" => "0.00"
          },
          {
            "currency" => "USD",
            "first_purchase_date" => "2014-02-01 00:00:00",
            "purchase_date" => "2014-02-01 00:00:00",
            "total_purchases" => "2",
            "total_spend" => "200.00"
          },
          {
            "currency" => "USD",
            "first_purchase_date" => "2014-02-01 00:00:00",
            "purchase_date" => "2014-03-01 00:00:00",
            "total_purchases" => "2",
            "total_spend" => "100.00"
          },
          {
            "currency" => "EUR",
            "first_purchase_date" => "2014-02-01 00:00:00",
            "purchase_date" => "2014-04-01 00:00:00",
            "total_purchases" => "2",
            "total_spend" => "100.00"
          },
          {
            "currency" => "GBP",
            "first_purchase_date" => "2014-02-01 00:00:00",
            "purchase_date" => "2014-04-01 00:00:00",
            "total_purchases" => "2",
            "total_spend" => "100.00"
          }]

          expect(data).to eq expected
        end

      end

    end

    describe "returning_customers_sql" do

      it "returns the correct emails for a given marketing types" do
        subject.marketing_types = [gang_marketing_type, peru_marketing_type]
        data = subject.send(:fetch_data_for_returning_customers)
        expect(data.size).to eq 1
        expected = [{"first_purchase_date"=>"2014-01-01 00:00:00", "count"=>"3"}]
        expect(data).to eq expected
      end

      context "Multiple orders from multiple users" do

        before do
          2.times do
            create_first_order
          end
        end

        it "returns the correct emails for a given marketing types" do
          subject.marketing_types = [gang_marketing_type, peru_marketing_type]
          data = subject.send(:fetch_data_for_returning_customers)
          expect(data.size).to eq 2
          expected = [
            {"first_purchase_date"=>"2014-01-01 00:00:00", "count"=>"3"},
            {"first_purchase_date"=>"2014-02-01 00:00:00", "count"=>"2"},
          ]
          expect(data).to eq expected
        end

      end

    end

    describe "formatted_data_for_returning_customers" do

      let(:data) do [
        {"first_purchase_date"=>"2014-01-01 00:00:00", "count"=>"3"},
        {"first_purchase_date"=>"2014-02-01 00:00:00", "count"=>"2"}
      ]
      end

      it "retrieves formated data" do
        allow(subject).to receive(:fetch_data_for_returning_customers).and_return data
        data = []
        subject.send(:formatted_data_for_returning_customers) do |r|
          data << r
        end
        expect(data.size).to eq 2
        expect(data).to eq [["2014-01-01 00:00:00", "3"], ["2014-02-01 00:00:00", "2"]]
      end

    end


    describe "retrieve_data" do

      context "Multiple orders from multiple users" do

        before do
          2.times do
            create_first_order
          end
        end

        it "returns the correct emails for a given marketing types" do
          data = []
          subject.send(:formatted_data_for_life_time_value) do |r|
            data << r
          end
          expect(data.size).to eq 4

          expected = [
            [
              "2014-01-01 00:00:00",
              "2014-01-01 00:00:00",
              3,
              0.0
            ],
            [
              "2014-02-01 00:00:00",
              "2014-02-01 00:00:00",
              2,
              122.0
            ],
            [
              "2014-02-01 00:00:00",
              "2014-03-01 00:00:00",
              2,
              61.0
            ],
            [
              "2014-02-01 00:00:00",
              "2014-04-01 00:00:00",
              4,
              183.0
            ]
          ]
          expect(data).to eq expected
        end

      end

    end
  end


  def create_first_order
    user = create(:user)

    # First order
    order = create(:order, user: user, payment_total: 100, currency: 'USD')
    create(:line_item, variant: gang_variant, order: order)
    create(:line_item, variant: peru_variant, order: order)
    order.update_column(:completed_at, '2014-02-01')

    # Second order
    order = create(:order, user: user, payment_total: 50, currency: 'USD')
    create(:line_item, variant: kit_variant, order: order)
    order.update_column(:completed_at, '2014-03-01')

    # Third order
    order = create(:order, user: user, payment_total: 50, currency: 'GBP')
    create(:line_item, variant: kit_variant, order: order, currency: 'GBP')
    order.update_column(:completed_at, '2014-04-01')

    # Fourth order
    order = create(:order, user: user, payment_total: 50, currency: 'EUR')
    create(:line_item, variant: kit_variant, order: order, currency: 'EUR')
    order.update_column(:completed_at, '2014-04-02')

  end

end

