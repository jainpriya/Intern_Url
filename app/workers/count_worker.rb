class CountWorker
  #Sidekiq worker to update counter table at midnight
    require 'date'
    include Sidekiq::Worker
    #perform sidekiq operation as a cron job
  def perform
      puts "Started at #{Time.now}"
      @counter = Counter.new
      @counter.date = Date.today
      @counter.count = $redis.get(Date.today) ? $redis.get(Date.today) : 0
      @counter.save
    end
end
