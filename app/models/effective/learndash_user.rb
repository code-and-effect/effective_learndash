module Effective
  class LearndashUser < ActiveRecord::Base
    belongs_to :owner, polymorphic: true
    log_changes(to: :owner) if respond_to?(:log_changes)

    effective_resource do
      # This user the wordpress credentials
      user_id                   :integer
      email                     :string
      username                  :string
      password                  :string

      timestamps
    end

    scope :deep, -> { includes(:owner) }
    scope :sorted, -> { order(:id) }

    # I want to validate owner uniqueness, and only then create the learndash user on wordpress
    validate(if: -> { owner && owner.persisted? && user_id.blank? }) do
      if self.class.where(owner: owner).exists?
        self.errors.add(:owner, "already exists for this owner")
      else
        find_or_create_learndash_user
      end
    end

    validates :user_id, presence: true
    validates :email, presence: true
    validates :username, presence: true
    validates :password, presence: true

    def to_s
      username.presence || 'learndash user'
    end

    def find_or_create_learndash_user
      data = learndash_api.find_user(owner) || learndash_api.create_user(owner)

      assign_attributes(
        email: data[:email],
        user_id: data[:id],
        username: data[:username],
        password: (data[:password] || 'unknown')
      )
    end

    def sync!
      find_or_create_learndash_user
      save!
    end

    private

    def learndash_api
      @learndash_api ||= EffectiveLearndash.api
    end

  end
end
