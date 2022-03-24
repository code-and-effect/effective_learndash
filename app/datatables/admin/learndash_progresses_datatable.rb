module Admin
  class EffectiveLearndashProgressesDatatable < Effective::Datatable
    datatable do
      col :id, visible: false

      col :owner
      col :learndash_course
      col :learndash_user

      col :progress_status

      col :last_step
      col :steps_completed
      col :steps_total

      col :created_at, label: 'Date Enroled'
      col :date_started
      col :date_completed

      actions_col
    end

    collection do
      Effective::LearndashProgress.deep.all
    end

  end
end
