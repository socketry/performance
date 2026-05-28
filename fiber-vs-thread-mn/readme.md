# Fiber vs Thread M:N Benchmark

This benchmark compares fibers and threads for three focused metrics:

1. Thread vs fiber allocation cost.
2. Context switching cost.
3. IOPS throughput (concurrent file-read operations per second).

It is intentionally separate from the original benchmark directory so you can iterate on parameters independently.

For Ruby 3.3 and newer, thread benchmarks are reported in two modes:

1. default: Main Ractor default scheduler behavior.
2. mn: Main Ractor with M:N scheduler enabled via environment variables.

## Usage

From this directory:

```bash
bundle install
bake benchmark
```

To force re-running all cached benchmark files:

```bash
bake benchmark --force
```

## Scenarios

- Allocation:
  - 20,000 units.
  - Reports microseconds per allocation and allocations per second.
- Context switch:
  - 2 workers, 200,000 switches each.
  - Reports microseconds per switch and switches per second.
- IOPS:
  - 1,000 workers, 200 operations each.
  - Reports operations per second and microseconds per operation.
  - Each operation performs a file read of a shared benchmark input file.

## Results

Allocation, context-switch, and file-read IOPS throughput benchmark.

### Allocation Cost

| Ruby Version | Thread Mode | Fiber alloc (us) | Thread alloc (us) | Ratio (thread/fiber) | Fiber alloc/s | Thread alloc/s |
|--------------|-------------|------------------|-------------------|----------------------|---------------|----------------|
| ruby:3.3     | default     | 0.495            | 47.120            | 95.19x               | 2,022,153     | 21,222         |
| ruby:3.3     | mn          | 0.495            | 4.286             | 8.66x                | 2,022,153     | 233,339        |
| ruby:3.4     | default     | 0.501            | 62.888            | 125.52x              | 1,995,743     | 15,901         |
| ruby:3.4     | mn          | 0.501            | 4.482             | 8.95x                | 1,995,743     | 223,091        |
| ruby:4.0     | default     | 0.580            | 51.202            | 88.28x               | 1,725,403     | 19,530         |
| ruby:4.0     | mn          | 0.580            | 5.367             | 9.25x                | 1,725,403     | 186,319        |

### Context Switching Cost

| Ruby Version | Thread Mode | Fiber switch (us) | Thread switch (us) | Ratio (thread/fiber) | Fiber switches/s | Thread switches/s |
|--------------|-------------|-------------------|--------------------|----------------------|------------------|-------------------|
| ruby:3.3     | default     | 0.101             | 1.228              | 12.16x               | 9,905,606        | 814,635           |
| ruby:3.3     | mn          | 0.101             | 0.063              | 0.62x                | 9,905,606        | 15,789,666        |
| ruby:3.4     | default     | 0.099             | 1.262              | 12.75x               | 10,088,351       | 792,616           |
| ruby:3.4     | mn          | 0.099             | 0.066              | 0.67x                | 10,088,351       | 15,171,489        |
| ruby:4.0     | default     | 0.097             | 1.311              | 13.52x               | 10,273,283       | 762,783           |
| ruby:4.0     | mn          | 0.097             | 0.059              | 0.61x                | 10,273,283       | 16,856,233        |

### IOPS Throughput

| Ruby Version | Thread Mode | Fiber IOPS | Thread IOPS | Ratio (fiber/thread) | Fiber op (us) | Thread op (us) |
|--------------|-------------|------------|-------------|----------------------|---------------|----------------|
| ruby:3.3     | default     | 554,351    | 65,558      | 8.00x                | 1.804         | 15.254         |
| ruby:3.3     | mn          | 554,351    | 115,405     | 4.00x                | 1.804         | 8.665          |
| ruby:3.4     | default     | 540,348    | 57,807      | 9.00x                | 1.851         | 17.299         |
| ruby:3.4     | mn          | 540,348    | 112,757     | 4.00x                | 1.851         | 8.869          |
| ruby:4.0     | default     | 556,065    | 71,803      | 7.00x                | 1.798         | 13.927         |
| ruby:4.0     | mn          | 556,065    | 192,869     | 2.00x                | 1.798         | 5.185          |

Notes:
  - Allocation: 20,000 units.
  - Context switch: 2 workers, 200,000 switches each.
  - IOPS: 1,000 workers, 200 operations each (each operation reads the shared benchmark file).
  - Thread mode: Ruby 3.3+ includes both default and mn (RUBY_MN_THREADS=1, RUBY_MAX_CPU=8).

## Notes

- The IOPS test performs non-trivial file I/O (`File.binread`) on each operation before yielding/passing.
- Results are cached under `results/` as YAML so repeated runs are fast.
- Docker images are used per Ruby version to keep runtime comparisons consistent.
- The mn variant uses `RUBY_MN_THREADS=1` and `RUBY_MAX_CPU=8` inside the benchmark container.
