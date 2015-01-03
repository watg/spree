require 'spec_helper'

describe Spree::AssetsBackupJob do
  include WebMock::API

  before do
    WebMock.enable!
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_SECRET'
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_ID'
  end
  subject { Spree::AssetsBackupJob.new(:capture) }

  describe '#s3s3mirror' do
    subject { super().s3s3mirror }
    it { is_expected.to include('vendor/s3s3mirror/s3s3mirror.sh')}
  end

  describe '#source' do
    subject { super().source }
    it { is_expected.to match_array(['bucket1', 'bucket2']) }
  end

  describe '#destination' do
    subject { super().destination }
    it { is_expected.to eq 'dest-buck'}
  end

  # removing the most annoying spec output ever
  # it "performs without error" do
  #   expect { subject.perform }.to_not raise_error
  # end

  describe :capture do
    it "sends backup capture command" do
      expect(subject).to receive(:execute).twice
      subject.capture
    end
  end

  describe :execute do
    it "runs a backup command" do
      expect(Spree::NotificationMailer).to_not receive(:send_notification)
      subject.send(:execute, "echo 'bytes copied: 0 bytes'")
    end
  end

  describe :invalid_actions do
    subject { Spree::AssetsBackupJob.new(:bad) }

    it "performs without error" do
      expect { subject.perform }.to raise_error
    end

    it "fails to execute command" do
      expect(Spree::NotificationMailer).to receive(:send_notification)
      subject.send(:execute, "ls")
    end

  end
end
