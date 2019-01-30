class Url < ApplicationRecord
  require 'elasticsearch/model'
  require "redis"
  require 'date'
  require 'digest/sha1'
  require 'base64'
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  index_name('urls') #Name of elastic search index
  after_commit :increment_count_generated_url 
  validates :long_url, presence: true, on: :create
  validates_format_of :long_url,
  with: /\A(?:(?:http|https):\/\/*)?([-a-zA-Z0-9.]{2,256}\.[a-z]{2,4})\b(?:\/[-a-zA-Z0-9@,!:%_\+.~#?&\/\/=]*)?\z/
  #Creates a Dynamic indexing on the basis of short_url
  settings index: {
    number_of_shards: 1,
    number_of_replicas: 0,
    analysis: {
      analyzer: {
        pattern: {
          type: 'pattern',
          pattern: "\\s|_|-|\\.",
          lowercase: true
        },
        trigram: {
          tokenizer: 'trigram'
        }
      },
      tokenizer: {
        trigram: {
          type: 'ngram',
          min_gram: 3,
          max_gram: 1000,
          token_chars: ['letter', 'digit']
        }
      }
    }
  } do
    mapping do
      indexes :short_url, type: 'text', analyzer: 'english' do
        indexes :keyword, analyzer: 'keyword'
        indexes :pattern, analyzer: 'pattern'
        indexes :trigram, analyzer: 'trigram'
      end
      indexes :long_url, type: 'text', analyzer: 'english' do
        indexes :keyword, analyzer: 'keyword'
        indexes :pattern, analyzer: 'pattern'
        indexes :trigram, analyzer: 'trigram'
      end
    end
  end
=begin
Author:Priya Jain
Authentication Required:None
Objective:Provides custom search for long and short urls
Params:Field(long_url/short_url);term(to be searched)
Output:objects of type url which matches search results  
=end
  def self.custom_search(params)
    field = params[:field]+".trigram"
    query = params[:term]
    urls = self.__elasticsearch__.search(
    {
      query: {
        bool: {
          must: [{
            term: {
              "#{field}":"#{query}"
            }
          }]
        }
      }
    }).records
    return urls
  end
=begin
Author:Priya Jain
Authentication Required:None
Objective:Increments the count of newly generated short_url every time a new _url is genearted and saved in database
Params:None
Output:Increments the count of generated short url in Redis
=end
  def increment_count_generated_url
    $redis.incr (Date.today)
  end
=begin
Author:Priya Jain
Objective:Gives a short Url and returns the genearted url or Invalid Url
Params:long_url from urls controller
Output:Generated short_url or invalid if long_url is invalid
=end
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
=begin
  Author:Priya Jain
  Objective:Encodes the long_url to short_url if long_url is valid
  Params:Long_url
  Output:Encoded short_url
=end
  def self.generate_short_url(long_url)
    regex_for_domain=/.*\./
    domain_name = long_url.match(regex_for_domain).to_s
    domain_name = self.encrypt_domain_name(domain_name)
    encrypted_id = Digest::MD5.hexdigest(long_url)[0,6]
    short_url = domain_name+'/'+encrypted_id
    return short_url
  end
=begin
Author:Priya Jain
Objective:Encodes the long_url to short_url if long_url is valid
Params:Long_url
Output:Encoded short_url
=end 
  def self.encrypt_domain_name(domain_name)
    @domain = Domain.find_by_domain_name(domain_name)
    encrypted_domain_name = @domain.nil? ? "others.com" : @domain.short_domain 
    return encrypted_domain_name
  end
end

