#!/usr/bin/env ruby

require 'yaml'

RUBY_VERSIONS = %w[ruby:3.3 ruby:3.4 ruby:4.0].freeze

MODES = {
	fibers: {script: 'fibers.rb', label: 'Fibers'},
	threads: {script: 'threads.rb', label: 'Threads'}
}.freeze

SCENARIOS = {
	allocation: {args: ['allocation', '20000']},
	context_switch: {args: ['context_switch', '2', '200000']},
	iops: {args: ['iops', '1000', '200']}
}.freeze

THREAD_VARIANTS = {
	default: {
		label: 'default',
		env: {}
	},
	mn: {
		label: 'mn',
		env: {
			'RUBY_MN_THREADS' => '1',
			'RUBY_MAX_CPU' => '8'
		}
	}
}.freeze

# Benchmark the performance of fibers vs threads in Ruby.
# @parameter force [Boolean] Whether to force re-run the benchmarks even if results exist.
# @parameter versions [Array(String)] Specific Ruby versions to benchmark.
def benchmark(force: false, versions: RUBY_VERSIONS)

	puts "## Fiber vs Thread M:N Benchmark"
	puts
	puts "Allocation, context-switch, and file-read IOPS throughput benchmark."
	puts

	generate_report(versions, force: force)
end

private

def run_benchmark(version, mode, scenario, arguments, force: false)
	thread_variant = :default
	run_benchmark_with_variant(version, mode, scenario, arguments, thread_variant, force: force)
end

def run_benchmark_with_variant(version, mode, scenario, arguments, thread_variant, force: false)
	variant = THREAD_VARIANTS.fetch(thread_variant)
	safe_version = version.gsub(':', '-')
	variant_suffix = mode == :threads ? "-#{variant[:label]}" : ''
	filename = "#{mode}#{variant_suffix}-#{safe_version}-#{scenario}-#{arguments.join('-')}.yaml"
	results_directory = File.join(context.root, 'results')
	output_path = File.join(results_directory, filename)

	if force or !File.exist?(output_path)
		$stderr.puts "Running #{version} #{mode} #{variant[:label]} #{scenario} #{arguments.join(' ')}"
		Dir.mkdir(results_directory) unless Dir.exist?(results_directory)

		script_file = MODES.fetch(mode).fetch(:script)
		env = mode == :threads ? variant[:env] : {}
		command = [
			'docker', 'run', '--rm',
			*env.flat_map{|key, value| ['-e', "#{key}=#{value}"]},
			'-v', "#{Dir.pwd}:/workspace:ro",
			version, 'ruby', "/workspace/#{script_file}", *arguments
		]

		status = system(*command, out: output_path)
		raise "Benchmark failed for #{version} #{mode} #{scenario}" unless status
	else
		$stderr.puts "Using cached result #{output_path}"
	end

	YAML.load_file(output_path, symbolize_names: true)
end

def mn_supported?(version)
	version.start_with?('ruby:3.3', 'ruby:3.4', 'ruby:3.5', 'ruby:4.')
end

def thread_variants_for(version)
	return [:default, :mn] if mn_supported?(version)

	[:default]
end

def format_int(value)
	value.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def generate_report(versions, force: false)
	puts "### Allocation Cost"
	puts
	puts "| Ruby Version | Thread Mode | Fiber alloc (us) | Thread alloc (us) | Ratio (thread/fiber) | Fiber alloc/s | Thread alloc/s |"
	puts "|--------------|-------------|------------------|-------------------|----------------------|---------------|----------------|"

	versions.each do |version|
		fiber = run_benchmark(version, :fibers, :allocation, SCENARIOS[:allocation][:args], force: force)

		thread_variants_for(version).each do |thread_variant|
			thread = run_benchmark_with_variant(version, :threads, :allocation, SCENARIOS[:allocation][:args], thread_variant, force: force)
			ratio = thread[:allocation_us] / fiber[:allocation_us]

			puts "| #{version.ljust(12)} | #{THREAD_VARIANTS.fetch(thread_variant).fetch(:label).ljust(11)} | #{format('%.3f', fiber[:allocation_us]).ljust(16)} | #{format('%.3f', thread[:allocation_us]).ljust(17)} | #{format('%.2fx', ratio).ljust(20)} | #{format_int(fiber[:allocations_per_second]).ljust(13)} | #{format_int(thread[:allocations_per_second]).ljust(14)} |"
		end
	end

	puts
	puts "### Context Switching Cost"
	puts
	puts "| Ruby Version | Thread Mode | Fiber switch (us) | Thread switch (us) | Ratio (thread/fiber) | Fiber switches/s | Thread switches/s |"
	puts "|--------------|-------------|-------------------|--------------------|----------------------|------------------|-------------------|"

	versions.each do |version|
		fiber = run_benchmark(version, :fibers, :context_switch, SCENARIOS[:context_switch][:args], force: force)

		thread_variants_for(version).each do |thread_variant|
			thread = run_benchmark_with_variant(version, :threads, :context_switch, SCENARIOS[:context_switch][:args], thread_variant, force: force)
			ratio = thread[:switch_us] / fiber[:switch_us]

			puts "| #{version.ljust(12)} | #{THREAD_VARIANTS.fetch(thread_variant).fetch(:label).ljust(11)} | #{format('%.3f', fiber[:switch_us]).ljust(17)} | #{format('%.3f', thread[:switch_us]).ljust(18)} | #{format('%.2fx', ratio).ljust(20)} | #{format_int(fiber[:switches_per_second]).ljust(16)} | #{format_int(thread[:switches_per_second]).ljust(17)} |"
		end
	end

	puts
	puts "### IOPS Throughput"
	puts
	puts "| Ruby Version | Thread Mode | Fiber IOPS | Thread IOPS | Ratio (fiber/thread) | Fiber op (us) | Thread op (us) |"
	puts "|--------------|-------------|------------|-------------|----------------------|---------------|----------------|"

	versions.each do |version|
		fiber = run_benchmark(version, :fibers, :iops, SCENARIOS[:iops][:args], force: force)

		thread_variants_for(version).each do |thread_variant|
			thread = run_benchmark_with_variant(version, :threads, :iops, SCENARIOS[:iops][:args], thread_variant, force: force)
			ratio = fiber[:iops] / thread[:iops]

			puts "| #{version.ljust(12)} | #{THREAD_VARIANTS.fetch(thread_variant).fetch(:label).ljust(11)} | #{format_int(fiber[:iops]).ljust(10)} | #{format_int(thread[:iops]).ljust(11)} | #{format('%.2fx', ratio).ljust(20)} | #{format('%.3f', fiber[:operation_us]).ljust(13)} | #{format('%.3f', thread[:operation_us]).ljust(14)} |"
		end
	end

	puts
	puts "Notes:"
	puts "  - Allocation: 20,000 units."
	puts "  - Context switch: 2 workers, 200,000 switches each."
	puts "  - IOPS: 1,000 workers, 200 operations each (each operation reads the shared benchmark file)."
	puts "  - Thread mode: Ruby 3.3+ includes both default and mn (RUBY_MN_THREADS=1, RUBY_MAX_CPU=8)."
end
