class CreateEffectiveLearndash < ActiveRecord::Migration[6.1]
  def change
    create_table :learndash_users do |t|
      t.integer :owner_id
      t.string :owner_type

      # Wordpress
      t.integer   :user_id
      t.string    :email
      t.string    :username
      t.string    :password

      t.datetime :last_course_enrolled_at
      t.datetime :last_course_completed_at

      t.timestamps
    end
  end
end
