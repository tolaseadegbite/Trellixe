require "faker"

PASSWORD = "Trellixe2026Seed!"
HOW_WE_MET = [
  "Sunday service visitor - sat in the back row",
  "Community outreach at Oshodi market",
  "Bible study group - Book of Romans",
  "Neighborhood prayer meeting on Adeola Street",
  "Youth conference 'Rise Up 2026'",
  "Hospital visitation ministry",
  "New Believers class - February cohort",
  "Marriage retreat - 'Building Lasting Homes'"
].freeze

EVENT_NAMES = [
  "Sunday Morning Service", "Community Food Drive",
  "Young Adults Fellowship", "Prayer Night",
  "Marriage Enrichment Workshop", "Children's Christmas Party",
  "Easter Outreach", "Leadership Training",
  "Weekly Cell Meeting", "Outreach Planning Session"
].freeze

LOG_NOTES = [
  "Called and prayed with them over the phone.",
  "Sent a WhatsApp message - they appreciated the check-in.",
  "Visited their home - shared Sunday's sermon recap.",
  "Met for coffee - they're interested in joining the ushering team."
].freeze

DECLINE_REASONS = [ "Out of town", "Had a prior commitment", "Wasn't feeling well" ].freeze

def seed_workspace_data(account:, creator:, member_ids:)
  contacts = (1..50).map do
    first = Faker::Name.first_name
    last = Faker::Name.last_name
    {
      owner_type: "Account", owner_id: account.id, creator_id: creator.id,
      first_name: first, last_name: last,
      email: Faker::Internet.unique.email(name: "#{first}.#{last}"),
      phone_number: Faker::PhoneNumber.phone_number,
      how_we_met: HOW_WE_MET.sample,
      created_at: Faker::Time.between(from: 90.days.ago, to: 7.days.ago),
      updated_at: Time.current
    }
  end
  Contact.insert_all!(contacts)
  contact_ids = Contact.where(owner: account).pluck(:id)

  events = (1..15).map do
    starts_at = Faker::Time.between(from: 30.days.ago, to: 45.days.from_now)
    {
      owner_type: "Account", owner_id: account.id,
      name: EVENT_NAMES.sample,
      starts_at: starts_at, duration_in_minutes: [ 60, 90, 120 ].sample,
      created_at: starts_at - 14.days, updated_at: Time.current
    }
  end
  Event.insert_all!(events)

  invitations = []
  Event.where(owner: account).find_each do |event|
    contact_ids.sample(rand(3..8)).each do |cid|
      status = event.starts_at > Time.current ? :invited : %i[invited attended declined].sample
      invitations << {
        contact_id: cid, event_id: event.id,
        status: Invitation.statuses[status],
        notes: status == :declined ? DECLINE_REASONS.sample : nil,
        created_at: event.created_at, updated_at: event.created_at
      }
    end
  end
  Invitation.insert_all!(invitations)

  follow_ups = []
  Invitation.joins(:event).where(events: { owner_type: "Account", owner_id: account.id }, status: :attended).where("events.starts_at <= ?", Time.current).find_each do |invitation|
    due = (invitation.event.ends_at + 1.day).change(hour: 9)
    assignee = (member_ids.sample if member_ids.any? && rand < 0.3) || creator.id
    completed = invitation.event.ends_at < 7.days.ago && [ true, false ].sample
    follow_ups << {
      invitation_id: invitation.id, user_id: assignee,
      due_at: due,
      completed_at: completed ? due + rand(1..48).hours : nil,
      created_at: due,
      updated_at: completed ? due + rand(1..48).hours : due
    }
  end
  FollowUpTask.insert_all!(follow_ups)

  logs = []
  FollowUpTask.joins(invitation: :event).where(events: { owner_type: "Account", owner_id: account.id }).where.not(completed_at: nil).find_each do |task|
    logs << {
      contact_id: task.invitation.contact_id, user_id: task.user_id,
      follow_up_task_id: task.id, note: LOG_NOTES.sample,
      created_at: task.completed_at, updated_at: task.completed_at
    }
  end
  InteractionLog.insert_all!(logs) if logs.any?
end

puts "=== Cleaning old data ==="
Noticed::Notification.destroy_all
Noticed::Event.destroy_all
InteractionLog.destroy_all
FollowUpTask.destroy_all
Invitation.destroy_all
Event.destroy_all
Contact.destroy_all
TeamInvitation.destroy_all
Membership.destroy_all
Account.destroy_all
User.destroy_all

puts "=== Creating users ==="
User.skip_callback(:create, :after, :create_personal_workspace)

users = []

users << User.create!(
  name: "Tolase Adegbite", email: "tolase@trellixe.com",
  password: PASSWORD, password_confirmation: PASSWORD,
  verified: true, time_zone: "West Central Africa"
)

