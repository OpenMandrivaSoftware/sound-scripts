#!/usr/bin/perl -pi

# known whitelist:
# - "DAC Volume" must be unmuted on Cirrus Logic CS4297A driver (#12151)
# - "wave surround" must be unmuted on SB Live in order to make rear speakers working

my $factor = 0.8;

# state machine:
if (/\s*control\./) {
    ($min, $max) = (0, 0);
} elsif (/\s*name '/) {
    # fix too fast sound on "Terratec Aureon 5.1 Sky" (#12100):
    $max = 44100/$factor if $fix_frequ = /Multi Track Internal Clock/;
    # fix distortion on SBLive Value with stereo analogue speakers (#13911):
    $max*= 0.5/$factor if /Tone Control - Treble|Tone Control - Bass/;
    # reduce level of speaker (#49045):
    $max /= 4 if /Speaker Playback Volume/;
    # skip masks and blacklist mixer elements that corrupt or mute the sound:
    $blacklisted = m!\s*name\s'.*(
# fix distorsion on some Ali 5455, AMD 768/8111, Intel i8x0, nVidia nForce and SiS 7012 sound cards:
        3D\ Control
# prevent a larsen effect above 50/60% on SB Live:
        |AC97\ Playback\ Volume
# most users use analog hps rather than digital ones and some audigy do not have digital output anyway:
# (also fix muted sound on Creative Labs EMU10K2 Audigy (#7938)):
        |^Analog/Digital\ Output\ Jack
# Some cards need this enabled (#17515, #18235), some need it disabled
# (Launchpad #106380, http://forum.mandriva.com/viewtopic.php?p=580272,
# ALSA #2560 for e.g.) According to Daniel Chen in the launchpad report
# it is probably best for the majority of users to mute it by default:
        |Audigy\ Analog/Digital\ Output\ Jack
# fix low sound on some laptops with internal HPs:
# (fix disabled b/c it mute sound on new laptops (#16582)
#        |External\ Amplifier
# fix muted sound on ICH4:
        |External\ Amplifier\ Power\ Down
# fix muted sound on C-Media PCI (CMI):
        |Exchange\ DAC
# fix sound on i845 with ALSA-1.0.8+:
# this is fixed in ALSA's CVS and we should probably split the blacklisted
# state into "ignored" and "blacklisted" ones.
# the state should be set to 'ignored' for the 2 following elements that we
# should really ignored since CVS driver really set the proper default value
# whereas we currently mute blacklisted elements
        |Headphone\ Jack\ Sense
        |Line\ Jack\ Sense
# fix sound on shuttle boxes:
        |IEC958\ input\ monitor
# fix sound on VIA 8233:
        |IEC958\ Capture\ Monitor
# fix loud sound on cmpci cards:
        |IEC958\ Mix\ Analog
# fix noise on ensoniq 1371:
        |IEC958\ Playback\ Switch
# fix recording on Via FX41/VT8233 && ATI IXP400 (#14571):
        |IEC958\ Capture\ Switch
# fix playing sound on SB Audigy 2 (#18735)
        |IEC958\ Optical\ Raw\ Playback\ Switch
# fix playing sound on Hercules Gamesurround Fortissimo 4 (#21173):
        |Multi\ Track\ Rate\ Locking
# prevent larsen on some laptops (especially some DELL notebooks with i8xx chipsets):
        |Mic\ Boost\ \(\+\d+dB\)
# fix larsen on laptops with ALI chipsets:
        |Mic\ Playback\ Switch
# SB Live: route sound to the first speaker couple rather than to the second pair of speakers
        |^Output\ Jack
# fix sound on SB Audigy LS:
        |SPDIF\ Out
# fix sound on shuttle boxes:
        |Surround\ down\ mix
# Fix nasty noise on several systems: #44703
	|Analog\ Loopback
# Fix excessive loud beep on intel hda: #45386, #57320
        |(PC\ )?Beep
# ignore masks, only care about regular mixer element (either rules or switches):
        |mask
)!xi;
} else {
    if (/s*comment.range '(\d+) - (\d+)'/) {
        ($min, $max) = ($1, $2);
    } elsif (/s*value/) {
        # Mute blacklisted elements
        if ($blacklisted) {
            # disable switches:
            s/(value\w*\S*)\s* true/\1 false/;
            # set volume to 0%:
            s/(value\w*\S*)\s* \d+/\1 0/;
        } else {
            # enable switches:
            s/(value\w*\S*)\s* false/\1 true/;
            # set volume to 80%:
            my $val = int($max*$factor);
            s/(value\w*\S*)\s* \d+/\1 $val/;
            # fix too fast sound on "Terratec Aureon 5.1 Sky" (#12100):
            s/(value)\s*'\d+'/\1 '$val'/ if $fix_frequ;
        }
    }
}
