# Fiber vs Thread Benchmark

This benchmark compares the allocation performance and memory usage of Fibers vs Threads across different Ruby versions.

## Overview

The benchmark consists of two focused tests:
1. **Memory Usage Test**: Allocates 10,000 fibers/threads with 2 context switches each to measure memory high water mark and allocation performance.
2. **Context Switching Test**: Uses 2 fibers/threads with 10,000 context switches each to measure switching performance.

**Performance Ratios**: All ratios in this benchmark show how much more expensive (slower) threads are compared to fibers. For example, a ratio of 5.0x means threads take 5 times longer than fibers to perform the same operation.

## Usage

You must have:

- Docker installed and running.
- Internet connection to pull Ruby images.

Then, to run the complete benchmark across all Ruby versions:

```bash
bake benchmark
```

## Results

### Performance Summary

| Ruby Version | Fiber Alloc (μs)  | Thread Alloc (μs) | Allocation Ratio | Fiber Switch (μs) | Thread Switch (μs) | Switch Ratio |
|--------------|-------------------|-------------------|------------------|-------------------|--------------------|--------------| 
| ruby:2.5     | 6.709             | 48.418            | 7.2x             | 0.312             | 0.734              | 2.4x         |
| ruby:2.6     | 5.537             | 64.420            | 11.6x            | 0.114             | 0.535              | 4.7x         |
| ruby:2.7     | 3.363             | 19.111            | 5.7x             | 0.118             | 0.477              | 4.1x         |
| ruby:3.0     | 3.363             | 17.928            | 5.3x             | 0.121             | 0.540              | 4.5x         |
| ruby:3.1     | 3.356             | 19.683            | 5.9x             | 0.124             | 0.684              | 5.5x         |
| ruby:3.2     | 3.489             | 18.103            | 5.2x             | 0.133             | 0.524              | 3.9x         |
| ruby:3.3     | 3.435             | 65.120            | 19.0x            | 0.106             | 1.276              | 12.0x        |
| ruby:3.4     | 3.394             | 78.586            | 23.2x            | 0.112             | 1.338              | 12.0x        |
| ruby:3.5-rc  | 3.505             | 64.825            | 18.5x            | 0.105             | 1.968              | 18.7x        |

  - Allocation times are per individual fiber/thread (10,000 total allocations).
  - Context switch times are per individual switch (2 workers × 10,000 switches = 20,000 total).

### Context Switching Performance

| Ruby Version | Fiber Switches/sec | Thread Switches/sec | Performance Ratio |
|--------------|--------------------|---------------------|-------------------|
| ruby:2.5     | 3,208,507          | 1,362,936           | 2.4x              |
| ruby:2.6     | 8,775,810          | 1,870,720           | 4.7x              |
| ruby:2.7     | 8,507,952          | 2,095,824           | 4.1x              |
| ruby:3.0     | 8,296,342          | 1,850,422           | 4.5x              |
| ruby:3.1     | 8,063,934          | 1,461,020           | 5.5x              |
| ruby:3.2     | 7,502,624          | 1,908,317           | 3.9x              |
| ruby:3.3     | 9,417,216          | 783,994             | 12.0x             |
| ruby:3.4     | 8,968,706          | 747,533             | 12.0x             |
| ruby:3.5-rc  | 9,490,705          | 508,003             | 18.7x             |

### Memory Usage Per Unit

| Ruby Version | Count      | Fiber Memory (bytes) | Thread Memory (bytes) | Fiber Total (MB) | Thread Total (MB) |
|--------------|------------|----------------------|-----------------------|-------------------|-------------------|
| ruby:2.5     | 10000      | 14,707               | 32,274                | 140.3             | 307.8             |
| ruby:2.6     | 10000      | 9,646                | 12,628                | 92.0              | 120.4             |
| ruby:2.7     | 10000      | 13,191               | 18,694                | 125.8             | 178.3             |
| ruby:3.0     | 10000      | 13,160               | 18,769                | 125.5             | 179.0             |
| ruby:3.1     | 10000      | 13,215               | 18,880                | 126.0             | 180.1             |
| ruby:3.2     | 10000      | 13,187               | 18,953                | 125.8             | 180.8             |
| ruby:3.3     | 10000      | 13,239               | 14,437                | 126.3             | 137.7             |
| ruby:3.4     | 10000      | 13,241               | 13,701                | 126.3             | 130.7             |
| ruby:3.5-rc  | 10000      | 13,214               | 14,359                | 126.0             | 136.9             |

