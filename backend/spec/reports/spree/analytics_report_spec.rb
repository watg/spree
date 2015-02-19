require "spec_helper"

describe Spree::AnalyticsReport do
  let(:order_type) { create(:regular_order_type) }

  let(:gang) { create(:user, email: "gang") }
  let(:peru) { create(:user, email: "peru") }
  let(:kit) { create(:user, email: "kit") }
  let(:peru_gang) { create(:user, email: "peru_gang") }
  let(:peru_gang_kit) { create(:user, email: "peru_gang_kit") }

  let!(:gang_marketing_type) { create(:marketing_type, name: "gang") }
  let!(:peru_marketing_type) { create(:marketing_type, name: "peru") }
  let!(:kit_marketing_type) { create(:marketing_type, name: "kit") }

  let!(:gang_product) { create(:base_product, marketing_type: gang_marketing_type) }
  let!(:gang_variant) { create(:base_variant, product: gang_product) }

  let!(:peru_product) { create(:base_product, marketing_type: peru_marketing_type) }
  let!(:peru_variant) { create(:base_variant, product: peru_product) }

  let!(:kit_product) { create(:base_product, marketing_type: kit_marketing_type) }
  let!(:kit_variant) { create(:base_variant, product: kit_product) }

  let!(:order_peru_and_gang) { create(:order, user: peru_gang, order_type: order_type) }
  let!(:gang_line_item) { create(:line_item, variant: gang_variant, order: order_peru_and_gang) }
  let!(:peru_line_item) { create(:line_item, variant: peru_variant, order: order_peru_and_gang) }

  let!(:order_peru_and_gang_and_kit) { create(:order, user: peru_gang_kit, order_type: order_type) }
  let!(:kit_line_item_2) do
    create(:line_item, variant: kit_variant, order: order_peru_and_gang_and_kit)
  end
  let!(:gang_line_item_2) do
    create(:line_item, variant: gang_variant, order: order_peru_and_gang_and_kit)
  end
  let!(:peru_line_item_2) do
    create(:line_item, variant: peru_variant, order: order_peru_and_gang_and_kit)
  end

  let!(:order_gang_only) { create(:order, user: gang, order_type: order_type) }
  let!(:gang_line_item_3) { create(:line_item, variant: gang_variant, order: order_gang_only) }

  let!(:order_peru_only) { create(:order, user: peru, order_type: order_type) }
  let!(:peru_line_item_3) { create(:line_item, variant: peru_variant, order: order_peru_only) }

  let!(:order_kit_only) { create(:order, user: kit, order_type: order_type) }
  let!(:kit_line_item) { create(:line_item, variant: kit_variant, order: order_kit_only) }

  subject { Spree::AnalyticsReport.new([gang_marketing_type, peru_marketing_type]) }

  before :all do
    begin
      Spree::AnalyticsReport.drop_views
    ensure
      Spree::AnalyticsReport.create_views
    end
  end

  before do
    order_peru_and_gang_and_kit.update_column(:completed_at, "2014-01-01")
    order_peru_and_gang.update_column(:completed_at, "2014-01-01")
    order_peru_only.update_column(:completed_at, "2014-01-01")
    order_gang_only.update_column(:completed_at, "2014-01-01")
    order_kit_only.update_column(:completed_at, "2014-01-01")
    Spree::AnalyticsReport.refresh_views

    allow(subject).to receive(:exchange_rate).with('GBP').and_return(1)
    allow(subject).to receive(:exchange_rate).with('USD').and_return(0.61)
    allow(subject).to receive(:exchange_rate).with('EUR').and_return(0.83)
  end

  describe "first_orders_view_sql" do
    it "returns the correct emails" do
      records = ActiveRecord::Base.connection.execute("select * from first_orders_view").to_a
      expect(records.size).to eq 5
      expected = [peru_gang.email, peru_gang_kit.email, peru.email, gang.email, kit.email]
      expect(records.map { |r| r["email"] }).to match_array expected
    end

    context "wrong order type" do
      let(:order_type) { create(:order_type, name: "foobar") }

      it "returns no emails" do
        records = ActiveRecord::Base.connection.execute("select * from first_orders_view").to_a
        expect(records.size).to eq 0
      end
    end
  end

  describe "email_marketing_types_sql" do
    it "returns the correct emails for a given marketing types" do
      subject.marketing_types = [gang_marketing_type, peru_marketing_type]
      sql = subject.send(:email_marketing_types_sql)
      records = ActiveRecord::Base.connection.execute(sql).to_a
      expect(records.size).to eq 3
      expected = [peru_gang.email, peru.email, gang.email]
      expect(records.map { |r| r["email"] }).to match_array expected
    end

    context "wrong order type" do
      let(:order_type) { create(:order_type, name: "foobar") }

      it "returns no emails " do
        sql = subject.send(:email_marketing_types_sql)
        records = ActiveRecord::Base.connection.execute(sql).to_a
        expect(records.size).to eq 0
      end
    end

    context "Multiple orders from same user" do
      let!(:order_peru_and_gang_2) { create(:order, user: kit) }
      let!(:order_kit_2) { create(:order, user: peru_gang) }
      before do
        create(:line_item, variant: gang_variant, order: order_peru_and_gang_2)
        create(:line_item, variant: peru_variant, order: order_peru_and_gang_2)
        create(:line_item, variant: kit_variant, order: order_kit_2)
        order_peru_and_gang_2.update_column(:completed_at, "2014-01-02")
        order_kit_2.update_column(:completed_at, "2014-01-02")
      end

      it "returns the correct emails for a given marketing types" do
        subject.marketing_types = [gang_marketing_type, peru_marketing_type]
        sql = subject.send(:email_marketing_types_sql)
        records = ActiveRecord::Base.connection.execute(sql).to_a

        expect(records.size).to eq 3
        expected = [peru_gang.email, peru.email, gang.email]
        expect(records.map { |r| r["email"] }).to match_array expected
      end
    end

    context "wrong order type" do
      let(:order_type) { create(:order_type, name: "foobar") }

      it "returns no emails" do
        subject.marketing_types = [gang_marketing_type]
        sql = subject.send(:email_marketing_types_sql)
        records = ActiveRecord::Base.connection.execute(sql).to_a

        expect(records.size).to eq 0
      end
    end
  end

  describe "second_orders_view_sql" do
    before do
      create_first_order
      Spree::AnalyticsReport.refresh_views
    end

    it "returns the correct emails" do
      records = ActiveRecord::Base.connection.execute("select * from second_orders_view").to_a
      expect(records.size).to eq 1
    end
  end

  describe "life_time_value_sql" do
    it "returns the correct emails for a given marketing types" do
      subject.marketing_types = [gang_marketing_type, peru_marketing_type]
      data = subject.send(:fetch_data_for_life_time_value)
      expect(data.size).to eq 1
      expected = [
        {
          "first_purchase_date" => "2014-01-01 00:00:00",
          "purchase_date" => "2014-01-01 00:00:00",
          "unique_customers" => "3",
          "total_purchases" => "3",
          "total_spend" => "0"
        }
      ]
      expect(data).to eq expected
    end

    context "Multiple orders from multiple users" do
      before do
        2.times do
          create_first_order
        end
        Spree::AnalyticsReport.refresh_views
      end

      it "returns the correct emails for a given marketing types" do
        subject.marketing_types = [gang_marketing_type, peru_marketing_type]
        data = subject.send(:fetch_data_for_life_time_value)
        expect(data.size).to eq 4

        # The first one is from the setup, the next 4 entries are from the create_first_order
        expected = [
          {
            "first_purchase_date" => "2014-01-01 00:00:00",
            "purchase_date" => "2014-01-01 00:00:00",
            "unique_customers" => "3",
            "total_purchases" => "3",
            "total_spend" => "0"
          },
          {
            "first_purchase_date" => "2014-02-01 00:00:00",
            "purchase_date" => "2014-02-01 00:00:00",
            "unique_customers" => "2",
            "total_purchases" => "2",
            "total_spend" => "122"
          },
          {
            "first_purchase_date" => "2014-02-01 00:00:00",
            "purchase_date" => "2014-03-01 00:00:00",
            "unique_customers" => "2",
            "total_purchases" => "2",
            "total_spend" => "61"
          },
          {
            "first_purchase_date" => "2014-02-01 00:00:00",
            "purchase_date" => "2014-04-01 00:00:00",
            "unique_customers" => "2",
            "total_purchases" => "4",
            "total_spend" => "183"
          }
        ]
        expect(data).to eq expected
      end
    end
  end

  describe "returning_customers_sql" do
    it "returns the correct emails for a given marketing types" do
      subject.marketing_types = [gang_marketing_type, peru_marketing_type]
      data = subject.send(:fetch_data_for_returning_customers)
      expect(data.size).to eq 1
      expected = [
        {
          "first_order_date" => "2014-01-01 00:00:00",
          "first_order_count" => "3",
          "second_order_count" => "0"
        }
      ]
      expect(data).to eq expected
    end

    context "Multiple orders from multiple users" do
      before do
        2.times do
          create_first_order
        end
        Spree::AnalyticsReport.refresh_views
      end

      it "returns the correct emails for a given marketing types" do
        subject.marketing_types = [gang_marketing_type, peru_marketing_type]
        data = subject.send(:fetch_data_for_returning_customers)
        expect(data.size).to eq 2
        expected = [
          {
            "first_order_date" => "2014-01-01 00:00:00",
            "first_order_count" => "3",
            "second_order_count" => "0"
          },
          {
            "first_order_date" => "2014-02-01 00:00:00",
            "first_order_count" => "2",
            "second_order_count" => "2"
          }
        ]
        expect(data).to eq expected
      end
    end
  end

  describe "formatted_data_for_returning_customers" do
    let(:data) do
      [
        {
          "first_order_date" => "2014-01-01 00:00:00",
          "first_order_count" => "3",
          "second_order_count" => "1"
        },
        {
          "first_order_date" => "2014-02-01 00:00:00",
          "first_order_count" => "2",
          "second_order_count" => "2"
        }
      ]
    end

    it "retrieves formated data" do
      allow(subject).to receive(:fetch_data_for_returning_customers).and_return data
      data = []
      subject.send(:formatted_data_for_returning_customers) do |r|
        data << r
      end
      expect(data.size).to eq 2
      expect(data).to eq [["2014-01-01 00:00:00", "3", "1"], ["2014-02-01 00:00:00", "2", "2"]]
    end
  end

  describe "retrieve_data" do
    context "Multiple orders from multiple users" do
      before do
        2.times do
          create_first_order
        end
        Spree::AnalyticsReport.refresh_views
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
            3,
            0.0
          ],
          [
            "2014-02-01 00:00:00",
            "2014-02-01 00:00:00",
            2,
            2,
            122.0
          ],
          [
            "2014-02-01 00:00:00",
            "2014-03-01 00:00:00",
            2,
            2,
            61.0
          ],
          [
            "2014-02-01 00:00:00",
            "2014-04-01 00:00:00",
            2,
            4,
            183.0
          ]
        ]
        expect(data).to eq expected
      end
    end
  end

  def create_first_order
    user = create(:user)

    # First order
    order = create(:order, user: user, payment_total: 100, currency: "USD", order_type: order_type)
    create(:line_item, variant: gang_variant, order: order)
    create(:line_item, variant: peru_variant, order: order)
    order.update_column(:completed_at, "2014-02-01")

    # Second order
    order = create(:order, user: user, payment_total: 50, currency: "USD", order_type: order_type)
    create(:line_item, variant: kit_variant, order: order)
    order.update_column(:completed_at, "2014-03-01")

    # Third order
    order = create(:order, user: user, payment_total: 50, currency: "GBP", order_type: order_type)
    create(:line_item, variant: kit_variant, order: order, currency: "GBP")
    order.update_column(:completed_at, "2014-04-01")

    # Fourth order
    order = create(:order, user: user, payment_total: 50, currency: "EUR", order_type: order_type)
    create(:line_item, variant: kit_variant, order: order, currency: "EUR")
    order.update_column(:completed_at, "2014-04-02")

    # Fifth order which has a bad payment type, hence we should ignore
    bad_order_type = create(:order_type, name: "foobar")
    order =
      create(:order, user: user, payment_total: 50, currency: "USD", order_type: bad_order_type)
    create(:line_item, variant: kit_variant, order: order)
    order.update_column(:completed_at, "2014-03-01")
  end
end
