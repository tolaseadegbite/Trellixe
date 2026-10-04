class AddThemeToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :theme, :string, null: false, default: "stock"
  end
end
