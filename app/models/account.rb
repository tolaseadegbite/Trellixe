class Account < ApplicationRecord
  include PublicIdentifiable
  has_public_id prefix: "acct"

  # Multitenancy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :team_invitations, dependent: :destroy

  # Trellixe Domain Data (Polymorphic Ownership)
  has_many :contacts, as: :owner, dependent: :destroy
  has_many :events, as: :owner, dependent: :destroy
  has_many :tags, as: :owner, dependent: :destroy
  has_many :event_series, as: :owner, dependent: :destroy

  # Through associations for deep querying
  has_many :invitations, through: :events
  has_many :follow_up_tasks, through: :invitations

  # Notifications
  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"
  has_many :notifications, through: :noticed_events, class_name: "Noticed::Notification"

  validates :name, presence: true

  # Workspace-wide reminder policy (admin-owned; §6). One shared rhythm per
  # cell: volunteers never set personal due times.
  validates :reminder_clock, format: { with: /\A([01]\d|2[0-3]):[0-5]\d\z/ }
  validates :pre_event_day_offset, :pre_event_buffer_minutes, :post_event_day_offset,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def reminder_hour = reminder_clock.split(":").first.to_i
  def reminder_minute = reminder_clock.split(":").last.to_i

  # Post-event task due: 09:00 (policy clock) on the Nth day after the event
  # ends, in the assignee's zone. Returned zone-aware; AR stores UTC.
  def post_reminder_due_at(event_ends_at, zone)
    at_clock(event_ends_at.in_time_zone(zone).to_date + post_event_day_offset.days, zone)
  end

  # Pre-event fire: earliest of next-day-09:00-post-invite and
  # starts_at-minus-buffer, in the volunteer's zone. Returns a Time, or
  # :immediate (slot past but event upcoming) or :skip (event started).
  def pre_reminder_fire_at(invited_at, event_starts_at, zone)
    candidate = at_clock(invited_at.in_time_zone(zone).to_date + pre_event_day_offset.days, zone)
    cutoff = event_starts_at - pre_event_buffer_minutes.minutes
    fire_at = [ candidate, cutoff ].min
    return :skip if event_starts_at <= Time.current
    fire_at <= Time.current ? :immediate : fire_at
  end

  def personal?
    # A workspace is "personal" if the current user is the only admin/member
    memberships.count == 1 && memberships.first.admin?
  end

  def seats_used
    memberships.count + team_invitations.count
  end

  def seat_limit_reached?
    seats_used >= seat_limit
  end

  private

    def at_clock(date, zone)
      tz = Time.find_zone(zone) || Time.find_zone!("UTC")
      tz.local(date.year, date.month, date.day, reminder_hour, reminder_minute)
    end
end
