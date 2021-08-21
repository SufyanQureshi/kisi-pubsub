# frozen_string_literal: true
require_relative './pubsub/logger'
require_relative './pubsub/worker'
require_relative './pubsub/launcher'
require_relative './pubsub/publisher'
require_relative './pubsub/processor'
require_relative './pubsub/google_cloud'
require_relative './pubsub/failed_jobs_consumer'

module Pubsub
  DEFAULT_WORKER_OPTIONS = {
    retries: 2,
    queue_name: 'default'
  }.freeze

  DEFAULT_OPTIONS = {
    concurrency: 4,
    labels: {},
    queues: %w[default morgue],
    deadline: 20,
    retry_interval: 300
  }.freeze

  private_constant :DEFAULT_OPTIONS

  DEFAULT_OPTIONS.keys.each do |k|
    define_singleton_method("#{k}=") do |value|
      options[k] = value
    end
  end

  class << self
    def options
      @options ||= DEFAULT_OPTIONS.dup
    end

     def topics
      @topics ||= request_topics
    end

    def request_topics
      options[:queues].each_with_object({}) do |topic, obj|
        obj[topic] = Thread.new do
          Pubsub::GoogleCloud.client.topic topic
        end
      end.transform_values(&:value)
    end

    def configure
      yield self
    end

    def reloader
      @reloader ||= proc { |&blk| blk.call }
    end

    def reloader=(reloader)
      @reloader = reloader
    end
  end
end
