
require_relative "support"

COUNT = (ARGV[0] || 1000).to_i

def allocate_fiber(count)
	if count > 0
		Fiber.new do
			allocate_fiber(count - 1)
		end.resume
	else
		memory_usage = get_memory_hwm - START_MEMORY_USAGE
		
		puts "Fiber stack depth reached 0, peak memory (VmHWM): #{memory_usage / COUNT} KB"
		
		return nil
	end
end

def allocate_thread(count)
	if count > 0
		Thread.new do
			allocate_thread(count - 1)
		end.join
	else
		memory_usage = get_memory_hwm - START_MEMORY_USAGE
		
		puts "Thread stack depth reached 0, peak memory (VmHWM): #{memory_usage / COUNT} KB"
	end
end

pid = fork do
	START_MEMORY_USAGE = get_memory_hwm
	allocate_fiber(COUNT)
end

Process.wait(pid)

pid = fork do
	START_MEMORY_USAGE = get_memory_hwm
	allocate_thread(COUNT)
end

Process.wait(pid)
