module Admin
  class EffectiveLearndashCoursesDatatable < Effective::Datatable
    datatable do
      col :id, visible: false

      col :course_id, label: 'Wordpress Id'
      col :title
      col :status
      col :link

      actions_col do |course|
        dropdown_link_to 'View Course', course.link, target: '_blank'
      end

    end

    collection do
      Effective::LearndashCourse.deep.all
    end

  end
end
