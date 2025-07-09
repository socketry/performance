# The Long Road to Care-Free Concurrency in Ruby

In 2017, I released Async, a framework for building concurrent Ruby applications. It used Ruby's existing Fiber implementation to provide elegant I/O multiplexing. However, the performance of Fiber left a lot to be desired. Previously, I had implemented another project in C++ that used fibers for concurrency, and I could see the potential.

The vision was simple: fibers should be so cheap that you'd never think twice about using them. No more thread pools, no more complex memory management spilling into application code. Just clean, simple concurrency.

## Ruby 2.6: The First Leap

My first major contribution was implementing [native assembly `coroutine_transfer`](https://github.com/ruby/ruby/blob/3f0e0d5c8bf9046aee7f262a3f9a7524d51aaf3e/coroutine/amd64/Context.S#L16-L56) in Ruby 2.6. Previously, Ruby was using `ucontext` and `setjmp`/`longjmp` which have known peformance issues.

**The impact was staggering:**

| Metric | Ruby 2.5 | Ruby 2.6 | Improvement |
|--------|----------|----------|-------------|
| Fiber Context Switches/sec | 3,208,507 | 8,775,810 | **2.7x faster** |

The native assembly implementation delivered a **2.7x improvement** in fiber context switching performance.

## Ruby 2.7: The Golden Age

By Ruby 2.7, I had a much deeper understanding of Ruby's internals. I implemented two key optimizations that would define the "golden age" of Ruby concurrency:

1. **[Pooled stack allocations](https://github.com/ruby/ruby/blob/3f0e0d5c8bf9046aee7f262a3f9a7524d51aaf3e/cont.c#L123-L172) for fibers**: Making fiber allocation essentially zero-cost.
2. **Thread VM stack allocation with `alloca`**: Improving memory locality for threads.

The `alloca` optimization was particularly satisfying. Once I understood the separation between the machine stack and Ruby's VM stack, the solution was obvious. It was a perfect example of how deep technical knowledge enables elegant solutions.

**The results were even more dramatic:**

| Metric | Ruby 2.6 | Ruby 2.7 | Improvement |
|--------|----------|----------|-------------|
| Fiber Allocation (μs) | 5.5 | 3.4 | **1.6x faster** |
| Thread Allocation (μs) | 64.4 | 19.1 | **3.4x faster** |

The pooled allocations made (cold) fiber allocation **1.6x faster**, while the `alloca` optimization made thread allocation **3.4x faster**. Combined with the previous improvements, we now had a concurrency model where fibers were nearly 6x faster to allocate than threads.

The numbers actually don't speak to the full magnitude of the improvement – Ruby 2.6 had a very rudimentary cache for stack allocations, but it performed poorly under load. In a server environment, I wanted to use one or more fibers per request, and this scenario was significantly improved in Ruby 2.7:

| Metric | Ruby 2.6 | Ruby 2.7 | Improvement |
|--------|----------|----------|-------------|
| Fiber Allocation (cold cache) | 5.6 μs | 3.4 μs | 1.6x faster |
| Fiber Allocation (hot cache) | 57.7 μs | 1.0 μs | **58x faster** |
| Thread Allocation (cold cache) | 67.1 μs | 19.1 μs | 3.5x faster |
| Thread Allocation (hot cache) | 85.7 μs | 10.5 μs | 8.2x faster |

## Ruby 3.1: The Fiber Scheduler

Ruby 3.1 introduced the first iteration of the Fiber Scheduler, marking a crucial milestone in the journey toward care-free concurrency. This wasn't just another performance improvement—it was the bridge between the raw performance gains and practical usability.

The Fiber Scheduler provided a standardized interface for integrating event loops with Ruby's fiber system. Before this, Async had to use various workarounds and wrappers to hook into Ruby's I/O operations. With the fiber scheduler, we could integrate directly into Ruby's core without any external dependencies.

**The impact was immediate and profound:**

- **Seamless I/O integration**: No more monkey-patching or complex wrappers
- **Standardized interface**: A consistent way for any event loop to integrate with Ruby
- **Better performance**: Direct integration meant fewer layers and better performance
- **Easier adoption**: The barrier to using Async dropped significantly

This was the moment when the performance improvements we'd been working on for years finally became accessible to everyday Ruby developers. The Fiber Scheduler made it possible to use Async with minimal code changes.

## Ruby 3.3+: A New Chapter

Ruby 3.3 introduced the M:N thread scheduler to support Ractors, marking a significant change in Ruby's concurrency model. This change brought both challenges and opportunities.

The M:N scheduler increased CRuby's complexity and caused some performance regressions in thread allocation and context switching.

The performance data shows this transition:

| Metric | Ruby 3.2 | Ruby 3.3 | Change |
|--------|----------|----------|--------|
| Thread Allocation (μs) | 18.1 | 65.1 | 3.6x slower |
| Thread Context Switches/sec | 1,908,317 | 783,994 | 2.4x slower |
| Fiber Performance | Maintained | Maintained | Stable |

While thread performance regressed, fiber performance remained stable. This created an interesting dynamic where the performance gap between fibers and threads widened significantly, making fibers an even more compelling choice for most concurrent workloads.

## The Future

[As I look back on this journey from Ruby 2.5 to 3.5](https://github.com/socketry/performance/blob/main/fiber-vs-thread/readme.md), I'm struck by how far we've come. What started as a simple observation—"Ruby's fibers are too slow"—has evolved into a fundamental improvement in Ruby's concurrency model.

The performance data tells a remarkable story: fibers have gone from being 7x faster than threads in Ruby 2.5 to being 18-23x faster in recent versions. But the real achievement isn't just the numbers—it's that care-free concurrency is now a reality for Ruby developers, unlocking new possibilities for building efficient applications.

These improvements are beginning to bear fruit across the ecosystem. We're seeing wider adoption of fiber-based concurrency libraries like Async and Falcon, with Shopify's implementation being a notable example. Yet while Ruby's adoption is encouraging, my internal measure of success extends beyond our community—it's seeing whether other programming languages recognize and adopt this concurrency model too. After all, true innovation transcends language boundaries.

## Lessons Learned

This journey has taught me several important lessons:

**Scope × Value = Impact.** Ruby has scope: millions of developers. Async has value: care-free concurrency. The combination creates meaningful impact.

**Stay true to your internal intuition.** When I first started, I had a clear vision of what care-free concurrency should look like. I've learned to trust that intuition, even when the path forward isn't clear.

**Train your intuition regularly.** Every challenge is an opportunity to further develop your internal compass. The more you exercise your intuition, the more valuable it becomes.

**Apply your intuition to problems you care about.** When you combine strong convictions with persistent effort on meaningful problems, you can achieve incredible things.

**Have strong design opinions, but keep an open mind.** It's important to have convictions about what you're building, but equally important to be willing to learn and adapt.

**Take your time with design.** Sometimes I think about design for weeks before writing a single line of code. Good design is worth the investment.

**Success may appear sudden to observers, but is built step by step.** Don't underestimate the cumulative impact of consistent, focused effort over time.
