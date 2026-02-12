# # db/seeds.rb
# require 'faker'

# # A helper to show progress bars for long-running tasks
# def show_progress(total, current, message = "Progress")
#   percent = (current.to_f / total * 100).round
#   bar_length = 30
#   filled_length = (bar_length * percent / 100).round
#   bar = "#" * filled_length + "-" * (bar_length - filled_length)
#   print "\r#{message}: [#{bar}] #{percent}%"
#   $stdout.flush
# end

# # A simple banner for visual separation
# def print_banner(message)
#   puts "\n" + "=" * 50
#   puts message
#   puts "=" * 50
# end

# print_banner "🌱 Starting database seed process..."

# # --- 1. Clean up old data ---
# print "🗑️  Destroying existing data..."
# InteractionLog.destroy_all
# FollowUpTask.destroy_all
# Invitation.destroy_all
# Event.destroy_all
# Contact.destroy_all
# User.destroy_all
# Account.destroy_all
# puts " Done."

# # --- 2. Create a default Account and User ---
# print_banner "👤 Creating Default User and Account"
# account = Account.create!
# user = User.create!(
#   name: "Tolase Kelvin",
#   email: "tolase@trellixe.com",
#   password: "tolasekelvin",
#   password_confirmation: "tolasekelvin",
#   verified: true,
#   account: account
# )
# puts "✅ Default User 'Tunde' created with email 'tolase@trellixe.com'."

# # --- 3. Seed Contacts for the default User ---
# print_banner "👥 Creating Contacts"
# contact_count = 150
# contacts_to_create = []
# how_we_met_options = ["at a tech conference", "through a mutual friend, Sarah", "on a LinkedIn discussion", "at the local coffee shop", "during a volunteer event"]

# contact_count.times do |i|
#   show_progress(contact_count, i + 1, "Preparing contacts")
#   contacts_to_create << {
#     # --- THIS IS THE FIX ---
#     owner_id: user.id,
#     owner_type: 'User',
#     # -----------------------
#     creator_id: user.id, # creator_id is a real column name, so it's fine
#     first_name: Faker::Name.first_name,
#     last_name: Faker::Name.last_name,
#     email: Faker::Internet.unique.email,
#     phone_number: Faker::PhoneNumber.phone_number,
#     how_we_met: "Met them #{how_we_met_options.sample}.",
#     created_at: Time.current,
#     updated_at: Time.current
#   }
# end
# Contact.insert_all!(contacts_to_create)
# puts "\n✅ #{contact_count} contacts created."
# user_contacts = Contact.where(owner: user)

# # --- 4. Seed Events for the default User ---
# print_banner "🗓️  Creating Events"
# event_count = 50
# events_to_create = []
# event_names = ["Community BBQ", "Quarterly Tech Meetup", "Newcomers' Lunch", "Weekly Prayer Meeting", "Project Kickoff"]
# durations = [30, 60, 90, 120]

# event_count.times do |i|
#   show_progress(event_count, i + 1, "Preparing events  ")
#   events_to_create << {
#     # --- THIS IS THE FIX ---
#     owner_id: user.id,
#     owner_type: 'User',
#     # -----------------------
#     name: "#{event_names.sample} - #{Faker::Address.city}",
#     starts_at: Faker::Time.between(from: 60.days.ago, to: 30.days.from_now),
#     duration_in_minutes: durations.sample,
#     created_at: Time.current,
#     updated_at: Time.current
#   }
# end
# Event.insert_all!(events_to_create)
# puts "\n✅ #{event_count} events created."
# user_events = Event.where(owner: user)

# # --- 5. Seed Invitations, Follow-Ups, and Logs ---
# # (The rest of the file from the previous response is correct and does not need changes,
# # as it uses real column names like `event_id`, `contact_id`, etc.)
# print_banner "🔗 Creating Invitations and Follow-Up History"
# invitations_to_create = []
# tasks_to_create = []
# logs_to_create = []

# user_events.each_with_index do |event, index|
#   show_progress(user_events.count, index + 1, "Processing events")
#   contacts_to_invite = user_contacts.sample(rand(5..20))

#   contacts_to_invite.each do |contact|
#     status = Invitation.statuses.keys.sample
#     notes = nil

#     if status == :declined
#       notes = ["Out of town", "Had a prior commitment", "Wasn't feeling well"].sample
#     elsif status == :attended && event.starts_at < Time.current
#       notes = ["Seemed very engaged", "Brought a friend", "Left a bit early"].sample
#     end

#     invitations_to_create << {
#       event_id: event.id,
#       contact_id: contact.id,
#       status: Invitation.statuses[status],
#       notes: notes,
#       created_at: event.created_at,
#       updated_at: event.created_at
#     }
#   end
# end

# puts "\nInserting invitations..."
# Invitation.insert_all!(invitations_to_create)
# puts "✅ #{invitations_to_create.count} invitations created."

# attended_invitations = Invitation.where(status: :attended)
# puts "\nCreating follow-up history for #{attended_invitations.count} attended events..."
# attended_invitations.each do |invitation|
#   completed = [true, false].sample

#   task = {
#     invitation_id: invitation.id,
#     user_id: user.id,
#     due_at: invitation.event.ends_at + 1.day,
#     completed_at: completed ? (invitation.event.ends_at + 2.days) : nil,
#     created_at: invitation.event.ends_at,
#     updated_at: invitation.event.ends_at
#   }
#   tasks_to_create << task

#   if completed
#     logs_to_create << {
#       contact_id: invitation.contact_id,
#       user_id: user.id,
#       follow_up_task_id: invitation.id, # Placeholder
#       note: "Had a great follow-up chat. They plan to come to the next event.",
#       created_at: task[:completed_at],
#       updated_at: task[:completed_at]
#     }
#   end
# end

# if tasks_to_create.any?
#   puts "Inserting follow-up tasks..."
#   created_tasks = FollowUpTask.insert_all!(tasks_to_create, returning: %w[id invitation_id])
#   puts "✅ #{tasks_to_create.count} follow-up tasks created."

#   if logs_to_create.any?
#     puts "Updating and inserting interaction logs..."
#     tasks_by_invitation_id = created_tasks.to_h { |task| [task['invitation_id'], task['id']] }

#     logs_to_create.each do |log_attrs|
#       invitation_id = log_attrs[:follow_up_task_id] # This is still the placeholder
#       task_id = tasks_by_invitation_id[invitation_id]
#       log_attrs[:follow_up_task_id] = task_id if task_id
#     end

#     # Filter out any logs for which a task wasn't found (shouldn't happen, but is safe)
#     valid_logs = logs_to_create.select { |log| log[:follow_up_task_id].is_a?(Integer) }
#     InteractionLog.insert_all!(valid_logs)
#     puts "✅ #{valid_logs.count} interaction logs created."
#   end
# end

# print_banner "🎉 Seeding complete!"