class UrlsController < ApplicationController

	skip_before_action :verify_authenticity_token
	def index
	end

	def new
		@url = Url.new
	end

	def create
		@url = Url.new(url_params)
		@url.long_url = sanitize(@url.long_url)
		respond_to do |format|
			@url_find = Rails.cache.fetch(@url.long_url , expires_in: 12.0.hours) do
							Url.find_by_long_url(@url.long_url)
            			end 
			@url.short_url = @url_find.nil? ? Url.shorten_url(@url.long_url): @url_find.short_url
			if @url.short_url == "Invalid Url"
				flash[:notice] = "Invalid Url"
				format.html {render :new}
				format.json { render json: {"response": "invalid" }}
			else
		    	format.html {render :show}
		    	format.json { render json: {"response": @url.short_url} }
		    end
		end
	end

	def show
	end

	def get_long_url
		@url = Url.new(url_params)
		@url.short_url = @url.short_url
		respond_to do |format|
			@url_find = Rails.cache.fetch(@url.short_url,expires_in: 12.0.hours) do
							Url.find_by_short_url(@url.short_url)
						end
			@url.long_url = @url_find.nil? ? "Not found" : @url_find.long_url
			if @url.long_url == "Not found"
		    	flash[:error] = 'Doesn\'t exist in database'
		    	format.html {render :new}
		    	format.json {render json: {"response": "not found"}}
		    else
		    	format.html{render 'get_long_url'}
		    	format.json{ render json: {"response": @url.long_url}}
		    end
		end
	end

	private
	def sanitize(long_url)
	    long_url.strip!
	    sanitized_url = long_url.downcase.gsub(/(https?:\/\/)|(www\.)|(http:\/\/)/, "")
	    sanitized_url.strip!
	    while(sanitized_url[0] == "/")
	    	sanitized_url.slice!(0)
	    end
	    return sanitized_url
	end

	def url_params
        params.require(:url).permit(:long_url, :short_url)
    end

end
