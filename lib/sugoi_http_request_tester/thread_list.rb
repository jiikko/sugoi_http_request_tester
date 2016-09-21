module SugoiHttpRequestTester
  class ThreadList
    def initialize(concarency)
      @queue = SizedQueue.new(100)
      @mutex = Mutex.new
      @threads = Array.new(concarency).map do
        Thread.new do
          loop do
            retry_counter = 0
            hash = @queue.pop
            begin
              hash ? hash[:block].call : break
            rescue Timeout::Error => e
              puts hash[:request].to_hash
              puts e.message
              retry_counter = retry_counter + 1
              retry if retry_counter < 3
            rescue Exception => e
              puts hash[:request].to_hash
              puts e.message
              puts e.backtrace.join("\n")
            end
          end
        end
      end
    end

    def mutex_synchronize
      @mutex.synchronize do
        yield
      end
    end

    def push_queue(hash)
      @queue.push(hash)
    end

    def join
      @threads.each { |x| @queue.push(nil) }
      @threads.each(&:join)
    end

    def size
      @threads.size
    end

    def live?
      # stop?だとsleepでもtrueが返ってきた
      @threads.all?(&:status)
    end
  end
end
