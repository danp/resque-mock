require 'resque'

module Resque
  def self.mock!
    extend MockExt
  end

  module MockExt
    def async
      @async = true
      create_worker_manager
      yield
    ensure
      wait_for_worker_manager
      @async = false
    end

    def enqueue(klass, *args)
      puts "Mock enqueue: async=#{!!@async}, stack_depth=#{caller.size}, #{klass}, #{args.inspect}" if ENV['VERBOSE']
      defer(klass, args)
    end

    def enqueue_in(delay, klass, *args)
      puts "Mock enqueue in #{delay}: async=#{!!@async}, stack_depth=#{caller.size}, #{klass}, #{args.inspect}" if ENV['VERBOSE']
      defer(klass, args, delay)
    end

    def defer(klass, args, delay = nil)
      if @async
        add_job('payload' => { 'class' => klass, 'args' => args }, 'delay' => delay)
      else
        sleep delay if delay
        klass.perform(*roundtrip(args))
      end
    end

    def create_worker_manager
      @worker_manager = Thread.new do
        Thread.current.abort_on_exception = true
        worker_threads = []

        while true
          break if Thread.current[:exit] && worker_threads.empty? && Thread.current[:jobs].empty?

          worker_threads.reject! {|t| !t.alive? }

          while Thread.current[:jobs] && job_data = Thread.current[:jobs].shift
            worker_threads << create_worker_thread_for(job_data)
          end

          sleep 0.5
        end
      end.tap {|t| t[:jobs] = [] }
    end

    def wait_for_worker_manager
      @worker_manager[:exit] = true
      @worker_manager.join
      @worker_manager = nil
    end

    def create_worker_thread_for(data)
      Thread.new(data) do |data|
        Thread.current.abort_on_exception = true
        if delay = data['delay']
          sleep delay
        end

        klass = data['payload']['class']
        puts "Mock perform: #{klass}.perform(*#{data['payload']['args'].inspect})" if ENV['VERBOSE']
        klass.perform(*roundtrip(data['payload']['args']))
        puts "Mock exit: #{klass}.perform(*#{data['payload']['args'].inspect})" if ENV['VERBOSE']
      end
    end

    def roundtrip(args)
      decode(encode(args))
    end

    def add_job(data)
      @worker_manager[:jobs] << data
    end
  end
end
