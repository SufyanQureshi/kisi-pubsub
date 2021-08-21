# Load the Rails application.
require_relative "application"
require_relative "../lib/active_job/queue_adapters/pubsub_adapter"

# Initialize the Rails application.
Rails.application.initialize!
