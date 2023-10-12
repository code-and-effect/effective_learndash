module Effective
  class LearndashEnrollment < ActiveRecord::Base
    belongs_to :owner, polymorphic: true
    belongs_to :learndash_course
    belongs_to :learndash_user

    acts_as_reportable if respond_to?(:acts_as_reportable)

    log_changes(to: :learndash_course, except: [:last_synced_at]) if respond_to?(:log_changes)

    # Only admin can mark finished
    # Finished is treated as an admin override for completed?
    PROGRESS_STATUSES = ['not-started', 'in-progress', 'completed', 'finished']

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

    scope :completed, -> { where(progress_status: ['completed', 'finished']) }
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

    # Admin override to completed
    def finished?
      progress_status == 'finished'
    end

    # Checked to see if the course is done throughout
    def completed?
      progress_status == 'completed' || finished?
    end

    def completed_on
      date_completed
    end

    def completed_at
      date_completed
    end

    def mark_as_finished!
      update!(progress_status: 'finished')
    end

    # Guess old status
    def unfinish!
      if date_completed.present?
        assign_attributes(progress_status: 'completed')
      elsif date_started.present?
        assign_attributes(progress_status: 'in-progress')
      else
        assign_attributes(progress_status: 'not-started')
      end

      save!
    end

    def refresh!(force: false)
      unless force
        return if last_synced_at.present? && (Time.zone.now - last_synced_at) < 5
      end

      assign_api_attributes
      save!
    end

    def assign_api_attributes(data = nil)
      data ||= EffectiveLearndash.api.find_enrollment(self) || EffectiveLearndash.api.create_enrollment(self)

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

  end
end
