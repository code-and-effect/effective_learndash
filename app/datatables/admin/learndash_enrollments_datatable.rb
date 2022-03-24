module Admin
  class EffectiveLearndashEnrollmentsDatatable < Effective::Datatable
    datatable do
      col :id, visible: false

      col :last_synced_at
      col :owner, visible: false
      col :learndash_course, label: 'LearnDash Course'
      col :learndash_user, label: 'LearnDash User'

      col :progress_status
      col :last_step, visible: false
      col :steps_completed, visible: false
      col :steps_total, visible: false

      col :date_started
      col :date_completed

      actions_col
    end

    collection do
      Effective::LearndashEnrollment.deep.all
    end

  end
end
