require "google/cloud/pubsub"

module Pubsub
  module GoogleCloud
    class << self
      def client
        @client ||= Google::Cloud::PubSub.new
      end

      def topics
        @topics ||= request_topics
      end

      def request_topics
        options[:queues].each_with_object({}) do |topic, obj|
          obj[topic] = Thread.new do
            client.topic topic
          end
        end.transform_values(&:value)
      end
    end
  end
end
