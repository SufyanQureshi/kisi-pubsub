ActiveSupport::Notifications.subscribe "perform.active_job" do|event|
  stat = WorkerStat.first || WorkerStat.create
  stat.total_count += 1
  stat.total_duration += event.duration
  stat.save
end
