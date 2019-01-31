class SearchController < ApplicationController
=begin
Author:Priya Jain
Objective:Uses elastic search to match words from starting
Params:field(long_url/short_url);term(term to be searched)
Request:Get
Path:"/search"
Output:urls object
=end 
  def search
    if params[:term].nil?
      @urls = []
    else
      @urls = Url.custom_search(params)
      render 'search'
    end
  end
end
