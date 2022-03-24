module Effective
  class LearndashUser < ActiveRecord::Base
    belongs_to :owner, polymorphic: true
    log_changes(to: :owner) if respond_to?(:log_changes)

    has_many :learndash_enrollments

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
    validate(if: -> { new_record? && owner.present? }) do
      self.errors.add(:owner, "already exists") if self.class.where(owner: owner).exists?
    end

    validate(if: -> { owner.present? && owner.persisted? && errors.blank? }) do
      assign_api_attributes
    end

    validates :user_id, presence: true
    validates :email, presence: true
    validates :username, presence: true
    validates :password, presence: true

    def to_s
      owner&.to_s || username.presence || 'learndash user'
    end

    def sync!
      assign_api_attributes; save!
    end

    private

    def learndash_api
      @learndash_api ||= EffectiveLearndash.api
    end

    def assign_api_attributes
      data = learndash_api.find_user(owner) || learndash_api.create_user(owner)

      # Take special care not to overwrite password. We only get password once.
      self.password ||= (data[:password].presence || 'unknown')

      assign_attributes(email: data[:email], user_id: data[:id], username: data[:username])
    end

  end
end
