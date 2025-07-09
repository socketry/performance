#!/usr/bin/env ruby

require 'open3'
require 'yaml'
require 'json'
require 'time'

# Array of Ruby versions to test.
RUBY_VERSIONS = %w[ruby:2.5 ruby:2.6 ruby:2.7 ruby:3.0 ruby:3.1 ruby:3.2 ruby:3.3 ruby:3.4 ruby:3.5-rc].freeze

# Mode configuration mapping.
MODES = {
	fibers: {
		script: 'fibers.rb',
		display_name: 'Fibers'
	},
	threads: {
		script: 'threads.rb',
		display_name: 'Threads'
	}
}.freeze

# Helper method to recursively convert string keys to symbols
def symbolize_keys(obj)
	case obj
	when Hash
		obj.transform_keys(&:to_sym).transform_values { |v| symbolize_keys(v) }
	when Array
		obj.map { |item| symbolize_keys(item) }
	else
		obj
	end
end

# Public tasks that can be invoked with `bake <task_name>`

# @parameter force [Boolean] Whether to force re-run the benchmarks even if results exist.
# @parameter versions [Array(String)] Specific Ruby versions to benchmark.
def benchmark(force: false, versions: RUBY_VERSIONS)
	puts "# Fiber vs Thread Allocation Benchmark"
	
	# Generate results tables (will run benchmarks on-demand if needed)
	generate_markdown_tables(versions, force: force)
end

private

# Execute a benchmark and cache the raw YAML result
# @parameter version [String] Ruby version to test.
# @parameter mode [Symbol] One of the available modes (e.g., :fibers, :threads).
# @parameter arguments [Array(String)] Arguments to pass to the benchmark script.
# @parameter force [Boolean] Whether to force regeneration even if cached result exists.
# @return [Hash] Parsed YAML data from the benchmark.
def run_benchmark(version, mode, arguments, force: false)
	# Compute path
	arguments_key = arguments.join('-')
	# Replace : with - for safer filenames
	safe_version = version.gsub(':', '-')
	filename = "#{mode}-#{safe_version}-#{arguments_key}.yaml"
	
	results_directory = File.join(context.root, 'results')
	output_path = File.join(results_directory, filename)
	
	# If path doesn't exist (or force is true), run the benchmark and redirect output to that path
	if force or !File.exist?(output_path)
		$stderr.puts "Running Ruby #{version} #{mode} benchmark with arguments: #{arguments.join(' ')}"
		
		# Ensure directory exists
		Dir.mkdir(results_directory) unless Dir.exist?(results_directory)
		
		# Build the command with output redirection
		script_file = MODES[mode][:script]
		command = [
			"docker", "run", "--rm",
			"-v", "#{Dir.pwd}:/workspace:ro",
			version, "ruby", "/workspace/#{script_file}", *arguments
		]
		
		# Execute the benchmark and redirect output to the result file
		status = system(*command, out: output_path)
		
		unless status
			raise "Benchmark failed for Ruby #{version} #{mode} #{arguments.join(' ')}"
		end
		
		$stderr.puts "Saved result to #{output_path}"
	else
		$stderr.puts "Using cached result for Ruby #{version} #{mode} #{arguments.join(' ')}"
	end

	# Load the result file and return the data
	begin
		result_data = YAML.load_file(output_path, symbolize_names: true)
		
		# If this is a repeat benchmark, extract the final result
		if result_data[:benchmarks] && result_data[:benchmarks].any?
			# Use the last benchmark result (after all repeats)
			final_benchmark = result_data[:benchmarks].last
			result_data.merge!(final_benchmark)
		end
		
		# Add metadata if not already present
		unless result_data[:timestamp]
			result_data[:timestamp] = Time.now.iso8601
			result_data[:ruby_version] = version
			result_data[:mode] = mode
			result_data[:arguments] = arguments
			
			# Update the file with metadata
			File.write(output_path, YAML.dump(result_data))
		end
		
		return result_data
	rescue => e
		$stderr.puts "Error loading result file: #{e.message}"
		return { error: 'Failed to load result file', file: output_path }
	end
end



