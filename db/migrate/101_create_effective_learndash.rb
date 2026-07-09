class CreateEffectiveLearndash < ActiveRecord::Migration[6.0]
  def change
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

      # Our attributes
      t.string :slug

      t.integer :roles_mask
      t.boolean :authenticate_user, default: false

      # Course Purchases
      t.boolean :can_register, default: false

      # Prices live on dated course_fee_histories (see below), not flat columns.

      t.string :qb_item_name
      t.boolean :tax_exempt, default: false

      t.timestamps
    end

    # Dated prices for a learndash course. The open-ended (end_on: nil) row holds the
    # current, ongoing prices; earlier rows are scheduled/expired price lists.
    create_table :course_fee_histories do |t|
      t.integer :learndash_course_id

      t.date :start_on
      t.date :end_on

      t.integer :regular_fee
      t.integer :member_fee

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :course_fee_histories, :learndash_course_id

    create_table :learndash_enrollments do |t|
      t.integer :owner_id
      t.string :owner_type

      t.integer :learndash_course_id
      t.integer :learndash_user_id

      t.datetime :last_synced_at
      t.boolean :admin_completed, default: false

      # Wordpress
      t.string :progress_status

      t.integer :last_step
      t.integer :steps_completed
      t.integer :steps_total

      t.datetime :date_started
      t.datetime :date_completed

      t.timestamps
    end

    create_table :course_registrants do |t|
      t.integer :owner_id
      t.string :owner_type

      t.integer :course_registration_id
      t.string :course_registration_type

      t.integer :learndash_course_id

      # Acts as purchasable
      t.integer :purchased_order_id
      t.integer :price
      t.boolean :tax_exempt, default: false
      t.string :qb_item_name

      t.timestamps
    end

    create_table :course_registrations do |t|
      t.string :token

      t.integer :owner_id
      t.string :owner_type

      t.integer :user_id
      t.string :user_type

      t.integer :learndash_course_id

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :course_registrations, [:owner_id, :owner_type]
    add_index :course_registrations, :status
    add_index :course_registrations, :token

  end
end
