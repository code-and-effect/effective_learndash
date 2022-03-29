# Dashboard Events
class EffectiveLearndashCoursesDatatable < Effective::Datatable
  filters do
    # Purchasable should be first here, so when displayed as a simple datatable on the dashboard they only see upcoming events
    scope :purchasable
    scope :all
  end

  datatable do
    order :title
    col :id, visible: false

    col :title, label: 'Title' do |learndash_course|
      link_to(learndash_course.to_s, effective_learndash.learndash_course_path(learndash_course))
    end

    actions_col show: false do |learndash_course|
      if learndash_course.purchasable?
        dropdown_link_to('Purchase', effective_learndash.new_learndash_course_course_purchase_wizard_path(learndash_course))
      end
    end
  end

  collection do
    Effective::LearndashCourse.deep.learndash_courses(user: current_user)
  end

end
