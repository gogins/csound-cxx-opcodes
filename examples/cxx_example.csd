<CsoundSynthesizer>
<CsLicense>
"Oblivion,"" by Astor Piazzola
Arranged for Csound by Michael Gogins
</CsLicense>
<CsOptions>
-+msg_color=0 -odac0 -m195 -d --opcode-lib="./libcxx_opcodes.so"
</CsOptions>
<CsInstruments>

sr = 48000
ksmps = 128
nchnls = 2
0dbfs = 5

gi_ampmidicurve_dynamic_range init .375
gi_ampmidicurve_exponent init 5

prealloc "ZakianFlute", 4
prealloc "Guitar", 4
prealloc "Harpsichord", 4
prealloc "YiString", 4
prealloc "Bower", 4

connect "Guitar", "outleft", "CxxReverb", "inleft"
connect "Guitar", "outleft", "CxxReverb", "inleft"
connect "ZakianFlute", "outleft", "CxxReverb", "inleft"
connect "ZakianFlute", "outleft", "CxxReverb", "inleft"
connect "Harpsichord", "outleft", "CxxReverb", "inleft"
connect "Harpsichord", "outright", "CxxReverb", "inright"
connect "YiString", "outleft", "CxxReverb", "inleft"
connect "YiString", "outright", "CxxReverb", "inright"
connect "Bower", "outleft", "CxxReverb", "inleft"
connect "Bower", "outright", "CxxReverb", "inright"
connect "CxxGuitar", "outleft", "CxxReverb", "inleft"
connect "CxxGuitar", "outright", "CxxReverb", "inright"
connect "CxxReverb", "outleft", "MasterOutput", "inleft"
connect "CxxReverb", "outright", "MasterOutput", "inright"

alwayson "CxxReverb"
alwayson "MasterOutput"

gk_overlap init .0125

gk_ZakianFlute_level init -4
gk_ZakianFlute_pan init .5; (2 / 7 - .5)
gi_ZakianFLute_seed init .5
gif2 ftgen 0, 0, 16, -2, 40, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240, 10240
gif26 ftgen 0, 0, 65536, -10, 2000, 489, 74, 219, 125, 9, 33, 5, 5
gif27 ftgen 0, 0, 65536, -10, 2729, 1926, 346, 662, 537, 110, 61, 29, 7
gif28 ftgen 0, 0, 65536, -10, 2558, 2012, 390, 361, 534, 139, 53, 22, 10, 13, 10
gif29 ftgen 0, 0, 65536, -10, 12318, 8844, 1841, 1636, 256, 150, 60, 46, 11
gif30 ftgen 0, 0, 65536, -10, 1229, 16, 34, 57, 32
gif31 ftgen 0, 0, 65536, -10, 163, 31, 1, 50, 31
gif32 ftgen 0, 0, 65536, -10, 4128, 883, 354, 79, 59, 23
gif33 ftgen 0, 0, 65536, -10, 1924, 930, 251, 50, 25, 14
gif34 ftgen 0, 0, 65536, -10, 94, 6, 22, 8
gif35 ftgen 0, 0, 65536, -10, 2661, 87, 33, 18
gif36 ftgen 0, 0, 65536, -10, 174, 12
gif37 ftgen 0, 0, 65536, -10, 314, 13
giwtsin ftgen 0, 0, 65536, 10, 1
instr ZakianFlute
; Author: Lee Zakian
; Adapted by: Michael Gogins
if p3 == -1 goto indefinite
goto non_indefinite
indefinite:
  p3 = 1000000
