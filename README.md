
🔻🔻🔻**Work in progress**🔻🔻🔻 usable, but documentation is fragmentary



# PipeStreams

PipeStreams use (pull-stream)[https://github.com/pull-stream/pull-stream]s as infrastructure to realize
rather performant streaming in NodeJS. The main purpose for PipeStreams is to facilitate the building of
streaming applications; in other words: to provide a simple and clear API to minimize mental overhead.

While PipeStreams as such are not directly compatible with 'classical' NodeJS push-style streams, one can
always interface the two using a number of adaptors to maintain interoperability.

PipeStreams encourages and simplifies the use of classical command line (shell/bash) tools to boost
performance.

## Documentation

* [The PDF](./pipestreams-manual/pipestreams-manual.pdf)
* [PipeStreams: Pipelines and Streams](./pipestreams-manual/chapter-00-intro.md)
* [sampling](./pipestreams-manual/chapter-00-sampling.md)
* [spawn](./pipestreams-manual/chapter-00-spawn.md)

## ToDo

* [ ] make (`stream-to-pull-stream`) `STPS.source`, `STPS.sink` methods public / rename
  `@_new_file_sink_using_stps`

