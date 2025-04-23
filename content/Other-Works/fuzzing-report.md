---
title: Fuzzing in Computer Security
---

> Note: This is a report originally written for a class.

Many codebases have a recurring problem of testing for bugs and undefined
behavior. Especially if said codebase is large, it becomes increasingly
difficult for programmers to locate and squash bugs across the project manually.
In this report, we’ll explore what fuzzing is, how it plays a vital role in
computer security, and even demonstrate how it helped unearth a complex bug in
an old Rust project of mine!

## Manual Testing

### Simple Example: Nuclear Launch Codes.

We can start with a simple example written in C. Suppose we created a program
that holds nuclear launch codes that can only be accessed if the right password
is entered. Scary, right? After a few tries of manual testing, it seems to work
as intended.

```console
[zsuper@nixos:~/very-important-program]$ ./nuclear-launch-codes
Enter the correct code: 600

Incorrect.
!!! The FBI are on their way to your location now !!!

[zsuper@nixos:~/very-important-program]$ ./nuclear-launch-codes
Enter the correct code: 153

Correct! Here are the nuclear launch codes...
```

But how can we guarantee the program won’t fail? Could there be certain inputs
that cause problems and lead to memory vulnerabilities? We will later see that
bugs do exist within the program, and uncover them with a real fuzzer.

### Complex Example: Custom Compression

An argument can be made that such a simple program like the one above can easily
be tested through some code review. Instead, let’s switch over to a much more
involved example.

Over the past 6 months, I’ve been developing a custom lossless compression
algorithm. The project is written entirely in Rust and in total has well over
2000 lines of code. Now, the task of finding bugs becomes much more daunting.
While Rust does (for the most part) ensure that the program will have no
undefined behavior, there’s no guarantee that the code functions as intended. So
how can we test such a large project?

First things first, we want to define a success metric so we know what an
incorrect output would look like. As is expected from any lossless compression
scheme, a compressed input should decompress back to its original content and
vice versa. We can account for this in the code:

1. Calculate and store the _hash_ of the original file contents in a variable
   `original_hash`
2. Compress the file (and perhaps write its contents to the disk somewhere)
3. Decompress the compressed file, calculate the hash of it, and store it in
   `new_hash`
4. If `new_hash!=original_hash`, there was an error with (de)compression
   somewhere, so `panic!()`

Unfortunately, a success metric alone isn’t enough to solve the original problem
regarding testing. We still have to tackle the issue of choosing what input
files should be tested. As of now, the input files still need to be picked out
manually, and finding one that causes a bug in such a complicated project can
take hours for a human.

## Fuzzing

Fortunately, not all is lost, and it's all thanks to fuzzing. **Fuzzing** is the
act of automatically running a specified program with pseudo-random input with
the goal of finding “interesting” inputs and their results.

### AFL: The American Fuzzy Lop

AFL, a fuzzing tool developed by Michael Zalewski in 2013, is the most popular
and standardized fuzzing tool today. Like most fuzzing tools, it keeps track of
a global queue of inputs to run the target program with, and follows the general
algorithm:

1. Load the next input, `x`, from the queue
2. “Minimize” `x`
3. “Mutate” `x`, and add all “interesting” mutations to the queue
4. Go back to Step 1.

Here, “interesting” means the unique code coverage achieved by an associated
input. Thus, the goal is to maximize the amount of code coverage that has been
seen throughout the fuzzing session. The input queue will originally contain
seeding files, which are defined by the user. It’s suggested to use inputs that
are known to work, but mainly those that may trigger edge cases.

#### Measuring Coverage

In order to measure coverage, AFL utilizes the Control Flow Graph (CFG) of the
program. It starts by enumerating each edge within the CFG such that it can be
uniquely identified. Then, it defines labels that each of these edges can be
marked with during an execution. The labels are 1, 2, 3, 4-7, 8-15, 16-31,
32-127, and 128+. The number/range of a label’s name depicts how many times a
certain edge was hit during a particular execution.

