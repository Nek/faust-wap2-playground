# What?
Playground and template for [Faust-based](https://faust.grame.fr/) web audio experiments. 

# Why
Faust statically compiles into a highly performant WASM module with a very small footprint.

# Running (on MacOS)
```
brew install faust
brew install binaryen
npm i
npm start
```

Now, you have a live browser page on http://localhost:8000 that updates on any change to melody.dsp or TS code.
And you can pack your work into a standalone web page with `npm build`.
