# resque-mock

In memory mocks for running resque without redis in test mode.

## Overview

Managing forking/background processes in test & CI environments is a
pain. `resque-mock` allows you to run resque jobs in tests without
forking or connecting to a redis server.

## Usage

Activate `resque-mock` by calling `Resque.mock!` in your test setup code.

    require 'resque'
    require 'resque/mock'

    class VerifyUserTest < Test::Unit::TestCase
      def setup
        Resque.mock!
      end

      def test_verify_user
        # model with a some states
        user = User.new(:state => :signup)

        # resque job which verifies a user
        VerifyUser.enqueue(user.id)

        # probably have to reload this guy
        user.reload!

        # the job has ran, the user should be verified
        assert_equal user.state, :verified
      end
    end

The `VerifyUser.enqueue` is synchronous and will block until the job
returns.

## Async Jobs

You can run jobs asynchronously with `Resque.async`.

    class AsyncTest < Test::Unit::TestCase
      def setup
        Resque.mock!
      end

      def test_async_verify
        user = User.new(:state => :signup)

        Resque.async do
          # this job might take a while, and spawn other jobs.
          VerifyUser.enqueue(user.id)

          # it's a slow job, so it probably won't be finished yet.
          user.reload!
          assert_not_equal user.state, :verified
        end

        # the block doesn't return until all jobs are finished, so
        # the verify job should be done
        assert_equal user.state, :verified
      end
    end

Async jobs are pushed onto a worker queue managed by a manager thread.
Each job is then started in it's own thread.

## resque-scheduler

`resque-mock` can also mock `resque-scheduler`'s `Resque.enqueue_in` and
`Resque.enqueue_at` methods.

## Contributors

Dan Peterson (https://github.com/dpiddy)

Ben Burkert  (https://github.com/benburkert)
