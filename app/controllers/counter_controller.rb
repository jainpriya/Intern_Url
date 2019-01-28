class CounterController < ApplicationController
  #count daily number of new generated short_url
  def report
  	@count = Counter.last
  end
end
