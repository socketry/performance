#!/usr/bin/env ruby

require 'benchmark'

def benchmark_thread_switch(count, switches)
  switch_count = 0
  threads = []

  time = Benchmark.realtime do
    count.times do
      threads << Thread.new do
        switches.times do
          switch_count += 1
          Thread.pass
        end
      end
    end

    threads.each(&:join)
  end

  puts "Total time: #{(time * 1000).round(3)} ms"
  puts "Total switches: #{switch_count}"
  puts "Thread switch (μs): #{((time * 1_000_000) / switch_count.to_f).round(3)}"
end

# Usage: ./benchmark.rb [thread_count] [switches_per_thread]
count = (ARGV[0] || 2).to_i
switches = (ARGV[1] || 100000).to_i

puts "Ruby #{RUBY_VERSION} on #{RUBY_PLATFORM}"
puts "Benchmarking #{count} threads with #{switches} switches each..."

benchmark_thread_switch(count, switches)
