module Admin
  class EffectiveLearndashUsersDatatable < Effective::Datatable
    datatable do
      col :id, visible: false
      col :user_id, label: 'LearnDash Id', visible: false

      col :owner
      col :email
      col :username
      col :password
      col :learndash_courses, label: 'LearnDash Courses'

      actions_col
    end

    collection do
      Effective::LearndashUser.deep.all
    end

  end
end
