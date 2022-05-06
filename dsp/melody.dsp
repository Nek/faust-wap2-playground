declare name "melody";

import("stdfaust.lib");

bpm = hslider("/input/bpm", 118, 30, 180, 0.1);

reset = button("restart");

pulse(w, bpm) = os.lf_sawpos_reset(bpm/60, reset) < w;
beat(bpm) = pulse(0.5, bpm);

hat_beat = beat(bpm)@ba.tempo(bpm*2);
hat = hat_beat : sy.hat(317, 12000, 0.005, 0.1): _ * ba.lin2LogGain(hslider("/input/hat/volume", 0, 0, 1, 0.0001)) : sp.panner(0.3);

reverb(volume) = _, _: re.jpverb(1, 0, 0.5, 0.707, 0.1, 2, 1, 1, 1, 500, 2000) : par(i,2, _ * volume);

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

prog1(n) = minor_prog_wave1, int(n) : rdtable;
prog2(n) = minor_prog_wave2, int(n) : rdtable;
prog3(n) = minor_prog_wave3, int(n) : rdtable;
prog4(n) = minor_prog_wave4, int(n) : rdtable;
 
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

rand_velocity(gate) = ((noise + 1)/2*0.3+0.7) : ba.latch(gate): _ * gate;

djembe_beat = (pattern1 + pattern2)*pattern3
with {
    pattern3 = pulse(0.75, bpm/2);
    pattern1 = pulse(0.4, bpm/1.5);
    pattern2 = pulse(0.2, bpm*4);
};
percussion = rand_velocity(djembe_beat) : pm.djembe(ba.midikey2hz(key + 12 * 6), 0, 1, 1): _ * ba.lin2LogGain(hslider("/input/djembe/volume", 0, 0, 1, 0.0001))  : sp.panner(ba.latch(djembe_beat, noise));

not = select2(_ > 0, 0, 1);

marimba_beat = (pattern1 + pattern2 + pattern3 + pattern4) > 1
with {
    pattern1 = pulse(0.35, bpm/8);
    pattern2 = pulse(0.5, bpm);
    pattern3 = pulse(0.2, bpm/4);
    pattern4 = pulse(0.5, bpm/2);
};
marimba_notes = rand_note : ba.latch(marimba_beat) : _ + 1 * 12 + key : ba.midikey2hz;
marimba = rand_velocity(marimba_beat) : pm.marimbaModel(marimba_notes, 1) : _ * ba.lin2LogGain(hslider("/input/marimba/volume", 0, 0, 1, 0.0001))  : fi.highpass(2, 250) : sp.panner(0.7);

filt_tri(gate, freq) =  os.osc(freq) : fi.bandpass(1, freq * (0.7 + 0.2 * os.osc(bpm / 60 * 4)), freq * (1.1 + 0.2 * os.osc(bpm / 60 * 4))) : _ * env
with {
    r = 60 / (bpm/8);   
    env = en.adsr(0.0001, 0, 1, r, gate);
};

gate = beat(bpm/8);
simple_pad(gate) =  par(i, 3, filt_tri(gate)) :> _ / 3;

kick_beat = beat(bpm);
kick = kick_beat : sy.kick(ba.midikey2hz(key + 12 * 3), 0.05, 0.01, 60/bpm, 1): _ * ba.lin2LogGain(hslider("/input/kick/volume", 0, 0, 1, 0.0001)) :  sp.panner(0.5);

degree_num = ba.counter(gate) % 4;
degree_note = degree_num : progression;


chords = degree_note : +(4 * 12 + key) : chord : par(i, 3, ba.midikey2hz) : simple_pad(gate) : _ *  ba.lin2LogGain(hslider("/input/chords/volume", 0, 0, 1, 0.0001)) <: _, _;
chords_reverb = chords : reverb(1) <: par(i, 2, fi.highpass(2, 250));

process = hat, kick, chords_reverb, percussion, marimba :> _ / 6, _ / 6;