### Cache Warming Performance

| Ruby Version | Mode    | First Alloc (μs) | Last Alloc (μs) | Improvement |
|--------------|---------|------------------|-----------------|-------------|
| ruby:2.5     | Fibers  | 6.581            | 121.847         | 0.1x        |
|              | Threads | 62.786           | 100.695         | 0.6x        |
| ruby:2.6     | Fibers  | 5.618            | 57.720          | 0.1x        |
|              | Threads | 67.137           | 85.704          | 0.8x        |
| ruby:2.7     | Fibers  | 3.367            | 1.047           | 3.2x        |
|              | Threads | 19.146           | 10.528          | 1.8x        |
| ruby:3.0     | Fibers  | 3.341            | 1.058           | 3.2x        |
|              | Threads | 18.183           | 10.065          | 1.8x        |
| ruby:3.1     | Fibers  | 3.357            | 1.119           | 3.0x        |
|              | Threads | 18.487           | 10.193          | 1.8x        |
| ruby:3.2     | Fibers  | 3.401            | 1.106           | 3.1x        |
|              | Threads | 18.554           | 10.502          | 1.8x        |
| ruby:3.3     | Fibers  | 3.362            | 0.988           | 3.4x        |
|              | Threads | 64.986           | 68.648          | 0.9x        |
| ruby:3.4     | Fibers  | 3.479            | 1.014           | 3.4x        |
|              | Threads | 79.296           | 74.272          | 1.1x        |
| ruby:3.5-rc  | Fibers  | 3.522            | 1.023           | 3.4x        |
|              | Threads | 65.108           | 70.522          | 0.9x        |

  - Shows allocation time improvement from cold start to cache-warmed state.
  - Cache warming: 10,000 fibers/threads with 1 switch, 10 repeats.

### Throughput Performance

| Ruby Version | Mode    | Total Time (ms) | Concurrency | Max Throughput (req/s) |
|--------------|---------|-----------------|-------------|----------------------|
| ruby:2.5     | Fibers  | 43.5            | 1,000       | 22976                |
|              | Threads | 265.4           | 1,000       | 3767                 |
| ruby:2.6     | Fibers  | 18.3            | 1,000       | 54558                |
|              | Threads | 299.5           | 1,000       | 3338                 |
| ruby:2.7     | Fibers  | 13.6            | 1,000       | 73757                |
|              | Threads | 290.2           | 1,000       | 3446                 |
| ruby:3.0     | Fibers  | 13.8            | 1,000       | 72543                |
|              | Threads | 305.3           | 1,000       | 3276                 |
| ruby:3.1     | Fibers  | 14.2            | 1,000       | 70195                |
|              | Threads | 304.4           | 1,000       | 3286                 |
| ruby:3.2     | Fibers  | 14.4            | 1,000       | 69594                |
|              | Threads | 313.2           | 1,000       | 3193                 |
| ruby:3.3     | Fibers  | 11.3            | 1,000       | 88621                |
|              | Threads | 189.8           | 1,000       | 5268                 |
| ruby:3.4     | Fibers  | 12.8            | 1,000       | 78315                |
|              | Threads | 194.0           | 1,000       | 5154                 |
| ruby:3.5-rc  | Fibers  | 11.3            | 1,000       | 88881                |
|              | Threads | 198.8           | 1,000       | 5030                 |

  - Shows maximum throughput in cache-warmed state.
  - Throughput test: 1,000 fibers/threads with 100 switches, 10 repeats.

## Performance History

While these benchmarks aim for accuracy, they may contain a moderate margin of error. Nonetheless, they effectively illustrate the historical trends in Ruby’s fiber and thread performance—highlighting both improvements and regressions across versions.

### Ruby 2.6: Elimination of Timer Thread and GVL Restructuring

Ruby 2.6 restructured the Global VM Lock (GVL) and eliminated the dedicated timer thread from the thread implementation. This change simplified thread scheduling and signal handling, reducing complexity and addressing race conditions present in earlier versions.

