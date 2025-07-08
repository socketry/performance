# Fiber vs Thread Benchmark

This benchmark compares the allocation performance and memory usage of Fibers vs Threads across different Ruby versions.

## Overview

The benchmark consists of two focused tests:
1. **Memory Usage Test**: Allocates 10,000 fibers/threads with 2 context switches each to measure memory high water mark and allocation performance.
2. **Context Switching Test**: Uses 2 fibers/threads with 10,000 context switches each to measure switching performance.

**Performance Ratios**: All ratios in this benchmark show how much more expensive (slower) threads are compared to fibers. For example, a ratio of 5.0x means threads take 5 times longer than fibers to perform the same operation.

## Usage

Run the complete benchmark across all Ruby versions:

```bash
bake benchmark
```

To print the table of results:

```bash
bake results
```

## Requirements

- Docker installed and running.
- Internet connection to pull Ruby images.

## Benchmark Results

*Last updated: July 8, 2025*

### Performance Summary

| Ruby Version | Fiber Alloc (μs)  | Thread Alloc (μs) | Allocation Ratio | Fiber Switch (μs) | Thread Switch (μs) | Switch Ratio |
|--------------|-------------------|-------------------|------------------|-------------------|--------------------|--------------| 
| 2.5          | 8.184             | 140.407           | 17.2x            | 0.380             | 0.987              | 2.6x         |
| 2.6          | 6.985             | 85.074            | 12.2x            | 0.151             | 0.522              | 3.5x         |
| 2.7          | 4.482             | 24.605            | 5.5x             | 0.158             | 0.619              | 3.9x         |
| 3.0          | 4.332             | 24.130            | 5.6x             | 0.152             | 0.991              | 6.5x         |
| 3.1          | 4.462             | 22.862            | 5.1x             | 0.152             | 0.858              | 5.7x         |
| 3.2          | 4.476             | 24.058            | 5.4x             | 0.166             | 0.674              | 4.1x         |
| 3.3          | 4.452             | 71.915            | 16.2x            | 0.130             | 1.508              | 11.6x        |
| 3.4          | 4.652             | 84.469            | 18.2x            | 0.135             | 2.352              | 17.4x        |
| 3.5-rc       | 4.531             | 71.468            | 15.8x            | 0.140             | 1.523              | 10.9x        |

*Allocation times are per individual fiber/thread (10,000 total allocations)*
*Context switch times are per individual switch (2 workers × 10,000 switches = 20,000 total)*

### Context Switching Performance

| Ruby Version | Fiber Switches/sec | Thread Switches/sec | Performance Ratio |
|--------------|--------------------|---------------------|-------------------|
| 2.5          | 2,629,311          | 1,012,839           | 2.6x              |
| 2.6          | 6,622,742          | 1,915,351           | 3.5x              |
| 2.7          | 6,327,612          | 1,615,233           | 3.9x              |
| 3.0          | 6,596,352          | 1,009,212           | 6.5x              |
| 3.1          | 6,592,810          | 1,166,126           | 5.7x              |
| 3.2          | 6,024,871          | 1,482,844           | 4.1x              |
| 3.3          | 7,669,714          | 663,028             | 11.6x             |
| 3.4          | 7,399,293          | 425,090             | 17.4x             |
| 3.5-rc       | 7,141,929          | 656,766             | 10.9x             |

### Memory Usage Per Unit

| Ruby Version | Count      | Fiber Memory (bytes) | Thread Memory (bytes) | Fiber Total (MB) | Thread Total (MB) |
|--------------|------------|----------------------|-----------------------|-------------------|-------------------|
| 2.5          | 10000      | 14,740               | 29,800                | 140.6             | 284.2             |
| 2.6          | 10000      | 9,730                | 14,126                | 92.8              | 134.7             |
| 2.7          | 10000      | 13,161               | 18,166                | 125.5             | 173.2             |
| 3.0          | 10000      | 13,191               | 18,690                | 125.8             | 178.2             |
| 3.1          | 10000      | 13,187               | 18,690                | 125.8             | 178.2             |
| 3.2          | 10000      | 13,187               | 18,769                | 125.8             | 179.0             |
| 3.3          | 10000      | 13,185               | 14,043                | 125.8             | 133.9             |
| 3.4          | 10000      | 13,185               | 13,172                | 125.8             | 125.6             |
| 3.5-rc       | 10000      | 13,107               | 14,198                | 125.0             | 135.4             |

*Page size on Linux is 4KB, so each fiber/thread uses approximately 3 pages.*

## Performance History

While these benchmarks aim for accuracy, they may contain a moderate margin of error. Nonetheless, they effectively illustrate the historical trends in Ruby’s fiber and thread performance—highlighting both improvements and regressions across versions.

### Ruby 2.6: Elimination of Timer Thread and GVL Restructuring

