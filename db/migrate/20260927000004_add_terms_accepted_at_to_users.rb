class AddTermsAcceptedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    # Nullable by design: rows predating the Terms page never saw a
    # checkbox and are treated as accepted-at-signup.
    add_column :users, :terms_accepted_at, :datetime
  end
end