**Commit**: [48b6bd74e2febde095ac85d818e94c0e58677647](https://github.com/ruby/ruby/commit/48b6bd74e2febde095ac85d818e94c0e58677647)

**Performance Impact**:
- **Thread scheduling and signal handling**: Now handled directly by the GVL, removing the need for a separate timer thread.
- **Improved thread context switching**: Due to the elimination of the timer thread.

### Ruby 2.6: Native Assembly Implementation

A significant performance improvement occurred in Ruby 2.6 with the implementation of native `coroutine_transfer` in assembly language, replacing the previous C implementation that used `ucontext`.

**Commit**: [07a324a0f6464f31765ee4bc5cfc23a99d426705](https://github.com/ruby/ruby/commit/07a324a0f6464f31765ee4bc5cfc23a99d426705)

**Performance Impact**:
- **Improved fiber context switching**: Due to the introduction of native assembly implementations.

The native assembly implementation of `coroutine_transfer` provided a substantial performance boost for fiber context switching, demonstrating the impact of low-level optimizations on high-level language performance and paving the way for future improvements in Ruby's concurrency model.

### Ruby 2.7: Pooled Stack Allocations

Ruby 2.7 introduced pooled stack allocations for fibers, optimizing memory management and allocation performance.

**Commit**: [14cf95cff35612c6238790ad2f605530f69e9a44](https://github.com/ruby/ruby/commit/14cf95cff35612c6238790ad2f605530f69e9a44)

**Performance Impact**:
- **Fiber allocation cost reduced**: Due to cached, pooled allocations of fiber stacks.

The pooled allocation strategy significantly reduced the cost of creating new fibers by reusing previously allocated stacks, leading to more predictable performance characteristics that have been maintained through subsequent Ruby versions, making care-free use of fibers a reality in Ruby applications.

### Ruby 2.7: Thread VM Stack Allocation with `alloca`

Ruby 2.7 also optimized thread performance by moving VM stack initialization into threads and using `alloca` for stack allocation.

**Commit**: [b24603adff8ec1e93e71358b93b3e30c99ba29d5](https://github.com/ruby/ruby/commit/b24603adff8ec1e93e71358b93b3e30c99ba29d5)

**Performance Impact**:
- **Thread allocation cost reduced**: Due to inline stack allocation using `alloca`.
- **Better memory locality**: Using thread stack for the Ruby VM stack allocation provides better cache locality.

This improvement in thread allocation illustrates how a deep understanding of system behavior can yield significant performance gains through targeted low-level changes.

### Ruby 3.0: Ractor Introduction and Thread-Local Storage

Ruby 3.0 introduced Ractors as an experimental feature for true parallelism, requiring significant changes to Ruby's VM architecture to support isolated execution contexts.

**Commit**: [79df14c04b452411b9d17e26a398e491bca1a811](https://github.com/ruby/ruby/commit/79df14c04b452411b9d17e26a398e491bca1a811)

**Performance Impact**:
- **Thread context switching regression**: Due to the overhead of TLS for internal VM state.
- **Implementation complexity**: The introduction of Ractors significantly increased the complexity of the implementation.

### Ruby 3.3: M:N Thread Scheduler for Ractors

Ruby 3.3 introduced an M:N thread scheduler to support Ractors, significantly changing how threads are managed internally.

**Commit**: [be1bbd5b7d40ad863ab35097765d3754726bbd54](https://github.com/ruby/ruby/commit/be1bbd5b7d40ad863ab35097765d3754726bbd54)

**Performance Impact**:
- **Thread allocation performance regressed**: Due to the removal of the `alloca` optimization and replacement with heap allocation (`ruby_xmalloc`).
- **Thread switching performance regressed**: Due to the increased complexity of the M:N scheduler? Reintroduction of the timer thread?

## Hardware and Software Environment

The benchmarks were run on a machine with the following specifications:

```
# Kernel and OS
Linux aiko 6.15.5-arch1-1 #1 SMP PREEMPT_DYNAMIC Sun, 06 Jul 2025 11:14:36 +0000 x86_64 GNU/Linux
Distributor ID: Arch
Description:   Arch Linux (rolling)

# CPU
AMD Ryzen 9 9950X3D 16-Core Processor
Cores: 16 (32 threads)
L1d: 768 KiB, L1i: 512 KiB, L2: 16 MiB, L3: 128 MiB

# Memory
Total: 46 GiB
Free: 39 GiB

# Disk
/dev/nvme0n1p2: 1.8T total, 1.1T available

# Virtualization
AMD-V

# Other
Page size: 4KB
```
