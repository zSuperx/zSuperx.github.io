---
title: T-Holder (a Thread Holding C library)
---

[Project Research Paper](https://drive.google.com/file/d/1gw1h8_Luz7IO7mb8fbgMe0Q_ZhzFM0Hs/view?usp=sharing)

[Github Repo](https://github.com/MangoShip/ECS251Project)

This is a group project I created with 6 other people in a Graduate level OS
class at Davis.

## What is T-Holder?

T-Holder is a C library that wraps around common `pthread.h` functions and
optimizes the creation/deletion of threads. It does this by reusing threads that
were recently scheduled for deletion.

## Features/API

The following describes the functionality of each of the functions defined in
`tholder.h`. Any debug info is ignored here.

1. `tholder_create(tholder_t *__newthread, ..., void *(*__start_routine)(void *), ...);`

   - Gets the first inactive index in the thread pool that's ready to do work
     (via `get_inactive_index()`). If no thread is alive in this slot, it will
     use `pthread_create` to spawn one and run `auxiliary_function()`.

   - `pthread_detatch` is used so the thread can exit on its own without
     blocking. In order to let the user block until the task is completed, a
     `task_output` struct is created on the heap, and its pointer is cast to
     `tholder_t` and written to `__newthread`.

2. `tholder_join(tholder_t th, void **thread_return);`
   - This function casts `th` to a pointer, which is where the
     given`task_output` struct lives.
   - This function will then block on a condition variable located in the
     struct, which is pinged only once the task is completed by
     `auxiliary_function`. It also cleans up the `task_output` struct once
     finished.

3. `tholder_init(size_t num_threads);`
   - A helper function that simply creates the global thread pool with a
     specified size. This function is implicitly called by `tholder_create(8)`
     if the thread pool has not been initialized yet.

4. `tholder_destroy();`
   - Cleans up the thread pool allocated by `tholder_init()`.

5. `auxiliary_function(void *args);`
   - This function sleeps on a timed condition variable for `DURATION` time.
     Each time it wakes up, it will check if there is new work in its assigned
     `thread_data` struct. If so, it will execute the task. If not, it will
     break the loop and exit.
   - This behavior allows the thread to be "reused" and exit if waiting for too
     long.

6. `get_inactive_index();`
   - Finds first index that is either:

   - `NULL`, which signifies that this thread slot is uninitialized and ready to
     be spawned
   - Idle but alive, in which case this thread is ready to be reused for a task
     Then it creates the `thread_data` struct

7. `task_output_init();`
   - Allocates the memory for a task. This is used by the `auxiliary_function`
     to write output data to, but it is uniquely tied to the task, NOT the
     thread itself.
