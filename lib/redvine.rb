require 'httparty'
require 'hashie'
require 'redvine/version'
require 'uri'
require 'securerandom'

class Redvine

  class Error < StandardError; end
  class ConnectionError < Redvine::Error
    attr_reader :code

    def initialize(code)
      @code = code
    end
  end

  class AuthenticationRequiredError < Redvine::Error
    def initialize(msg="You must authenticate as a valid Vine user (call #connect) before accessing other API methods")
      super(msg)
    end
  end

  attr_reader :vine_key, :username, :user_id

  @@baseUrl = 'https://api.vineapp.com/'
  @@deviceToken = SecureRandom.hex 32
  @@userAgent = 'iphone/1.3.1 (iPhone; iOS 6.1.3; Scale/2.00) (Redvine)'

  def connect(opts={})
    validate_connect_args(opts)

    if opts[:key]
      @vine_key = opts[:key]
      return @vine_key
    end

    query = {username: opts[:email], password: opts[:password], deviceToken: @@deviceToken}
    headers = {'User-Agent' => @@userAgent}
    response = HTTParty.post(@@baseUrl + 'users/authenticate', {body: query, headers: headers})
    if opts[:skip_exception] || response['success']
      @vine_key = response.parsed_response['data']['key']
    else
      raise Redvine::ConnectionError.new(response['code'].to_i), response['error']
    end
  end

  def search(tag, opts={})
    raise(ArgumentError, 'You must specify a tag') if !tag
    get_request_data("timelines/tags/#{URI.escape tag}", opts)
  end

  def popular(opts={})
    get_request_data('timelines/popular', opts)
  end

  def promoted(opts={})
    get_request_data('timelines/promoted', opts)
  end

  def timeline(opts={})
    raise Redvine::AuthenticationRequiredError unless @vine_key
    get_request_data('timelines/graph', opts)
  end

  def likes(opts={})
    raise Redvine::AuthenticationRequiredError unless @vine_key
    user_likes('me', opts)
  end

  def following(uid, opts={})
    raise Redvine::AuthenticationRequiredError unless @vine_key
    raise(ArgumentError, 'You must specify a user id') if !uid
    get_request_data("users/#{uid}/following", opts)
  end

  def followers(uid, opts={})
    raise Redvine::AuthenticationRequiredError unless @vine_key
    raise(ArgumentError, 'You must specify a user id') if !uid
    get_request_data("users/#{uid}/followers", opts)
  end

  def user_profile(uid)
    raise(ArgumentError, 'You must specify a user id') if !uid
    if is_i?(uid)
      get_request_data("users/profiles/#{uid}", {})
    else
      get_request_data("users/profiles/vanity/#{uid}", {})
    end
  end

  def user_timeline(uid, opts={})
    raise(ArgumentError, 'You must specify a user id') if !uid
    get_request_data("timelines/users/#{uid}", opts)
  end

  def user_likes(uid, opts={})
    raise(ArgumentError, 'You must specify a user id') if !uid
    get_request_data("timelines/users/#{uid}/likes", opts)
  end

  def single_post(pid)
    raise(ArgumentError, 'You must specify a post id') if !pid
    if is_i?(pid)
      response = get_request_data("/timelines/posts/#{pid}")
    else
      response = get_request_data("/timelines/posts/s/#{pid}")
    end
    return response.kind_of?(Array) ? response.first : response
  end

  def search_posts(q, opts={})
    raise(ArgumentError, 'You must specify a user id') if !q
    get_request_data("posts/search/#{URI.escape q}", opts)
  end

  def self.popular(opts={})
    Redvine.new.popular(opts)
  end

  def self.user_profile(uid)
    Redvine.new.user_profile(uid)
  end

  def self.single_post(pid)
    Redvine.new.single_post(pid)
  end

  private

  def validate_connect_args(opts={})
    unless (opts.has_key?(:email) and opts.has_key?(:password)) or opts.has_key?(:key)
      raise(ArgumentError, 'You must specify both :email and :password, or :key')
    end
  end

  def session_headers
    {
      'User-Agent' => @@userAgent,
      'Accept' => '*/*',
      'Accept-Language' => 'en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5'
    }
  end

  def get_request_data(endpoint, query={})
    query.merge!(:size => 20) if query.has_key?(:page) && !query.has_key?(:size)
    args = {:headers => session_headers}
    args.merge!('vine-session-id' => @vine_key) if @vine_key
    args.merge!(:query => query) if query != {}
    response = HTTParty.get(@@baseUrl + endpoint, args).parsed_response
    if response.nil? or response.kind_of?(String)
      Hashie::Mash.new({"success" => false, "error" => true})
    elsif response['success'] == false
      response['error'] = true
      Hashie::Mash.new(response)
    else
      Hashie::Mash.new(response)
    end
  rescue Errno::ETIMEDOUT
    Hashie::Mash.new({"success" => false, "error" => true})
  end

  def is_i?(n)
    n.is_a?(Integer) || !!(n =~ /\A[-+]?[0-9]+\z/)
  end
end
