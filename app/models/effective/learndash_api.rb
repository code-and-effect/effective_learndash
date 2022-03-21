require 'net/http'

module Effective
  class LearndashApi

    attr_accessor :url
    attr_accessor :username
    attr_accessor :password

    def initialize(url:, username:, password:)
      @url = url
      @username = username
      @password = password
    end

    # Methods
    # https://developer.wordpress.org/rest-api/reference/users/#definition
    # curl --user username:password http://www.example.com/wp-json/wp/v2/users/me
    def me
      get('/wp/v2/users/me')
    end

    def users
      get('/wp/v2/users')
    end

    def courses
      get('/ldlms/v2/courses')
    end

    private

    def get(endpoint, params = nil)
      query = ('?' + params.compact.map { |k, v| "#{k}=#{v}" }.join('&')) if params.present?

      uri = URI.parse(api_url + endpoint + query.to_s)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.read_timeout = 10

      response = with_retries do
        puts "[GET] #{uri}" if Rails.env.development?
        http.get(uri, headers)
      end

      JSON.parse(response.body, symbolize_names: true)
    end

    def post(endpoint, params = nil)
      uri = URI.parse(api_url + endpoint)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.read_timeout = 10

      response = with_retries do
        puts "[POST] #{uri} #{params}" if Rails.env.development?
        http.post(uri.path, (params || {}).to_json, headers)
      end

      unless response.code == '200' || response.code == '204'
        puts("Response code: #{response.code} #{response.body}")
        return false
      end

      JSON.parse(response.body, symbolize_names: true)
    end

    def api_url
      url.chomp('/') + '/wp-json'
    end

    def headers
      {
        'Authorization': "Basic #{Base64.strict_encode64("#{username}:#{password}")}",
        'Accept': 'application/json'
      }
    end

    def with_retries(retries: 3, wait: 2, &block)
      raise('expected a block') unless block_given?

      begin
        return yield
      rescue Exception => e
        if (retries -= 1) > 0
          sleep(wait); retry
        else
          raise
        end
      end
    end

  end
end
