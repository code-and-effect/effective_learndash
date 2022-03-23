# EffectiveLearndashOwner
#
# Mark your user model with effective_learndash_owner to get all the includes

module EffectiveLearndashOwner
  extend ActiveSupport::Concern

  module Base
    def effective_learndash_owner
      include ::EffectiveLearndashOwner
    end
  end

  module ClassMethods
    def effective_learndash_owner?; true; end
  end

  included do
    # Effective Scoped - this is a has_one in preactice
    has_many :learndash_users, class_name: 'Effective::LearndashUser', inverse_of: :owner, dependent: :delete_all
    accepts_nested_attributes_for :learndash_users, allow_destroy: true
  end

  def learndash_user
    learndash_users.first
  end

  def find_or_create_learndash_user
    learndash_user || begin
      data = learndash_api.find_user(self) || learndash_api.create_user(self)
      attributes = { user_id: data[:id], username: data[:username], password: (data[:password].presence || 'unknown') }
      learndash_users.create!(attributes)
    end
  end

  private

  def learndash_api
    @learndash_api ||= EffectiveLearndash.api
  end

end
