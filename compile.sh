#! /bin/bash
faust2wasm melody.dsp -worklet -opt
rm melody.js
rm melody-processor.js