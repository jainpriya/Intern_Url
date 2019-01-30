class Url < ApplicationRecord
  searchkick word_start: [:short_url]
  require 'elasticsearch/model'
  include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
    #Creates a Dynamic indexing on the basis of short_url
  settings do
    mappings dynamic: false do
      indexes :short_url, type: :text
    end
  end
  require "redis"
  require 'date'
  index_name('urls') #Name of elastic search index
  after_commit :increment_count_generated_url 
  require 'digest/sha1'
  require 'base64'
  validates :long_url, presence: true, on: :create
    validates_format_of :long_url,
    with: /\A(?:(?:http|https):\/\/*)?([-a-zA-Z0-9.]{2,256}\.[a-z]{2,4})\b(?:\/[-a-zA-Z0-9@,!:%_\+.~#?&\/\/=]*)?\z/
    #Increments the count of newly generated short_url every time a new _url is genearted and saved in database
    def increment_count_generated_url
      $redis.incr (Date.today)
    end
    #Gives a short Url and returns the genearted url or Invalid Url
    def self.shorten_url(long_url)
      @url = Url.new
      @url.long_url = long_url
      @url.short_url = self.generate_short_url(long_url)
      if(@url.save)
        @url_find = Url.find_by_long_url(@url.long_url)
        resp = @url_find.short_url
        #Write in cache
        Rails.cache.write(@url.long_url,@url_find)
      else
        resp = "Invalid Url"
    end
    return resp
    end
    #Encodes the long_url to short_url
    #Params:Long_url
    #Output:Encoded short_url
    def self.generate_short_url(long_url)
      regex_for_domain=/.*\./
      domain_name = long_url.match(regex_for_domain).to_s
      domain_name = self.encrypt_domain_name(domain_name)
      id_for_encryption = Url.last.id.to_s
      encrypted_id = Digest::MD5.hexdigest(Base64.encode64(id_for_encryption))[0,3]
      short_url = domain_name+'/'+encrypted_id
      return short_url
    end
    #Encrypts domain name 
    def self.encrypt_domain_name(domain_name)
      case domain_name
      when "housing."
        domain_name = "hsg.com"
      when "makaan."
        domain_name = "mkn.com"
      when "proptiger."
        domain_name = "ptr.com"
      else
        domain_name = domain_name[0,3]+".com"
      end
      return domain_name
    end
end

