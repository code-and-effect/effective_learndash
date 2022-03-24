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
  end

  def learndash_user
    learndash_users.first
  end

  # Find or create
  def create_learndash_user
    learndash_user || create_learndash_user!
  end

  # Find or create
  def create_learndash_enrollment(course:)
    raise('expected a persisted learndash_user') unless learndash_user&.persisted?
    learndash_user.create_enrollment(course: course)
  end

  def learndash_enrollment(course:)
    learndash_user&.enrollment(course: course)
  end

  def completed_learndash_course?(course:)
    enrollment = learndash_enrollment(course: course)
    return false if enrollment.blank?

    return true if enrollment.completed?

    # Check the API
    enrollment.sync!

    enrollment.completed?
  end

  private

  def create_learndash_user!
    raise('must be persisted to create a learndash user') unless persisted?
    learndash_users.create!(owner: self)
  end

end
