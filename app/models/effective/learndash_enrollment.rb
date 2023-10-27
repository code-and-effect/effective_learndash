module Effective
  class LearndashEnrollment < ActiveRecord::Base
    belongs_to :owner, polymorphic: true
    belongs_to :learndash_course
    belongs_to :learndash_user

    acts_as_reportable if respond_to?(:acts_as_reportable)

    log_changes(to: :learndash_course, except: [:last_synced_at]) if respond_to?(:log_changes)

    PROGRESS_STATUSES = ['not-started', 'in-progress', 'completed']

    effective_resource do
      last_synced_at      :string
      admin_completed     :boolean

      # Wordpress
      progress_status     :string

      last_step           :integer
      steps_completed     :integer
      steps_total         :integer

      date_started        :datetime
      date_completed      :datetime

      timestamps
    end

    scope :completed, -> { where(progress_status: 'completed').or(where(admin_completed: true)) }
    scope :in_progress, -> { where(progress_status: 'in-progress') }
    scope :not_started, -> { where(progress_status: 'not-started') }

    scope :deep, -> { all }
    scope :sorted, -> { order(:id) }

    # effective_reports
    def reportable_scopes
      { completed: nil, in_progress: nil, not_started: nil }
    end

    before_validation do
      self.owner ||= learndash_user&.owner
    end

    validates :learndash_user_id, uniqueness: { scope: :learndash_course_id, message: 'already enrolled in this course' }

    # First time sync only for creating a new enrollment from the form
    validate(if: -> { last_synced_at.blank? && learndash_user.present? && learndash_course.present? && errors.blank? }) do
      assign_api_attributes
    end

    def to_s
      persisted? ? "#{learndash_user} #{learndash_course}" : 'learndash enrollment'
    end

    def not_started?
      progress_status == 'not-started'
    end

    def in_progress?
      progress_status == 'in-progress'
    end

    # Checked to see if the course is done throughout
    def completed?
      progress_status == 'completed' || admin_completed?
    end

    def completed_on
      date_completed
    end

    # This is an admin action only
    def mark_as_completed!
      self.date_started ||= Time.zone.now
      self.date_completed ||= Time.zone.now

      update!(progress_status: 'completed', admin_completed: true)
    end

    # This is an admin action only
    def uncomplete!
      assign_attributes(date_started: nil, date_completed: nil, progress_status: nil, admin_completed: false)
      refresh!
    end

    def refresh!(force: false)
      unless force
        return if last_synced_at.present? && (Time.zone.now - last_synced_at) < 5
      end

      assign_api_attributes
      save!
    end

    def assign_api_attributes(data = nil)
      return if EffectiveLearndash.disabled?

      data ||= EffectiveLearndash.api.find_enrollment(self) || EffectiveLearndash.api.create_enrollment(self)

      assign_attributes(
        last_synced_at: Time.zone.now,
        last_step: data[:last_step],
        steps_completed: data[:steps_completed],
        steps_total: data[:steps_total],
      )

      if (date = data[:date_started]).present?
        assign_attributes(date_started: Time.use_zone('UTC') { Time.zone.parse(date) })
      end

      if (date = data[:date_completed]).present?
        assign_attributes(date_completed: Time.use_zone('UTC') { Time.zone.parse(date) })
      end

      unless completed?
        assign_attributes(progress_status: data[:progress_status])
      end

      true
    end

  end
end