non_indefinite:
i_instrument = p1
i_time = p2
i_duration = p3
i_midi_key = p4
i_midi_velocity = p5
k_space_front_to_back = p6
k_space_left_to_right = p1/6
k_space_bottom_to_top = p8
i_phase = p9
i_overall_amps = 65
i_amplitude ampmidicurve i_midi_velocity, gi_ampmidicurve_dynamic_range, gi_ampmidicurve_exponent
k_gain = ampdb(gk_ZakianFlute_level)
iattack = .002
isustain = p3
irelease = .3
xtratim iattack + isustain + irelease
iHz = cpsmidinn(i_midi_key)
kHz = k(iHz)
aenvelope transeg 1.0, 20.0, -10.0, 0.05
ip3 = (p3 < 3.0 ? p3 : 3.0)
; parameters
; p4 overall amplitude scaling factor
ip4 init i_amplitude
; p5 pitch in Hertz (normal pitch range: C4-C7)
ip5 init iHz
; p6 percent vibrato depth, recommended values in range [-1., +1.]
ip6 init 0.5
; 0.0 -> no vibrato
; +1. -> 1% vibrato depth, where vibrato rate increases slightly
; -1. -> 1% vibrato depth, where vibrato rate decreases slightly
; p7 attack time in seconds
; recommended value: .12 for slurred notes, .06 for tongued notes
; (.03 for short notes)
ip7 init .08
; p8 decay time in seconds
; recommended value: .1 (.05 for short notes)
ip8 init .08
; p9 overall brightness / filter cutoff factor
; 1 -> least bright / minimum filter cutoff frequency (40 Hz)
; 9 -> brightest / maximum filter cutoff frequency (10,240Hz)
ip9 init 5
; initial variables
iampscale = ip4 ; overall amplitude scaling factor
ifreq = ip5 ; pitch in Hertz
ivibdepth = abs(ip6*ifreq/100.0) ; vibrato depth relative to fundamental frequency
iattack = ip7 * (1.1 - .2*gi_ZakianFLute_seed) ; attack time with up to +-10% random deviation
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947) ; reset gi_ZakianFLute_seed
idecay = ip8 * (1.1 - .2*gi_ZakianFLute_seed) ; decay time with up to +-10% random deviation
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
ifiltcut tablei ip9, gif2 ; lowpass filter cutoff frequency
iattack = (iattack < 6/kr ? 6/kr : iattack) ; minimal attack length
idecay = (idecay < 6/kr ? 6/kr : idecay) ; minimal decay length
isustain = p3 - iattack - idecay
p3 = (isustain < 5/kr ? iattack+idecay+5/kr : p3) ; minimal sustain length
isustain = (isustain < 5/kr ? 5/kr : isustain)
iatt = iattack/6
isus = isustain/4
idec = idecay/6
iphase = gi_ZakianFLute_seed ; use same phase for all wavetables
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
; vibrato block
; kvibdepth linseg .1, .8*p3, 1, .2*p3, .7
kvibdepth linseg .1, .8*ip3, 1, isustain, 1, .2*ip3, .7
kvibdepth = kvibdepth* ivibdepth ; vibrato depth
kvibdepthr randi .1*kvibdepth, 5, gi_ZakianFLute_seed ; up to 10% vibrato depth variation
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
kvibdepth = kvibdepth + kvibdepthr
ivibr1 = gi_ZakianFLute_seed ; vibrato rate
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
ivibr2 = gi_ZakianFLute_seed
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
if ip6 < 0 goto vibrato1
kvibrate linseg 2.5+ivibr1, p3, 4.5+ivibr2 ; if p6 positive vibrato gets faster
 goto vibrato2
