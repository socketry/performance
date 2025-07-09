#!/usr/bin/env ruby

require_relative 'support'

def benchmark_threads(count, switches = 1)
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
	result = {
		count: count,
		switches: switches,
		total_switches: switch_count,
		time_ms: (time * 1000).round(3),
		creation_rate: creations_per_second.round(0),
		switch_rate: switches_per_second.round(0)
	}
	
	# Minimise impact of GC on repeat runs:
	GC.start
	
	return result
end

# Main execution

# Parse simple ARGV: count switches [repeats]
count = (ARGV[0] || 1000).to_i
switches = (ARGV[1] || 1).to_i
repeats = (ARGV[2] || 0).to_i

# Send progress info to stderr, structured data to stdout
$stderr.puts "Benchmarking Ruby #{RUBY_VERSION} on #{RUBY_PLATFORM}"
$stderr.puts "Running thread benchmark with #{count} threads, #{switches} switches each, #{repeats} repeats..."

results = {}
results[:ruby_version] = RUBY_VERSION
results[:platform] = RUBY_PLATFORM
results[:count] = count
results[:switches] = switches

# Measure initial memory before any benchmark operations:
$stderr.puts "Measuring initial memory usage..."
initial_memory = force_gc_and_measure

# Warmup:
$stderr.puts "Warming up..."
benchmark_threads(10, 1)
sleep 1

# Repeats:
results[:benchmarks] = benchmarks = repeats.times.map do
	benchmark_threads(count, switches)
end

# Benchmark:
$stderr.puts "Running thread benchmark..."
benchmarks << benchmark_threads(count, switches)

# Measure final memory after all operations:
$stderr.puts "Measuring final memory usage..."
final_memory = force_gc_and_measure

# Calculate memory usage:
total_memory_used = final_memory[:memory_bytes] - initial_memory[:memory_bytes]
memory_per_unit = count > 0 ? total_memory_used / count : 0

results[:memory_usage] = {
	memory_used_bytes: total_memory_used,
	memory_per_unit_bytes: memory_per_unit.round(0),
	initial_memory: initial_memory[:memory_bytes],
	final_memory: final_memory[:memory_bytes],
	gc_objects_initial: initial_memory[:gc_stats][:heap_live_slots],
	gc_objects_final: final_memory[:gc_stats][:heap_live_slots]
}

$stderr.puts "Total memory used: #{total_memory_used} bytes (#{memory_per_unit.round(0)} bytes/thread)"

YAML.dump(results, $stdout)
