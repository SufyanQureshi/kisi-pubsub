require 'rails'
module Pubsub
  class Rails < ::Rails::Engine
    class Reloader
      def initialize(app = ::Rails.application)
        @app = app
      end

      def call
        @app.reloader.wrap do
          yield
        end
      end

      def inspect
        "#<Pubsub::Rails::Reloader @app=#{@app.class.name}>"
      end
    end

    initializer "pubsub.active_job_integration" do
      ActiveSupport.on_load(:active_job) do
        include ::Pubsub::Worker::Options unless respond_to?(:pubsub_options)
      end
    end

    config.after_initialize do
      Pubsub.configure_server do |_|
        Pubsub.options[:reloader] = Pubsub::Rails::Reloader.new
      end
    end
  end
end
