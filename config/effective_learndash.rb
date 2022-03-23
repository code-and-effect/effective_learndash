EffectiveLearndash.setup do |config|
  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Application Password
  # This is an application password from your Wordpress install hosting Learndash plugin.
  # https://make.wordpress.org/core/2020/11/05/application-passwords-integration-guide/
  #
  config.learndash_url = ENV['LEARNDASH_URL']
  config.learndash_username = ENV['LEARNDASH_USERNAME']
  config.learndash_password = ENV['LEARNDASH_PASSWORD']

  # Customize the method used to assign Wordpress username and passwords
  # Usernames can only contain lowercase letters (a-z) and numbers.
  # config.wp_username = Proc.new { |user| "user#{user.id}" }
  # config.wp_password = Proc.new { |user| "password#{user.id}" }
end