vibrato1:
ivibr3 = gi_ZakianFLute_seed
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
kvibrate linseg 3.5+ivibr1, .1, 4.5+ivibr2, p3-.1, 2.5+ivibr3 ; if p6 negative vibrato gets slower
vibrato2:
kvibrater randi .1*kvibrate, 5, gi_ZakianFLute_seed ; up to 10% vibrato rate variation
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
kvibrate = kvibrate + kvibrater
kvib oscili kvibdepth, kvibrate, giwtsin
ifdev1 = -.03 * gi_ZakianFLute_seed ; frequency deviation
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
ifdev2 = .003 * gi_ZakianFLute_seed
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
ifdev3 = -.0015 * gi_ZakianFLute_seed
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
ifdev4 = .012 * gi_ZakianFLute_seed
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
kfreqr linseg ifdev1, iattack, ifdev2, isustain, ifdev3, idecay, ifdev4
kfreq = kHz * (1 + kfreqr) + kvib
if ifreq < 427.28 goto range1 ; (cpspch(8.08) + cpspch(8.09))/2
if ifreq < 608.22 goto range2 ; (cpspch(9.02) + cpspch(9.03))/2
if ifreq < 1013.7 goto range3 ; (cpspch(9.11) + cpspch(10.00))/2
goto range4
; wavetable amplitude envelopes
range1: ; for low range tones
kamp1 linseg 0, iatt, 0.002, iatt, 0.045, iatt, 0.146, iatt, \
0.272, iatt, 0.072, iatt, 0.043, isus, 0.230, isus, 0.000, isus, \
0.118, isus, 0.923, idec, 1.191, idec, 0.794, idec, 0.418, idec, \
0.172, idec, 0.053, idec, 0
kamp2 linseg 0, iatt, 0.009, iatt, 0.022, iatt, -0.049, iatt, \
-0.120, iatt, 0.297, iatt, 1.890, isus, 1.543, isus, 0.000, isus, \
0.546, isus, 0.690, idec, -0.318, idec, -0.326, idec, -0.116, idec, \
-0.035, idec, -0.020, idec, 0
kamp3 linseg 0, iatt, 0.005, iatt, -0.026, iatt, 0.023, iatt, \
0.133, iatt, 0.060, iatt, -1.245, isus, -0.760, isus, 1.000, isus, \
0.360, isus, -0.526, idec, 0.165, idec, 0.184, idec, 0.060, idec, \
0.010, idec, 0.013, idec, 0
iwt1 = gif26 ; wavetable numbers
iwt2 = gif27
iwt3 = gif28
inorm = 3949
goto end
range2: ; for low mid-range tones
kamp1 linseg 0, iatt, 0.000, iatt, -0.005, iatt, 0.000, iatt, \
0.030, iatt, 0.198, iatt, 0.664, isus, 1.451, isus, 1.782, isus, \
1.316, isus, 0.817, idec, 0.284, idec, 0.171, idec, 0.082, idec, \
0.037, idec, 0.012, idec, 0
kamp2 linseg 0, iatt, 0.000, iatt, 0.320, iatt, 0.882, iatt, \
1.863, iatt, 4.175, iatt, 4.355, isus, -5.329, isus, -8.303, isus, \
-1.480, isus, -0.472, idec, 1.819, idec, -0.135, idec, -0.082, idec, \
-0.170, idec, -0.065, idec, 0
kamp3 linseg 0, iatt, 1.000, iatt, 0.520, iatt, -0.303, iatt, \
0.059, iatt, -4.103, iatt, -6.784, isus, 7.006, isus, 11, isus, \
12.495, isus, -0.562, idec, -4.946, idec, -0.587, idec, 0.440, idec, \
0.174, idec, -0.027, idec, 0
iwt1 = gif29
iwt2 = gif30
iwt3 = gif31
inorm = 27668.2
goto end
range3: ; for high mid-range tones
kamp1 linseg 0, iatt, 0.005, iatt, 0.000, iatt, -0.082, iatt, \
0.36, iatt, 0.581, iatt, 0.416, isus, 1.073, isus, 0.000, isus, \
0.356, isus, .86, idec, 0.532, idec, 0.162, idec, 0.076, idec, 0.064, \
idec, 0.031, idec, 0
kamp2 linseg 0, iatt, -0.005, iatt, 0.000, iatt, 0.205, iatt, \
-0.284, iatt, -0.208, iatt, 0.326, isus, -0.401, isus, 1.540, isus, \
0.589, isus, -0.486, idec, -0.016, idec, 0.141, idec, 0.105, idec, \
-0.003, idec, -0.023, idec, 0
kamp3 linseg 0, iatt, 0.722, iatt, 1.500, iatt, 3.697, iatt, \
0.080, iatt, -2.327, iatt, -0.684, isus, -2.638, isus, 0.000, isus, \
1.347, isus, 0.485, idec, -0.419, idec, -.700, idec, -0.278, idec, \
0.167, idec, -0.059, idec, 0
iwt1 = gif32
iwt2 = gif33
iwt3 = gif34
inorm = 3775
goto end
range4: ; for high range tones
kamp1 linseg 0, iatt, 0.000, iatt, 0.000, iatt, 0.211, iatt, \
0.526, iatt, 0.989, iatt, 1.216, isus, 1.727, isus, 1.881, isus, \
1.462, isus, 1.28, idec, 0.75, idec, 0.34, idec, 0.154, idec, 0.122, \
idec, 0.028, idec, 0
kamp2 linseg 0, iatt, 0.500, iatt, 0.000, iatt, 0.181, iatt, \
0.859, iatt, -0.205, iatt, -0.430, isus, -0.725, isus, -0.544, isus, \
-0.436, isus, -0.109, idec, -0.03, idec, -0.022, idec, -0.046, idec, \
-0.071, idec, -0.019, idec, 0
kamp3 linseg 0, iatt, 0.000, iatt, 1.000, iatt, 0.426, iatt, \
0.222, iatt, 0.175, iatt, -0.153, isus, 0.355, isus, 0.175, isus, \
0.16, isus, -0.246, idec, -0.045, idec, -0.072, idec, 0.057, idec, \
-0.024, idec, 0.002, idec, 0
iwt1 = gif35
iwt2 = gif36
iwt3 = gif37
inorm = 4909.05
goto end
end:
kampr1 randi .02*kamp1, 10, gi_ZakianFLute_seed ; up to 2% wavetable amplitude variation
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
kamp1 = kamp1 + kampr1
kampr2 randi .02*kamp2, 10, gi_ZakianFLute_seed ; up to 2% wavetable amplitude variation
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
kamp2 = kamp2 + kampr2
kampr3 randi .02*kamp3, 10, gi_ZakianFLute_seed ; up to 2% wavetable amplitude variation
gi_ZakianFLute_seed = frac(gi_ZakianFLute_seed*105.947)
kamp3 = kamp3 + kampr3
awt1 poscil kamp1, kfreq, iwt1, iphase ; wavetable lookup
awt2 poscil kamp2, kfreq, iwt2, iphase
awt3 poscil kamp3, kfreq, iwt3, iphase
asig = awt1 + awt2 + awt3
asig = asig*(iampscale/inorm)
kcut linseg 0, iattack, ifiltcut, isustain, ifiltcut, idecay, 0 ; lowpass filter for brightness control
afilt tone asig, kcut
a_signal balance afilt, asig
i_attack = .002
i_sustain = p3
i_release = 0.01
xtratim i_attack + i_sustain + i_release
a_declicking linsegr 0, i_attack, 1, i_sustain, 1, i_release, 0
a_signal = a_signal * i_amplitude * a_declicking * k_gain
#ifdef USE_SPATIALIZATION
a_spatial_reverb_send init 0
a_bsignal[] init 16
a_bsignal, a_spatial_reverb_send Spatialize a_signal, k_space_front_to_back, k_space_left_to_right, k_space_bottom_to_top
outletv "outbformat", a_bsignal
outleta "out", a_spatial_reverb_send
#else
a_out_left, a_out_right pan2 a_signal, gk_ZakianFlute_pan
outleta "outleft", a_out_left
outleta "outright", a_out_right
#endif
prints "%-24s i %9.4f t %9.4f d %9.4f k %9.4f v %9.4f p %9.4f #%3d\n", nstrstr(p1), p1, p2, p3, p4, p5, gk_ZakianFlute_pan, active(p1)
endin

