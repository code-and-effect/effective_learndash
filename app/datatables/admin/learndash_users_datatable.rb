module Admin
  class EffectiveLearndashUsersDatatable < Effective::Datatable
    datatable do
      col :user

      col :user_id, label: 'Wordpress User'
      col :username
      col :password

      actions_col
    end

    collection do
      Effective::LearndashUser.deep.all
    end

  end
end
