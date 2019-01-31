class AddIndexToCounters < ActiveRecord::Migration[5.2]
  def change
    add_index :counters, :date
  end
end
