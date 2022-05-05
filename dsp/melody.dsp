declare name "melody";

import("stdfaust.lib");

bpm = hslider("/input/bpm", 118, 30, 180, 0.1);

ch(p, v) = _ * v : sp.panner(p);

pulse(w, bpm) = os.lf_sawpos_reset(bpm/60, 0) < w;

reset = button("restart");

beat(bpm) = os.lf_sawpos_reset(bpm/60, reset) < 0.5;

hat_beat = beat(bpm)@ba.tempo(bpm*2);
hat = hat_beat : sy.hat(317, 12000, 0.005, 0.1) : ch(0.3, 0.3);

// stringBpm = bpm*4;
// stringBeat = beat(stringBpm)@ba.tempo(bpm*4*3);
// stringArp = os.lf_saw(ba.tempo(stringBpm)+3)/2 * 1200 : ba.sAndH(stringBeat) : qu.quantize(440, qu.penta);
// string = stringBeat : sy.combString(stringArp, 0.5)*0.5 : fi.lowpass(2, 1500) : ch(0.35, 0.3);
delay(dt) = de.sdelay(dt*2, 1024, dt);

myPhasor = int(os.phasor(8, bpm/120));
delayChain = delay(ba.tempo(bpm*1.5))*0.6, _ :> _ <: delay(ba.tempo(bpm/2))*0.5, _;

// pick 

reverb(volume) = _, _: re.jpverb(1, 0, 0.5, 0.707, 0.1, 2, 1, 1, 1, 500, 2000) : par(i,2, _ * volume);

//process = marimba, kick, hat, reverb(hat, 0.6), djembe, reverb(djembe, 0.5) :> _, _ : co.limiter_1176_R4_stereo;

// 1. generate one of the midi notes
random_note(l,h) = (no.noise+1)/2 : int(l + (h - l) * _);
// 2. convert to hz
// ba.midikey2hz
// 3. quantize
// qu.quantize(ba.midikey2hz(0), minor_scale)
// 4. convert to midi
// 5. make chord
// 6. convert to hz
// 7. play

// 1. pick degree
// 2. pick the right note
// 3. construct the chord

// function createRandomGenerator(seed){
//      const a = 5486230734;  // some big numbers
//      const b = 6908969830; 
//      const m = 9853205067;
//      var x = seed;
//      // returns a random value 0 <= num < 1
//      return function(seed = x){  // seed is optional. If supplied sets a new seed
//          x = (seed  * a + b) % m;
//          return x / m;
//      }
// }

random  = +(12345)~*(1103515245);
noise   = random/2147483647.0;

minor_chord = _ <: _, _+3, _+7;

minor_scale = waveform{0, 2, 3, 5, 7, 8, 10};
rand_note(scale, n) = rdtable(minor_scale, int(n * (noise + 1)/2));

progression1 = waveform{0, 5, 2, 6}; // i-VI-III-VII 
progression2 = waveform{0, 5, 2, 3}; // i-VI-III-iv    
progression3 = waveform{0, 3, 4}; // i-iv-v

key = 3; 

djembe_beat = beat(bpm*4);
percussion = djembe_beat : pm.djembe(ba.midikey2hz(key + 12 * 6), 0, 1, 1) : ch(ba.latch(djembe_beat, noise), 0.75);

not = select2(_ > 0, 0, 1);

marimba_beat = not(pulse(0.35, bpm/8) * pulse(0.5, bpm) + pulse(0.2, bpm/4) * pulse(0.5, bpm/2));
marimba_notes = rand_note(minor_scale, 7) : ba.latch(djembe_beat) : _ + 12 * 2 + key;
marimba =  marimba_beat : pm.marimbaModel(marimba_notes, 1) : ch(0.5, 0.2);

filt_tri(gate, freq) =  os.osc(freq) : fi.bandpass(1, freq*(0.7+0.2*os.osc(bpm/60*4)), freq*(1.1+0.2*os.osc(bpm/60*4))) : _ * env
with {
    r = 60 / (bpm/8);   
    env = en.adsr(0.0001, 0, 1, r, gate);
};

kick_beat = beat(bpm) <: attach(_, an.amp_follower_ar(0.001, 0.001) > 0 : vbargraph("/output/kick-beat", 0, 1));
kick = kick_beat : sy.kick(60, 0, 0.0001, 0.5, 2) : ch(0.5, 0.7);

degree_num = ba.counter(gate) % 4;
degree_note = rdtable(progression2, degree_num);

gate = beat(bpm/8);
simple_pad(gate) =  par(i, 3, filt_tri(gate)) :> _ / 3;
chords = degree_note : +(4 * 12 + key) : minor_chord : par(i, 3, ba.midikey2hz) : simple_pad(gate) <: _, _;
chords_reverb = chords : reverb(0.5) <: par(i, 2, fi.highpass(2, 250));

log_beat = beat(bpm) <: attach(_, vbargraph("/output/log", 0, 100)) <: _, _ ;//attach(beat(bpm), vbargraph("/output/log", 0, 1)) * 0.00001 <: _, _;
process = chords_reverb, percussion, kick, hat, marimba :> _ /3 , _ /3;