gk_Guitar_level init 8
instr Guitar
; Michael Gogins
if p3 == -1 goto indefinite
goto non_indefinite
indefinite:
  p3 = 1000000
non_indefinite:
i_instrument = p1
i_time = p2
i_duration = p3
i_midi_key = p4
i_midi_velocity = p5
k_space_front_to_back = p6
k_space_left_to_right = p1/6
k_space_bottom_to_top = p8
i_phase = p9
i_frequency = cpsmidinn(i_midi_key)
i_amplitude ampmidicurve i_midi_velocity, gi_ampmidicurve_dynamic_range, gi_ampmidicurve_exponent
k_gain = ampdb(gk_Guitar_level)
acomp pluck i_amplitude, 440.0, 440.0, 0, 1, .1
i_frequency2 = i_frequency / 2.0
kHz = k(i_frequency)
iattack = 0.004
isustain = p3
irelease = 0.05
p3 = iattack + isustain + irelease
asigcomp pluck 1.0, 440, 440, 0, 1
asig pluck 1.0, i_frequency, i_frequency, 0, 1
af1 reson asig, 110, 80
af2 reson asig, 220, 100
af3 reson asig, 440, 80
aout balance 0.6 * af1 + af2 + 0.6 * af3 + 0.4 * asig, asigcomp
aexp expseg 1.0, iattack, 2.0, isustain, 1.0, irelease, 1.0
aenv = aexp - 1.0
a_signal = aout * aenv
a_declicking linsegr 0, iattack, 1, isustain, 1, irelease, 0
a_signal = a_signal * i_amplitude * a_declicking * k_gain
#ifdef USE_SPATIALIZATION
a_spatial_reverb_send init 0
a_bsignal[] init 16
a_bsignal, a_spatial_reverb_send Spatialize a_signal, k_space_front_to_back, k_space_left_to_right, k_space_bottom_to_top
outletv "outbformat", a_bsignal
outleta "out", a_spatial_reverb_send
#else
a_out_left, a_out_right pan2 a_signal, p1/6
outleta "outleft", a_out_left
outleta "outright", a_out_right
#endif
prints "%-24s i %9.4f t %9.4f d %9.4f k %9.4f v %9.4f p %9.4f #%3d\n", nstrstr(p1), p1, p2, p3, p4, p5, gk_ZakianFlute_pan, active(p1)
endin

gk_YiString_level init 6
gk_YiString_reverb_send init .5
gk_YiString_chorus_send init .5
gi_YiString_overlap init .1
instr YiString
 //////////////////////////////////////////////
 // Original by Steven Yi.
 // Adapted by Michael Gogins.
 //////////////////////////////////////////////
if p3 == -1 goto indefinite
goto non_indefinite
indefinite:
  p3 = 1000000
non_indefinite:
i_instrument = p1
i_time = p2
i_duration = p3
i_midi_key = p4
i_midi_velocity = p5
k_space_front_to_back = p6
k_space_left_to_right = p1/6
k_space_bottom_to_top = p8
i_phase = p9
i_frequency = cpsmidinn(i_midi_key)
i_amplitude ampmidicurve i_midi_velocity, gi_ampmidicurve_dynamic_range, gi_ampmidicurve_exponent
k_gain = ampdb(gk_YiString_level)
iattack = gi_YiString_overlap
isustain = p3
idecay = gi_YiString_overlap
p3 = iattack + isustain + idecay
aenvelope transeg 0.0, iattack / 2.0, 1.5, i_amplitude / 2.0, iattack / 2.0, -1.5, i_amplitude, isustain, 0.0, i_amplitude, idecay / 2.0, 1.5, i_amplitude / 2.0, idecay / 2.0, -1.5, 0
;ampenv = madsr:a(1, 0.1, 0.95, 0.5)
asignal = vco2(1, i_frequency)
asignal = moogladder(asignal, 6000, 0.1)
a_signal = asignal * aenvelope
i_attack = .002
i_release = 0.01
i_sustain = p3 - (i_attack + i_release)
a_declicking linsegr 0, i_attack, 1, i_sustain, 1, i_release, 0
a_signal = a_signal * i_amplitude * a_declicking * k_gain
#ifdef USE_SPATIALIZATION
a_spatial_reverb_send init 0
a_bsignal[] init 16
a_bsignal, a_spatial_reverb_send Spatialize a_signal, k_space_front_to_back, k_space_left_to_right, k_space_bottom_to_top
outletv "outbformat", a_bsignal
outleta "out", a_spatial_reverb_send
#else
a_out_left, a_out_right pan2 a_signal, p1/6
outleta "outleft", a_out_left * gk_YiString_reverb_send
outleta "outright", a_out_right * gk_YiString_reverb_send
outleta "chorusleft", a_out_left * gk_YiString_chorus_send
outleta "chorusright", a_out_right * gk_YiString_chorus_send
;printks "YiString         %9.4f  %9.4f\n", 0.5, a_out_left, a_out_right
#endif
prints "%-24s i %9.4f t %9.4f d %9.4f k %9.4f v %9.4f p %9.4f #%3d\n", nstrstr(p1), p1, p2, p3, p4, p5, gk_ZakianFlute_pan, active(p1)
endin

