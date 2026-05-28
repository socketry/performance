#!/usr/bin/env ruby

require_relative 'support'

def benchmark_thread_allocation(count)
	threads = []

	time = Benchmark.realtime do
		count.times do
			threads << Thread.new {}
		end
		threads.each(&:join)
	end

	{
		scenario: 'allocation',
		count: count,
		time_ms: (time * 1000.0).round(3),
		allocation_us: microseconds_per(time, count).round(3),
		allocations_per_second: operations_per_second(count, time).round(0)
	}
end

def benchmark_thread_context_switch(workers, switches)
	total_switches = 0
	threads = []

	time = Benchmark.realtime do
		workers.times do
			threads << Thread.new do
				switches.times do
					total_switches += 1
					Thread.pass
				end
			end
		end
		threads.each(&:join)
	end

	{
		scenario: 'context_switch',
		workers: workers,
		switches_per_worker: switches,
		total_switches: total_switches,
		time_ms: (time * 1000.0).round(3),
		switch_us: microseconds_per(time, total_switches).round(3),
		switches_per_second: operations_per_second(total_switches, time).round(0)
	}
end

def benchmark_thread_iops(workers, operations)
	total_operations = workers * operations
	threads = []

	time = Benchmark.realtime do
		workers.times do
			threads << Thread.new do
				local_processed = 0
				local_bytes = 0

				operations.times do
					local_bytes += perform_io_operation
					local_processed += 1
					Thread.pass
				end

				[local_processed, local_bytes]
			end
		end
		threads.each(&:join)
	end

	processed = threads.sum{|thread| thread.value[0]}
	bytes_processed = threads.sum{|thread| thread.value[1]}

	{
		scenario: 'iops',
		workers: workers,
		operations_per_worker: operations,
		total_operations: total_operations,
		processed_operations: processed,
		bytes_processed: bytes_processed,
		time_ms: (time * 1000.0).round(3),
		iops: operations_per_second(total_operations, time).round(0),
		operation_us: microseconds_per(time, total_operations).round(3)
	}
end

scenario = (ARGV[0] || 'allocation').to_s
first = parse_integer(ARGV[1], 1000)
second = parse_integer(ARGV[2], 1000)

$stderr.puts "Benchmarking Ruby #{RUBY_VERSION} on #{RUBY_PLATFORM} (threads, #{scenario})"

result = case scenario
when 'allocation'
	benchmark_thread_allocation(first)
when 'context_switch'
	benchmark_thread_context_switch(first, second)
when 'iops'
	benchmark_thread_iops(first, second)
else
	raise ArgumentError, "Unknown scenario: #{scenario}. Use allocation, context_switch, or iops"
end

result[:ruby_version] = RUBY_VERSION
result[:platform] = RUBY_PLATFORM
result[:mode] = 'threads'

YAML.dump(result, $stdout)
