module Admin
  class EffectiveCoursePurchasesDatatable < Effective::Datatable
    filters do
      scope :unarchived, label: "All"
      scope :archived
    end

    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :learndash_course

      col :owner, visible: false
      col :course_purchase_wizard, visible: false

      col :purchased_order, visible: false
      col :price, visible: false

      actions_col
    end

    collection do
      scope = Effective::CoursePurchase.deep.purchased
    end

  end
end
