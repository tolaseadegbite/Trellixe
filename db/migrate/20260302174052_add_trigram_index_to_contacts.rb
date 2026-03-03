class AddTrigramIndexToContacts < ActiveRecord::Migration[8.0]
  def up
    # Enable the extension for fuzzy searching
    enable_extension :pg_trgm

    # Add index for the fields in your combined_search alias
    add_index :contacts, :first_name, opclass: :gin_trgm_ops, using: :gin
    add_index :contacts, :last_name, opclass: :gin_trgm_ops, using: :gin
    add_index :contacts, :email, opclass: :gin_trgm_ops, using: :gin
    # 'how_we_met' is text, GIN is great for searching inside it
    add_index :contacts, :how_we_met, opclass: :gin_trgm_ops, using: :gin
  end

  def down
    remove_index :contacts, :first_name
    remove_index :contacts, :last_name
    remove_index :contacts, :email
    remove_index :contacts, :how_we_met
    disable_extension :pg_trgm
  end
end
