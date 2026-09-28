"""Original menu cue: Une lumiere sous les lames.

Run with Python + numpy scipy soundfile mido imageio-ffmpeg.
Downloads only required instrument samples into ignored artifacts/music-samples.
The score, instrument manifest, MIDI, stems and masters remain reproducible.
"""
from __future__ import annotations

import concurrent.futures
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import urllib.parse
import urllib.request

import imageio_ffmpeg
import mido
import numpy as np
from scipy import signal
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "artifacts/music-samples"
WORK = ROOT / "artifacts/music-production"
DOC = ROOT / "docs/conception/music-v01"
ASSET = ROOT / "assets/audio/music"
SR = 48000
BPM = 72
BEAT = 60 / BPM
BAR = 3 * BEAT
LENGTH = 32 * BAR
N = round(LENGTH * SR)
SEED = 53054
RNG = np.random.default_rng(SEED)
EVENTS: list[dict] = []


def note(name: str) -> int:
    match = re.fullmatch(r"([A-G])([#b]?)(-?\d+)", name)
    assert match, name
    letter, accidental, octave = match.groups()
    return (int(octave) + 1) * 12 + dict(C=0, D=2, E=4, F=5, G=7, A=9, B=11)[letter] + {"": 0, "#": 1, "b": -1}[accidental]


def add(inst, bar, eighth, pitch, duration, velocity, pan=0.0):
    # Small deterministic timing/dynamic differences, not quantized repetitions.
    start = bar * BAR + eighth * BEAT / 2
    start += float(RNG.normal(0, .009 if inst in ("piano", "harp", "glock") else .014))
    EVENTS.append(dict(instrument=inst, time=max(0., start),
                       note=note(pitch) if isinstance(pitch, str) else pitch,
                       duration=duration * BEAT / 2,
                       velocity=float(np.clip(velocity + RNG.normal(0, 2), 15, 110)), pan=pan))


