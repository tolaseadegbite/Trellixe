class SetupTrellixeTeams < ActiveRecord::Migration[8.0]
  def change
    # 1. Update Accounts (The Workspace)
    add_column :accounts, :name, :string, null: false, default: "Personal Workspace"
    add_column :accounts, :seat_limit, :integer, default: 5, null: false
    add_column :accounts, :public_id, :string
    add_index :accounts, :public_id, unique: true

    # 2. Update Users
    add_column :users, :public_id, :string
    add_index :users, :public_id, unique: true
    # Since you have no users yet, we can safely remove the old 1:1 link now
    remove_column :users, :account_id, :integer

    # 3. Create Memberships (The Link)
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :role, default: "member", null: false
      t.string :public_id
      t.timestamps
    end
    add_index :memberships, [ :user_id, :account_id ], unique: true
    add_index :memberships, :public_id, unique: true

    # 4. Create Team Invitations
    # (Named 'TeamInvitation' to avoid conflict with your existing Event 'Invitation')
    create_table :team_invitations do |t|
      t.string :email, null: false
      t.references :account, null: false, foreign_key: true
      t.string :role, default: "member", null: false
      t.string :token, null: false
      t.string :public_id
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :team_invitations, :token, unique: true
    add_index :team_invitations, :public_id, unique: true
    add_index :team_invitations, [ :account_id, :email ], unique: true

    # 5. Update Notifications for Noticed v2
    add_reference :noticed_notifications, :account, foreign_key: true
    add_column :noticed_notifications, :public_id, :string
    add_index :noticed_notifications, :public_id, unique: true
  end
end
