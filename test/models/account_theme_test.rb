require "test_helper"

class AccountThemeTest < ActiveSupport::TestCase
  test "defaults to stock" do
    assert_equal "stock", Account.new.theme
    assert_equal "stock", accounts(:workspace_one).theme
  end

  test "accepts only curated themes" do
    account = accounts(:workspace_one)

    Account::THEMES.each_key do |key|
      account.theme = key
      assert_predicate account, :valid?, "#{key} should be valid"
    end

    account.theme = "midnight-unicorn"
    assert_not account.valid?
    assert_includes account.errors[:theme], "is not included in the list"
  end
end
