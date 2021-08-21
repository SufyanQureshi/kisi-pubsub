module Pubsub
  class Launcher
    def initialize(options=Pubsub.options)
      @queues = options[:queues] | ["morgue"]
      @options = options
    end

    def run
      trap("INT") { handle_signal("INT") }
      trap("TERM") { handle_signal("TERM") }
      at_exit { cleanup }

      Logger.log 'Starting Pubsub process...'
      create_topics
      create_subscriptions
      @retry_processor = FailedJobsConsumer.new(@options).tap(&:init)
      @subscribers = init_subscribers
      Logger.log "Listening for messages..."
      @subscribers.each(&:start)

      sleep
    end

    private

    def handle_signal(sig)
      Logger.log 'Waiting for jobs to complete processing, would shut down in a moment...'
      raise SignalException, sig
    end

    def cleanup
      @subscribers.each { |sub| sub.stop!(10) }
      Logger.log 'Exited!!!!!'
    end

    def init_subscribers
      (@queues - ['morgue']).map do |q|
        subscription = Pubsub::GoogleCloud.client.subscription "#{q}-subscription"
        subscription.listen(**subscription_options) do |message|
          if schedule?(message)
            processor = Processor.new(message, @retry_processor, @options)
            deadline_extension = schedule_in(message).ceil + 5
            message.modify_ack_deadline!(deadline_extension)
            Scheduler.schedule(processor, schedule_in(message))
          else
            Processor.process(message, @retry_processor, @options)
          end
        end
      end
    end

    def schedule_in(message)
      (message.published_at + message.attributes['at'].to_f) - (Time.now + 0.1)
    end

    def schedule?(message)
      message.attributes['at'] && schedule_in(message).positive?
    end

    def create_subscriptions
      @queues.map do |name|
        sub = "#{name}-subscription"
        Thread.new do
          begin
            Pubsub.topics[name].subscribe sub
            Logger.log "Subscription #{sub} successfully created"
          rescue Google::Cloud::AlreadyExistsError
            Logger.log "Subscription #{sub} already exists"
          end
        end
      end.each(&:join)
    end

    def create_topics
      @queues.map do |topic|
        Thread.new do
          begin
            Pubsub::GoogleCloud.client.create_topic topic, **topic_options
            Logger.log "Topic #{topic} successfully created"
          rescue Google::Cloud::AlreadyExistsError => e
            Logger.log "Topic #{topic} already exists"
          end
        end
      end.each(&:join)
    end

    def subscription_options
      {
        deadline: @options[:deadline],
        threads: { callback: @options[:concurrency] }
      }
    end

    def topic_options
      {
        labels: @options[:labels],
        async: { threads: { publish: @options [:concurrency] } }
      }
    end
  end
end
