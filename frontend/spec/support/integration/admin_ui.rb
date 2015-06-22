require 'spree'

module Support
  class AdminUi
    include Capybara::DSL
    include RSpec::Matchers
    attr_reader :master, :variant, :user

    def initialize(opts)
      @user     = opts[:user]
      @variant  = opts[:variant]
      @master   = opts[:master]
    end

    def login
      visit '/login'
      fill_in "Email", :with => user.email
      fill_in "Password", :with => user.password
      check "Remember me"
      click_button "Login"
    end

    def visit_item
      visit '/admin'
      click_on 'Products'
      click_on variant.product.name
      click_on 'Prices'
    end

    def check_price_form(variant_id)
      %w{ GBP USD EUR }.each do |c|
        expect(page.find_field("vp_#{variant_id}_normal_#{c}").value).to eq price(10.00, currency: c)
        expect(page.find_field("vp_#{variant_id}_normal_sale_#{c}").value).to eq price(20.00, currency: c)
        expect(page.find_field("vp_#{variant_id}_part_#{c}").value).to eq price(30.00, currency: c)
      end
    end

    def price(amount, currency)
      Spree::Money.new(amount, currency: currency).to_s
    end

    def update_item
      fill_in "vp_#{master.id}_normal_GBP", :with => "£999"
      fill_in "vp_#{master.id}_normal_sale_USD", :with =>  "$666"
      fill_in "vp_#{master.id}_part_EUR", :with => "€333"
      click_button 'apply_all'
    end

    def confirm_item_updated
      expect(page.find_field("vp_#{master.id}_normal_GBP").value).to eq "£999.00"
      expect(page.find_field("vp_#{master.id}_normal_sale_USD").value).to eq "$666.00"
      expect(page.find_field("vp_#{master.id}_part_EUR").value).to eq "€333.00"
    end
  end
end
