declare name "  ";

import("stdfaust.lib");

bpm = hslider("BPM", 120, 30, 180, 0.1);

ch(p, v, s) = s*v : sp.panner(p);

djembeBeat = ba.beat(bpm*4);
arp = (os.lf_saw(ba.tempo(bpm*4))+1)/2 * 4000 : ba.sAndH(djembeBeat) : qu.quantize(440, qu.penta);
djembe = djembeBeat : pm.djembe(arp, 0, 1, 1) : ch(0.5, 0.8);

kickBeat = ba.beat(bpm);
kick = kickBeat : sy.kick(60, 0, 0.0001, 0.5, 10) : ch(0.5, 1);

hatBeat = ba.beat(bpm)@ba.tempo(bpm*2);
hat = hatBeat : sy.hat(317, 12000, 0.005, 0.1) : ch(0.3, 1);

stringBpm = bpm*4;
stringBeat = ba.beat(stringBpm)@ba.tempo(bpm*4*3);
stringArp = os.lf_saw(ba.tempo(stringBpm)+3)/2 * 1200 : ba.sAndH(stringBeat) : qu.quantize(440, qu.penta);
string = stringBeat : sy.combString(stringArp, 0.5)*0.5 : fi.lowpass(2, 1000) : ch(0.35, 0.3);

reverb(s, volume) = s : re.jpverb(1, 0, 0.5, 0.707, 0.1, 2, 1, 1, 1, 500, 2000) : par(i,2, _ * volume);

process =  vgroup("melody", (djembe, reverb(djembe, 0.3) , kick, hat, string, reverb(string, 0.7) :> _, _, djembeBeat));
