require "faker"

puts "=== Cleaning old data ==="
InteractionLog.destroy_all
FollowUpTask.destroy_all
Invitation.destroy_all
Event.destroy_all
Contact.destroy_all
Membership.destroy_all
Account.destroy_all
User.destroy_all

puts "=== Creating default user + workspace ==="
user = User.create!(
  name: "Tunde Balogun",
  email: "tunde@gracechapel.org",
  password: "password123",
  password_confirmation: "password123",
  verified: true,
  time_zone: "Lagos"
)

# Rename the auto-created personal workspace to our seed account
account = user.accounts.first
account.update!(name: "Grace Chapel Outreach")

puts "  User:     #{user.email} / password123"
puts "  Account:  #{account.name}"

puts "=== Creating contacts ==="
how_we_met_options = [
  "Sunday service visitor - sat in the back row",
  "Community outreach at Oshodi market",
  "Bible study group - Book of Romans",
  "Neighborhood prayer meeting on Adeola Street",
  "Youth conference 'Rise Up 2026'",
  "Hospital visitation ministry",
  "New Believers class - February cohort",
  "Marriage retreat - 'Building Lasting Homes'"
]

contacts = (1..80).map do
  first = Faker::Name.first_name
  last = Faker::Name.last_name
  {
    owner_type: "Account",
    owner_id: account.id,
    creator_id: user.id,
    first_name: first,
    last_name: last,
    email: Faker::Internet.unique.email(name: "#{first}.#{last}"),
    phone_number: Faker::PhoneNumber.phone_number,
    how_we_met: how_we_met_options.sample,
    created_at: Faker::Time.between(from: 90.days.ago, to: 7.days.ago),
    updated_at: Time.current
  }
end
Contact.insert_all!(contacts)
contact_ids = Contact.where(owner: account).pluck(:id)
puts "  #{contact_ids.size} contacts created"

puts "=== Creating events ==="
event_names = [
  "Sunday Morning Service", "Community Food Drive",
  "Young Adults Fellowship", "Prayer Night",
  "Marriage Enrichment Workshop", "Children's Christmas Party",
  "Easter Outreach", "Leadership Training"
]

events_data = (1..30).map do
  starts_at = Faker::Time.between(from: 30.days.ago, to: 45.days.from_now)
  {
    owner_type: "Account",
    owner_id: account.id,
    name: event_names.sample,
    starts_at: starts_at,
    duration_in_minutes: [ 60, 90, 120 ].sample,
    created_at: starts_at - 14.days,
    updated_at: Time.current
  }
end
Event.insert_all!(events_data)
puts "  #{events_data.size} events created"

puts "=== Creating invitations ==="
invitations_data = []
Event.where(owner: account).find_each do |event|
  contact_ids.sample(rand(3..8)).each do |cid|
    status = %i[invited attended declined].sample
    invitations_data << {
      contact_id: cid,
      event_id: event.id,
      status: Invitation.statuses[status],
      notes: status == :declined ? [ "Out of town", "Had a prior commitment", "Wasn't feeling well" ].sample : nil,
      created_at: event.created_at,
      updated_at: event.created_at
    }
  end
end
Invitation.insert_all!(invitations_data)
puts "  #{invitations_data.size} invitations created"

puts "=== Creating follow-up tasks ==="
follow_ups_data = []
Invitation.where(status: :attended).find_each do |invitation|
  due = (invitation.event.ends_at + 1.day).change(hour: 9)
  completed = invitation.event.ends_at < 7.days.ago && [ true, false ].sample
  follow_ups_data << {
    invitation_id: invitation.id,
    user_id: user.id,
    due_at: due,
    completed_at: completed ? due + rand(1..48).hours : nil,
    created_at: due,
    updated_at: completed ? due + rand(1..48).hours : due
  }
end
FollowUpTask.insert_all!(follow_ups_data)
puts "  #{follow_ups_data.size} follow-up tasks created"

puts "=== Creating interaction logs ==="
logs_data = []
FollowUpTask.where.not(completed_at: nil).find_each do |task|
  logs_data << {
    contact_id: task.invitation.contact_id,
    user_id: user.id,
    follow_up_task_id: task.id,
    note: [
      "Called and prayed with them over the phone.",
      "Sent a WhatsApp message - they appreciated the check-in.",
      "Visited their home - shared Sunday's sermon recap.",
      "Met for coffee - they're interested in joining the ushering team."
    ].sample,
    created_at: task.completed_at,
    updated_at: task.completed_at
  }
end
InteractionLog.insert_all!(logs_data) if logs_data.any?
puts "  #{logs_data.size} interaction logs created"

puts ""
puts "=== Seed complete ==="
puts "  Sign in with: #{user.email} / password123"
