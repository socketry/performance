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

### `set_multi` System Calls

#### Main

```
  ℹ 2266 samples, mean: 204.89μs, standard deviation: 99.52μs, standard error: 2.09μs
1 passed out of 1 total (5 assertions)
🏁 Finished in 518.4ms; 9.644 assertions per second.
🐢 Slow tests:
  518.3ms: file multi.rb with memcached measure multi set multi.rb:14
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ------------------
 46.15    0.026967           0     36450           write
 34.11    0.019933           0     38536           poll
  6.89    0.004024           0      9064           getrusage
  2.87    0.001678           0      3352           read
```

This shows approximately `36450 / 2266 = 16` writes per `set_multi`. I assumed `5*3+1` - and I tested with 10 keys, and it showed 31 writes per `set_multi` which is the same `10*3+1`.

#### Branch

https://github.com/Shopify/dalli/pull/55

```
  ℹ 11286 samples, mean: 34.09μs, standard deviation: 36.95μs, standard error: 347.83ns
1 passed out of 1 total (5 assertions)
🏁 Finished in 530.7ms; 9.421 assertions per second.
🐢 Slow tests:
  530.6ms: file multi.rb with memcached measure multi set multi.rb:14
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ------------------
 38.83    0.014337           0     45144           getrusage
 17.21    0.006354           0     11480           write
 13.62    0.005028           0     12370           read
 12.38    0.004570           0     11292           poll
```

This shows `11286 / 11480 = 1` writes per `set_multi`.
