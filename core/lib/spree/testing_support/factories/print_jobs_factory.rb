FactoryGirl.define do
  factory :print_job, class: Spree::PrintJob do
    print_time { Time.now }
    job_type { "invoice" }

    after(:create) do |print_job|
      create(:order, invoice_print_job_id: print_job.id)
    end
  end
end