def compose():
    # Bass and close upper voices are chosen explicitly for voice leading.
    chords = {
        "Dm9": ("D2", ["A3", "D4", "E4", "F4"]),
        "Bb7": ("Bb2", ["A3", "D4", "F4", "Bb4"]),
        "F9": ("A2", ["A3", "C4", "F4", "G4"]),
        "C9": ("G2", ["G3", "C4", "D4", "E4"]),
        "Gm9": ("G2", ["A3", "Bb3", "D4", "F4"]),
        "DmF": ("F2", ["A3", "D4", "E4", "F4"]),
        "Asus": ("A2", ["G3", "A3", "D4", "E4"]),
        "A7": ("A2", ["G3", "A3", "C#4", "E4"]),
    }
    harmony = ["Dm9", "Bb7", "Dm9", "Asus",
               "Dm9", "Bb7", "F9", "C9", "Gm9", "DmF", "Bb7", "A7",
               "Dm9", "F9", "Gm9", "A7",
               "Bb7", "C9", "Dm9", "F9", "Bb7", "Gm9", "Asus", "A7",
               "Dm9", "Bb7", "F9", "C9", "Gm9", "DmF", "Bb7", "Asus"]
    for b, name in enumerate(harmony):
        bass, upper = chords[name]
        upper = [note(p) for p in upper]
        lift = 16 <= b < 24
        dyn = 43 if b < 4 else 53 if lift else 47 if b < 28 else 39
        # Six-eight cradle: the third eighth is frequently left empty to breathe.
        pattern = [(0, 0), (1, 1), (2, 2), (3, 3), (4, 1), (5, 2)]
        if b < 4 or b >= 28:
            pattern = [(0, 0), (1.5, 1), (3.2, 3), (4.5, 2)]
        for e, ix in pattern:
            if b in (11, 15, 23, 31) and e > 3: continue
            add("piano", b, e, upper[ix], 3.2, dyn + (4 if e == 0 else -3), -.14)
        add("piano", b, 0, note(bass) + 12, 5.8, dyn - 7, -.2)
        if b >= 4 and b < 30:
            add("cello", b, .05, bass, 5.5, 48 if lift else 38, .2)
        if 6 <= b < 28:
            add("viola", b, .15, upper[0], 5.35, 42 if lift else 32, -.24)
        if 8 <= b < 28:
            add("violin", b, .25, upper[2] + 12, 5.1, 41 if lift else 29, -.36)
        if 12 <= b < 28:
            for e, ix in [(0, 1), (2.5, 2), (3.5, 3), (5, 2)]:
                add("harp", b, e, upper[ix] + 12, 2.8, 32 if lift else 25, .38)
        if lift:
            # A barely audible wood pulse lends scale to the small inhabitants.
            add("wood", b, 0, 48, .4, 34, -.35)
            add("wood", b, 3, 55, .4, 24, .35)

    # Original motif: rising fourth, sighing second, then a third falling home.
    theme = [
        [(0, "A4", 1), (1, "D5", 2), (3, "E5", 1), (4, "F5", 1.7)],
        [(0, "E5", 1), (1, "D5", 2), (3, "A4", 2.6)],
        [(0, "C5", 1.5), (1.5, "A4", 1.5), (3, "G4", 1), (4, "A4", 1.6)],
        [(0, "G4", 3.7), (4, "E4", 1.3)],
        [(0, "G4", 1), (1, "A4", 1), (2, "Bb4", 1), (3, "D5", 2.4)],
        [(0, "C5", 1), (1, "A4", 2), (3, "F4", 2.6)],
        [(0, "F4", 1), (1, "A4", 2), (3, "D5", 1.6), (5, "C5", .7)],
        [(0, "B4", 1), (1, "A4", 1.5), (3, "G4", 1), (4, "E4", 1.3)],
    ]
    for start in (4, 24):
        for j, phrase in enumerate(theme):
            for k, (e, pitch, dur) in enumerate(phrase):
                if start == 24 and j >= 6 and k > 1: continue
                vel = 66 if start == 4 else 57
                add("piano", start + j, e + .035, pitch, dur, vel + (4 if k == 1 else 0), .06)
                if j in (0, 1, 4, 6) and k in (0, 1):
                    add("glock", start + j, e + .085, note(pitch) + 12, dur + 2, 39 if start == 4 else 30, .23)

    # Intro only hints at the motif; pauses are part of the phrase.
    for b, e, p, d in [(0, 3, "A5", 2), (1, 1, "D6", 3), (2, 3, "E6", 2), (3, 0, "D6", 3)]:
        add("glock", b, e, p, d, 36, .2)
    answer = [
        [(0, "F5", 2), (2, "E5", 1), (3, "D5", 2.5)],
        [(0, "C5", 2), (3, "A4", 2.4)],
        [(0, "Bb4", 2), (2, "A4", 1), (3, "G4", 2.5)],
        [(0, "E5", 2), (2, "D5", 1), (3, "C#5", 2.4)],
    ]
    for j, phrase in enumerate(answer):
        for e, p, d in phrase: add("piano", 12 + j, e, p, d, 63, .06)
    development = [
        [(0, "D5", 2), (2, "F5", 1), (3, "A5", 2.5)],
        [(0, "G5", 3), (3, "E5", 2.5)],
        [(0, "F5", 2), (2, "E5", 1), (3, "D5", 2.5)],
        [(0, "C5", 2), (2, "A4", 1), (3, "C5", 2.5)],
        [(0, "D5", 2), (2, "F5", 1), (3, "E5", 2.5)],
        [(0, "D5", 3), (3, "Bb4", 2.5)],
        [(0, "A4", 2), (2, "D5", 1), (3, "E5", 2.5)],
        [(0, "D5", 2), (2, "C#5", 1), (3, "A4", 2.4)],
    ]
    for j, phrase in enumerate(development):
        for k, (e, p, d) in enumerate(phrase):
            add("flute", 16 + j, e, p, d + .12, 58 + (3 if j < 4 else -2), .13)
            add("piano", 16 + j, e + .03, p, d, 57, .04)
            if j in (0, 2, 4) and k == 0: add("glock", 16 + j, e, note(p) + 12, d, 32, .26)
    # Gentle E pickup prepares D at the next cycle, without a forced fade-out.
    add("glock", 31, 4, "E5", 3, 25, .2)
    return harmony


