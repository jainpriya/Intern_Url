class SearchController < ApplicationController

	def search
		if params[:term].nil?
      		@urls = []
      	else
        	@urls = Url.search (params[:term]),fields: [:short_url], match: :word_start
    	end
	end
end
