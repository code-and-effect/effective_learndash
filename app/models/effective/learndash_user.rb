module Effective
  class LearndashUser < ActiveRecord::Base
    belongs_to :owner, polymorphic: true
    log_changes(to: :owner) if respond_to?(:log_changes)

    effective_resource do
      # This user the wordpress credentials
      user_id                   :integer
      username                  :string
      password                  :string

      last_course_assigned_at   :datetime
      last_course_completed_at  :datetime

      timestamps
    end

    scope :deep, -> { includes(:owner) }
    scope :sorted, -> { order(:id) }

    validates :user_id, presence: true
    validates :username, presence: true
    validates :password, presence: true

    def to_s
      username.presence || 'learndash user'
    end

  end
end