A global HashSet of 2-tuples is maintained throughout the entire fuzzing
session, where each entry is of the form `(edge, label)`. Each time an input is
used to run a program, AFL will track how many times each edge was hit by
creating a `(edge, label)` tuple. If a new 2-tuple that has not been seen before
is generated, it’s added to the global HashSet. The associated input is
consequently considered “interesting” and is added to the input queue.

> Note: In order to track the CFG and edge hitcount, AFL provides compilers that
> add required instrumentation at compile time. While it is possible to fuzz
> regular binaries, it is not recommended.

#### Mutating Input

Suppose the `nuclear-launch-codes` program from before discards all non-integer
input, and keeps only the leading numbers.

If AFL attempts to simply mutate the input `“123 hello”`, it may create many
redundant inputs such as `“123 hellp”`, `“123 hell”`, and `“123 helloo”`, all of
which are interpreted as `”123”` when the program executes. None of these
mutations provide any real value, and end up slowing down the total fuzzing
process.

Instead, AFL performs a “minimization” of the input, where it attempts to trim
the input at various offsets. If the trimmed input yields the same coverage as
the original, AFL will discard the original and continue with the trimmed
version. With the case of `”123 hello”`, AFL will quickly minimize it to simply
`”123”`.

### Simple Example Revisited

Looking back at the nuclear-launch-codes example from before, we can use AFL++
(a fork of AFL) to fuzz the program and find bugs. After installing AFL++, we
get access to `afl-gcc`, a drop-in C compiler that inserts the necessary
instrumentation into the binary at compile-time.

We also need to tell AFL++ what seed files to use, so we create a `testcases/`
directory. For the sake of this simple example, we will use 2 seed files, with
contents `600` and `153` respectively. Now, it’s time to see it in action!

First we compile using the provided compiler (`afl-gcc-fast` or
`afl-clang-fast`):

```console
[zsuper@nixos:~/very-important-program]$ afl-gcc-fast ./nuclear-launch-codes
afl-gcc-fast ./nuclear-launch-codes.c -o nuclear-launch-codes
afl-cc++4.31c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: GCC_PLUGIN-DEFAULT
afl-gcc-pass ++4.31c by <oliva@adacore.com>
[*] Inline instrumentation at ratio of 100% in non-hardened mode.
[+] Instrumented 4 locations (non-hardened mode, inline, ratio 100%).
```

Then we run the fuzzer using `afl-fuzz`:

```console
[zsuper@nixos:~/very-important-program]$ afl-fuzz -i testcases/ -o findings/ ./nuclear-launch-codes
afl-fuzz++4.31c based on afl by Michal Zalewski and a large online community
[+] AFL++ is maintained by Marc "van Hauser" Heuse, Dominik Maier, Andrea Fioraldi and Heiko "hexcoder" Eißfeldt
[+] AFL++ is open source, get it at https://github.com/AFLplusplus/AFLplusplus
[+] NOTE: AFL++ >= v3 has changed defaults and behaviours - see README.md
[+] No -M/-S set, autoconfiguring for "-S default"
[*] Getting to work...

    american fuzzy lop ++4.31c {default} (./nuclear-launch-codes) [explore]    
┌─ process timing ────────────────────────────────────┬─ overall results ────┐
│        run time : 0 days, 0 hrs, 0 min, 29 sec      │  cycles done : 507   │
│   last new find : none yet (odd, check syntax!)     │ corpus count : 2     │
│last saved crash : 0 days, 0 hrs, 0 min, 29 sec      │saved crashes : 1     │
│ last saved hang : none seen yet                     │  saved hangs : 0     │
├─ cycle progress ─────────────────────┬─ map coverage┴──────────────────────┤
│  now processing : 1.1715 (50.0%)     │    map density : 0.00% / 0.00%      │
│  runs timed out : 0 (0.00%)          │ count coverage : 1.00 bits/tuple    │
├─ stage progress ─────────────────────┼─ findings in depth ─────────────────┤
│  now trying : havoc                  │ favored items : 2 (100.00%)         │
│ stage execs : 51/100 (51.00%)        │  new edges on : 2 (100.00%)         │
│ total execs : 202k                   │ total crashes : 16 (1 saved)        │
│  exec speed : 6826/sec               │  total tmouts : 0 (0 saved)         │
├─ fuzzing strategy yields ────────────┴─────────────┬─ item geometry ───────┤
│   bit flips : 0/0, 0/0, 0/0                        │    levels : 1         │
│  byte flips : 0/0, 0/0, 0/0                        │   pending : 0         │
│ arithmetics : 0/0, 0/0, 0/0                        │  pend fav : 0         │
│  known ints : 0/0, 0/0, 0/0                        │ own finds : 0         │
│  dictionary : 0/0, 0/0, 0/0, 0/0                   │  imported : 0         │
│havoc/splice : 1/202k, 0/0                          │ stability : 100.00%   │
│py/custom/rq : unused, unused, unused, unused       ├───────────────────────┘
│    trim/eff : n/a, n/a                             │          [cpu000: 25%]
└─ strategy: explore ────────── state: started :-) ──┘
```

