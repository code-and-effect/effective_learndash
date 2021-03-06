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

    # List users
    def users
      get('/wp/v2/users')
    end

    # Returns a WP Hash of User or nil
    # This find by EMAIL doesn't work reliably
    def find_user(value)
      # Find by email
      if value.kind_of?(String) && value.include?('@')
        return find_by("/wp/v2/users", :email, email_for(value))
      end

      # Fetch by saved param value
      user_id = user_id(value)
      user = find("/wp/v2/users/#{user_id}", context: :edit) if user_id
      return user if user.present?

      # Find by email
      email = email_for(value)
      user = find_by("/wp/v2/users", :email, email) if email
      return user if user.present?

      # Find by username
      username = username_for(value) if value.class.respond_to?(:effective_learndash_owner?)
      user = find_by("/wp/v2/users", :username, username) if username
      return user if user.present?

      # Otherwise none
      nil
    end

    def update_password(owner, password)
      raise('expected a leardash owner') unless owner.class.respond_to?(:effective_learndash_owner?)
      raise('expected an existing learndash user') unless owner.learndash_user&.persisted?
      raise('expected a password') unless password.present?

      user = user_id(owner) || raise('expected a user')
      payload = { password: password }

      post("/wp/v2/users/#{user}", payload.stringify_keys)
    end

    # Create User
    # Usernames can only contain lowercase letters (a-z) and numbers.
    def create_user(owner)
      raise ('expected a leardash owner') unless owner.class.respond_to?(:effective_learndash_owner?)
      raise('owner must have an email') unless owner.try(:email).present?

      username = username_for(owner)
      password = password_for(owner)
      email = email_for(owner)

      payload = {
        username: username,
        password: password,
        email: email,

        name: owner.to_s,
        roles: ['subscriber'],

        first_name: owner.try(:first_name),
        last_name: owner.try(:last_name)
      }.compact

      post("/wp/v2/users", payload.stringify_keys).merge(password: password)
    end

    # List Courses
    def courses
      get('/ldlms/v2/sfwd-courses')
    end

    # List User Course Progress
    def user_enrollments(user)
      user = user_id(user) || raise('expected a user')

      get("/ldlms/v2/users/#{user}/course-progress")
    end

    # Helper methods for enrollments
    def find_enrollment(enrollment)
      find_user_course(enrollment.learndash_user, enrollment.learndash_course)
    end

    def create_enrollment(enrollment)
      create_user_course(enrollment.learndash_user, enrollment.learndash_course)
    end

    # Find User Course Progress
    def find_user_course(user, course)
      user = user_id(user) || raise('expected a user')
      course = course_id(course) || raise('expected a course')

      find("/ldlms/v2/users/#{user}/course-progress/#{course}")
    end

    # Crete Course User
    def create_user_course(user, course)
      user = user_id(user) || raise('expected a user')
      course = course_id(course) || raise('expected a course')

      response = post("/ldlms/v2/sfwd-courses/#{course}/users", user_ids: [user])

      unless (response.first.fetch(:code) rescue nil) == 'learndash_rest_enroll_success'
        raise("unsuccessful course creation: #{response}")
      end

      find_user_course(user, course)
    end

    # private under this point

    def user_id(resource)
      if resource.class.respond_to?(:effective_learndash_owner?) # This is a user
        resource.learndash_user&.user_id
      elsif resource.kind_of?(LearndashEnrollment)
        resource.learndash_user&.user_id
      elsif resource.kind_of?(LearndashUser)
        resource.user_id
      else
        resource
      end
    end

    def course_id(resource)
      if resource.kind_of?(LearndashCourse)
        resource.course_id
      elsif resource.kind_of?(LearndashEnrollment)
        resource.learndash_course&.course_id
      else
        resource
      end
    end

    def username_for(resource)
      raise('expected a LearnDash owner') unless resource.class.respond_to?(:effective_learndash_owner?) # This is a user
      name = EffectiveLearndash.wp_username_for(resource)

      Rails.env.production? ? name : "test#{name}"
    end

    def password_for(resource)
      raise('expected a LearnDash owner') unless resource.class.respond_to?(:effective_learndash_owner?) # This is a user
      EffectiveLearndash.wp_password_for(resource)
    end

    def email_for(value)
      email = value.try(:email) || value.to_s
      return nil unless email.present? && email.include?('@')

      Rails.env.production? ? email : "test#{email}"
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
        raise("unexpected LearnDash API response #{response}")
      end
    end

    # We can't just like, find by email, so we gotta search then filter on our side
    def find_by(endpoint, key, value)
      raise('expected a symbol key') unless key.kind_of?(Symbol)
      raise('expected a value') unless value.present?

      response = get(endpoint, { search: value, context: :edit })

      collection = Array(
        if response == false
          nil
        elsif response.kind_of?(Hash) && response.dig(:data, :status) == 404
          nil
        elsif response.kind_of?(Hash)
          response
        elsif response.kind_of?(Array)
          response
        else
          raise("unexpected LearnDash API find_by response #{response}")
        end
      )

      resource = collection.find { |data| data[key] == value }
      resource
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
