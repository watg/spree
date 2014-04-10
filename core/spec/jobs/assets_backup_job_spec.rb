require 'spec_helper'

describe Spree::AssetsBackupJob do
  before do
    WebMock.enable!
    ENV['AWS_SECRET_ACCESS_KEY'] = 'FAKE_SECRET'
    ENV['AWS_ACCESS_KEY_ID'] = 'FAKE_ID'
  end
  subject { Spree::AssetsBackupJob.new(:capture) }
  its(:s3s3mirror)    { should include('vendor/s3s3mirror/s3s3mirror.sh')}
  its(:source)        { should match_array(['bucket1', 'bucket2']) }
  its(:destination)   { should eq 'dest-buck'}

  it "performs without error" do
    expect { subject.perform }.to_not raise_error
  end

  describe :capture do
    it "sends backup capture command" do
      expect(subject).to receive(:execute).twice
      subject.capture
    end
  end

  describe :execute do
    it "runs a backup command" do
      expect(NotificationMailer).to_not receive(:send_notification)
      subject.send(:execute, "echo 'bytes copied: 0 bytes'")
    end
  end

  describe :invalid_actions do
    subject { Spree::AssetsBackupJob.new(:bad) }

    it "performs without error" do
      expect { subject.perform }.to raise_error
    end

    it "fails to execute command" do
      expect(NotificationMailer).to receive(:send_notification)
      subject.send(:execute, "hhhhhhhhhhhhhhhhhhhhhhhhhh")      
    end
    
  end
end
