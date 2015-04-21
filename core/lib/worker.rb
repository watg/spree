class Worker
  def self.enque(klass, delay)
    klass.delay(run_at: delay.from_now).perform
  end
end
