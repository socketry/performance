# Measure the time to allocate 1000 threads in Ruby
require 'benchmark'

COUNT = (ARGV[0] || 1000).to_i
threads = []

# Warm up
Thread.new {}.join

elapsed_us = Benchmark.realtime do
  COUNT.times do
    threads << Thread.new { }
  end
  threads.each(&:join)
end * 1_000_000 # convert seconds to microseconds

puts "Allocated #{COUNT} threads in %.2f us (%.2f us/thread)" % [elapsed_us, elapsed_us / COUNT]
