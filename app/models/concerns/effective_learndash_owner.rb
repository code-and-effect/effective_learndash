# EffectiveLearndashOwner
#
# Mark your user model with effective_learndash_owner to get all the includes

module EffectiveLearndashOwner
  extend ActiveSupport::Concern

  module Base
    def effective_learndash_owner
      include ::EffectiveLearndashOwner
    end
  end

  module ClassMethods
    def effective_learndash_owner?; true; end
  end

  included do
    # Effective Scoped - this is a has_one in preactice
    has_many :learndash_users, class_name: 'Effective::LearndashUser', as: :owner, inverse_of: :owner, dependent: :delete_all
    accepts_nested_attributes_for :learndash_users, allow_destroy: true

    # Not used
    has_many :learndash_enrollments, class_name: 'Effective::LearndashEnrollment', as: :owner, inverse_of: :owner, dependent: :delete_all
    accepts_nested_attributes_for :learndash_enrollments, allow_destroy: true
  end

  # Find
  def learndash_user
    learndash_users.first
  end

  # Find or create
  def create_learndash_user
    learndash_user || learndash_users.create!(owner: self)
  end

  # Find
  def learndash_enrollment(course:)
    learndash_user&.enrollment(course: course)
  end

  # Find or create
  def create_learndash_enrollment(course:)
    raise('expected a persisted learndash_user') unless learndash_user&.persisted?
    learndash_user.create_enrollment(course: course)
  end

  # Find or sync and check completed?
  def learndash_completed?(course:)
    enrollment = learndash_enrollment(course: course)

    # We haven't been enrolled
    return false if enrollment.blank?

    # Return completed right away if previously marked completed
    return true if enrollment.completed?

    # Check the API
    enrollment.refresh!
    enrollment.completed?
  end

end
