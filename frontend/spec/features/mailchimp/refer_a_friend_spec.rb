require 'spec_helper'

describe "Refer a friend subscription", inaccessible: true do

  let(:interface) { double('List') }
  let(:referee_batch) {[
    {:email=>{:email=>"referee1@person.com"}, :merge_vars=>{"REFERRER"=>referrer_email}}, 
    {:email=>{:email=>"referee2@person.com"}, :merge_vars=>{"REFERRER"=>referrer_email}}, 
    {:email=>{:email=>"referee3@person.com"}, :merge_vars=>{"REFERRER"=>referrer_email}}
  ]}
  let(:referrer_email) { "referrer@person.com" }

  before do
    expect(Spree::Chimpy::Interface::List).to receive(:new).and_return(interface).twice
    expect(interface).to receive(:batch_subscribe).with(referee_batch)
    expect(interface).to receive(:batch_subscribe).with([{email: {email: referrer_email}, :merge_vars=>{"SOURCE"=>nil} }])
  end

  it "should be successful" do
    visit '/competition-2014'
    expect(page).not_to have_content("Wool respect")
      fill_in "referrerEmail", :with => referrer_email
      referee_fields = page.all(:fillable_field, 'refereeEmails[]')
      
      referee_fields[0].set("referee1@person.com")
      referee_fields[1].set("referee2@person.com")
      referee_fields[2].set("referee3@person.com")

    within '#referralForm' do
      click_button "Enter"
    end
    expect(page).to have_content("Wool respect")
    
    expect(Spree::Chimpy::Action.where(email: 'referrer@person.com')).to exist
  end

end
