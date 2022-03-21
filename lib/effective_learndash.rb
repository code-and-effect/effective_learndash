require 'effective_resources'
require 'effective_datatables'
require 'effective_learndash/engine'
require 'effective_learndash/version'

module EffectiveLearndash
  def self.config_keys
    [
      :learndash_url, :learndash_username, :learndash_password,
      :layout
    ]
  end

  include EffectiveGem

  def self.api
    raise('please set learndash_url in config/initializers/effective_learndash.rb') unless learndash_url.present?
    raise('please set learndash_username in config/initializers/effective_learndash.rb') unless learndash_username.present?
    raise('please set learndash_password in config/initializers/effective_learndash.rb') unless learndash_password.present?

    Effective::LearndashApi.new(
      url: learndash_url,
      username: learndash_username,
      password: learndash_password
    )

  end

end