> Note: Because AFL operates by observing the behavior of its spawned processes,
> it may require you to change where your system dumps core logs as well as what
> CPU scaling governer you're using. AFL will print out exactly what commands
> need to be run to fix this, as well as options you can set to skip these (at
> the cost of some performance)

After just 20 seconds, AFL++ found 3 crashes! Because the inputs for each of
these crashes were likely similar, it decided that only 1 of them was worth
saving. We can view the contents of this file by using `hexdump` (in case the
input is not strictly ASCII).

```console
[zsuper@nixos:~/very-important-program]$ hexdump -C findings/default/crashes/id:000000,sig:11,src:000000,time:765,execs:4757,op:havoc,rep:7
00000000  33 32                                             |32|
00000002
```

Now we can see that an input of `“032”` causes a crash to our program! If we
take a look at the source code of `nuclear-launch-codes.c`, we can now clearly
see the issue:

```c
#include <stdio.h>

#define SECRET 153

int main(void) {
  printf("Enter the correct code: ");

  long long guess;
  int result = scanf("%lld", &guess);

  if (guess % 100 == 32) {
    // Simulate segfault (SIGSEGV)
    printf("CURSED\n");
    int *cursed = (int *)guess;
    *cursed = 5;
  }

  if (guess == SECRET)
    printf("Correct! Here are the nuclear launch codes...\n");
  else
    printf(
        "Incorrect.\n!!! The FBI are on their way to your location now !!!\n");

  return 0;
}
```

As you can see, the program simply crashes if any number ending in `“32”` is
entered!

While fuzzing was definitely not necessary for such an obvious error, this
example demonstrates the utility it provides. The next example will truly
highlight the power of fuzzers like AFL++.

### Complex Example Revisited

Since this compression program is written in Rust and not C, a bit more work
needs to be done before the fuzzing can begin. Note that we will be using
`cargo-fuzz`, a tool used to invoke underlying fuzzing tools like AFL++ through
Cargo’s support.

#### Rust Errors

First, we have to understand how Rust handles errors. Unlike the previous C
example, which aborted the program with `SIGSEGV`, Rust will almost never run
into segmentation faults.

Instead, we wish to catch all `panic!()` statements, which abort the program
within the safety of Rust’s runtime. These occur whenever a `.unwrap()` or
`.expect()` is called on an Err. Additionally, we manually `panic!()` if we
detect an error with the (de)compression process. So all we need now is to make
AFL aware of such crashes.

Because Rust’s runtime catches `panic!()` statements instead of propagating
errors to the kernel, AFL will not view these as “crashes” (since AFL relies on
core dumped files). To remedy this, I added the following specification to my
`Cargo.toml`:

```toml
[profile.dev]
panic = "abort"
```

With this, Rust will now treat all `panic!()` statements as crashes, and abort
the program with signal `SIGABRT`, making AFL aware of erroneous cases.

#### Input Format

