module Admin
  class EffectiveLearndashCoursesDatatable < Effective::Datatable
    datatable do
      col :id, visible: false
      col :course_id, label: 'LearnDash Id', visible: false

      col :title
      col :status

      col :link do |course|
        link_to(course.link, course.link, target: '_blank')
      end

      col :learndash_users

      actions_col
    end

    collection do
      Effective::LearndashCourse.deep.all
    end

  end
end
