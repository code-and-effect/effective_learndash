require 'effective_resources'
require 'effective_datatables'
require 'effective_learndash/engine'
require 'effective_learndash/version'

module EffectiveLearndash
  WP_USERNAME_PROC = Proc.new { |user| "user#{user.id}" }
  WP_PASSWORD_PROC = Proc.new { |user| SecureRandom.base64(12) }

  def self.config_keys
    [
      :learndash_url, :learndash_username, :learndash_password,
      :wp_username, :wp_password,
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

  def self.wp_username
    config[:wp_username] || WP_USERNAME_PROC
  end

  def self.wp_password
    config[:wp_password] || WP_PASSWORD_PROC
  end

  # The user.learndash_username is the source of truth
  # This is the backup to generate a new username
  def self.wp_username_for(owner)
    raise('expecting a learndash owner') unless owner.class.respond_to?(:effective_learndash_owner?)
    owner.instance_exec(owner, &wp_username)
  end

  def self.wp_password_for(owner)
    raise('expecting a learndash owner') unless owner.class.respond_to?(:effective_learndash_owner?)
    owner.instance_exec(owner, &wp_password)
  end

end
