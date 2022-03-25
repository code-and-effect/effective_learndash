require 'test_helper'

class LearndashApiTest < ActiveSupport::TestCase
  test 'api credentials are present' do
    api = EffectiveLearndash.api

    assert api.url.present?
    assert api.username.present?
    assert api.password.present?
  end

  test 'me' do
    api = EffectiveLearndash.api

    user = api.me()
    assert user.kind_of?(Hash)

    # Wordpress Attributes
    assert user[:id].present?
    assert user[:name].present?
    assert user[:link].present?
    assert user[:link].start_with?(api.url)
    assert user[:_links].present?

    # LearnDash Courses
    links = user[:_links]

    assert links[:courses].present?
    assert links[:courses].first[:href].start_with?(api.url)

    assert links[:groups].present?
    assert links[:groups].first[:href].start_with?(api.url)

    assert links[:"course-progress"].present?
    assert links[:"course-progress"].first[:href].start_with?(api.url)

    assert links[:quiz_progress].present?
    assert links[:quiz_progress].first[:href].start_with?(api.url)
  end

  test 'find user' do
    api = EffectiveLearndash.api

    response = api.find_user(999999)
    assert response.blank?

    response = api.find_user('test@nope.com')
    assert response.blank?

    response = api.find_user(User.new(email: 'test@nope.com'))
    assert response.blank?
  end

  # This creates a user on wordpress
  test 'create user' do
    api = EffectiveLearndash.api
    user = build_unique_user()

    response = api.find_user(user)
    assert response.blank?

    response = api.create_user(user)
    assert response.present?

    assert_equal user.email, response[:email]
    assert_equal user.first_name, response[:first_name]
    assert_equal user.last_name, response[:last_name]

    assert response[:password].present?
    assert_equal ['subscriber'], response[:roles]

    response = api.find_user(user)
    assert response.present?
  end
end
