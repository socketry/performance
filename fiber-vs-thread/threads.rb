#!/usr/bin/env ruby

require_relative 'support'

def benchmark_threads(count, switches = 1, output = nil)
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
		
		# Wait for all threads to complete
		threads.each{|thread| thread.join}
	end
	
	# Calculate rates
	creations_per_second = count / time
	switches_per_second = switch_count / time
	
	# Output YAML directly (without memory info - will be reported globally)
	if output
		output.puts "count: #{count}"
		output.puts "switches: #{switches}"
		output.puts "total_switches: #{switch_count}"
		output.puts "time_ms: #{(time * 1000).round(3)}"
		output.puts "creation_rate: #{creations_per_second.round(0)}"
		output.puts "switch_rate: #{switches_per_second.round(0)}"
	end
	
	time
end

# Main execution
# Parse simple ARGV: count switches
count = (ARGV[0] || ITERATIONS).to_i
switches = (ARGV[1] || 1).to_i

# Send progress info to stderr, structured data to stdout
$stderr.puts "Benchmarking Ruby #{RUBY_VERSION} on #{RUBY_PLATFORM}"
$stderr.puts "Running thread benchmark with #{count} threads, #{switches} switches each..."

# Output basic info to YAML
puts "ruby_version: #{RUBY_VERSION}"
puts "platform: #{RUBY_PLATFORM}"
puts "count: #{count}"
puts "switches: #{switches}"

# Measure initial memory before any benchmark operations
$stderr.puts "Measuring initial memory usage..."
initial_memory = force_gc_and_measure

# Warmup
$stderr.puts "Warming up..."
benchmark_threads(10, 1)
sleep 1

# Run benchmark
$stderr.puts "Running thread benchmark..."
thread_time = benchmark_threads(count, switches, $stdout)
$stderr.puts "Thread time: #{(thread_time * 1000).round(2)}ms"

# Measure final memory after all operations
$stderr.puts "Measuring final memory usage..."
final_memory = force_gc_and_measure

# Calculate and output memory usage
total_memory_used = final_memory[:memory_bytes] - initial_memory[:memory_bytes]
memory_per_unit = count > 0 ? total_memory_used / count : 0

puts "memory_used_bytes: #{total_memory_used}"
puts "memory_per_unit_bytes: #{memory_per_unit.round(0)}"
puts "initial_memory: #{initial_memory[:memory_bytes]}"
puts "final_memory: #{final_memory[:memory_bytes]}"
puts "gc_objects_initial: #{initial_memory[:gc_stats][:heap_live_slots]}"
puts "gc_objects_final: #{final_memory[:gc_stats][:heap_live_slots]}"

$stderr.puts "Total memory used: #{total_memory_used} bytes (#{memory_per_unit.round(0)} bytes/thread)"
