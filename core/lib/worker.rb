class Worker
  def self.enque(klass, delay)
    klass.delay(run_at: delay).perform
  end
end
