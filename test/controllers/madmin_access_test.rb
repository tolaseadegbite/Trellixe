require "test_helper"

# Guards the madmin engine's authentication: the engine doesn't run the
# main ApplicationController chain, so the session must be resolved in
# Madmin::ApplicationController before the admin check. Anonymous and
# non-admin redirect to root; only app admins get in.
class MadminAccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "madmin-admin@example.com", password: "Secret1*3*5*",
      password_confirmation: "Secret1*3*5*", verified: true, admin: true
    )
    @member = User.create!(
      email: "madmin-member@example.com", password: "Secret1*3*5*",
      password_confirmation: "Secret1*3*5*", verified: true
    )
  end

  test "anonymous visitors are redirected away from madmin" do
    get madmin_root_path

    assert_redirected_to "/"
  end

  test "signed-in non-admins are redirected away from madmin" do
    sign_in_as(@member)

    get madmin_root_path

    assert_redirected_to "/"
  end

  test "app admins can access madmin" do
    sign_in_as(@admin)

    get madmin_root_path

    assert_response :success
  end
end
