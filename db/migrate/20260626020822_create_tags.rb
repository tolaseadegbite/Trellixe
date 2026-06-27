class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.references :owner, polymorphic: true, null: false

      t.timestamps
    end

    add_index :tags, [ :owner_type, :owner_id, :name ], unique: true
  end
end
