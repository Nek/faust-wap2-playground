declare name "melody";

import("stdfaust.lib");

bpm = hslider("/input/bpm", 118, 30, 180, 0.1);

ch(p, v, s) = s*v : sp.panner(p);

globalFreqRise = (os.lf_saw(bpm/(960 * 1.5))+1)/2 * 30;

djembeBeat = ba.beat(bpm*4);
firstFreq = (os.lf_saw(bpm/120)+1)/2 * 1000;
secondFreq = (os.lf_saw(bpm/480)+1)/2 * 200;
randomFreqs = (firstFreq + secondFreq + globalFreqRise) : ba.latch(djembeBeat) <: attach(_, vbargraph("/output/djembe-freqs", 0, 1000));
arp =  randomFreqs : qu.quantize(440, qu.penta);
djembe = djembeBeat : pm.djembe(arp, 0, 1, 1) : ch(0.5, 0.8);

kickBeat = ba.beat(bpm) <: attach(_, an.amp_follower_ar(0.001, 0.001) > 0 : vbargraph("/output/kick-beat", 0, 1));
kick = kickBeat : sy.kick(60, 0, 0.0001, 0.5, 10) : ch(0.5, 1);

hatBeat = ba.beat(bpm)@ba.tempo(bpm*2);
hat = hatBeat : sy.hat(317, 12000, 0.005, 0.1) : ch(0.3, 1);

// stringBpm = bpm*4;
// stringBeat = ba.beat(stringBpm)@ba.tempo(bpm*4*3);
// stringArp = os.lf_saw(ba.tempo(stringBpm)+3)/2 * 1200 : ba.sAndH(stringBeat) : qu.quantize(440, qu.penta);
// string = stringBeat : sy.combString(stringArp, 0.5)*0.5 : fi.lowpass(2, 1500) : ch(0.35, 0.3);
delay(dt) = de.sdelay(dt*2, 1024, dt);

myPhasor = int(os.phasor(8, bpm/120));
pulse(w, bpm) = ba.period(ba.tempo(bpm)) > (w * ba.tempo(bpm));//ba.pulsen(ba.tempo(bpm)*w, ba.tempo(bpm));
marimbaBeat = pulse(0.75, bpm/8) * pulse(0.5, bpm) + pulse(0.2, bpm/4) * pulse(0.5, bpm/2); //waveform{1,0,0,0,0,0,0,0}, myPhasor : rdtable <: attach(_, vbargraph("/output/phasor", 0, 1));
marimbaFreq = (os.lf_saw(bpm/8/60)+1)/2 * 40 + 20 + globalFreqRise : ba.latch(marimbaBeat) : qu.quantize(440, qu.penta);
delayChain = delay(ba.tempo(bpm*1.5))*0.6, _ :> _ <: delay(ba.tempo(bpm/2))*0.5, _;
marimba =  marimbaBeat : pm.marimbaModel(marimbaFreq, 1) : ch(0.5, 0.2);

reverb(s, volume) = s : re.jpverb(1, 0, 0.5, 0.707, 0.1, 2, 1, 1, 1, 500, 2000) : par(i,2, _ * volume);

process = marimba , kick, hat, reverb(hat, 0.6), djembe, reverb(djembe, 0.5) :> _, _ : co.limiter_1176_R4_stereo;

