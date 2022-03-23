require 'test_helper'

class LearndashOwnerTest < ActiveSupport::TestCase

  # This creates a user on wordpress
  test 'find_or_create_learndash_user' do
    api = EffectiveLearndash.api
    user = build_unique_user()

    response = api.find_user(user)
    assert response.blank?

    assert user.learndash_user.blank?

    learndash_user = user.find_or_create_learndash_user()
    assert learndash_user.present?

    assert learndash_user.kind_of?(Effective::LearndashUser)
    assert learndash_user.persisted?

    assert_equal user, learndash_user.owner
    assert_equal user.email, learndash_user.email

    user.reload
    assert user.learndash_user.present?
  end

end
