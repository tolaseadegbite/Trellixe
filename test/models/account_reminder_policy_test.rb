require "test_helper"

class AccountReminderPolicyTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:workspace_one)
  end

  test "policy defaults match the locked behavior" do
    assert_equal "09:00", @account.reminder_clock
    assert @account.pre_event_enabled?
    assert_equal 1, @account.pre_event_day_offset
    assert_equal 120, @account.pre_event_buffer_minutes
    assert_equal 1, @account.post_event_day_offset
  end

  test "rejects bad clock and negative offsets" do
    @account.reminder_clock = "9am"
    assert_not @account.valid?

    @account.reminder_clock = "09:00"
    @account.post_event_day_offset = -1
    assert_not @account.valid?
  end

  test "post due is next day at policy clock in assignee zone" do
    ends_at = Time.utc(2026, 9, 13, 11, 0) # Sunday 11:00 UTC

    due = @account.post_reminder_due_at(ends_at, "UTC")

    assert_equal Time.utc(2026, 9, 14, 9, 0), due
  end

  test "pre fire is next-day 09:00 for early invitations" do
    invited_at = Time.utc(2026, 9, 7, 16, 0) # Monday
    starts_at = Time.utc(2026, 9, 13, 9, 0) # Sunday

    travel_to Time.utc(2026, 9, 7, 17, 0) do
      assert_equal Time.utc(2026, 9, 8, 9, 0),
        @account.pre_reminder_fire_at(invited_at, starts_at, "UTC")
    end
  end

  test "pre fire falls back to start-minus-buffer for late invitations" do
    invited_at = Time.utc(2026, 9, 12, 22, 0) # Saturday night
    starts_at = Time.utc(2026, 9, 13, 9, 0) # Sunday 9am

    travel_to Time.utc(2026, 9, 12, 23, 0) do
      assert_equal Time.utc(2026, 9, 13, 7, 0),
        @account.pre_reminder_fire_at(invited_at, starts_at, "UTC")
    end
  end

  test "pre fire is immediate when slots passed but event upcoming" do
    invited_at = Time.utc(2026, 9, 13, 8, 40)
    starts_at = Time.utc(2026, 9, 13, 9, 0)

    travel_to Time.utc(2026, 9, 13, 8, 45) do
      assert_equal :immediate,
        @account.pre_reminder_fire_at(invited_at, starts_at, "UTC")
    end
  end

  test "pre fire skips past events" do
    assert_equal :skip,
      @account.pre_reminder_fire_at(2.days.ago, 1.hour.ago, "UTC")
  end
end
