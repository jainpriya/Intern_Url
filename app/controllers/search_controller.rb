class SearchController < ApplicationController
	# Uses elastic search to match words from starting 
	def search
		if params[:term].nil?
      @urls = []
    else
      @urls = Url.search (params[:term]),fields: [:short_url], match: :word_start
    end
	end
end
