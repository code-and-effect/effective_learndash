require 'test_helper'

class LearndashTest < ActiveSupport::TestCase
  test 'user factory' do
    user = build_user()
    assert user.valid?
    assert user.learndash_user.blank?
  end
end
