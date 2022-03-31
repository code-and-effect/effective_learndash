module Admin
  class EffectiveLearndashUsersDatatable < Effective::Datatable
    datatable do
      col :id, visible: false
      col :user_id, label: 'LearnDash Id', visible: false

      col :last_refreshed, visible: true do |user|
        time_ago_in_words(user.last_synced_at) + ' ago'
      end

      col :owner
      col :email
      col :username
      col :password
      col :learndash_courses

      actions_col
    end

    collection do
      Effective::LearndashUser.deep.all
    end

  end
end
