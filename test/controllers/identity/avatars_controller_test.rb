require "test_helper"

class Identity::AvatarsControllerTest < ActionDispatch::IntegrationTest
  PNG_1PX = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  setup do
    @user = users(:lazaro_nixon)
    sign_in_as(@user)
  end

  test "update swaps the avatar and refreshes every shell instance" do
    @user.avatar.attach(io: StringIO.new(PNG_1PX), filename: "old.png", content_type: "image/png")
    old_signed_id = @user.avatar.blob.signed_id

    patch identity_avatar_url, params: { avatar: uploaded_png("new.png") }, as: :turbo_stream

    assert_response :success
    assert @user.reload.avatar.attached?
    new_signed_id = @user.avatar.blob.signed_id
    assert_not_equal old_signed_id, new_signed_id

    assert_match "header_avatar", response.body
    assert_match "sidebar_avatar_full", response.body
    assert_match "sidebar_avatar_compact", response.body
    assert_includes response.body, new_signed_id
  end

  test "update without a file is rejected" do
    patch identity_avatar_url, params: {}, as: :turbo_stream

    assert_redirected_to edit_identity_avatar_path
  end

  private

  def uploaded_png(filename)
    file = Tempfile.new([ "avatar", ".png" ])
    file.binmode
    file.write(PNG_1PX)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: filename)
  end
end
