
require "sus/fixtures/benchmark"
require "sus/fixtures/async/scheduler_context"

include Sus::Fixtures::Benchmark

with "memcached" do
	before do
		require "dalli"
	end

	let(:client) {Dalli::Client.new("localhost:11211")}

	measure "multi set" do |repeats|
		keys = ["test1", "test2", "test3", "test4", "test5",]
		pairs = keys.map{[it, it]}.to_h
		
		repeats.times do
			client.set_multi(pairs, 1000)
		end

		keys.each do |key|
			expect(client.get(key)).to be == key
		end
	end
end

with "redis" do
	before do
		require "redis"
	end

	let(:client) {Redis.new(host: "localhost", port: 6379)}

	measure "multi get+set" do |repeats|
		keys = ["test1", "test2", "test3", "test4", "test5"]

		repeats.times do
			# Multi set
			client.multi do |multi|
				keys.each do |key|
					multi.set(key, key)
				end
			end

			# Multi get
			client.multi do |multi|
				keys.each do |key|
					multi.get(key)
				end
			end
		end

		keys.each do |key|
			expect(client.get(key)).to be == key
		end
	end
end