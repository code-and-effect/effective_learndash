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

    # Returns a WP Hash of User or nil
    def find_user(value)
      # Find by email
      if value.kind_of?(String) && value.include?('@')
        return find("/wp/v2/users", context: :edit, search: value)
      end

      # Find by param value
      user_id = user_id(value)
      user = find("/wp/v2/users/#{user_id}", context: :edit) if user_id
      return user if user.present?

      # Find by email
      email = value.try(:email)
      user = find("/wp/v2/users", context: :edit, search: email) if email
      return user if user.present?

      # Otherwise none
      nil
    end

    # Usernames can only contain lowercase letters (a-z) and numbers.
    def create_user(owner)
      raise ('expected a leardash owner') unless owner.class.respond_to?(:effective_learndash_owner?)
      raise('owner must have an email') unless owner.try(:email).present?

      username = EffectiveLearndash.wp_username_for(owner)
      password = EffectiveLearndash.wp_password_for(owner)

      payload = {
        username: username,
        password: password,

        name: owner.to_s,
        email: owner.email,
        roles: ['subscriber'],

        first_name: owner.try(:first_name),
        last_name: owner.try(:last_name)
      }.compact

      post("/wp/v2/users", payload.stringify_keys).merge(password: password)
    end

    def courses
      get('/ldlms/v2/sfwd-courses')
    end

    private

    def user_id(resource)
      if resource.class.respond_to?(:effective_learndash_owner?) # This is a user
        resource.learndash_user&.user_id
      elsif resource.kind_of?(LearndashUser)
        resource.user_id
      else
        resource
      end
    end

    def find(endpoint, params = nil)
      response = get(endpoint, params)

      if response == false
        nil
      elsif response.kind_of?(Hash) && response.dig(:data, :status) == 404
        nil
      elsif response.kind_of?(Hash)
        response
      elsif response.kind_of?(Array)
        response.first
      else
        raise("unexpected Learndash API response #{respone}")
      end
    end

    def get(endpoint, params = nil)
      query = ('?' + params.compact.map { |k, v| "#{k}=#{v}" }.join('&')) if params.present?

      uri = URI.parse(api_url + endpoint + query.to_s)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.read_timeout = 10

      response = with_retries do
        puts("[GET] #{uri}") if Rails.env.development?
        http.get(uri, headers)
      end

      unless response.code.start_with?('2')
        puts("Response code: #{response.code} #{response.body}") if Rails.env.development?
        return false
      end

      JSON.parse(response.body, symbolize_names: true)
    end

    def post(endpoint, params = nil)
      uri = URI.parse(api_url + endpoint)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.read_timeout = 10

      response = with_retries do
        puts("[POST] #{uri} #{params}") if Rails.env.development?
        http.post(uri.path, (params || {}).to_json, headers)
      end

      unless response.code.start_with?('2')
        raise("Invalid Learndash API request: #{response.body}")
      end

      JSON.parse(response.body, symbolize_names: true)
    end

    def api_url
      url.chomp('/') + '/wp-json'
    end

    def headers
      {
        'Authorization': "Basic #{Base64.strict_encode64("#{username}:#{password}")}",
        'Accept': 'application/json',
        'Content-Type': 'application/json'
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
