# Dashboard Course Purchases Wizards
class EffectiveCoursePurchaseWizardsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :token, visible: false
    col :created_at, visible: false

    col(:submitted_at, label: 'Purchased on') do |wiz|
      wiz.submitted_at&.strftime('%F') || 'Incomplete'
    end

    col :learndash_course, search: :string do |wiz|
      wiz.learndash_course.to_s
    end

    col :owner, visible: false, search: :string
    col :status, visible: false
    col :orders, action: :show, visible: false, search: :string

    actions_col(actions: []) do |wiz|
      if wiz.draft?
        dropdown_link_to('Continue', effective_learndash.learndash_course_course_purchase_wizard_build_path(wiz.learndash_course, wiz, wiz.next_step), 'data-turbolinks' => false)
        dropdown_link_to('Delete', effective_learndash.learndash_course_course_purchase_wizard_path(wiz.learndash_course, wiz), 'data-confirm': "Really delete #{wiz}?", 'data-method': :delete)
      else
        dropdown_link_to('Show', effective_learndash.learndash_course_course_purchase_wizard_path(wiz.learndash_course, wiz))
      end
    end
  end

  collection do
    EffectiveLearndash.CoursePurchaseWizard.deep.where(owner: current_user)
  end

end