Ruby 2.6 restructured the Global VM Lock (GVL) and eliminated the dedicated timer thread from the thread implementation. This change simplified thread scheduling and signal handling, reducing complexity and addressing race conditions present in earlier versions.

**Commit**: [48b6bd74e2febde095ac85d818e94c0e58677647](https://github.com/ruby/ruby/commit/48b6bd74e2febde095ac85d818e94c0e58677647)

**Performance Impact**:
- **Thread scheduling and signal handling**: Now handled directly by the GVL, removing the need for a separate timer thread.
- **Improved thread context switching ~50%**: From 0.987 μs/switch (Ruby 2.5) to 0.522 μs/switch (Ruby 2.6), due to the elimination of the timer thread.

### Ruby 2.6: Native Assembly Implementation

A significant performance improvement occurred in Ruby 2.6 with the implementation of native `coroutine_transfer` in assembly language, replacing the previous C implementation that used `ucontext`.

**Commit**: [07a324a0f6464f31765ee4bc5cfc23a99d426705](https://github.com/ruby/ruby/commit/07a324a0f6464f31765ee4bc5cfc23a99d426705)

**Performance Impact**:
- **Improved fiber context switching ~60%**: From 0.380 μs/switch (Ruby 2.5) to 0.151 μs/switch (Ruby 2.6) due to the introduction of native assembly implementations.
- **Assembly implementations**: Added for multiple architectures including x86_64, ARM, and others.

The native assembly implementation of `coroutine_transfer` provided a substantial performance boost for fiber context switching, demonstrating the impact of low-level optimizations on high-level language performance and paving the way for future improvements in Ruby's concurrency model.

### Ruby 2.7: Pooled Stack Allocations

Ruby 2.7 introduced pooled stack allocations for fibers, optimizing memory management and allocation performance.

**Commit**: [14cf95cff35612c6238790ad2f605530f69e9a44](https://github.com/ruby/ruby/commit/14cf95cff35612c6238790ad2f605530f69e9a44)

**Performance Impact**:
- **Fiber allocation cost reduced ~35%**: From 6.99 μs/allocation (Ruby 2.6) to 4.48 μs/allocation (Ruby 2.7).
- **Memory efficiency**: Reusing stack allocations reduces system call overhead.
- **Consistent performance**: Ruby 2.7-3.5 show stable ~4.3-4.5 μs allocation times.

The pooled allocation strategy significantly reduced the cost of creating new fibers by reusing previously allocated stacks, leading to more predictable performance characteristics that have been maintained through subsequent Ruby versions, making care-free use of fibers a reality in Ruby applications.

### Ruby 2.7: Thread VM Stack Allocation with `alloca`

Ruby 2.7 also optimized thread performance by moving VM stack initialization into threads and using `alloca` for stack allocation.

**Commit**: [b24603adff8ec1e93e71358b93b3e30c99ba29d5](https://github.com/ruby/ruby/commit/b24603adff8ec1e93e71358b93b3e30c99ba29d5)

**Performance Impact**:
- **Thread allocation cost reduced ~70%**: From 85 μs/allocation (Ruby 2.6) to 25 μs/allocation (Ruby 2.7).
- **Better memory locality**: Using thread stack for the Ruby VM stack allocation provides better cache locality.

This improvement in thread allocation illustrates how a deep understanding of system behavior can yield significant performance gains through targeted low-level changes.

### Ruby 3.0: Ractor Introduction and Thread-Local Storage

Ruby 3.0 introduced Ractors as an experimental feature for true parallelism, requiring significant changes to Ruby's VM architecture to support isolated execution contexts.

**Commit**: [79df14c04b452411b9d17e26a398e491bca1a811](https://github.com/ruby/ruby/commit/79df14c04b452411b9d17e26a398e491bca1a811)

**Performance Impact**:
- **Thread context switching regression ~60%**: From 0.619 μs/switch (Ruby 2.7) to 0.991 μs/switch (Ruby 3.0).
- **Implementation complexity**: The introduction of Ractors significantly increased the complexity of the implementation.

### Ruby 3.3: M:N Thread Scheduler for Ractors

Ruby 3.3 introduced an M:N thread scheduler to support Ractors, significantly changing how threads are managed internally.

**Commit**: [be1bbd5b7d40ad863ab35097765d3754726bbd54](https://github.com/ruby/ruby/commit/be1bbd5b7d40ad863ab35097765d3754726bbd54)

**Performance Impact**:
- **Thread allocation performance regressed ~200%**: From 24 μs/allocation (Ruby 3.2) to 71 μs/allocation (Ruby 3.3), primarily due to the removal of the `alloca` optimization and replacement with heap allocation (`ruby_xmalloc`).
- **Thread switching performance regressed ~120%**: From 0.674 μs/switch (Ruby 3.2) to 1.508 μs/switch (Ruby 3.3).
