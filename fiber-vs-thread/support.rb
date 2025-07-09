
require 'benchmark'
require 'yaml'

# Memory profiling utilities
def get_memory_usage
	# Try to get RSS from /proc/self/status (Linux)
	if File.exist?('/proc/self/status')
		status = File.read('/proc/self/status')
		if match = status.match(/VmRSS:\s+(\d+)\s+kB/)
			return match[1].to_i * 1024 # Convert to bytes
		end
	end
	
	# Fallback to using `ps` command:
	return `ps -o rss= -p #{Process.pid}`.strip.to_f
end

def get_memory_hwm
	# Get VmHWM (High Water Mark) from /proc/self/status (Linux)
	if File.exist?('/proc/self/status')
		status = File.read('/proc/self/status')
		if match = status.match(/VmHWM:\s+(\d+)\s+kB/)
			return match[1].to_i * 1024 # Convert to bytes
		end
	end
	
	# Fallback to RSS if VmHWM is not available
	return get_memory_usage
end

def get_gc_stats
	GC.stat.slice(:heap_live_slots, :heap_free_slots, :total_allocated_objects, :heap_allocated_pages)
end

def force_gc_and_measure
	# Force garbage collection to get clean measurements
	3.times{GC.start}
	
	return {
		memory_bytes: get_memory_hwm,
		gc_stats: get_gc_stats
	}
end
