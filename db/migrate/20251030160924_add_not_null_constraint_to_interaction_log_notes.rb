class AddNotNullConstraintToInteractionLogNotes < ActiveRecord::Migration[8.0]
  def change
    # The `note` column in your schema was text but allowed nulls.
    # This migration enforces the requirement that a note must be present.
    change_column_null :interaction_logs, :note, false
  end
end
