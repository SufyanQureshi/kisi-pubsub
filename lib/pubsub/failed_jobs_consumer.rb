require 'concurrent/scheduled_task'

module Pubsub
  class FailedJobsConsumer
    def initialize(options)
      @options = options
      @queue = Queue.new
    end

    def <<(work)
      @queue.push work
    end

    def init
      Thread.new do
        loop do
          processor = @queue.pop
          Scheduler.schedule(processor, @options[:retry_interval])
        end
      end
    end
  end
end