gk_Bower_level init 20
gk_Bower_pressure init 4.2
gisine ftgen 0,0,65536,10,1
instr Bower
if p3 == -1 goto indefinite
goto non_indefinite
indefinite:
  p3 = 1000000
non_indefinite:
insno = p1
istart = p2
iduration = p3
ikey = p4
ivelocity = p5
iphase = p6
ipan = (4 / 7 - .5)
iamp ampmidicurve ivelocity, gi_ampmidicurve_dynamic_range, gi_ampmidicurve_exponent
iattack = i(gk_overlap)
idecay = i(gk_overlap)
isustain = p3 - i(gk_overlap)
p3 = iattack + isustain + idecay
kenvelope transeg 0.0, iattack / 2.0, 1.5, iamp / 2.0, iattack / 2.0, -1.5, iamp, isustain, 0.0, iamp, idecay / 2.0, 1.5, iamp / 2.0, idecay / 2.0, -1.5, 0
ihertz = cpsmidinn(ikey)
kamp = kenvelope
kfreq = ihertz
kpres = 0.25
krat rspline 0.006,0.988,1,2
kvibf = 4.5
kvibamp = 0
iminfreq = 30
aSig wgbow kamp,kfreq,gk_Bower_pressure,krat,kvibf,kvibamp,gisine,iminfreq
aleft, aright pan2 aSig / 7, p1/6
adamping linseg 0, 0.03, 1, p3 - 0.1, 1, 0.07, 0
aleft = adamping * aleft
aright = adamping * aright
kgain = ampdb(gk_Bower_level)
outleta "outleft", aleft * kgain
outleta "outright", aright * kgain 
prints "%-24s i %9.4f t %9.4f d %9.4f k %9.4f v %9.4f p %9.4f #%3d\n", nstrstr(p1), p1, p2, p3, p4, p5, gk_ZakianFlute_pan, active(p1)
endin

gk_Harpsichord_level init 0
gk_Harpsichord_pick init .275
gk_Harpsichord_reflection init .75
gk_Harpsichord_pluck init .5
giharptable ftgen 0, 0, 65536, 7, -1, 1024, 1, 1024, -1
instr Harpsichord
if p3 == -1 goto indefinite
goto non_indefinite
indefinite:
  p3 = 1000000
non_indefinite:
i_instrument = p1
i_time = p2
i_duration = p3
i_midi_key = p4
i_midi_velocity = p5
k_space_front_to_back = p6
k_space_left_to_right = .2
k_space_bottom_to_top = p8
i_phase = p9
i_amplitude ampmidicurve i_midi_velocity, gi_ampmidicurve_dynamic_range, gi_ampmidicurve_exponent
k_gain = ampdb(gk_Harpsichord_level)
iHz = cpsmidinn(i_midi_key)
kHz = k(iHz)
aenvelope transeg 1.0, 20.0, -10.0, 0.05
k_amplitude = 1
apluck pluck 1, kHz, iHz, 0, 1
aharp poscil 1, kHz, giharptable
aharp2 balance apluck, aharp
a_signal	= (apluck + aharp2)
i_attack = .002
i_sustain = p3
i_release = 0.01
p3 = i_attack + i_sustain + i_release
a_declicking linsegr 0, i_attack, 1, i_sustain, 1, i_release, 0
a_signal = a_signal * i_amplitude * a_declicking * k_gain
#ifdef USE_SPATIALIZATION
a_spatial_reverb_send init 0
a_bsignal[] init 16
a_bsignal, a_spatial_reverb_send Spatialize a_signal, k_space_front_to_back, k_space_left_to_right, k_space_bottom_to_top
outletv "outbformat", a_bsignal
outleta "out", a_spatial_reverb_send
#else
a_out_left, a_out_right pan2 a_signal, p1/6
outleta "outleft", a_out_left
outleta "outright", a_out_right
#endif
; printks "Harpsichord      %9.4f   %9.4f\n", 0.5, a_out_left, a_out_right
prints "%-24s i %9.4f t %9.4f d %9.4f k %9.4f v %9.4f p %9.4f #%3d\n", nstrstr(p1), p1, p2, p3, p4, p5, gk_ZakianFlute_pan, active(p1)
kpbend    pchbend   2
printks2 "pchbend %9.4f\n", kpbend
kmodw     midictrl  1
printks2 "kmodw   %9.4f\n", kmodw
kctl6     midictrl  6
printks2 "kctl6   %9.4f\n", kctl6
kctl4     midictrl  4
printks2 "kctl4   %9.4f\n", kctl4
kctl5     midictrl  5
printks2 "kctl5   %9.4f\n", kctl5
kafter    aftouch   1
printks2 "kafter  %9.4f\n", kafter
endin