19.times do
  first = Faker::Name.first_name
  last = Faker::Name.last_name
  users << User.create!(
    name: "#{first} #{last}",
    email: Faker::Internet.unique.email(name: "#{first}.#{last}"),
    password: PASSWORD, password_confirmation: PASSWORD,
    verified: true, time_zone: "West Central Africa"
  )
end

puts "  #{users.size} users created (tolase@trellixe.com + 19 Faker)"

puts "=== Creating workspaces ==="
workspace_configs = [
  { name: "Abraham's Seed Cell", owner: users[0], extra_members: 3 },
  { name: "Love Cell",             owner: users[1], extra_members: 2 },
  { name: "Virtuous Women Cell",   owner: users[2], extra_members: 1 },
  { name: "Minstrel Cell",         owner: users[3], extra_members: 2 },
  { name: "Pacesetters Cell",      owner: users[4], extra_members: 1 },
  { name: "Light Cell",            owner: users[5], extra_members: 0 },
  { name: "Illumination Cell",     owner: users[6], extra_members: 0 },
  { name: "Faith Warriors Cell",   owner: users[7], extra_members: 0 },
  { name: "Kingdom Kids Cell",     owner: users[8], extra_members: 0 },
  { name: "Harvest Field Cell",    owner: users[9], extra_members: 0 }
]

next_member_idx = 10
workspaces = []

workspace_configs.each do |cfg|
  account = Account.create!(name: cfg[:name])
  Membership.create!(user: cfg[:owner], account: account, role: "admin")

  member_ids = [ cfg[:owner].id ]
  cfg[:extra_members].times do
    member = users[next_member_idx]
    Membership.create!(user: member, account: account, role: "member")
    member_ids << member.id
    next_member_idx += 1
  end

  workspaces << { account: account, creator: cfg[:owner], member_ids: member_ids }
end

unassigned_count = users.size - next_member_idx
puts "  #{workspaces.size} workspaces created (#{unassigned_count} user(s) remain unassigned)"

puts "=== Seeding workspace data ==="
workspaces.each_with_index do |ws, i|
  print "  [#{i + 1}/#{workspaces.size}] #{ws[:account].name}..."
  seed_workspace_data(**ws)
  puts " done"
end

puts ""
puts "=== Creating notification seeds ==="
notif_events = []
notif_records = []

now = Time.current
workspaces.each_with_index do |ws, idx|
  account = ws[:account]
  creator = ws[:creator]

  ws[:member_ids].each do |member_id|
    next if member_id == creator.id
    member = User.find(member_id)

    notif_events << {
      type: "TeamNotifier::MemberJoined",
      params: { account_id: account.id, account_name: account.name, user_name: member.full_name },
      created_at: now, updated_at: now
    }
    notif_records << {
      type: "TeamNotifier::MemberJoined::Notification",
      recipient_type: "User", recipient_id: creator.id,
      account_id: account.id,
      read_at: nil, seen_at: nil,
      created_at: now, updated_at: now
    }
  end

  if ws[:member_ids].size > 1
    member = User.find(ws[:member_ids].last)

    notif_events << {
      type: "TeamNotifier::RoleChanged",
      params: {
        account_id: account.id, account_name: account.name,
        user_id: member.id, user_name: member.full_name,
        role: "member"
      },
      created_at: now, updated_at: now
    }
    notif_records << {
      type: "TeamNotifier::RoleChanged::Notification",
      recipient_type: "User", recipient_id: member.id,
      account_id: account.id,
      read_at: nil, seen_at: nil,
      created_at: now, updated_at: now
    }
  end

  puts "  [#{idx + 1}/#{workspaces.size}] #{account.name} notifications created"
end

Noticed::Event.insert_all!(notif_events)
events = Noticed::Event.last(notif_events.size)
notif_records.each_with_index { |r, i| r[:event_id] = events[i].id }
Noticed::Notification.insert_all!(notif_records)

# InvitationReceived for unassigned user (global — no account_id)
if (unassigned = users[19])
  inv_event = Noticed::Event.create!(
    type: "TeamNotifier::InvitationReceived",
    params: { account_name: workspaces.first[:account].name, token: "invite_seed_token_abc123" },
    created_at: now, updated_at: now
  )
  Noticed::Notification.create!(
    type: "TeamNotifier::InvitationReceived::Notification",
    event: inv_event,
    recipient: unassigned, account: nil,
    created_at: now, updated_at: now
  )
  puts "  Invitation notification created for #{unassigned.name}"
end

puts ""
puts "=== Seed complete ==="
puts "  #{User.count} users / #{Account.count} workspaces"
puts "  #{Contact.count} contacts / #{Event.count} events"
puts "  #{Invitation.count} invitations / #{FollowUpTask.count} follow-ups / #{InteractionLog.count} logs"
puts "  #{Noticed::Event.count} notification events / #{Noticed::Notification.count} notifications"
puts ""
puts "  Sign in with: tolase@trellixe.com / #{PASSWORD}"
puts "  (same password for all users)"