def fetch(url, dest):
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        req = urllib.request.Request(url, headers={"User-Agent": "SousLePlancher-original-score"})
        with urllib.request.urlopen(req, timeout=90) as response:
            data = response.read()
        dest.write_bytes(data)
    return dest


def instruments():
    # Resolve to immutable commit IDs and retain them with the production.
    manifest_file = DOC / "sample-manifest.json"
    if manifest_file.exists():
        manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
    else:
        repos = {"vsco": ("sgossner/VSCO-2-CE", "SFZ"),
                 "piano": ("sfzinstruments/SalamanderGrandPiano", "master")}
        versions = {}
        for key, (repo, branch) in repos.items():
            req = urllib.request.Request(f"https://api.github.com/repos/{repo}/commits/{branch}", headers={"User-Agent": "SousLePlancher-original-score"})
            versions[key] = json.load(urllib.request.urlopen(req))["sha"]
        manifest = {"sources": versions, "samples": [], "licenses": []}
        mappings = {"cello": "CelloEnsSusVib-Quiet.sfz", "viola": "ViolaEnsSusVib.sfz",
                    "violin": "ViolinEnsSusVib.sfz", "glock": "Glockenspiel.sfz",
                    "harp": "Harp.sfz", "flute": "FluteSusVib.sfz"}
        for inst, filename in mappings.items():
            prefix = f"https://raw.githubusercontent.com/sgossner/VSCO-2-CE/{versions['vsco']}/"
            source = fetch(prefix + filename, CACHE / filename).read_text()
            base = re.search(r"default_path=([^\r\n]+)", source).group(1).replace("\\", "/")
            regions = []
            for region in source.split("<region>")[1:]:
                sample = re.search(r"sample=([^\r\n]+)", region).group(1).strip()
                pitch = int(re.search(r"pitch_keycenter=(\d+)", region).group(1))
                # Quiet layer, first round robin only.
                if any(x[0] == pitch for x in regions): continue
                regions.append((pitch, base + sample))
            wanted = sorted({e["note"] for e in EVENTS if e["instrument"] == inst})
            chosen = {min(regions, key=lambda r: abs(r[0] - pitch)) for pitch in wanted}
            for pitch, path in sorted(chosen):
                manifest["samples"].append(dict(instrument=inst, root=pitch, path=inst + "/" + Path(path).name,
                                                 url=prefix + urllib.parse.quote(path)))
        roots = list(range(33, 88, 3))
        wanted = sorted({e["note"] for e in EVENTS if e["instrument"] == "piano"})
        for pitch in sorted({min(roots, key=lambda r: abs(r - p)) for p in wanted}):
            nn = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][pitch % 12] + str(pitch // 12 - 1)
            path = f"Samples/{nn}v4.flac"
            manifest["samples"].append(dict(instrument="piano", root=pitch, path="piano/" + Path(path).name,
                url=f"https://raw.githubusercontent.com/sfzinstruments/SalamanderGrandPiano/{versions['piano']}/" + urllib.parse.quote(path)))
        for key, (repo, _) in repos.items():
            url = f"https://raw.githubusercontent.com/{repo}/{versions[key]}/LICENSE"
            manifest["licenses"].append(dict(url=url, path=f"{key}-LICENSE.txt"))
        manifest_file.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    for lic in manifest["licenses"]:
        fetch(lic["url"], DOC / "licenses" / lic["path"])
    def download(s):
        path = fetch(s["url"], CACHE / s["path"])
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if "sha256" in s: assert digest == s["sha256"], path
        s["sha256"] = digest
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        list(pool.map(download, manifest["samples"]))
    manifest_file.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Samples ready: {len(manifest['samples'])}", flush=True)
    return manifest


class Sampler:
    def __init__(self, manifest):
        self.sources = {}
        self.pitched = {}
        for sample in manifest["samples"]:
            x, rate = sf.read(CACHE / sample["path"], dtype="float32", always_2d=True)
            if rate != SR:
                g = math.gcd(rate, SR)
                x = signal.resample_poly(x, SR // g, rate // g, axis=0).astype(np.float32)
            if x.shape[1] == 1: x = np.repeat(x, 2, axis=1)
            x = x[:, :2]
            inst = sample["instrument"]
            # Preserve natural attacks; remove file-leading silence only.
            active = np.flatnonzero(np.max(np.abs(x), axis=1) > max(.00004, np.max(np.abs(x)) * .008))
            if active.size: x = x[max(0, active[0] - 240):]
            x = signal.sosfilt(signal.butter(2, 35, "highpass", fs=SR, output="sos"), x, axis=0).astype(np.float32)
            cutoff = {"piano": 4200, "glock": 6500, "cello": 3800, "viola": 4500, "violin": 5500, "harp": 5500, "flute": 6500}[inst]
            x = signal.sosfilt(signal.butter(2, cutoff, fs=SR, output="sos"), x, axis=0).astype(np.float32)
            reference = np.sqrt(np.mean(x[:min(len(x), SR * 2)] ** 2))
            x *= .10 / max(reference, .001)
            self.sources.setdefault(inst, []).append((sample["root"], x))

    def render(self, event):
        inst, pitch = event["instrument"], event["note"]
        if inst == "wood":
            t = np.arange(int(SR * .17)) / SR
            f = 330 * 2 ** ((pitch - 48) / 12)
            y = .07 * np.sin(2 * np.pi * f * t) * np.exp(-t * 38)
            y += .02 * np.sin(2 * np.pi * f * 2.73 * t) * np.exp(-t * 70)
            y *= np.minimum(t / .0015, 1)
            x = np.column_stack([y, y]).astype(np.float32)
        else:
            key = inst, pitch
            if key not in self.pitched:
                root, original = min(self.sources[inst], key=lambda s: abs(s[0] - pitch))
                ratio = 2 ** ((pitch - root) / 12)
                # Polyphase anti-aliasing, not low-quality linear transposition.
                up, down = 10000, round(10000 * ratio)
                g = math.gcd(up, down)
                self.pitched[key] = signal.resample_poly(original, up // g, down // g, axis=0).astype(np.float32)
            x = self.pitched[key]
            duration = event["duration"]
            sustain = inst in ("cello", "viola", "violin", "flute")
            release = .48 if sustain else 1.4 if inst == "piano" else 2.8
            n = min(len(x), round((duration + release) * SR))
            x = x[:n].copy()
            t = np.arange(n, dtype=np.float32) / SR
            env = np.ones(n, np.float32)
            if sustain:
                attack = .22 if inst != "flute" else .07
                env *= np.sin(np.clip(t / attack, 0, 1) * np.pi / 2) ** 2
                env *= .72 + .28 * np.sin(np.clip(t / max(duration, .1), 0, 1) * np.pi)
            else:
                env *= np.minimum(t / .003, 1)
            env *= np.cos(np.clip((t - duration) / release, 0, 1) * np.pi / 2) ** 2
            # Always taper the sample end even for recordings shorter than a note.
            end = min(round(.045 * SR), n)
            env[-end:] *= np.linspace(1, 0, end)
            x *= env[:, None]
        pan = event["pan"]
        mid = x.mean(axis=1)
        side = (x[:, 0] - x[:, 1]) * .24
        left = (mid + side) * math.cos((pan + 1) * math.pi / 4)
        right = (mid - side) * math.sin((pan + 1) * math.pi / 4)
        x = np.column_stack([left, right]).astype(np.float32)
        x *= (event["velocity"] / 64) ** 1.55
        return x


def reverb(x, send):
    # A common warm chamber glues the ensemble. Stereo late fields are decorrelated.
    size = round(SR * 3.2)
    t = np.arange(size) / SR
    result = np.zeros((len(x) + size - 1, 2), np.float32)
    for channel in range(2):
        rng = np.random.default_rng(SEED + 100 + channel)
        ir = rng.normal(size=size) * np.exp(-t * 3.0)
        ir *= np.minimum(t / .06, 1)
        ir[:round(.027 * SR)] = 0
        ir = signal.sosfilt(signal.butter(2, 4200, fs=SR, output="sos"), ir)
        ir /= np.sqrt(np.sum(ir ** 2))
        for delay, level in [(.029, .14), (.047, .11), (.071, .07), (.113, .05)]:
            ir[round((delay + channel * .0031) * SR)] += level
        wet = signal.fftconvolve(x[:, channel] * .8 + x[:, 1-channel] * .2, ir, mode="full")
        result[:, channel] = wet * send
        result[:len(x), channel] += x[:, channel]
    return result


def export_midi():
    midi = mido.MidiFile(ticks_per_beat=960)
    conductor = mido.MidiTrack()
    conductor.append(mido.MetaMessage("track_name", name="Une lumiere sous les lames"))
    conductor.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(BPM)))
    conductor.append(mido.MetaMessage("time_signature", numerator=6, denominator=8))
    conductor.append(mido.MetaMessage("key_signature", key="Dm"))
    for i, title in enumerate(["La lueur", "Le refuge", "La reponse", "Au-dela des lames", "Le retour"]):
        bars = [0, 4, 12, 16, 24]
        prev = bars[i-1] if i else 0
        conductor.append(mido.MetaMessage("marker", text=title, time=(bars[i] - prev) * 2880))
    midi.tracks.append(conductor)
    programs = dict(piano=0, glock=10, cello=42, viola=41, violin=48, harp=46, flute=73, wood=115)
    for channel, (inst, program) in enumerate(programs.items()):
        track = mido.MidiTrack()
        track.append(mido.MetaMessage("track_name", name=inst))
        track.append(mido.Message("program_change", channel=channel, program=program))
        schedule = []
        phrases = sorted([e for e in EVENTS if e["instrument"] == inst], key=lambda e: e["time"])
        for index, e in enumerate(phrases):
            end = e["time"] + e["duration"]
            later = next((n["time"] for n in phrases[index + 1:] if n["note"] == e["note"]), None)
            if later is not None: end = min(end, later - .001)
            for on, seconds in [(True, e["time"]), (False, end)]:
                schedule.append((round(seconds / BEAT * 960), mido.Message("note_on" if on else "note_off", channel=channel, note=e["note"], velocity=round(e["velocity"]) if on else 0)))
        previous = 0
        for tick, message in sorted(schedule, key=lambda x: (x[0], x[1].type == "note_on")):
            message.time = tick - previous
            track.append(message)
            previous = tick
        midi.tracks.append(track)
    midi.save(DOC / "une-lumiere-sous-les-lames.mid")


def main():
    for p in (CACHE, WORK, DOC, ASSET): p.mkdir(parents=True, exist_ok=True)
    (ROOT / "artifacts/.gdignore").touch()
    (DOC / ".gdignore").touch()
    harmony = compose()
    (DOC / "score.json").write_text(json.dumps(dict(title="Une lumière sous les lames", bpm=BPM, meter="6/8", bars=32, duration=LENGTH, harmony=harmony, events=EVENTS), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    export_midi()
    sampler = Sampler(instruments())
    gains = dict(piano=.80, glock=.24, cello=.40, viola=.24, violin=.20, harp=.19, flute=.37, wood=.16)
    sends = dict(piano=.23, glock=.43, cello=.27, viola=.34, violin=.39, harp=.31, flute=.31, wood=.14)
    mix = np.zeros((N, 2), np.float32)
    release_tail = np.zeros((SR * 8, 2), np.float32)
    # Single-cycle contributions + all their tails are wrapped, including reverb.
    # This preserves the exact sample clock and does not duplicate a crossfade bar.
    for inst, gain in gains.items():
        dry = np.zeros((N + SR * 8, 2), np.float32)
        for event in EVENTS:
            if event["instrument"] != inst: continue
            x = sampler.render(event)
            start = round(event["time"] * SR)
            count = min(len(x), len(dry) - start)
            dry[start:start+count] += x[:count] * gain
        wet = reverb(dry, sends[inst])
        loop = wet[:N].copy()
        tail = wet[N:]
        loop[:len(tail)] += tail
        release_tail += tail[:len(release_tail)]
        sf.write(WORK / f"stem-{inst}.wav", loop, SR, subtype="FLOAT")
        mix += loop
        print(f"Rendered {inst}", flush=True)
    # Conservative peak headroom, no brickwall compression over the chamber dynamics.
    peak = float(np.max(np.abs(mix)))
    gain = 10 ** (-2.0 / 20) / peak
    mix *= gain
    sf.write(WORK / "une-lumiere-sous-les-lames-loop-48k24.wav", mix, SR, subtype="PCM_24")
    # Listening edition has a real tonic ending, unlike the runtime loop.
    preview = np.zeros((N + SR * 8, 2), np.float32)
    preview[:N] = mix
    ending = np.zeros_like(preview)
    for inst, pitch, vel in [("piano", 50, 42), ("piano", 57, 40), ("piano", 62, 52), ("piano", 65, 40), ("glock", 86, 28), ("cello", 38, 30)]:
        e = dict(instrument=inst, note=pitch, velocity=vel, duration=2.7, pan=.0)
        x = sampler.render(e) * gains[inst] * gain
        ending[N:N+len(x)] += x
    ending = reverb(ending, .30)[:len(preview)]
    # Carry the loop's final release into the tonic cadence.
    preview[N:] += release_tail * gain
    preview += ending
    preview[:SR] *= np.linspace(0, 1, SR)[:, None]
    preview[-SR*3:] *= np.linspace(1, 0, SR*3)[:, None] ** 1.6
    preview *= min(1, 10 ** (-1.5/20) / float(np.max(np.abs(preview))))
    wav = WORK / "une-lumiere-sous-les-lames-ecoute-48k24.wav"
    sf.write(wav, preview, SR, subtype="PCM_24")
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    subprocess.run([ffmpeg, "-y", "-v", "error", "-i", str(WORK / "une-lumiere-sous-les-lames-loop-48k24.wav"), "-c:a", "libvorbis", "-q:a", "7", "-metadata", "title=Une lumiere sous les lames", str(ASSET / "une-lumiere-sous-les-lames.ogg")], check=True)
    subprocess.run([ffmpeg, "-y", "-v", "error", "-i", str(wav), "-c:a", "libmp3lame", "-b:a", "320k", "-metadata", "title=Une lumiere sous les lames", str(DOC / "une-lumiere-sous-les-lames.mp3")], check=True)
    decoded, sr = sf.read(ASSET / "une-lumiere-sous-les-lames.ogg", dtype="float32", always_2d=True)
    assert sr == SR and len(decoded) == N and np.isfinite(decoded).all()
    assert float(np.max(np.abs(decoded))) < .99
    analysis = dict(duration_loop_seconds=LENGTH, duration_listening_seconds=len(preview)/SR,
                    sample_rate=SR, samples_loop=N, note_events=len(EVENTS),
                    peak_dbfs=float(20*np.log10(np.max(np.abs(decoded)))),
                    rms_dbfs=float(20*np.log10(np.sqrt(np.mean(decoded**2)))),
                    seam_step=float(np.max(np.abs(decoded[0]-decoded[-1]))),
                    max_sample_step=float(np.max(np.abs(np.diff(decoded, axis=0)))),
                    stereo_correlation=float(np.corrcoef(decoded.T)[0, 1]),
                    stem_master_gain_db=float(20*np.log10(gain)))
    loudness = subprocess.run([ffmpeg, "-hide_banner", "-i", str(ASSET / "une-lumiere-sous-les-lames.ogg"), "-af", "ebur128=peak=true", "-f", "null", "-"], capture_output=True, text=True, check=True).stderr
    (WORK / "loudness.txt").write_text(loudness)
    summary = loudness[loudness.rfind("Summary:"):]
    for field, pattern in [("integrated_lufs", r"I:\s+(-?[\d.]+) LUFS"), ("loudness_range_lu", r"LRA:\s+([\d.]+) LU"), ("true_peak_dbfs", r"Peak:\s+(-?[\d.]+) dBFS")]:
        analysis[field] = float(re.search(pattern, summary).group(1))
    (DOC / "audio-analysis.json").write_text(json.dumps(analysis, indent=2) + "\n")
    print(json.dumps(analysis, indent=2), flush=True)


if __name__ == "__main__":
    main()
