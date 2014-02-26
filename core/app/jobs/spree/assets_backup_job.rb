AssetsBackupJob = Struct.new(:action) do
  include ActiveModel::Validations

  validates_inclusion_of :action, in: [:capture], message: "Cannot perform action."
  validates_presence_of :destination
  validates_presence_of :source

  def perform
    raise errors.messages.to_s if invalid?
    send(action)
  end

  def capture
    cmd_fragment = [destination, Time.now.to_i]
    source.each do |bucket|
      execute("#{s3s3mirror} #{bucket} #{cmd_fragment.join('/')}/#{bucket}/ #{options}")
    end
  end

  def options
    "-m 50 -c 50"
  end
  
  def destination
    config['destination']
  end

  def source
    config['source']
  end

  def s3s3mirror
    @bin ||= File.expand_path(File.join(Rails.root, 'vendor/s3s3mirror/s3s3mirror.sh'))
  end

  private
  def config
    @config ||= YAML.load_file(File.join(Rails.root, 'config/assets_backup.yml'))[Rails.env]
  end
  
  def execute(cmd)
    output = %x[#{cmd}]
    if failed?(output)
      NotificationMailer.send_notification("[S3 BACKUP FAILED]: Could not execute command #{cmd} got output #{output}")
    end
  end

  def failed?(o)
    !o.match(/bytes copied: 0 bytes/) rescue true
  end
end
