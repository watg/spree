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

  it "returns the correct emails for a given marketing types" do
    sql = subject.send(:email_marketing_types_sql, [gang_marketing_type, peru_marketing_type])
    records = ActiveRecord::Base.connection.execute(sql).to_a
    d { records.map{ |r| r["email"] } }
    expect(records.size).to eq 3
    expect(records.first["email"]).to eq peru_gang.email
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
      sql = subject.send(:email_marketing_types_sql, [gang_marketing_type, peru_marketing_type])
      records = ActiveRecord::Base.connection.execute(sql).to_a
      d { records }
      expect(records.size).to eq 3
      expect(records.first["email"]).to eq peru_gang.email
    end

    describe "life_time_value_sql" do

      context "Multiple orders from multiple users" do

        before do
          2.times do
            user = create(:user)

            # First order
            order = create(:order, user: user, item_total: 100, currency: 'USD')
            create(:line_item, variant: gang_variant, order: order)
            create(:line_item, variant: peru_variant, order: order)
            order.update_column(:completed_at, '2014-02-01')

            # Second order
            order = create(:order, user: user, item_total: 50, currency: 'USD')
            create(:line_item, variant: kit_variant, order: order)
            order.update_column(:completed_at, '2014-03-01')

            # Third order
            order = create(:order, user: user, item_total: 50, currency: 'GBP')
            create(:line_item, variant: kit_variant, order: order, currency: 'GBP')
            order.update_column(:completed_at, '2014-04-01')

            # Fourth order
            order = create(:order, user: user, item_total: 50, currency: 'EUR')
            create(:line_item, variant: kit_variant, order: order, currency: 'EUR')
            order.update_column(:completed_at, '2014-04-02')
          end
        end

        it "returns the correct emails for a given marketing types" do
          sql = subject.send(:life_time_value_sql, [gang_marketing_type, peru_marketing_type])
          records = ActiveRecord::Base.connection.execute(sql).to_a
          d {records}
        end

      end

    end
  end

end

