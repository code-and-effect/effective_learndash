module Effective
  class LearndashUser < ActiveRecord::Base
    belongs_to :owner, polymorphic: true
    log_changes(to: :owner) if respond_to?(:log_changes)

    has_many :learndash_enrollments
    accepts_nested_attributes_for :learndash_enrollments

    has_many :learndash_courses, through: :learndash_enrollments

    effective_resource do
      last_synced_at            :string

      # This user the wordpress credentials
      user_id                   :integer
      email                     :string
      username                  :string
      password                  :string

      timestamps
    end

    scope :deep, -> { includes(:owner) }
    scope :sorted, -> { order(:id) }

    # I want to validate owner uniqueness, and only then create the learndash user on wordpress
    validate(if: -> { new_record? && owner.present? }) do
      self.errors.add(:owner, "already exists") if self.class.where(owner: owner).exists?
    end

    # First time sync only for creating a new user from the form
    validate(if: -> { last_synced_at.blank? && owner.present? && errors.blank? }) do
      assign_api_attributes
    end

    with_options(if: -> { last_synced_at.present? }) do
      validates :user_id, presence: true
      validates :email, presence: true
      validates :username, presence: true
      validates :password, presence: true
    end

    def to_s
      owner&.to_s || username.presence || 'learndash user'
    end

    def check_and_refresh!
      return if last_synced_at.present? && (Time.zone.now - last_synced_at) < 10
      return if learndash_enrollments.none? { |enrollment| !enrollment.completed? }
      refresh!
    end

    def refresh!
      assign_api_course_enrollments
      save!
    end

    # Find
    def enrollment(course:)
      learndash_enrollments.find { |enrollment| enrollment.learndash_course_id == course.id }
    end

    # Find or build
    def build_enrollment(course:)
      enrollment(course: course) || learndash_enrollments.build(learndash_course: course)
    end

    # Create
    def create_enrollment(course:)
      enrollment = build_enrollment(course: course)
      enrollment.save!
      enrollment
    end

    # Assign my model attributes from API. These should never change.
    def assign_api_attributes(data = nil)
      data ||= EffectiveLearndash.api.find_user(owner) || EffectiveLearndash.api.create_user(owner)

      # Take special care not to overwrite password. We only get password once.
      self.password ||= (data[:password].presence || 'unknown')

      assign_attributes(email: data[:email], user_id: data[:id], username: data[:username], last_synced_at: Time.zone.now)
    end

    # This synchronizes all the course enrollments from the API down locally.
    def assign_api_course_enrollments
      raise('must be persisted') unless persisted?

      courses = LearndashCourse.all()

      EffectiveLearndash.api.user_enrollments(self).each do |data|
        course = courses.find { |course| course.course_id == data[:course] }
        raise("unable to find local persisted learndash course for id #{data[:course]}. Run Effective::LearndashCourse.sync!") unless course.present?

        enrollment = build_enrollment(course: course)
        enrollment.assign_api_attributes(data)
      end

      assign_attributes(last_synced_at: Time.zone.now)
    end

  end
end
