import std/streams
import os
import strformat
import uri
import std/random

import VafUtils
import VafLogger
import VafFuzzArguments

proc prepareWordlist*(fuzzArguments: VafFuzzArguments): seq[string] =
    let wordlistFile = fuzzArguments.wordlistFile
    let prefixes = fuzzArguments.prefixes
    let suffixes = fuzzArguments.suffixes
    let urlencode = fuzzArguments.urlencode
    let threadcount = fuzzArguments.threadCount
    let tempdir = getTempDir()

    if fuzzArguments.debug:
        log("debug", fmt"Storing temporary wordlists in temp dir: {tempdir}")

    randomize()
    let x = rand(1000)
    var wordlistStreams: seq[File] = @[]
    var threadWordlists: seq[string] = @[]

    for tid in countTo(threadcount - 1):
        let fn = fmt"{tempdir}/vaf{x}_thread{tid}.txt"
        wordlistStreams.add(open(fn, fmAppend))
        threadWordlists.add(fn)

    var strm = newFileStream(wordlistFile, fmRead)
    var line = ""
    var i = 0

    log("info", fmt"Parsing wordlist..... this might take a while if your wordlist is large.")

    if not isNil(strm):
        while strm.readLine(line):
            for prefix in prefixes:
                for suffix in suffixes:
                    var word = prefix & line & suffix
                    if urlencode:
                        word = encodeUrl(word, true)
                    wordlistStreams[i].writeLine(word)
            inc i
            if i == threadcount:
                i = 0

    # close streams
    strm.close()
    for stream in wordlistStreams:
        stream.close()
    
    return threadWordlists