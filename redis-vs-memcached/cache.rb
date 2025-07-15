
require "sus/fixtures/benchmark"
require "sus/fixtures/async/scheduler_context"

include Sus::Fixtures::Benchmark

with "memcached" do
	before do
		require "dalli"
	end

	let(:client) {Dalli::Client.new("localhost:11211")}

	measure "get+set" do |repeats|
		repeats.times do
			client.set("test", "test")
			client.get("test")
		end

		expect(client.get("test")).to be == "test"
	end
end

with "redis" do
	before do
		require "redis"
	end

	let(:client) {Redis.new(host: "localhost", port: 6379)}

	measure "get+set" do |repeats|
		repeats.times do
			client.set("test", "test")
			client.get("test")
		end

		expect(client.get("test")).to be == "test"
	end
end

with Async do
	include Sus::Fixtures::Async::SchedulerContext

	before do
		require "async/redis/client"
	end

	let(:client) {Async::Redis::Client.new}

	measure "async-redis get+set" do |repeats|
		repeats.times do
			client.set("test", "test")
			client.get("test")
		end

		expect(client.get("test")).to be == "test"
	end
end