S_reverb_code init {{

static bool diagnostics_enabled = true;

// defined in this module to work around `__dso_handle` not being 
// defined in the C++ startup code. Not applicable on Linux!

//void* __dso_handle = (void *)&__dso_handle;


/**
 * Adapts the Synthesis Toolkit in C++'s "NRev" class for use directly in Csound.
 */
#include <stk/NRev.h>
#include "cxx_invokable.hpp"
#include <csdl.h>
#include <cstdio>

// Csound's PI conflicts with the STK's PI.
#undef PI

class InvokableReverb : public CxxInvokableBase {
    // Monophonic input, stereophonic outout. So, we use two of them to get stereo in, stereo out.
    stk::NRev reverberator_left;
    stk::NRev reverberator_right;
    public:
        ~InvokableReverb() {
            if (diagnostics_enabled) csound->Message(csound, ">>>>>>> InvokableReverb::~InvokableReverb.\\n");
        }
        int init(CSOUND *csound, OPDS *opds, MYFLT **outputs, MYFLT **inputs) override {
            if (diagnostics_enabled) csound->Message(csound, ">>>>>>> InvokableReverb::init....\\n");
            int result = OK;
            reverberator_left.setSampleRate(csound->GetSr(csound));
            reverberator_right.setSampleRate(csound->GetSr(csound));
            result = CxxInvokableBase::init(csound, opds, outputs, inputs);
            MYFLT T60 = *(inputs[0]);
            reverberator_left.setT60(T60);
            reverberator_right.setT60(T60);
            if (diagnostics_enabled) csound->Message(csound, ">>>>>>> InvokableReverb::init:  T60: %9.4f.\\n", T60);
            return result;
        }
        int kontrol(CSOUND *csound, MYFLT **outputs, MYFLT **inputs) override {
            int result = OK;
            //MYFLT T60 = *(inputs[0]);
            //reverberator_left.setT60(T60);
            //reverberator_right.setT60(T60);
            int frame_index = 0;
            for( ; frame_index < kperiodOffset(); ++frame_index) {
                outputs[0][frame_index] = 0;
                outputs[1][frame_index] = 0;
            }
            for( ; frame_index < kperiodEnd(); ++frame_index) {
                MYFLT audio_input = inputs[1][frame_index];
                MYFLT audio_output_left = 0;
                audio_output_left += reverberator_left.tick(audio_input, 0);
                audio_output_left += reverberator_left.tick(audio_input, 1);
                outputs[0][frame_index] = audio_output_left;
                MYFLT audio_output_right = 0;
                audio_output_right += reverberator_right.tick(audio_input, 0);
                audio_output_right += reverberator_right.tick(audio_input, 1);
                outputs[1][frame_index] = audio_output_right;
             }
            for( ; frame_index < ksmps(); ++frame_index) {
                outputs[0][frame_index] = 0;
                outputs[1][frame_index] = 0;
            }
            return result;
        }
};

extern "C" {
    int reverb_main(CSOUND *csound) {
        int result = OK;
        if (diagnostics_enabled) csound->Message(csound, ">>>>>>> This is \\"reverb_main\\".\\n");
        return result;
    }
    CxxInvokable *reverb_factory() {
        if (diagnostics_enabled) std::fprintf(stderr, ">>>>>>> This is \\"reverb_factory\\".\\n");
        auto result = new InvokableReverb;
        if (diagnostics_enabled) std::fprintf(stderr, ">>>>>>> \\"reverb_factory\\" created %p.\\n", result);
        return result;
    }
};

}}

gS_os, gS_macros cxx_os

if strcmp(gS_os, "macOS") == 0 then
i_result cxx_compile "reverb_main", S_reverb_code, "g++ -g -v -O2 -fPIC -shared -std=c++17 -DUSE_DOUBLE -stdlib=libc++ -I/usr/local/include/csound -I/Library/Frameworks/CsoundLib64.framework/Versions/6.0/Headers -I/opt/homebrew/Cellar/stk/4.6.2/include -I. -L/opt/homebrew/lib -lm -lpthread", "libstk.dylib"
endif
if strcmp(gS_os, "Linux") == 0 then
i_result cxx_compile "reverb_main", S_reverb_code, "g++ -g -v -O2 -fPIC -shared -std=c++17 -I/usr/local/include -I/usr/local/include/csound -I. -L/usr/lib -L/usr/local/lib -L/usr/lib/gcc/x86_64-linux-gnu/9 -L/home/mkg/csound-cxx-opcodes/examples -lm -lpthread", "libstk.so"
endif

