module Admin
  class EffectiveLearndashUsersDatatable < Effective::Datatable
    datatable do
      col :id, visible: false
      col :owner

      col :user_id, label: 'Wordpress Id'
      col :email
      col :username
      col :password

      actions_col
    end

    collection do
      Effective::LearndashUser.deep.all
    end

  end
end
