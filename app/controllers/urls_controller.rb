class UrlsController < ApplicationController
  skip_before_action :verify_authenticity_token
=begin
**Author:** Priya Jain
**Common-Name:** Startin Page of Api
**Request-Type** : Get
**Routes** : /urls
**url:** URI("localhost:3000/urls)
**section** Sample Api Request
     section: Get request
     post request : localhost:3000/urls
     response : body {
                      "status": "200/rendered",
    --------------------------------------
**Content-Type:** application/json; charset=utf-8
**Output-Type:** HTML
**Output-Fields:** HTML 
**Host:** localhost:3000
=end
  def index
    if(!user_signed_in?)
      redirect_to root_path
    else
      flash[:notice] = ""
      flash[:error] = ""
    end
  end
=begin
**Author:** Priya Jain
**Common-Name:** Show Results of Create Request
**Request-Type** : Get
**Params**: [:id] of the object to be printed
**url:** URI("localhost:3000/urls)
    response : body {
                    "status": "200/rendered",
    --------------------------------------
**Content-Type:** application/json,text/html; charset=utf-8
**Output-Type:** HTML
**Output-Fields:** HTML 
**Host:** localhost:3000
=end
  def show
    if(!user_signed_in?)
    else
      redirect_to root_path
    end
  end
=begin
**Author:** Priya Jain
**Common-Name:** Process api request form  for converting long url to short url/searching short_url from long_url
**End-points:** Create
**Request-Type** : Get
**Routes** : /urls/new
**url:** URI("localhost:3000/urls/new)
**section** Sample Api Request
     section: Get request
     post request : localhost:3000/urls/new
     response : body {
                      "status": "200/rendered",
    --------------------------------------
**Content-Type:** application/json,text/html; charset=utf-8
**Output-Type:** HTML
**Output-Fields:** HTML FORM
**Host:** localhost:3000
=end
  def new
    if(user_signed_in?)
      flash[:notice] = ""
      @url = Url.new
    else
      redirect_to root_path
    end
  end
=begin
**Author:** Priya Jain
**Common-Name:** Process api post request for converting long url to short url
**End-points:** Other services
**Request-Type** : Post
**Routes** : url_shorteners
**url:** URI("localhost:3000/url_shorteners)
**Params:** long_url,type: text ,required: yes, DESCRIPTION-> 'Long Url which is to be converted'
**section** Sample Api Request
     section: Post request
     post request : localhost:3000/url_shorteners
     response : body {
                      "status": "200/OK;422/unprocessable entity",
                      "short_url": "hsg.com/940f7da6",
                      "long_url": "https://housing.com/news/budget-2018",
                      "domain": "housing"
                      },
    --------------------------------------
**Content-Type:** application/json; charset=utf-8
**Output-Type:** JSON
**Output-Fields:** status,long_url,short_url
**Host:** localhost:3000
=end
  def create
    @url = Url.new(url_params)
    long_url = sanitize(@url.long_url)
    respond_to do |format|
      @url.short_url = Url.shorten_url(long_url)
      if(@url.short_url == "invalid Url")
        @url.short_url = ""
        flash[:notice] = "Invalid Url"
        format.html {render :new,:status=>422}
        format.json { render json: {"response": "invalid" },:status=>422}
      else
        format.html {render :show}
        format.json { render json: {"response": @url.short_url} }
      end
    end
  end
=begin
**Author:** Priya Jain
**Common-Name:** Process api get request for retrieving long url from short url
**End-points:** Other services
**Request-Type** : Get
**Routes** : long_url
**url:** URI("localhost:3000/long_url?url={short_url = "hsg.com/940f7da6"})
**Params:** short_url,type: string ,required: yes, DESCRIPTION-> 'Short Url which is to be searched'
**section** Sample Api Request
     section: Get request
     post request : localhost:3000/long_url
     response : body {
                      "status": "200/OK;404/not found",
                      "short_url": "hsg.com/940f7da6",
                      "long_url": "https://housing.com/news/budget-2018",
                      "domain": "housing"
                      },
                     

     --------------------------------------
**Content-Type:** application/json; charset=utf-8
**Output-Type:** JSON
**Output-Fields:** status,long_url,short_url
**Host:** localhost:3000
=end
  def get_long_url
    @url = Url.new(url_params)
    @url.short_url = sanitize(@url.short_url)
    respond_to do |format|
      @url_find = Rails.cache.fetch(@url.short_url,expires_in: 12.0.hours){Url.find_by_short_url(@url.short_url)}
      @url.long_url = @url_find.nil? ? "Not found" : @url_find.long_url
      if @url.long_url == "Not found"
        @url.long_url = ""
        flash[:error] = 'Doesn\'t exist in database'
        format.html {render :new,:status=>404}
        format.json {render json: {"response": "not found"},:status=>404}
      else
        format.html{render 'get_long_url'}
        format.json{ render json: {"response": @url.long_url}}
      end
    end
  end
=begin
**Author:** Priya Jain
**Common-Name:** Process for sanitizing long url of different syntax but same paths
**End-points:** Create / get_long_url request
**Params:** long_url,type: text ,required: yes, DESCRIPTION-> 'long Url which is to be sanitized'
  response : body {
                    "long_url": "https://///housing.com/news/budget-2018",
                    "long_url": "https://housing.com/news/budget-2018",
                    "domain": "housing"
                      },
                --------------------------------------
**Output-Fields:** status,long_url,sanitized long_url
**Host:** localhost:3000
=end
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
=begin
Author:Priya Jain
Objective:Only permits those params that are required.Done for safety purpose
=end
  def url_params
    params.require(:url).permit(:long_url, :short_url)
  end
end
