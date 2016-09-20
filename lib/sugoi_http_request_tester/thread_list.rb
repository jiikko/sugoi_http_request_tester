module SugoiHttpRequestTester
  class ThreadList
    def initialize(concarency)
      @queue = SizedQueue.new(100)
      @mutex = Mutex.new
      @threads = Array.new(concarency).map do
        Thread.new do
          loop do
            retry_counter = 0
            block = @queue.pop
            begin
              block ? block.call : break
            rescue Exception => e # タイムアウトとかくる
              retry_counter = retry_counter + 1
              puts e.message
              puts e.backtrace.join("\n")
              retry if retry_counter < 10
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
