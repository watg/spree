require 'spec_helper'

describe Mailchimp do
  let(:mc) { Mailchimp.new(email: 'test@mail.com', action: :subscribe, request_params: {list_name: 'Testing', signupEmail: 'test@mail.com'}.to_json) }
  let(:list_id) { 9870987 }

  before do
    ENV['MAILCHIMP_API_KEY']='089098TEST'
    mc.stub(:lists).and_return({'data' => [{'id' => list_id}]})
  end
  
  it "should submit customer details to MAILCHIMP" do
    expected_data = {
      id:           list_id,
      email:        {email: 'test@mail.com'},
      merge_vars:   {FNAME: nil,LNAME: nil},
      double_optin: false
    }
    mc.should_receive(:gb_subscribe).with(expected_data).and_return({euid: 234234, leid: 987})
    
    mc.subscribe!
  end

  it "should unsubscribe customer from Newsletter" do
    expected_data = {
      id: list_id,
      email: {email: 'test@mail.com'},
      delete_member: false,
      send_goodbye: true,
      send_notify: false
    }

    mc.should_receive(:gb_unsubscribe).with(expected_data).and_return({})

    mc.unsubscribe!
  end
  
  context "#process_requset" do
    it "should subcribe when action is subscribe" do
      mc.should_receive(:subscribe!)
      mc.process_request
    end

    it "should unsubcribe when action is unsubscribe" do
      mc.action = :unsubscribe

      mc.should_receive(:unsubscribe!)
      mc.process_request
    end
    
  end

  context "Validation" do
    it "on Customer Email" do
      bad_emails = %w(23stnoesthn @@@stnhoeu.com tnhe@stnhs 0932e@.nte).map do |e|
        Mailchimp.new(email: e, action: 'subscribe', request_params: {list_name: 'Testing', signupEmail: e}.to_json)
      end
     
      mc.should be_valid
      bad_emails.each {|email| email.should be_invalid }
    end

    it "should not create unsubscription when not subscription exists" do
      mc = Mailchimp.new(email: 'newcustomer@email.com', action: :unsubscribe, request_params: {}.to_json)
      expect(mc).to be_invalid
    end
  end

  context "Class Methods" do
    let(:subject) { Mailchimp }
    let(:mc) { FactoryGirl.create(:mailchimp, email: 'bob@sponge.net') }

    it "#customer_has_subscribed?" do
      expect(subject.customer_has_subscribed?('bob@sponge.net')).to be_true
    end
  end
end