The `nuclear-launch-codes` example took input through `stdin`, where the user
would enter a passcode to the program. However, since this project compresses
files, we want to instruct AFL to fuzz the _contents_ of a file rather than
what’s written to `stdin`. To do this, we simply need to call our compression
binary with a command-line argument `@@`, which tells AFL++ to fuzz the contents
of a file and then provide its path to the program.

Additionally, we now populate the `testcases/` directory with 3 sample files,
ranging in size:

- A small text file containing only `”hello”` (5 B)
- The Bee Movie script (85 KB)
- A file containing a random sequence of bytes (created by reading from
  `/dev/random`) (170 KB)

Now, we're ready to fuzz!

#### Fuzzing the Compressor

```console
[zsuper@nixos:~/coding-projects/compression-v2]$ afl-fuzz -i testcases/ -o findings/ ./target/debug/compression-v2 compress @@ --check-integrity
afl-fuzz++4.31c based on afl by Michal Zalewski and a large online community
[+] AFL++ is maintained by Marc "van Hauser" Heuse, Dominik Maier, Andrea Fioraldi and Heiko "hexcoder" Eißfeldt
[+] AFL++ is open source, get it at https://github.com/AFLplusplus/AFLplusplus
[+] NOTE: AFL++ >= v3 has changed defaults and behaviours - see README.md
[+] No -M/-S set, autoconfiguring for "-S default"
[*] Getting to work...

    american fuzzy lop ++4.31c {default} (target/debug/compression-v2) [explore]    
┌─ process timing ────────────────────────────────────┬─ overall results ────┐
│        run time : 0 days, 0 hrs, 0 min, 29 sec      │  cycles done : 507   │
│   last new find : none yet (odd, check syntax!)     │ corpus count : 2     │
│last saved crash : 0 days, 0 hrs, 0 min, 29 sec      │saved crashes : 1     │
│ last saved hang : none seen yet                     │  saved hangs : 0     │
├─ cycle progress ─────────────────────┬─ map coverage┴──────────────────────┤
│  now processing : 1.1715 (50.0%)     │    map density : 0.00% / 0.00%      │
│  runs timed out : 0 (0.00%)          │ count coverage : 1.00 bits/tuple    │
├─ stage progress ─────────────────────┼─ findings in depth ─────────────────┤
│  now trying : havoc                  │ favored items : 2 (100.00%)         │
│ stage execs : 51/100 (51.00%)        │  new edges on : 2 (100.00%)         │
│ total execs : 202k                   │ total crashes : 16 (1 saved)        │
│  exec speed : 6826/sec               │  total tmouts : 0 (0 saved)         │
├─ fuzzing strategy yields ────────────┴─────────────┬─ item geometry ───────┤
│   bit flips : 0/0, 0/0, 0/0                        │    levels : 1         │
│  byte flips : 0/0, 0/0, 0/0                        │   pending : 0         │
│ arithmetics : 0/0, 0/0, 0/0                        │  pend fav : 0         │
│  known ints : 0/0, 0/0, 0/0                        │ own finds : 0         │
│  dictionary : 0/0, 0/0, 0/0, 0/0                   │  imported : 0         │
│havoc/splice : 1/202k, 0/0                          │ stability : 100.00%   │
│py/custom/rq : unused, unused, unused, unused       ├───────────────────────┘
│    trim/eff : n/a, n/a                             │          [cpu000: 25%]
└─ strategy: explore ────────── state: started :-) ──┘
```

And just like that, we’ve found a file that triggers a crash! The input file’s
contents are:

