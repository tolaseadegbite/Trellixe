require "application_system_test_case"

class AvatarsTest < ApplicationSystemTestCase
  PNG_1PX = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  setup do
    @user = users(:lazaro_nixon)
    visit sign_in_url
    fill_in "Email", with: @user.email
    fill_in "Password", with: "Secret1*3*5*"
    click_on "Sign in"
    assert_text "Today's follow-ups", wait: 10
  end

  test "updating avatar refreshes the header photo without a reload" do
    path = Rails.root.join("tmp/test_avatar.png")
    File.binwrite(path, PNG_1PX)

    visit edit_identity_avatar_path
    old_src = find("#header_avatar img")[:src]

    attach_file "avatar", path.to_s
    click_on "Save"

    assert_text "Avatar updated"
    new_src = find("#header_avatar img")[:src]
    assert_not_equal old_src, new_src
  ensure
    File.delete(path) if path && File.exist?(path)
  end
end
