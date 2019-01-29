class UrlsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
  end
  #Generates a new form 
  def new
    @url = Url.new
  end
  #Create a short_url for given long_url
  #params: long_url can be send in json and html form
  #Request Type: Post
  #Output:short_url in json and html format
  #Path:https://localhost:3000/url_shorteners
  def create
    @url = Url.new(url_params)
    @url.long_url = sanitize(@url.long_url)
    respond_to do |format|
      #Using Redis cache store
      @url_find = Rails.cache.fetch(@url.long_url , expires_in: 12.0.hours){ Url.find_by_long_url(@url.long_url) }
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
  #shows the view of short_url generated from long_url
  #Params:[:id]
  def show
  end
  #Gets a long_url from short_url from database
  #Params:short_url in json and html format
  #Request Type:Get
  #Output:Long_url in json and html format
  #Path:https://localhost:3000/long_url?short_url=params
  def get_long_url
    @url = Url.new(url_params)
    @url.short_url = sanitize(@url.short_url)
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
  #Interprets all urls as same with differing syntax of same paths
  #Params:Long_url given by the user in new form
  #Output:santized url with stripped out https://www.
  def sanitize(long_url)
      long_url.strip!
      sanitized_url = long_url.downcase.gsub(/(https?:\/\/)|(www\.)|(http:\/\/)/, "")
      sanitized_url.strip!
      while(sanitized_url[0] == "/")
        sanitized_url.slice!(0)
      end
      return sanitized_url
  end
  #Only permits those params that are required.Done for safety purpose
  def url_params
        params.require(:url).permit(:long_url, :short_url)
    end

end
