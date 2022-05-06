declare name "melody";

import("stdfaust.lib");

bpm = hslider("/input/bpm", 118, 30, 180, 0.1);

ch(p, v) = _ * v : sp.panner(p);


reset = button("restart");

pulse(w, bpm) = os.lf_sawpos_reset(bpm/60, reset) < w;
beat(bpm) = pulse(0.5, bpm);

hat_beat = beat(bpm)@ba.tempo(bpm*2);
hat = hat_beat : sy.hat(317, 12000, 0.005, 0.1) : ch(0.3, 0.05);

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

input_scale = hslider("/input/scale", 0, 0, 1, 1);

random  = +(12345)~*(1103515245);
noise   = random/2147483647.0;

triad(d1,d2,d3,s) = s + d1, s + d2, s + d3;  

minor_chord = triad(0, 3, 7);
major_chord = triad(0, 4, 7);

chord = ba.selectmulti(0, (minor_chord, major_chord), input_scale);

minor_scale_wave = waveform{0, 2, 3, 5, 7, 8, 10};
major_scale_wave = waveform{0, 2, 4, 5, 7, 9, 11};

minor_scale(n) = minor_scale_wave, n : rdtable;
major_scale(n) = minor_scale_wave, n : rdtable;

scale(n) = minor_scale(n), major_scale(n) : ba.selectn(2, input_scale);

rand_note = int(7 * (noise + 1)/2) : scale;

minor_prog_wave1 = waveform{0, 3, 2, 5}; // i-iv-III-VI Smells like teen spirit
minor_prog_wave2 = waveform{0, 3, 5, 4}; // i-iv-VI-v Back to Black
minor_prog_wave3 = waveform{0, 5, 2, 6}; // i-VI-III-VII Save tonight
minor_prog_wave4 = waveform{0, 5, 2, 3}; // i-VI-III-iv Turning Tables

// minor_prog_wave1 = waveform{0, 5, 2, 6}; // i-VI-III-VII 
// prog2 = waveform{0, 5, 2, 3}; // i-VI-III-iv    
// prog2 = waveform{0, 1, 1, 1}; // i-VI-III-iv    

// prog3 = waveform{0, 3, 4}; // i-iv-v

prog1(n) = minor_prog_wave1, int(n) : rdtable;
prog2(n) = minor_prog_wave2, int(n) : rdtable;
prog3(n) = minor_prog_wave3, int(n) : rdtable;
prog4(n) = minor_prog_wave4, int(n) : rdtable;

// minor_prog1(n) = minor_prog_wave1, int(n) : rdtable;
// minor_prog2(n) = minor_prog_wave2, int(n) : rdtable;
// minor_prog3(n) = minor_prog_wave3, int(n) : rdtable;
// minor_prog4(n) = minor_prog_wave4, int(n) : rdtable;
 
major_prog_wave5 = waveform{0, 5, 3, 4}; // I - vi - IV - V
major_prog_wave6 = waveform{0, 4, 5, 3}; // I - V - vi - IV
major_prog_wave7 = waveform{0, 3, 4, 3}; // I - IV - V - IV
major_prog_wave8 = waveform{5, 3, 0, 4}; // vi - IV - I - V
major_prog_wave9 = waveform{0, 3, 1, 4}; // I - IV - ii - V
major_prog_wave10 = waveform{0, 3, 0, 4}; // I - IV - I - V
major_prog_wave11 = waveform{0, 4, 0, 3}; // i - V - i - iv
major_prog_wave12 = waveform{5, 4, 3, 2}; // vi - V - IV - III

prog5(n)  = major_prog_wave5, int(n) : rdtable;
prog6(n)  = major_prog_wave6, int(n) : rdtable;
prog7(n)  = major_prog_wave7, int(n) : rdtable;
prog8(n)  = major_prog_wave8, int(n) : rdtable;
prog9(n)  = major_prog_wave9, int(n) : rdtable;
prog10(n) = major_prog_wave10, int(n) : rdtable;
prog11(n) = major_prog_wave11, int(n) : rdtable;
prog12(n) = major_prog_wave12, int(n) : rdtable;

progression(n) = sel_wave(n)
with {
    progs = prog1(n), prog2(n), prog3(n), prog4(n),prog5(n), prog6(n), prog7(n), prog8(n), prog9(n), prog10(n), prog11(n), prog12(n);
    sel_wave(n) = progs : ba.selectn(12, (hslider("/input/progression", 0, 0, 11, 1)));
};

key = hslider("/input/key", 0, 0, 11, 1); 

djembe_beat = beat(bpm*4);
percussion = djembe_beat : pm.djembe(ba.midikey2hz(key + 12 * 6), 0, 1, 1) : ch(ba.latch(djembe_beat, noise), 0.75);

not = select2(_ > 0, 0, 1);

marimba_beat = not(pulse(0.35, bpm/8) * pulse(0.5, bpm) + pulse(0.2, bpm/4) * pulse(0.5, bpm/2)) <: attach(_, vbargraph("/output/log", 0, 100));
marimba_notes = rand_note : ba.latch(djembe_beat) : _ + 3 * 12 + key : ba.midikey2hz;
marimba = marimba_beat : pm.marimbaModel(marimba_notes, 1) : ch(0.5, 0.2);

filt_tri(gate, freq) =  os.osc(freq) : fi.bandpass(1, freq * (0.7 + 0.2 * os.osc(bpm / 60 * 4)), freq * (1.1 + 0.2 * os.osc(bpm / 60 * 4))) : _ * env
with {
    r = 60 / (bpm/8);   
    env = en.adsr(0.0001, 0, 1, r, gate);
};

gate = beat(bpm/8);
simple_pad(gate) =  par(i, 3, filt_tri(gate)) :> _ / 3;

kick_beat = beat(bpm) <: attach(_, an.amp_follower_ar(0.001, 0.001) > 0 : vbargraph("/output/kick-beat", 0, 1));
kick = kick_beat : sy.kick(60, 0, 0.0001, 0.5, 2) : ch(0.5, 0.7);

degree_num = ba.counter(gate) % 4;
degree_note = degree_num : progression;


chords = degree_note : +(4 * 12 + key) : chord : par(i, 3, ba.midikey2hz) : simple_pad(gate) <: _, _;
chords_reverb = chords : reverb(0.5) <: par(i, 2, fi.highpass(2, 250));

log_beat = beat(bpm) <: _, _ ;//attach(beat(bpm), vbargraph("/output/log", 0, 1)) * 0.00001 <: _, _;
process = chords_reverb, percussion, kick, hat, marimba :> _ /3 , _ /3;