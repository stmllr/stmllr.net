---
layout: post
title: Limiting cleanup routines in Rspec hooks to passed tests
date: 2016-04-12 15:42
excerpt: Here comes a tiny howto for cleaning up fixture files of Rspec examples within hooks. The fixtures shall be kept if the test fails.
tags:
  - Ruby
  - Testing
  - Rspec
---

### Problem: Fixture files left on disk after test run

One of the key functionality of [BackHub](https://backhub.co) is storing data to disk.
The BackHub application and its I/O methods are covered by Rspec tests. Unfortunately we can't use
[fakefs/fakefs](https://github.com/fakefs/fakefs) in certain cases to mock the filesystem.
Some examples create fixture data, which had to be wiped from the disk afterwards.
In general this gets done by our Continuous Integration Server. However, on the developers machines, the CI routines
are not fully in place and a cleanup routine was required as a workaround. The routine should wipe any fixtures,
except for failed tests, so that developers could examine the test environment.

### Solution: Hook into Rspec and delete fixtures if the test passed

The _after_ hook in Rspec can be used for cleanup routines. To avoid conflicts between examples, we use the
`after :example` hook. Its block is called at the end of each example as a part of the example itself.

    after :example do
      # do stuff here
    end

Implementing our routine for wiping the disk was easy:

    after :example do
      FileUtils.rm_rf path_to_fixtures
    end

However, we do not want to wipe fixtures of failed tests. In [Cucumber](https://github.com/cucumber/cucumber/wiki/Hooks)
the final state of a scenario could be queried using:

    # Cucumber hook here...
    After do |scenario|
      if scenario.passed? do
        FileUtils.rm_rf path_to_fixtures
      end
    end

Rspec also comes with a construct which represents the state of an executed test:

    example.execution_result[:status]

But as mentioned above, the `after :example` hook of Rspec is part of the example itself. Within the hook, the example
does not yet have a state, because it has not finished.

Nevertheless we need the current state of an example to decide if fixtures should be deleted or not.

With Rspec 2.7, an API was introduced to [ask the example for exceptions](https://github.com/rspec/rspec-core/issues/401)
which occurred during its execution. Exceptions can be used as an indicator that a test failed:

    after :example do |example|
      FileUtils.rm_rf path_to_fixtures unless example.exception
    end

Et voilà.

