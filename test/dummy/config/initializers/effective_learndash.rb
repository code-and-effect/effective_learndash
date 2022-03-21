EffectiveLearndash.setup do |config|
  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Application Password
  # This is an application password from your Wordpress install hosting Learndash plugin.
  # https://make.wordpress.org/core/2020/11/05/application-passwords-integration-guide/
  #
  config.learndash_url = ENV.fetch('LEARNDASH_URL')
  config.learndash_username = ENV.fetch('LEARNDASH_USERNAME')
  config.learndash_password = ENV.fetch('LEARNDASH_PASSWORD')
end
