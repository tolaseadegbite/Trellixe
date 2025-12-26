class RemoveUniqueIndexFromUsersName < ActiveRecord::Migration[8.0]
  def change
    # Remove the unique index on the `name` column of the `users` table.
    # The email column's uniqueness is sufficient for user identification.
    remove_index :users, :name, name: "index_users_on_name"
  end
end
