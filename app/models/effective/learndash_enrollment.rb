module Effective
  class LearndashEnrollment < ActiveRecord::Base
    belongs_to :owner, polymorphic: true
    belongs_to :learndash_course
    belongs_to :learndash_user

    effective_resource do
      last_synced_at      :string

      # Wordpress
      progress_status     :string

      last_step           :integer
      steps_completed     :integer
      steps_total         :integer

      date_started        :datetime
      date_completed      :datetime

      timestamps
    end

    scope :deep, -> { all }
    scope :sorted, -> { order(:id) }

    before_validation do
      self.owner ||= learndash_user&.owner
    end

    validates :learndash_user_id, uniqueness: { scope: :learndash_course_id, message: 'already enrolled in this course' }

    validate(if: -> { last_synced_at.blank? && learndash_user.present? && learndash_course.present? && errors.blank? }) do
      assign_api_attributes
    end

    def to_s
      persisted? ? "#{learndash_user} #{learndash_course}" : 'learndash enrollment'
    end

    def sync!
      assign_api_attributes
      save!
    end

    def assign_api_attributes(data = nil)
      data ||= learndash_api.find_enrollment(self) || learndash_api.create_enrollment(self)

      assign_attributes(
        last_synced_at: Time.zone.now,
        progress_status: data[:progress_status],
        last_step: data[:last_step],
        steps_completed: data[:steps_completed],
        steps_total: data[:steps_total],
        date_started: Time.use_zone('UTC') { Time.zone.parse(data[:date_started]) },
        date_completed: (Time.use_zone('UTC') { Time.zone.parse(data[:date_completed]) } if data[:date_completed].present?)
      )
    end

    private

    def learndash_api
      @learndash_api ||= EffectiveLearndash.api
    end

  end
end
