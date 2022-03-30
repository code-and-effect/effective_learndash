module Admin
  class EffectiveLearndashEnrollmentsDatatable < Effective::Datatable
    filters do
      scope :all
      scope :completed
      scope :in_progress
      scope :not_started
    end

    datatable do
      col :id, visible: false

      col :last_refreshed, visible: false do |enrollment|
        time_ago_in_words(enrollment.last_synced_at) + ' ago'
      end

      col :owner
      col :learndash_course
      col :learndash_user

      col :progress_status

      col :last_step, visible: false
      col :steps_completed, visible: false
      col :steps_total, visible: false

      col :date_started, as: :date
      col :date_completed, as: :date

      actions_col
    end

    collection do
      Effective::LearndashEnrollment.deep.all
    end

  end
end
