declare name "melody";
import("stdfaust.lib");

minor_scale_wave = waveform{0, 2, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22};
major_scale_wave = waveform{0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23};

minor_scale(n) = minor_scale_wave, n : rdtable;
major_scale(n) = minor_scale_wave, n : rdtable;

triad(degree, scale) = note1, note2, note3
with {
    note1 = scale(degree);
    note2 = scale(degree + 2);
    note3 = scale(degree + 4);
};

wave_i_iv_III_VI = waveform{0, 0, 3, 2, 5};
wave_i_iv_VI_v = waveform{0, 0, 3, 5, 4};
wave_i_VI_III_VII = waveform{0, 0, 5, 2, 6};
wave_i_VI_III_iv = waveform{0, 0, 5, 2, 3};

prog_i_iv_VI_v(n) = wave_i_iv_VI_v, int(n) : rdtable;
prog_i_iv_III_VI(n) = wave_i_iv_III_VI, int(n) : rdtable;
prog_i_VI_III_VII(n) = wave_i_VI_III_VII, int(n) : rdtable;
prog_i_VI_III_iv(n) = wave_i_VI_III_iv, int(n) : rdtable;

wave_I_vi_IV_V = waveform{1, 0, 5, 3, 4};
wave_I_V_vi_IV = waveform{1, 0, 4, 5, 3};
wave_I_IV_V_IV = waveform{1, 0, 3, 4, 3};
wave_vi_IV_I_V = waveform{1, 5, 3, 0, 4};
wave_I_IV_ii_V = waveform{1, 0, 3, 1, 4};
wave_I_IV_I_V  = waveform{1, 0, 3, 0, 4};

prog_I_vi_IV_V(n) = wave_I_vi_IV_V, int(n) : rdtable; 
prog_I_V_vi_IV(n) = wave_I_V_vi_IV, int(n) : rdtable; 
prog_I_IV_V_IV(n) = wave_I_IV_V_IV, int(n) : rdtable; 
prog_vi_IV_I_V(n) = wave_vi_IV_I_V, int(n) : rdtable; 
prog_I_IV_ii_V(n) = wave_I_IV_ii_V, int(n) : rdtable; 
prog_I_IV_I_V(n) = wave_I_IV_I_V, int(n) : rdtable; 

input_progression = hslider("/input/progression", 0, 0, 10, 1);

progression(n) = sel_wave(n)
with {
    progs = prog_i_iv_III_VI(n), 
    prog_i_iv_VI_v(n), 
    prog_i_VI_III_VII(n), 
    prog_i_VI_III_iv(n), 
    prog_I_V_vi_IV(n), 
    prog_I_vi_IV_V(n),
    prog_I_IV_V_IV(n), 
    prog_vi_IV_I_V(n), 
    prog_I_IV_ii_V(n), 
    prog_I_IV_I_V(n);
    sel_wave(n) = progs : ba.selectn(10, input_progression);
};

pulse(w, bpm) = os.lf_sawpos_reset(bpm/60, reset) < w;
beat(bpm) = pulse(0.5, bpm);

random  = +(12345)~*(1103515245);
noise   = random/2147483647.0;

rand_velocity(gate) = ((noise + 1)/2*0.3+0.7) : ba.latch(gate): _ * gate;

not = select2(_ > 0, 0, 1);

reverb(volume) = _, _: re.jpverb(1, 0, 0.5, 0.707, 0.1, 2, 1, 1, 1, 500, 2000) : par(i,2, _ * volume);

// Input parameters
reset = button("/input/reset");
bpm = hslider("/input/bpm", 118, 30, 180, 0.1);
key = hslider("/input/key", 0, 0, 11, 1);
input_scale = hslider("/input/scale", 0, 0, 1, 1);

is_minor = progression(0);


filt_tri(gate, freq) =  os.osc(freq) : fi.bandpass(1, freq * (0.7 + 0.2 * os.osc(bpm / 60 * 4)), freq * (1.1 + 0.2 * os.osc(bpm / 60 * 4))) : _ * env
with {
    r = 60 / (bpm/8);   
    env = en.adsr(0.0001, 0, 1, r, gate);
};

kick_beat = beat(bpm);
kick = kick_beat : sy.kick(ba.midikey2hz(key + 12 * 3), 0.05, 0.01, 60/bpm, 1): _ * ba.lin2LogGain(hslider("/input/kick/volume", 0, 0, 1, 0.0001)) :  sp.panner(0.5);

hat_beat = beat(bpm)@ba.tempo(bpm*2);
hat = hat_beat : sy.hat(317, 12000, 0.005, 0.1) : _ * ba.lin2LogGain(hslider("/input/hat/volume", 0, 0, 1, 0.0001)) : sp.panner(0.3);

scale(n) = minor_scale(n), major_scale(n) : ba.selectn(2, is_minor);

rand_note = int(7 * (noise + 1)/2) : scale : _ + key;

djembe_beat = (pattern1 + pattern2)*pattern3
with {
    pattern3 = pulse(0.75, bpm/2);
    pattern1 = pulse(0.4, bpm/1.5);
    pattern2 = pulse(0.2, bpm*4);
};
djembe = rand_velocity(djembe_beat) : pm.djembe(ba.midikey2hz(key + 12 * 6), 0, 1, 1): _ * ba.lin2LogGain(hslider("/input/djembe/volume", 0, 0, 1, 0.0001))  : sp.panner(ba.latch(djembe_beat, noise));

marimba_beat = (pattern1 + pattern2 + pattern3 + pattern4) > 1
with {
    pattern1 = pulse(0.35, bpm/8);
    pattern2 = pulse(0.5, bpm);
    pattern3 = pulse(0.2, bpm/4);
    pattern4 = pulse(0.5, bpm/2);
};
marimba_notes = rand_note : ba.latch(marimba_beat) : _ + 1 * 12 : ba.midikey2hz;
marimba = rand_velocity(marimba_beat) : pm.marimbaModel(marimba_notes, 1) : _ * ba.lin2LogGain(hslider("/input/marimba/volume", 0, 0, 1, 0.0001))  : fi.highpass(2, 250) : sp.panner(0.7);

gate = beat(bpm/4);
degree_at_step = progression(ba.counter(gate) % 4 + 1);
chords = triad(degree_at_step, major_scale)  : par(i, 3, _ + key + 12*4) : par(i, 3, ba.midikey2hz) : par(i, 3, filt_tri(gate)) :> (_ + _ + _) / 3 : _ *  ba.lin2LogGain(hslider("/input/chords/volume", 0, 0, 1, 0.0001)) <: reverb(1) <: par(i, 2, fi.highpass(2, 250));

process =  kick, hat, djembe, marimba, chords :> _ / 2, _ / 2;
