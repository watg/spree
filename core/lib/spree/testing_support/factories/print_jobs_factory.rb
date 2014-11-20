FactoryGirl.define do
  factory :invoice_print_job, class: Spree::PrintJob do
    print_time { Time.now }
    job_type { "invoice" }
  end

  factory :image_sticker_print_job, class: Spree::PrintJob do
    print_time { Time.now }
    job_type { "image_sticker" }
  end


  factory :print_job, class: Spree::PrintJob do
    print_time { Time.now }
    job_type { "invoice" }

    after(:create) do |print_job|
      create(:order, invoice_print_job_id: print_job.id)
    end
  end
end
