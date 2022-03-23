module EffectiveLearndashTestBuilder
  def create_user!
    build_user.tap { |user| user.save! }
  end

  def build_user
    @user_index ||= 0
    @user_index += 1

    User.new(
      email: "user#{@user_index}@example.com",
      password: 'rubicon2020',
      password_confirmation: 'rubicon2020',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  def build_unique_user
    id = Time.zone.now.to_i
    user = build_user()
    user.update!(id: id, email: "user#{id}@example.com")
    user
  end
end
