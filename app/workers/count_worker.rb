class CountWorker
=begin
Author:Priya Jain
Objective:Updates Counter whenever a new url is generated
Output:updated counter table
=end
  require 'date'
  include Sidekiq::Worker
  def perform
    puts "Started at #{Time.now}"
    @counter = Counter.last
    if(@counter.nil?)
      @counter = Counter.new
      @counter.date = Date.today.to_s
      @counter.count = 1
    else
      if(@counter.date == Date.today.to_s)
        @counter.count+=1
      else
        @counter = Counter.new
        @counter.date = Date.today.to_s
        @counter.count = 1
      end
    end 
    @counter.save
  end
end
