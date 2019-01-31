class CounterController < ApplicationController
=begin
Author:Priya Jain
Objective:Reports the number of created short urls in a day
Request: Get
Path :'counter/report'
=end
  def report
  	respond_to do |format|
      @count = Counter.last
      format.html{render :report}
      format.json{render json:{"count" => @count.count }}
    end
  end
  end
