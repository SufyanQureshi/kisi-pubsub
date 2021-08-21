class MessageJob < ApplicationJob
  def perform(message, raise_error=false)
    raise 500 if raise_error
    puts message
  end
end