gk_Reverb_feedback init 2.2
instr CxxReverb
aleftout init 0
arightout init 0
aleftin inleta "inleft"
arightin inleta "inright"
aleftout, arightout cxx_invoke "reverb_factory", 3, gk_Reverb_feedback, aleftin, arightin
outleta "outleft", aleftout
outleta "outright", arightout
prints "%-24s i %9.4f t %9.4f d %9.4f k %9.4f v %9.4f p %9.4f #%3d\n", nstrstr(p1), p1, p2, p3, p4, p5, 0, active(p1)
endin

gk_MasterOutput_level init -15
gS_MasterOutput_filename init ""
instr MasterOutput
aleft inleta "inleft"
aright inleta "inright"
k_gain = ampdb(gk_MasterOutput_level)
printks2 "Master gain: %f\n", k_gain
iamp init 1
iattack init .01
idecay init 10
isustain = 2400 - (iattack + idecay)
aenvelope transeg 0.0, iattack / 2.0, 1.5, iamp / 2.0, iattack / 2.0, -1.5, iamp, isustain, 0.0, iamp, idecay / 2.0, 1.5, iamp / 2.0, idecay / 2.0, -1.5, 0
aleft butterlp aleft, 18000
aright butterlp aright, 18000
outs aleft * k_gain * aenvelope, aright * k_gain * aenvelope
; We want something that will play on my phone.
i_amplitude_adjustment = ampdbfs(-3) / 32767
i_filename_length strlen gS_MasterOutput_filename
if i_filename_length > 0 goto has_filename
goto non_has_filename
has_filename:
prints sprintf("Output filename: %s\n", gS_MasterOutput_filename)
fout gS_MasterOutput_filename, 18, aleft * i_amplitude_adjustment, aright * i_amplitude_adjustment
non_has_filename:
prints "%-24s i %9.4f t %9.4f d %9.4f k %9.4f v %9.4f p %9.4f #%3d\n", nstrstr(p1), p1, p2, p3, p4, p5, 0, active(p1)
kstatus, kchan, kdata1, kdata2 midiin
;printf "          midi in s %4d c %4d %4d %4d\n", kdata2, kstatus, kchan, kdata1, kdata2
endin

