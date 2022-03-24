class CreateEffectiveLearndash < ActiveRecord::Migration[6.1]
  create_table :learndash_users do |t|
    t.integer :owner_id
    t.string :owner_type

    t.datetime :last_synced_at

    # Wordpress
    t.integer   :user_id
    t.string    :email
    t.string    :username
    t.string    :password

    t.timestamps
  end

  create_table :learndash_courses do |t|
    # Wordpress
    t.integer :course_id
    t.string  :status
    t.string  :title
    t.string  :link

    t.timestamps
  end

  create_table :learndash_enrollments do |t|
    t.integer :owner_id
    t.string :owner_type

    t.integer :learndash_course_id
    t.integer :learndash_user_id

    t.datetime :last_synced_at

    # Wordpress
    t.string :progress_status

    t.integer :last_step
    t.integer :steps_completed
    t.integer :steps_total

    t.datetime :date_started
    t.datetime :date_completed

    t.timestamps
  end

end
