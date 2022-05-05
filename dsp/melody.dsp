declare name "melody";

import("stdfaust.lib");

bpm = hslider("/input/bpm", 118, 30, 180, 0.1);

ch(p, v, s) = s*v : sp.panner(p);

globalFreqRise = (os.lf_saw(bpm/(960 * 1.5))+1)/2 * 30;


djembeBeat = ba.beat(bpm*4);
firstFreq = (os.lf_saw(bpm/120)+1)/2 * 1000;
secondFreq = (os.lf_saw(bpm/480)+1)/2 * 200;
randomFreqs = (firstFreq + secondFreq + globalFreqRise) : ba.latch(djembeBeat) <: attach(_, vbargraph("/output/djembe-freqs", 0, 1000));
arp =  randomFreqs : qu.quantize(440, minor_scale);
djembe = djembeBeat : pm.djembe(arp, 0, 1, 1) : ch(0.5, 0.8);

kickBeat = ba.beat(bpm) <: attach(_, an.amp_follower_ar(0.001, 0.001) > 0 : vbargraph("/output/kick-beat", 0, 1));
kick = kickBeat : sy.kick(60, 0, 0.0001, 0.5, 10) : ch(0.5, 1);

hatBeat = ba.beat(bpm)@ba.tempo(bpm*2);
hat = hatBeat : sy.hat(317, 12000, 0.005, 0.1) : ch(0.3, 1);

// [T, S, T, T, S, T, T]
// [2, 1, 2, 2, 1, 2, 2]
// [2, 3, 5, 7, 8, 10, 12]
// stringBpm = bpm*4;
// stringBeat = ba.beat(stringBpm)@ba.tempo(bpm*4*3);
// stringArp = os.lf_saw(ba.tempo(stringBpm)+3)/2 * 1200 : ba.sAndH(stringBeat) : qu.quantize(440, qu.penta);
// string = stringBeat : sy.combString(stringArp, 0.5)*0.5 : fi.lowpass(2, 1500) : ch(0.35, 0.3);
delay(dt) = de.sdelay(dt*2, 1024, dt);

myPhasor = int(os.phasor(8, bpm/120));
pulse(w, bpm) = ba.period(ba.tempo(bpm)) > (w * ba.tempo(bpm));//ba.pulsen(ba.tempo(bpm)*w, ba.tempo(bpm));
marimbaBeat = pulse(0.75, bpm/8) * pulse(0.5, bpm) + pulse(0.2, bpm/4) * pulse(0.5, bpm/2); //waveform{1,0,0,0,0,0,0,0}, myPhasor : rdtable <: attach(_, vbargraph("/output/phasor", 0, 1));
marimbaFreq = (os.lf_saw(bpm/8/60)+1)/2 * 40 + 20 + globalFreqRise : ba.latch(marimbaBeat) : qu.quantize(440, minor_scale);
delayChain = delay(ba.tempo(bpm*1.5))*0.6, _ :> _ <: delay(ba.tempo(bpm/2))*0.5, _;
marimba =  marimbaBeat : pm.marimbaModel(marimbaFreq, 1) : ch(0.5, 0.2);

// pick 

reverb(s, volume) = s : re.jpverb(1, 0, 0.5, 0.707, 0.1, 2, 1, 1, 1, 500, 2000) : par(i,2, _ * volume);

//process = marimba, kick, hat, reverb(hat, 0.6), djembe, reverb(djembe, 0.5) :> _, _ : co.limiter_1176_R4_stereo;

gate = ba.beat(bpm/4);

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

// minor_scale = (1,pow(2,2/12),pow(2,3/12),pow(2,5/12),pow(2,7/12),pow(2,8/12),pow(2,10/12));
// 0 - 1
// 0 2 3 5 7 10 12

minor_scale = waveform{0, 2, 3, 5, 7, 8, 10};
rand_note(scale, n) = rdtable(minor_scale, int(n * (noise + 1)/2));

// process = random_note(36, 60) : ba.midikey2hz : ba.latch(gate) : qu.quantize(ba.midikey2hz(3), minor_scale) : ba.hz2midikey : minor_chord : simple_pad <: _ , _;
// fi.highpass6e(_, os.osc(_))

filt_tri(gate, freq) =  os.triangle(freq) : fi.bandpass(1, freq*0.95, freq*1.05) : _ * env
with {
    env = en.adsr(0.0001, 0.3, 1, 2, gate) : si.smoo;
};

simple_pad(gate) =  par(i, 3, filt_tri(gate)) :> _ / 3;

process = rand_note(minor_scale, 7) : ba.latch(gate) <: attach(_, vbargraph("/output/notes", 0, 127)) : +(4 * 12) : minor_chord : par(i, 3, ba.midikey2hz) : simple_pad(gate) <: _ , _;