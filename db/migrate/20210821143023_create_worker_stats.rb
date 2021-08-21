class CreateWorkerStats < ActiveRecord::Migration[6.1]
  def change
    create_table :worker_stats do |t|
      t.integer :total_count, default: 0
      t.integer :total_duration, default: 0

      t.timestamps
    end
  end
end
