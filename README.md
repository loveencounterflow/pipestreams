


# PipeStreams

PipeStreams use (pull-stream)[https://github.com/pull-stream/pull-stream]s as infrastructure to realize
rather performant streaming in NodeJS. The main purpose for PipeStreams is to facilitate the building of
streaming applications; in other words: to provide a simple and clear API to minimize mental overhead.

While PipeStreams as such are not directly compatible with 'classical' NodeJS push-style streams, one can
always interface the two using a number of adaptors to maintain interoperability.

PipeStreams encourages and simplifies the use of classical command line (shell/bash) tools to boost
performance.

### @spawn = ( command, settings ) ->

PipeStreams `spawn` is a re-imagination of how to deal with spawning child processes in an
asynchronous world. Many attempts to provide for proper process spawning are either too simplistic or
too hard to use right; in either case, there is too much opportunity to get things not quite right and
to produce subtly faulty code that opens the door to silent failures; conversely, client code that does
manage to consider all edge cases is frequently overly convoluted.

The underlying platform—NodeJS—does get some things right: it is generally a good idea to listen to
streams of output from spawned processes rather than to wait for one chunk of data that only arrives
when the process has finished; likewise, listening in on events is superior to evaluating exit codes on
a channel that also carries result data and / or error messages. The difficulty with NodeJS `spawn`,
however, is that there are so many loose ends that have to be tied together before a single process can
be started: There's the child process' `stdout` and `stderr` streams that may both produce data (that
may or may not be indicative of success or failure, depending on the command executed) on the one hand,
and there's the `error`, `disconnect` and `exit` events, the last of which may communicate either a
numerical code or else a signal name.

The basic insight that guided the implementation of `pipestreams.spawn` is threefold:

* Fewer datasources are easier to handle than many, provided that different points of data origin remain
  discernible and are not just poured into one big pot; hence, output to `stdout` has to remain distinct
  from output to `stderr`.

* Streams are an appropriate and manageable abstraction for the data that results from spawning an
  asynchronous sub-process.

* The fewer the types of events that come down the stream and the more predictable their relative
  ordering, the better; especially the shape of the terminating event should be clear from the outset,
  because that single piece of information decides what will be communicated to the continuation and
  when.

PipeStreams `spawn` returns a single in the form of a pull stream source; this is the single source of
'truth' when it comes to handling success or failure (or, indeed, both, as they can co-occur in complex
shell commands). That source provides the following characteristics and guarantees:

* `spawn` is initiated with a command *string* or a command *list*; in the former case, a shell is
  started (`/bin/sh`) which will take care of argument parsing, while in the latter case, command and
  arguments must already be appropriately sliced, and no shell will be invoked.

* The method returns a pull streams source. The events that come down the source will all be `[ key,
  value, ]` pairs (also known as 'facets').

* Every key will be one of `'command'`, `'stdout'`, `'stderr'`, or `'exit'` (occasionally, `'error'` and
`'disconnect'` may also occur, but I have yet to find trigger conditions for those).

* The `command` event will always be the first event to come down the stream; its value is always the
  first argument with which `spawn` was initiated. Next come the `stdout` and `stderr` events. The last
  event is always `exit`; its value is an object with a `code` and a `signal` property.

* The `signal` property will name the signal, if any, with which the spawned process was terminated; if
  it is present and known and the `code` value was not also set (which should be impossible), then the
  `code` value is set to `128` plus the numerical equivalent (the signal number) of the signal.
  Otherwise, only `code` is set; in most cases, it will be `0` indicating success or else a value
  greater than `0` (frequently `1`) indicating failure.

* Since it turns out that in practice neither error codes, nor signals or output to `stderr` are
  sufficiently reliable to judge about success or failure in a generic fashion, PipeStreams `spawn` will
  *never* error out with allowable inputs.

To drive that last point home, consider that calling `spawn 'bonkers'` is totally legal even if you have
no executable called `bonkers` on the path; it should produce three events, in this order:

```json
["command","bonkers"]
["stderr","/bin/sh: bonkers: command not found"]
["exit",{"code":127,"signal":null}]
```

`spawn` cannot tell whether—maybe!—what you wanted was indeed testing whether `bonkers` was installed
on the system. At any rate, erroring out because `stderr` (!) and exit code (!!) would not be a wise
thing to do for a generic utility, because a slight adjustment totally changes things:

```json
["command","bonkers 2>&1; exit 0"]
["stdout","/bin/sh: bonkers: command not found"]
["exit",{"code":0,"signal":null}]
```

Now the error message is hidden in `stdout`, and the exit code looks just fine. Add to this that some
executables routinely write their informational messages to `stderr` and may not even communicate
'errors', just 'conditions' using exit codes, and should become abundantly clear that it can only be the
responsibility of the one who spawns a process to analyze the output as seen fit. This becomes
especially true with compound commands; here is a sample that mixes success and failure:

```json
["command","bonkers; echo \"success!\"; exit 0"]
["stdout","success!"]
["stderr","/bin/sh: bonkers: command not found"]
["exit",{"code":0,"signal":null}]
```

Worse is possible:

```json
["command","bonkers; echo \"success!\"; kill -27 $$"]
["stdout","success!"]
["stderr","/bin/sh: bonkers: command not found"]
["exit",{"code":155,"signal":"SIGPROF"}]
```


### @$sample = ( p = 0.5, options ) ->

Given a `0 <= p <= 1`, interpret `p` as the *p*robability to *p*ick a given record and otherwise toss
it, so that `$sample 1` will keep all records, `$sample 0` will toss all records, and
`$sample 0.5` (the default) will toss (on average) every other record.

You can pipe several `$sample()` calls, reducing the data stream to 50% with each step. If you know
your data set has, say, 1000 records, you can cut down to a random sample of 10 by piping the result of
calling `$sample 1 / 1000 * 10` (or, of course, `$sample 0.01`).

Tests have shown that a data file with 3'722'578 records (which didn't even fit into memory when parsed)
could be perused in a matter of seconds with `$sample 1 / 1e4`, delivering a sample of around 370
records. Because these records are randomly selected and because the process is so immensely sped up, it
becomes possible to develop regular data processing as well as coping strategies for data-overload
symptoms with much more ease as compared to a situation where small but realistic data sets are not
available or have to be produced in an ad-hoc, non-random manner.

**Parsing CSV**: There is a slight complication when your data is in a CSV-like format: in that case,
there is, with `0 < p < 1`, a certain chance that the *first* line of a file is tossed, but some
subsequent lines are kept. If you start to transform the text line into objects with named values later in
the pipe (which makes sense, because you will typically want to thin out largeish streams as early on as
feasible), the first line kept will be mis-interpreted as a header line (which must come first in CSV
files) and cause all subsequent records to become weirdly malformed. To safeguard against this, use
`$sample p, headers: true` (JS: `$sample( p, { headers: true } )`) in your code.

**Predictable Samples**: Sometimes it is important to have randomly selected data where samples are
constant across multiple runs:

* once you have seen that a certain record appears on the screen log, you are certain it will be in the
  database, so you can write a snippet to check for this specific one;

* you have implemented a new feature you want to test with an arbitrary subset of your data. You're
  still tweaking some parameters and want to see how those affect output and performance. A random
  sample that is different on each run would be a problem because the number of records and the sheer
  bytecount of the data may differ from run to run, so you wouldn't be sure which effects are due to
  which causes.

To obtain predictable samples, use `$sample p, seed: 1234` (with a non-zero number of your choice);
you will then get the exact same
sample whenever you re-run your piping application with the same stream and the same seed. An interesting
property of the predictable sample is that—everything else being the same—a sample with a smaller `p`
will always be a subset of a sample with a bigger `p` and vice versa.


## ToDo

* [ ] make (`stream-to-pull-stream`) `STPS.source`, `STPS.sink` methods public / rename
  `@_new_file_sink_using_stps`

