module Admin
  class EffectiveLearndashCoursesDatatable < Effective::Datatable
    datatable do
      order :title

      col :id, visible: false
      col :course_id, label: 'LearnDash Id', visible: false

      col :title
      col :status

      col :link do |course|
        link_to(course.link, course.link, target: '_blank')
      end

      col :learndash_users, visible: false

      col :can_register
      # Prices now live on date-ranged CourseFeeHistory records — see Admin::CourseFeeHistoriesDatatable.

      actions_col
    end

    collection do
      Effective::LearndashCourse.deep.all
    end

  end
end