S_score_generator_code init {{

#include <eigen3/Eigen/Dense>
#include <csdl.h>
#include <iostream>
#include <cstdio>
#include <sstream>
#include <random>
#include <vector>

/**
 * Multipe Copy Reducing Machine for dimensions:
 * 0 instrument
 * 1 time
 * 2 duration
 * 3 key
 * 4 velocity
 * 5 pan
 * 6 homogeneity
 */
 
typedef Eigen::Matrix<double, 7, 1> Note;
typedef Eigen::Matrix<double, 7, 7> Transformation;
typedef std::vector<Note> Score;
 
struct Scaling {
    Note minima;
    Note maxima;
    Note ranges;
};

void update_bounds(Scaling &scaling, const Note &note) {
    for (int i = 0; i < 6; ++i) {
        if (note[i] < scaling.minima[i]) {
            scaling.minima[i] = note[i];
        }
        if (note[i] > scaling.maxima[i]) {
            scaling.maxima[i] = note[i];
        }
    }
    scaling.ranges = scaling.maxima - scaling.minima;
}

void multiple_copy_reducing_machine(const Note &note, const std::vector<Transformation> &transformations, Score &score, int depth) {
    --depth;
    if (depth < 0) {
        return;
    }
    for (const auto &transformation : transformations) {
        auto new_note = transformation * note;
        if (depth == 1) {
            score.push_back(new_note);
        }
        multiple_copy_reducing_machine(new_note, transformations, score, depth);
    }
}

void rescale(Scaling &scaling, Score &score, int dimension, bool rescale_minimum, bool rescale_range, double minimum, double range) {
    scaling.minima = score.front();
    scaling.maxima = score.front();
    for (const auto &note : score) {
        update_bounds(scaling, note);
    }
    std::fprintf(stderr, "rescale: dimension: %2d rescale minimum: %d rescale range: %d actual minimum: %9.4f actual range: %9.4f target_minimum: %9.4f target_range: %9.4f\\n", dimension, rescale_minimum, rescale_range, scaling.minima[dimension], scaling.ranges[dimension], minimum, range);
    double scaling_factor = range / scaling.ranges[dimension];
    double move_to_origin = scaling.minima[dimension];
    for (auto &note : score) {
         // Move note to origin.
        double value = note[dimension];
        value -= move_to_origin;
        // Rescale to fit target range.
        if (scaling.ranges[dimension]  != 0.) {
            value *= scaling_factor;
        }
        // Move back from origin to target.
        value += minimum;
        note[dimension] = value;
    }
}

std::string to_csound_score(const Score &score) {
    // Randomize all stereo pans.
    std::mt19937 mersenne_twister(49850);
    std::uniform_real_distribution<double> random_pan(.05, .95);
    std::stringstream stream_;
    char buffer[0x500];
    for (const auto &note : score) {
        auto instrument = note[0];
        auto time = note[1];
        auto duration = note[2];
        auto midi_key = std::round(note[3]);
        auto midi_velocity = note[4];
        double depth = 0;
        double pan = random_pan(mersenne_twister);
        std::snprintf(buffer, 0x500, "i %9.4f %9.4f %9.4f %9.4f %9.4f %9.4f %9.4f\\n", instrument, time, duration, midi_key, midi_velocity, depth, pan);
        stream_ << buffer;
    }
    auto generated_score = stream_.str();
    std::cerr << "generated_score:" << std::endl << generated_score << std::endl;
    return generated_score;
}

extern "C" int score_generator(CSOUND *csound) {
    csound->Message(csound, ">>>>>>> This is \\"score_generator\\".\\n");
    int result = OK;
    // Notes are column vectors. Notes and transformations are homogeneous.
    Note note;
    note << 1., 1., 1., 60., 60., .5, 1.;
    std::cerr << "initial note: " << std::endl << note << std::endl;
    std::vector<Transformation> transformations;
    transformations.resize(4);
    //                     i   t   d   k   v   p   T
    transformations[0] << .5,  0,  0,  .1, 0,  0,  1, /* i */
                           0, .5,  0,  0,  0,  0,  0, /* t */
                           0,  0, .5,  0,  0,  0,  0, /* d */
                           0,  0,  0, .5,  0,  0,  0, /* k */
                           0,  0,  0,  0, .5,  0,  0, /* v */
                           0,  0,  0,  0,  0, .5,  0, /* p */
                           0,  0,  0,  0,  0,  0,  1; /* H */
                           
    transformations[1] << .5,  0,  0,  0,  0,  0,  0,
                           0, .45, 0,  0,  0,  0,  1,
                           0,  0, .5,  0,  0,  0,  0,
                           0,  1,  0, .5,  0,  0,  0,
                           0,  0,  0,  0, .6,  0,  0,
                           0,  0,  0,  0,  0, .5,  0,
                           0,  0,  0,  0,  0,  0,  1;
                           
    transformations[2] << .5,  0,  0,  0,  0,  0, -1,
                           0, .5,  0,  0,  0,  0,  0,
                           0,  0, .5,  0,  0,  0,  0,
                           0,  0,  0, .5,  0,  0,  1,
                           0,  0,  0,  0, .5,  0,  0,
                           0,  0,  0,  0,  0, .5,  0,
                           0,  0,  0,  0,  0,  0,  1;
                           
    transformations[3] << .5,  0,  0,  0,  0,  0,  0,
                           0, .5,  0,  0,  0,  0,  1.05,
                           0,  0, .5,  0, -1,  0,  0,
                           0,  0,  0, .45, 0,  0,  1,
                           0,  0,  0,  0, .5,  0,  0,
                           0,  0,  .1, 0,  0, .5,  0,
                           0,  0,  0,  0,  0,  0,  1;
    Score score;
    Scaling scaling;
    multiple_copy_reducing_machine(note, transformations, score, 6);
    rescale(scaling, score, 0, true, true,  1.,    4.999);
    rescale(scaling, score, 1, true, true,  1.,  120.0);
    rescale(scaling, score, 2, true, true,  3,     6.);
    rescale(scaling, score, 3, true, true, 24.,   72.0);
    rescale(scaling, score, 4, true, true, 20.,   10.0);
    auto csound_score = to_csound_score(score);
    csound->InputMessage(csound, csound_score.c_str());
    csound->Message(csound, "Sent generated score to Csound.\\n");
    return 0;
}

}}

if strcmp(gS_os, "macOS") == 0 then
i_result cxx_compile "score_generator", S_score_generator_code, "g++ -g -v -O2 -fPIC -shared -std=c++17 -DUSE_DOUBLE -stdlib=libc++ -I/usr/local/include/csound -I/Library/Frameworks/CsoundLib64.framework/Versions/6.0/Headers -I/opt/homebrew/Cellar/eigen/3.4.0_1/include -lpthread -lm"
endif
if strcmp(gS_os, "Linux") == 0 then
i_result cxx_compile "score_generator", S_score_generator_code, "g++ -g -v -O2 -fPIC -shared -std=c++17 -I/usr/local/include/csound -I/usr/include/eigen3 -lpthread -lm -lstk"
endif

</CsInstruments>
<CsScore>
f 0 125
</CsScore>
</CsoundSynthesizer>
