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
end
