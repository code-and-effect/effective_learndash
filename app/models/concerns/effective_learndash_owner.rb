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

    scope :with_completed_learndash_course, -> (course) {
      courses = Array(course)
      raise('expected a Learndash Course') unless courses.all? { |course| course.kind_of?(Effective::LearndashCourse) }

      owners = Effective::LearndashEnrollment.completed
        .where(learndash_course: courses)
        .where(owner_type: name)
        .select(:owner_id)

      where(id: owners)
    }

  end

  # Find
  def learndash_user
    learndash_users.first
  end

  def in_progress_learndash_enrollments
    learndash_enrollments.reject(&:completed?).sort_by(&:created_at)
  end

  def completed_learndash_enrollments
    learndash_enrollments.select(&:completed?).sort_by(&:created_at)
  end

  def completed_learndash_courses
    learndash_enrollments.select(&:completed?).map(&:course).sort_by(&:id)
  end

  def learndash_enrolled_courses
    learndash_enrollments.map { |enrollment| enrollment.learndash_course }
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
    enrollment.completed?

    # DO NOT check API
  end

  def learndash_enroll!(courses:)
    courses = Array(courses)

    # Find or create the user
    create_learndash_user
    raise('expected a persisted learndash user') unless learndash_user&.persisted?

    courses.each do |course|
      # Find or Enroll in the course
      create_learndash_enrollment(course: course)
      raise('expected a persisted learndash enrollment') unless learndash_enrollment(course: course)&.persisted?
    end

    # This syncs the learndash enrollment locally
    learndash_enrollments.select { |enrollment| courses.include?(enrollment.learndash_course) }.each do |enrollment|
      enrollment.refresh! unless enrollment.completed?
    end

    save!

    after_learndash_enroll() if respond_to?(:after_learndash_enroll)

    true
  end

  def learndash_refresh!(force: false)
    raise('expected a previously persisted learndash user') if learndash_user.blank?

    learndash_enrollments.each do |enrollment|
      enrollment.refresh!(force: force) unless (force || enrollment.completed?)
    end

    save!

    after_learndash_refresh() if respond_to?(:after_learndash_refresh)

    true
  end

end