def generate_markdown_tables(versions, force: false)
	puts "\n### Performance Summary\n\n"
	puts "| Ruby Version | Fiber Alloc (μs)  | Thread Alloc (μs) | Allocation Ratio | Fiber Switch (μs) | Thread Switch (μs) | Switch Ratio |"
	puts "|--------------|-------------------|-------------------|------------------|-------------------|--------------------|--------------| "

	versions.each do |version|
		# Pull memory usage data
		fiber_memory = run_benchmark(version, :fibers, ['10000', '2'], force: force)
		thread_memory = run_benchmark(version, :threads, ['10000', '2'], force: force)
		
		# Pull context switching data
		fiber_switch = run_benchmark(version, :fibers, ['2', '10000'], force: force)
		thread_switch = run_benchmark(version, :threads, ['2', '10000'], force: force)
		
		# Calculate ratios
		allocation_ratio = thread_memory[:time_ms] / fiber_memory[:time_ms]
		switch_ratio = thread_switch[:time_ms] / fiber_switch[:time_ms]
		
		# Calculate time per allocation in microseconds
		fiber_alloc_per_us = (fiber_memory[:time_ms] * 1000.0 / 10000.0)
		thread_alloc_per_us = (thread_memory[:time_ms] * 1000.0 / 10000.0)
		
		# Calculate time per context switch in microseconds
		fiber_switch_per_us = (fiber_switch[:time_ms] * 1000.0 / 20000.0)
		thread_switch_per_us = (thread_switch[:time_ms] * 1000.0 / 20000.0)
		
		# Format times
		puts "| #{version.ljust(12)} | #{("%.3f" % fiber_alloc_per_us).ljust(17)} | #{("%.3f" % thread_alloc_per_us).ljust(17)} | #{("%.1fx" % allocation_ratio).ljust(16)} | #{("%.3f" % fiber_switch_per_us).ljust(17)} | #{("%.3f" % thread_switch_per_us).ljust(18)} | #{("%.1fx" % switch_ratio).ljust(12)} |"
	end

	puts "\n*Allocation times are per individual fiber/thread (10,000 total allocations)*"
	puts "*Context switch times are per individual switch (2 workers × 10,000 switches = 20,000 total)*"

	puts "\n### Context Switching Performance\n\n"
	puts "| Ruby Version | Fiber Switches/sec | Thread Switches/sec | Performance Ratio |"
	puts "|--------------|--------------------|---------------------|-------------------|"

	versions.each do |version|
		# Pull context switching data
		fiber_switch = run_benchmark(version, :fibers, ['2', '10000'], force: force)
		thread_switch = run_benchmark(version, :threads, ['2', '10000'], force: force)
		
		switch_ratio = thread_switch[:time_ms] / fiber_switch[:time_ms]
		fiber_switch_rate = fiber_switch[:switch_rate]
		thread_switch_rate = thread_switch[:switch_rate]
		
		# Format switch rates with commas
		fiber_rate_formatted = fiber_switch_rate.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
		thread_rate_formatted = thread_switch_rate.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
		
		puts "| #{version.ljust(12)} | #{fiber_rate_formatted.ljust(18)} | #{thread_rate_formatted.ljust(19)} | #{("%.1fx" % switch_ratio).ljust(17)} |"
	end

	puts "\n### Memory Usage Per Unit\n\n"
	puts "| Ruby Version | Count      | Fiber Memory (bytes) | Thread Memory (bytes) | Fiber Total (MB) | Thread Total (MB) |"
	puts "|--------------|------------|----------------------|-----------------------|-------------------|-------------------|"

	versions.each do |version|
		# Pull memory usage data
		fiber_memory = run_benchmark(version, :fibers, ['10000', '2'], force: force)
		thread_memory = run_benchmark(version, :threads, ['10000', '2'], force: force)
		
		count = fiber_memory[:count].to_s
		fiber_mem_per_unit = fiber_memory[:memory_usage][:memory_used_bytes] / fiber_memory[:count]
		thread_mem_per_unit = thread_memory[:memory_usage][:memory_used_bytes] / thread_memory[:count]
		fiber_mem_total = fiber_memory[:memory_usage][:memory_used_bytes]
		thread_mem_total = thread_memory[:memory_usage][:memory_used_bytes]
		
		# Convert total bytes to MB and format
		fiber_total_mb = "%.1f" % (fiber_mem_total / 1024.0 / 1024.0)
		thread_total_mb = "%.1f" % (thread_mem_total / 1024.0 / 1024.0)
		
		# Format per-unit memory with commas
		fiber_per_formatted = fiber_mem_per_unit.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
		thread_per_formatted = thread_mem_per_unit.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
		
		puts "| #{version.ljust(12)} | #{count.ljust(10)} | #{fiber_per_formatted.ljust(20)} | #{thread_per_formatted.ljust(21)} | #{fiber_total_mb.ljust(17)} | #{thread_total_mb.ljust(17)} |"
	end

	puts "\n### Cache Warming Performance\n\n"
	puts "| Ruby Version | Mode    | First Alloc (μs) | Last Alloc (μs) | Improvement |"
	puts "|--------------|---------|------------------|-----------------|-------------|"

	versions.each do |version|
		# Pull regular allocation data (10000 fibers/threads, 1 switch, 10 repeats)
		fiber_cache = run_benchmark(version, :fibers, ['10000', '2', '10'], force: force)
		thread_cache = run_benchmark(version, :threads, ['10000', '2', '10'], force: force)
		
		# Extract last benchmark result from cache warming:
		fiber_first = fiber_cache[:benchmarks].first
		fiber_last = fiber_cache[:benchmarks].last
		thread_first = thread_cache[:benchmarks].first
		thread_last = thread_cache[:benchmarks].last
		
		# Calculate allocation time per fiber/thread in microseconds
		# Use creation_rate to get pure allocation time
		fiber_first_alloc_per_us = (1.0 / fiber_first[:creation_rate]) * 1000000.0
		fiber_last_alloc_per_us = (1.0 / fiber_last[:creation_rate]) * 1000000.0
		thread_first_alloc_per_us = (1.0 / thread_first[:creation_rate]) * 1000000.0
		thread_last_alloc_per_us = (1.0 / thread_last[:creation_rate]) * 1000000.0
		
		# Calculate improvement ratios
		fiber_improvement = fiber_first_alloc_per_us / fiber_last_alloc_per_us
		thread_improvement = thread_first_alloc_per_us / thread_last_alloc_per_us
		
		# Format times
		puts "| #{version.ljust(12)} | Fibers  | #{("%.3f" % fiber_first_alloc_per_us).ljust(16)} | #{("%.3f" % fiber_last_alloc_per_us).ljust(15)} | #{("%.1fx" % fiber_improvement).ljust(11)} |"
		puts "| #{' ' * 12} | Threads | #{("%.3f" % thread_first_alloc_per_us).ljust(16)} | #{("%.3f" % thread_last_alloc_per_us).ljust(15)} | #{("%.1fx" % thread_improvement).ljust(11)} |"
	end

	puts "\n*Shows allocation time improvement from cold start to cache-warmed state*"
	puts "*Cache warming: 10,000 fibers/threads with 1 switch, 10 repeats*"

	puts "\n### Throughput Performance\n\n"
	puts "| Ruby Version | Mode    | Total Time (ms) | Concurrency | Max Throughput (req/s) |"
	puts "|--------------|---------|-----------------|-------------|----------------------|"

	versions.each do |version|
		# Pull throughput data (1000 fibers/threads, 100 switches, 10 repeats)
		fiber_throughput = run_benchmark(version, :fibers, ['1000', '100', '10'], force: force)
		thread_throughput = run_benchmark(version, :threads, ['1000', '100', '10'], force: force)
		
		# Extract last benchmark result (cache-warmed state)		
		fiber_last = fiber_throughput[:benchmarks].last
		thread_last = thread_throughput[:benchmarks].last
		
		# Calculate theoretical maximum throughput (requests per second)
		# If using one fiber/thread per request, this is the max requests we can handle
		fiber_max_throughput = (1000.0 / fiber_last[:time_ms]) * 1000.0
		thread_max_throughput = (1000.0 / thread_last[:time_ms]) * 1000.0
		
		# Format output
		puts "| #{version.ljust(12)} | Fibers  | #{("%.1f" % fiber_last[:time_ms]).ljust(15)} | #{("1,000").ljust(11)} | #{("%.0f" % fiber_max_throughput).ljust(20)} |"
		puts "| #{' ' * 12} | Threads | #{("%.1f" % thread_last[:time_ms]).ljust(15)} | #{("1,000").ljust(11)} | #{("%.0f" % thread_max_throughput).ljust(20)} |"
	end

	puts "\n*Shows maximum throughput in cache-warmed state*"
	puts "*Throughput test: 1,000 fibers/threads with 100 switches, 10 repeats*"
end
