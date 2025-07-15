# Redis vs Memcached

## Results

```
> bundle exec sus cache.rb --verbose
context Test Registry
  file cache.rb
    file cache.rb with memcached
      file cache.rb with memcached measure get+set cache.rb:14
        expect "test" to
          be == "test"
            ✓ assertion passed cache.rb:20
        ℹ 16122 samples, mean: 20.88μs, standard deviation: 27.05μs, standard error: 213.02ns
    file cache.rb with redis
      file cache.rb with redis measure get+set cache.rb:31
        expect "test" to
          be == "test"
            ✓ assertion passed cache.rb:37
        ℹ 7383 samples, mean: 16.99μs, standard deviation: 14.9μs, standard error: 173.37ns
    file cache.rb with Async
      file cache.rb with Async measure async-redis get+set cache.rb:50
        expect "test" to
          be == "test"
            ✓ assertion passed cache.rb:56
        ℹ 6551 samples, mean: 26.05μs, standard deviation: 21.51μs, standard error: 265.74ns
3 passed out of 3 total (3 assertions)
🏁 Finished in 693.8ms; 4.324 assertions per second.
🐢 Slow tests:
  371.1ms: file cache.rb with memcached measure get+set cache.rb:14
  182.8ms: file cache.rb with Async measure async-redis get+set cache.rb:50
  139.7ms: file cache.rb with redis measure get+set cache.rb:31
```