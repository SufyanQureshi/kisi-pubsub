require_relative '../../pubsub'
require 'active_job'

module ActiveJob
  module QueueAdapters
    class PubsubAdapter
      def enqueue(job)
        args = job.serialize.merge('class' => JobWrapper.to_s)
        Pubsub::Publisher.publish args
      end

      def enqueue_at(job, timestamp)
        args = job.serialize.merge('class' => JobWrapper.to_s, 'at' => timestamp)
        Pubsub::Publisher.publish args
      end
    end

    class JobWrapper
      include Pubsub::Worker
      def perform(job_data)
        Base.execute job_data
      end
    end
  end
end
