
require 'benchmark'
require 'yaml'

BENCHMARK_IO_FILE = File.expand_path('support.rb', __dir__)

# Robustly parse integer arguments with fallbacks.
def parse_integer(value, default)
	Integer(value || default)
rescue ArgumentError, TypeError
	default
end

# Return microseconds-per-unit from total time and total operations.
def microseconds_per(total_time_seconds, count)
	return 0.0 if count <= 0
	(total_time_seconds * 1_000_000.0) / count
end

# Return operations per second for totals and elapsed time.
def operations_per_second(total_operations, total_time_seconds)
	return 0.0 if total_time_seconds <= 0
	total_operations / total_time_seconds
end

# Perform a single non-trivial I/O operation by reading a shared file.
def perform_io_operation(file_path = BENCHMARK_IO_FILE)
	File.binread(file_path).bytesize
end
