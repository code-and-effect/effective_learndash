# Dashboard LearndashUsers
class EffectiveLearndashEnrollmentsDatatable < Effective::Datatable
  datatable do
    col :learndash_course
    col :progress_status

    col :last_step, visible: false
    col :steps_completed, visible: false
    col :steps_total, visible: false

    col :date_started, as: :date
    col :date_completed, as: :date
  end

  collection do
    Effective::LearndashEnrollment.deep.where(learndash_user: current_user.learndash_user)
  end

end
