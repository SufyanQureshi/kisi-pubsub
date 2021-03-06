require 'benchmark'
require 'json'
require 'active_job'

module Pubsub
  class Processor
    def initialize(message, retry_processor, options)
      @message = message
      @retry_count = @message.attributes['retries'].to_i
      @retry_processor = retry_processor
      @options = options
      @retry_interval = options[:retry_interval]
    end

    def process
      @attributes = @message.attributes
      retries = @attributes['retries'].to_i
      @executions ||= (@attributes['executions']&.to_i || 0)
      @klass = @attributes['class']
      @job_class = @attributes['job_class']
      @attributes.merge!(
        'retries' => retries, 'executions' => @executions,
        'arguments' => JSON.parse(@attributes['arguments']),
        'job_id' => @message.message_id
      )

      Logger.log "Job started: #{@attributes["job_id"]}"
      run_job
      @message.acknowledge!

      Logger.log "Completed #{job_name} at #{Time.now}. Took #{@time_took}s"
    rescue StandardError => e
      retry_job e
    end

    def self.process(message, retry_processor, options)
      new(message, retry_processor, options).process
    end

    private

    def run_job
      @time_took = Benchmark.realtime do
        Pubsub.reloader.call do
          Object.const_get(@klass)&.new.perform(@attributes)
        end
      end.round(2)
    end

    def retry_job(error)
      if @retry_count > 0
        deadline_extension = @retry_interval + @options[:deadline] + 5
        @message.modify_ack_deadline!(deadline_extension)
        @retry_count -= 1
        @executions += 1
        Logger.log "#{failure_message error} Job scheduled for a retry in #{@retry_interval}s. Number of retries left = #{@retry_count}"
        @retry_processor << self
      else
        Logger.log "#{failure_message error}. Retries exhausted. Enqueuing to morgue queue"
        Publisher.publish(@attributes.merge('morgue' => true))
        @message.acknowledge!
      end
    rescue StandardError => e
      Logger.log(e.exception)
    end

    def failure_message(error)
      "Job #{job_name} failed with error #{error.exception}."
    end

    def job_name
      "#{@job_class}-#{@message.message_id}"
    end
  end
end