```console
[zsuper@nixos:~/coding-projects/compression-v2]$ hexdump -C findings/...
00000000  6761 736b 6e6a 7673 7461 6564 726e 7169    |gasknjvstaedrnqi|
00000010  6e77 1000 75fb fbfb 0000 546a 6700 2000    |nw..u.....Tjg. .|
00000020  cd73 6773 cdcd 0000 cdcd cd63 cdcd cd00    |.sgs.......c....|
00000030  00cd cdcd 6372 50d8 ccde de29 2833 2426    |....crp....)(3$&|
00000040  238c 8c8c 8c8c 8c8c 8d6d 6173 3e6d 4660    |#........mas>mF`|
00000050  8629 5558 5557 595a 4e4d 5755 4a5a 4a52    |.)UXUWYZNMWUJZJR|
00000060  4a4d 6365 6372 6b01 6c46 7668 2b71 6b20    |JMcecrk.LFvh+qk |
00000070  4f65 6567 6478 01e2 0079 5da9 002a 0000    |Oeegdx...y]..*..|
00000080  2395 9595 9595 009e 0000 0000 0000 0000    |#...............|
00000090  00e8 0300 0001 0000 6f67 6271 761c 7a73    |........ogbqv.zs|
000000a0  0179 436e 692b 6e6e 204c 6366 7861 6801    |.yCni+nn Lcfxah.|
000000b0  e200 745e a901 01a9 0000 694d ec89 6661    |..t^......iM..fa|
000000c0  4e5b eb74 0101 0110 006d ed89 7278 546b    |N[.t.....m..rxTk|
000000d0  7300 ec01 0101 004f 7261 6800 0000 0000    |s......Orah.....|
000000e0  2488 5556 5347 4e73 fa64 6413 6264 6263    |$.UVSGNS.dd.bdbc|
000000f0  6c63 6e75 626f 0000 0101 0101 0101 0100    |lcnubo..........|
00000100  0100 0000 0000 0000 0057 6c66 6900 1d00    |.........Wlfi...|
00000110  f4                                         |.|
```

Visually this doesn’t make much sense, so we can call the program with this file
to reproduce the bug and see the cause of the crash at the bottom:

```console
[zsuper@nixos:~/coding-projects/compression-v2]$ ./target/debug/compression-v2 compress findings/id...
...
thread `main` panicked at src/encoders/bwt.rs:113:14:
Unable to parse `4hi` into a b36 number: ParseIntError { kind: InvalidDigit }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
Aborted (core dumped)
```

And just like that, we’ve confirmed that this case causes an error! Thanks to
the logging within the program, I was able to quickly trace the cause of this
bug to the RLE Encoding stage, which rarely produces incorrect results if using
ASCII 92 (`\`) as a delimiter. After patching this error, we can even use this
erroneous input as a seed file in the `testcases/` directory and see if more
problems occur:

```console
    american fuzzy lop ++4.31c {default} (target/debug/compression-v2) [explore]    
┌─ process timing ────────────────────────────────────┬─ overall results ────┐
│        run time : 0 days, 1 hrs, 50 min, 17 sec     │  cycles done : 0     │
│   last new find : 0 days, 1 hrs, 24 min, 58 sec     │ corpus count : 414   │
│last saved crash : none seen yet                     │saved crashes : 0     │
│ last saved hang : none seen yet                     │  saved hangs : 0     │
```

After nearly 2 hours of fuzzing, no new crashes were found!

It is important to note that when creating the program, I had indeed manually
tested inputs where (`\`) was picked as a delimiter. However, I was unable to
find one that causes a crash. It was specifically a combination of this special
case delimiter and other data within the file which causes this crash, a case
that I personally would **not** have found.

## Conclusion

To conclude, Fuzzing is a powerful technique for uncovering bugs and
vulnerabilities in programs, especially those with complex or extensive
codebases. It automates the process of testing with diverse and unpredictable
inputs, achieving results that are difficult or impossible to replicate
manually. Through examples like the `nuclear-launch-codes` program and my custom
compression project, we’ve seen how tools like AFL++ can identify tricky bugs
that can directly lead to security vulnerabilities through memory errors like
segmentation faults.

While fuzzing is highly effective, there are still areas for improvement and
ongoing research. Especially in supermassive projects, AFL is still considered
quite slow. Enhancements in mutation strategies and better coverage measurement
techniques could further improve its efficiency. Additionally, adapting fuzzing
tools to work seamlessly with languages like Rust, which prioritize memory
safety, presents new challenges and opportunities for improvement.
