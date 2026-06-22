class AddPerformanceIndexesAndFixColumnTypes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # --- Add composite indexes ---
    add_index :events, %i[ owner_type owner_id starts_at ],
              name: "index_events_on_owner_and_starts_at",
              algorithm: :concurrently

    add_index :memberships, %i[ account_id role ],
              name: "index_memberships_on_account_id_and_role",
              algorithm: :concurrently

    add_index :follow_up_tasks, %i[ user_id completed_at ],
              name: "index_follow_up_tasks_on_user_id_and_completed_at",
              algorithm: :concurrently

    # --- Add timestamps to accounts ---
    add_timestamps :accounts, default: -> { "NOW()" }, null: false

    # --- Add timestamps to sign_in_tokens ---
    add_timestamps :sign_in_tokens, default: -> { "NOW()" }, null: false

    # --- Fix integer → bigint on FK columns ---
    change_column :sessions, :user_id, :bigint, null: false
    change_column :sign_in_tokens, :user_id, :bigint, null: false
    change_column :user_activities, :user_id, :bigint, null: false

    # --- Add NOT NULL constraints ---
    change_column_null :contacts, :first_name, false
    change_column_null :web_push_subscriptions, :endpoint, false
    change_column_null :web_push_subscriptions, :p256dh, false
    change_column_null :web_push_subscriptions, :auth, false
  end

  def down
    remove_index :events, name: "index_events_on_owner_and_starts_at"
    remove_index :memberships, name: "index_memberships_on_account_id_and_role"
    remove_index :follow_up_tasks, name: "index_follow_up_tasks_on_user_id_and_completed_at"

    remove_timestamps :accounts
    remove_timestamps :sign_in_tokens

    change_column :sessions, :user_id, :integer, null: false
    change_column :sign_in_tokens, :user_id, :integer, null: false
    change_column :user_activities, :user_id, :integer, null: false

    change_column_null :contacts, :first_name, true
    change_column_null :web_push_subscriptions, :endpoint, true
    change_column_null :web_push_subscriptions, :p256dh, true
    change_column_null :web_push_subscriptions, :auth, true
  end
end
