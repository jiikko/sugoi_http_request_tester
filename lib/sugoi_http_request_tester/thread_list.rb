module SugoiHttpRequestTester
  class ThreadList
    def initialize(concarency)
      threads = []
      @queue = SizedQueue.new(100)
      @mutex = Mutex.new
      @threads = Array.new(concarency).map do
        Thread.new do
          begin
            loop do
              block = @queue.pop
              block ? block.call : break
            end
          rescue Exception => e
            puts e.message
            puts e.backtrace.join("\n")
          end
        end
      end
    end

    def mutex_synchronize
      @mutex.synchronize do
        yield
      end
    end

    def push_queue(&block)
      @queue.push(block)
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
