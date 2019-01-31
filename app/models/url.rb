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
**Author:** Priya Jain
**Objective:** Custom search for Elastic search
**Params:** field :long_url/short_url ;Term : keyword that is to be searched
**Output:** Url type objects containing related long_url /short_url
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
**Author:** Priya Jain
**Objective:** increment count of generated hits
**Output:** Perform asynchronously increment operation
=end
  def increment_count_generated_url
    CountWorker.perform_async
  end
=begin
**Author:** Priya Jain
**Objective:** Generates short Url from Long url 
**Params:** Long_url,type: text ,required: yes, DESCRIPTION-> 'long Url which is to be converted'
**Output:** short_url /invalid (if long_url is not valid)
=end
  def self.shorten_url(long_url)
    @url = Url.new
    @url.long_url = long_url
    @url.domain_name = self.fetch_domain_name(@url.long_url)
    @url_find =Url.find_by :domain_name => @url.domain_name, :long_url => @url.long_url
    if(@url_find.blank?)
      @url.short_url = self.generate_short_url(@url.long_url,@url.domain_name,@url.long_url.length)
      while(Url.exists?(short_url: @url.short_url))
        @url.short_url = self.generate_short_url(@url.long_url,@url.domain_name,(@url.long_url.length)+1)
      end
      if(@url.save)
        return @url.short_url
      else
        return "invalid Url"
      end
    else
      return @url_find.short_url
    end
  end
=begin
**Author:** Priya Jain
**Objective:** Encode short Url from Long url 
**Params:** Long_url,type: text ,required: yes, DESCRIPTION-> 'long Url which is to be converted'
            Domain,type:text,required:yes,DESCRIPTION->'Domain which is to be appended'
            length,type:integer,required:yes,DESCRIPTION->'length of the long_url'
**Output:** short_url
=end
  def self.generate_short_url(long_url,domain_name,length)
    domain_name = self.encrypt_domain_name(domain_name)
    encrypted_url = Digest::MD5.hexdigest(long_url)[0,6]
    encrypted_id = Digest::MD5.hexdigest(Base64.encode64(length.to_s))[0,2]
    short_url = domain_name+'/'+encrypted_url+encrypted_id
    return short_url
  end
=begin
**Author:** Priya Jain
**Objective:** Encode domain_name from domain_name 
**Params:**Domain,type:text,required:yes,DESCRIPTION->'Domain which is to be appended'
**Output:** encrypted domain name
=end
  def self.encrypt_domain_name(domain_name)
    @domain = Domain.find_by_domain_name(domain_name)
    encrypted_domain_name = @domain.nil? ? "others.com" : @domain.short_domain 
    return encrypted_domain_name
  end
=begin
**Author:** Priya Jain
**Objective:** Fetch domain_name from long_url 
**Params:**Long_url,type: text ,required: yes, DESCRIPTION-> 'long Url from which domain is to be extracted'
**Output:**domain name
=end
  def self.fetch_domain_name(long_url)
    regex_for_domain=/.*\./
    domain_name = long_url.match(regex_for_domain).to_s
    return domain_name
  end
end



