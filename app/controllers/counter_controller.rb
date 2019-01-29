class CounterController < ApplicationController
  #counts daily number of new generated short_url
  def report
  	@count = Counter.last
  end
end
