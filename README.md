# arm-monitor

## Project Files

* monitor.s: A skeleton file for your monitor program.
* main.s: The test harness for your monitor. This file doesn't need to be modified.
* getline.a: A binary of the line parsing routine is included since writing your own routine can be tricky. However, to get maximum marks for the project, you are expected to write your own replacement for this routine.
* vectors.s: Already seen in the "SWI handler" exercise, this is an example on how to initialise the ARM Vector Table to a default state. Modify it to link your monitor to the appropriate events.

## Commands

| Command | arg1          | arg2        | arg3       | Description                                                                 |
| ------- | ------------- | ----------- | ---------- | --------------------------------------------------------------------------- |
| `M`     | `{<address>}` | `{<value>}` |            | Display the contents of the memory word                                     |
| `m`     | `{<address>}` | `{<value>}` |            | Display the contents of the memory byte                                     |
| `R/r`   | `{<number>}`  | `{<value>}` |            | Display the contents of the specified register                              |
| `C`     | `<source>`    | `<dest>`    | `<length>` | Copy a memory block                                                         |
| `E`     | `{0/1}`       |             |            | Change the data endian representation to either little-endian or big-endian |
| `D`     | `{10/16/2}`   |             |            | Change the display of memory/register to decimal, hexadecimal or binary     |
