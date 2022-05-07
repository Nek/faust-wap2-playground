declare name "melody";
import("stdfaust.lib");

minor_scale_wave = waveform{0, 2, 3, 5, 7, 8, 10, 0, 2, 3, 5, 7, 8, 10};
major_scale_wave = waveform{0, 2, 4, 5, 7, 9, 11, 0, 2, 4, 5, 7, 9, 11};

minor_scale(n) = minor_scale_wave, n : rdtable;
major_scale(n) = minor_scale_wave, n : rdtable;

triad(degree, octave, scale) = note1, note2, note3
with {
    note1 = scale(degree) + octave * 12;
    note2 = scale(degree + 2) + octave * 12;
    note3 = scale(degree + 4) + octave * 12;
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

reset = button("/input/reset");

bpm = hslider("/input/bpm", 118, 30, 180, 0.1);

pulse(w, bpm) = os.lf_sawpos_reset(bpm/60, reset) < w;
beat(bpm) = pulse(0.5, bpm);

gate = beat(bpm);

degree_at_step = progression(ba.counter(gate) % 4 + 1);
is_minor = progression(0);

filt_tri(gate, freq) =  os.osc(freq) : fi.bandpass(1, freq * (0.7 + 0.2 * os.osc(bpm / 60 * 4)), freq * (1.1 + 0.2 * os.osc(bpm / 60 * 4))) : _ * env
with {
    r = 60 / (bpm/8);   
    env = en.adsr(0.0001, 0, 1, r, gate);
};

process =   triad(degree_at_step, 5, major_scale)  : par(i, 3, ba.midikey2hz) : par(i, 3, filt_tri(gate)) :> (_ + _ + _) / 3 <: _, _;
