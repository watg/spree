require 'spec_helper'

module Spree
  module Core
    describe MailSettings do
      context "override option is true" do
        before { Config.override_actionmailer_config = true }

        it "calls override!" do
          allow(Rails.env).to receive(:test?).and_return(false)
          expect(ActionMailer::Base).to receive(:delivery_method=).with(:spree)
          MailSettings.init
        end
      end

      context "override option is false" do
        before { Config.override_actionmailer_config = false }

        it "doesnt calls override!" do
          expect(MailSettings).not_to receive(:override!)
          MailSettings.init
        end
      end

      describe "mail_server_settings" do
        subject{ described_class.new.mail_server_settings }
        context "authentication method is none" do
          before do
            Config.mail_host = "smtp.example.com"
            Config.mail_domain = "example.com"
            Config.mail_port = 123
            Config.mail_auth_type = MailSettings::SECURE_CONNECTION_TYPES[0]
            Config.smtp_username = "schof"
            Config.smtp_password = "hellospree!"
            Config.secure_connection_type = "TLS"
          end

          it { expect(subject[:address]).to eq("smtp.example.com") }
          it { expect(subject[:domain]).to eq("example.com") }
          it { expect(subject[:port]).to eq(123) }
          it { expect(subject[:authentication]).to eq("None") }
          it { expect(subject[:enable_starttls_auto]).to be true }
          it { is_expected.not_to have_key(:user_name) }
          it { is_expected.not_to have_key(:password) }
        end

        context "when mail_auth_type is other than none" do
          before do
            Config.mail_auth_type = "login"
            Config.smtp_username = "schof"
            Config.smtp_password = "hellospree!"
          end

          context "overrides user credentials" do
            it { expect(subject[:user_name]).to eq("schof") }
            it { expect(subject[:password]).to eq("hellospree!") }
          end
        end
      end
    end
  end
end
