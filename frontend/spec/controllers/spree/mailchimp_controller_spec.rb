require 'spec_helper'

describe MailchimpController, type: :controller do
  
  let(:user) { create(:user, email: 'user@spree.com') }

  before do 
    controller.stub(:try_spree_current_user => user)
    Delayed::Job.destroy_all 
    Delayed::Worker.delay_jobs = true 
  end

  context "subscribe" do
    it "should registration customer" do
      post :subscribe, {list_name: 'Testing', signupEmail: 'tester@woolandthegang.com'}
      should_be_successful(response) {
        expect(Mailchimp.count).to    eq(1)
      }
    end
    
    it "should return error message" do
      post :subscribe, {list_name: 'Testing', signupEmail: 'tester@com'}
      should_be_failure(response) {        
        expect(Mailchimp.count).to    eq(0)
      }
    end
    
    it "should only accept one email per action" do
      2.times do
        post :subscribe, {list_name: 'Testing', signupEmail: 'tester@woolandthegang.com'}
      end
      should_be_failure(response)
    end
  end

  
  context "unsubscribe" do
    before { FactoryGirl.create(:mailchimp, email: 'luther@bbc.co.uk', action: :subscribe) }
    
    it "should remove customer from newsletter" do
      post :unsubscribe, {signupEmail: 'luther@bbc.co.uk'}
      should_be_successful(response)
    end

  end

  def should_be_successful(response)
    expect(response).to be_success
    response_hash = JSON.parse(response.body)
    response_hash['response'].should eql('success')
    yield if block_given?
  end

  def should_be_failure(response)
    expect(response).to be_success
    response_hash = JSON.parse(response.body)
    response_hash['response'].should eql('failure')
    yield if block_given?
  end

end
