require 'test_helper'

class LearndashEnrollmentTest < ActiveSupport::TestCase
  # This creates a user on wordpress
  test 'enroll a user' do
    api = EffectiveLearndash.api

    # Load Existing Courses
    Effective::LearndashCourse.sync!
    learndash_course = Effective::LearndashCourse.where(title: 'Test Course').first!

    # Create a User
    user = build_unique_user()
    learndash_user = user.find_or_create_learndash_user()

    # Make sure no enrollment already exists
    assert api.find_user_course(learndash_user, learndash_course).blank?

    # Create an Enrollment
    enrollment = learndash_user.learndash_enrollments.build(learndash_course: learndash_course)
    assert api.find_enrollment(enrollment).blank?
    enrollment.save!

    # The enrollment exists
    assert enrollment.date_started.present?
    assert api.find_enrollment(enrollment).present?
  end

end
