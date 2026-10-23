require 'test_helper'
require 'minitest/mock'

class LearndashApiContractTest < ActiveSupport::TestCase
  Response = Struct.new(:code, :body, :total_pages) do
    def [](header)
      total_pages if header == 'X-WP-TotalPages'
    end
  end

  class Http
    attr_accessor :use_ssl, :open_timeout, :read_timeout
    attr_reader :requests

    def initialize(responses)
      @responses = responses
      @requests = []
    end

    def get(uri, headers)
      @requests << [:get, uri, headers]
      @responses.shift || raise('Unexpected HTTP request')
    end

    def post(path, body, headers)
      @requests << [:post, path, JSON.parse(body), headers]
      @responses.shift || raise('Unexpected HTTP request')
    end
  end

  setup do
    @api = Effective::LearndashApi.new(url: 'https://courses.example.test/', username: 'api-user', password: 'application-password')
    @responses = []
    @http = Http.new(@responses)
  end

  test 'individual progress accepts the LearnDash 5 object response' do
    queue(course: 10, progress_status: 'in_progress')

    with_http do
      assert_equal({ course: 10, progress_status: 'in_progress' }, @api.find_user_course(42, 10))
    end
    assert_equal '/wp-json/ldlms/v2/users/42/course-progress/10', @http.requests.first[1].path
  end

  test 'individual progress accepts the LearnDash 4 array response' do
    queue([{ course: 10, progress_status: 'in-progress' }])

    with_http do
      assert_equal 'in-progress', @api.find_user_course(42, 10)[:progress_status]
    end
  end

  test 'missing individual progress returns nil for HTTP 404 and empty collections' do
    queue({ code: 'rest_no_route' }, status: '404')
    queue([])

    with_http do
      assert_nil @api.find_user_course(42, 10)
      assert_nil @api.find_user_course(42, 10)
    end
  end

  test 'authentication and server failures do not look like missing users' do
    %w[401 403 500 503].each do |status|
      queue({ code: 'request_failed' }, status: status)

      with_http do
        error = assert_raises(Effective::LearndashApi::Error) { @api.find_user(42) }
        assert_includes error.message, status
      end
    end
    assert_equal 4, @http.requests.length
  end

  test 'user course progress follows all response pages' do
    queue([{ course: 10 }], pages: '2')
    queue([{ course: 56 }], pages: '2')

    with_http do
      assert_equal [10, 56], @api.user_enrollments(42).map { |progress| progress[:course] }
    end
    assert_equal ['1', '2'], @http.requests.map { |request| URI.decode_www_form(request[1].query).to_h['page'] }
    assert @http.requests.all? { |request| URI.decode_www_form(request[1].query).to_h['per_page'] == '100' }
  end

  test 'later pages retain the known page count if a pagination header is absent' do
    queue([{ course: 10 }], pages: '3')
    queue([{ course: 56 }])
    queue([{ course: 141 }])

    with_http do
      assert_equal [10, 56, 141], @api.user_enrollments(42).map { |progress| progress[:course] }
    end
    assert_equal 3, @http.requests.length
  end

  test 'courses and users use their paginated collection endpoints' do
    queue([{ id: 10 }], pages: '2')
    queue([{ id: 56 }], pages: '2')
    queue([{ id: 42 }], pages: '1')

    with_http do
      assert_equal [10, 56], @api.courses.map { |course| course[:id] }
      assert_equal [42], @api.users.map { |user| user[:id] }
    end
    assert_equal ['/wp-json/ldlms/v2/sfwd-courses', '/wp-json/ldlms/v2/sfwd-courses', '/wp-json/wp/v2/users'], @http.requests.map { |request| request[1].path }
  end

  test 'search finds an exact match on a later page and encodes reserved characters' do
    email = 'person+training&review@example.test'
    queue([{ email: 'another@example.test' }], pages: '2')
    queue([{ id: 42, email: email }], pages: '2')

    with_http do
      assert_equal 42, @api.find_by('/wp/v2/users', :email, email)[:id]
    end
    @http.requests.each do |request|
      query = URI.decode_www_form(request[1].query).to_h
      assert_equal email, query['search']
      assert_equal 'edit', query['context']
    end
  end

  test 'failed later pages raise instead of returning partial course progress' do
    queue([{ course: 10 }], pages: '2')
    queue({ code: 'request_failed' }, status: '503')

    with_http do
      assert_raises(Effective::LearndashApi::Error) { @api.user_enrollments(42) }
    end
  end

  test 'empty collections and servers without pagination headers terminate' do
    queue([])
    queue([{ id: 10 }])

    with_http do
      assert_empty @api.users
      assert_equal [10], @api.courses.map { |course| course[:id] }
    end
    assert_equal 2, @http.requests.length
  end

  test 'collection failures and unexpected object responses are rejected' do
    queue({ code: 'rest_no_route' }, status: '404')
    queue({ course: 10 })

    with_http do
      assert_raises(Effective::LearndashApi::Error) { @api.courses }
      assert_raises(Effective::LearndashApi::Error) { @api.user_enrollments(42) }
    end
  end

  test 'enrollment posts the documented user_ids and reads the resulting progress' do
    queue([{ user_id: 42, status: 'success', code: 'learndash_rest_enroll_success' }])
    queue(course: 10, progress_status: 'not_started')

    with_http do
      assert_equal 'not_started', @api.create_user_course(42, 10)[:progress_status]
    end
    assert_equal :post, @http.requests.first[0]
    assert_equal '/wp-json/ldlms/v2/sfwd-courses/10/users', @http.requests.first[1]
    assert_equal({ 'user_ids' => [42] }, @http.requests.first[2])
  end

  test 'failed enrollment responses do not fetch or report successful progress' do
    queue([{ user_id: 42, status: 'failed', code: 'learndash_rest_enroll_failed' }])

    with_http do
      assert_raises(RuntimeError) { @api.create_user_course(42, 10) }
    end
    assert_equal 1, @http.requests.length
  end

  test 'development POST logging omits passwords from the payload' do
    queue(id: 42)

    output, = capture_io do
      Rails.stub(:env, 'development'.inquiry) do
        with_http { @api.post('/wp/v2/users', password: 'do-not-log-this') }
      end
    end
    assert_includes output, '[POST]'
    refute_includes output, 'do-not-log-this'
  end

  private

  def queue(body = nil, status: '200', pages: nil, **attributes)
    body = attributes if body.nil?
    @responses << Response.new(status, body.to_json, pages)
  end

  def with_http(&block)
    Net::HTTP.stub(:new, @http, &block)
  end
end
