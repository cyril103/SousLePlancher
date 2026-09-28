"""Build the underfloor Foley palette and an audition montage.
Uses requirements-music.txt. Original processing + credited CC0 recordings.
Raw downloads stay in artifacts/foley-source; no whole bank is shipped.
"""
from pathlib import Path
import hashlib
import io
import json
import math
import re
import subprocess
import urllib.request
import zipfile

import imageio_ffmpeg
import numpy as np
from scipy import signal
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "artifacts/foley-source"
OUT = ROOT / "assets/audio/ambience"
DOC = ROOT / "docs/conception/soundscape-v01"
SR = 48000
RNG = np.random.default_rng(55001)
SOURCES = {
    "creak": "https://freesound.org/people/Rudmer_Rotteveel/sounds/502505/",
    "saw": "https://freesound.org/people/Mateusz_Chenc/sounds/519661/",
    "fire": "https://freesound.org/people/florianreichelt/sounds/563766/",
}
ZIP_URL = "https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip"
MANIFEST = {"sources": {}, "files": {}}
BANK = {}


def download(url, dest):
    if not dest.exists():
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        dest.write_bytes(urllib.request.urlopen(req, timeout=60).read())
    return dest


def read(source):
    x, sr = sf.read(source, dtype="float32", always_2d=True)
    x = x.mean(axis=1)
    if sr != SR:
        g = math.gcd(sr, SR)
        x = signal.resample_poly(x, SR//g, sr//g)
    return x


def filtered(x, low=45, high=9000):
    return signal.sosfilt(signal.butter(2, [low, high], "bandpass", fs=SR, output="sos"), x).astype(np.float32)


def pitch(x, ratio):
    up, down = 1000, round(ratio * 1000)
    return signal.resample_poly(x, up, down).astype(np.float32)


def mix(*layers):
    result = np.zeros(max(len(x) for x in layers), np.float32)
    for x in layers: result[:len(x)] += x
    return result


def trim(x):
    active = np.flatnonzero(abs(x) > max(np.max(abs(x)) * .008, .00002))
    if active.size: x = x[max(0, active[0]-240):min(len(x), active[-1]+2400)]
    return x


def save(group, index, x, provenance, loop=False, peak=.56):
    if not loop: x = trim(x)
    x = np.asarray(x, np.float32)
    x -= x.mean()
    if not loop:
        fade = min(int(.008*SR), len(x)//4)
        x[:fade] *= np.linspace(0, 1, fade)
        x[-fade:] *= np.linspace(1, 0, fade)
    x *= peak / max(.0001, np.max(abs(x)))
    name = f"{group}_{index:02d}.wav"
    sf.write(OUT / name, x, SR, subtype="PCM_16")
    BANK.setdefault(group, []).append(x)
    MANIFEST["files"][name] = {"group": group, "duration": len(x)/SR,
        "loop": loop, "sources": provenance, "peak_dbfs": float(20*np.log10(np.max(abs(x)))),
        "sha256": hashlib.sha256((OUT/name).read_bytes()).hexdigest()}


def circular_excerpt(x, duration):
    # Overlap the recorded end into the beginning, without a silent boundary.
    n, overlap = round(duration*SR), SR
    if len(x) < n + overlap: x = np.tile(x, math.ceil((n+overlap)/len(x)))
    y = x[:n].copy()
    blend = np.linspace(0, 1, overlap)
    y[:overlap] = x[n:n+overlap] * (1-blend) + y[:overlap] * blend
    return y


def main():
    for path in (CACHE, OUT, DOC): path.mkdir(parents=True, exist_ok=True)
    (ROOT / "artifacts/.gdignore").touch()
    (DOC / ".gdignore").touch()
    previous = DOC / "source-manifest.json"
    known = json.loads(previous.read_text()) if previous.exists() else {"sources": {}}
    recordings = {}
    for key, page in SOURCES.items():
        if key in known["sources"]:
            info = known["sources"][key]
        else:
            html = urllib.request.urlopen(urllib.request.Request(page, headers={"User-Agent": "Mozilla/5.0"})).read().decode()
            assert "creativecommons.org/publicdomain/zero/1.0" in html
            url = re.search(r'data-static-file-url="([^"]+)"', html).group(1)
            info = {"page": page, "download": url, "license": "CC0-1.0", "format": "public HQ MP3 preview"}
        raw = download(info["download"], CACHE / f"{key}.mp3")
        digest = hashlib.sha256(raw.read_bytes()).hexdigest()
        if "sha256" in info: assert digest == info["sha256"]
        info["sha256"] = digest
        MANIFEST["sources"][key] = info
        recordings[key] = read(raw)
    archive = download(ZIP_URL, CACHE / "kenney-impact.zip")
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    if "kenney" in known["sources"]: assert digest == known["sources"]["kenney"]["sha256"]
    MANIFEST["sources"]["kenney"] = {"page": "https://kenney.nl/assets/impact-sounds", "download": ZIP_URL, "license": "CC0-1.0", "sha256": digest}
    bank = zipfile.ZipFile(archive)
    license_text = bank.read("License.txt").decode("utf-8")
    (OUT / "Kenney-LICENSE.txt").write_text("\n".join(line.rstrip() for line in license_text.splitlines()).strip()+"\n", encoding="utf-8")
    def source(name): return read(io.BytesIO(bank.read("Audio/" + name + ".ogg")))
    for i in range(5):
        step = source(f"footstep_wood_{i:03d}")
        heavy = source(f"impactWood_heavy_{i:03d}")
        light = source(f"impactWood_light_{i:03d}")
        metal = source(f"impactTin_medium_{i:03d}")
        carpet = source(f"footstep_carpet_{i:03d}")
        grass = source(f"footstep_grass_{i:03d}")
        # Low body resonance is added to recorded impacts, not used as a substitute.
        t = np.arange(SR*.65)/SR
        body = .12*np.sin(2*np.pi*(62-i*2)*t)*np.exp(-t*10)*(1-np.exp(-t*150))
        save("giant", i, filtered(mix(pitch(step,.73), pitch(heavy,.63)*.45, body), 28, 1300), ["kenney", "original body resonance"], peak=.7)
        save("step", i, filtered(mix(pitch(step,1.3)*.22, carpet*.65), 180, 6500), ["kenney"], peak=.32)
        save("hammer", i, filtered(mix(light, metal*.12), 110, 8000), ["kenney"], peak=.50)
        save("crate", i, filtered(mix(source(f"impactWood_medium_{i:03d}"), source(f"impactPlank_medium_{i:03d}")*.35), 85, 6500), ["kenney"], peak=.48)
        save("fiber", i, filtered(mix(pitch(carpet,.8)*.6, grass*.25), 250, 7000), ["kenney"], peak=.3)
        save("crumb", i, filtered(mix(pitch(grass,1.4)*.65, source(f"impactSoft_medium_{i:03d}")*.3), 220, 7500), ["kenney"], peak=.3)
        save("creak", i, filtered(pitch(recordings["creak"], .7+i*.085), 75, 4300), ["creak"], peak=.45)
    for i in range(3):
        x = recordings["saw"][int((.2+i*.9)*SR):int((1+i*.9)*SR)]
        save("scrape", i, filtered(x,180,5500), ["saw"], peak=.36)
        # Original water-in-a-thimble design: several damped, falling resonances.
        x = np.zeros(SR, np.float32)
        for at in [0., .12, .29, .54]:
            t = np.arange(int(SR*.35))/SR
            f = RNG.uniform(950,1900)
            chirp = np.sin(2*np.pi*(f*t-420*t*t))*np.exp(-t*23)*np.minimum(t/.002,1)
            k = int((at+RNG.uniform(0,.02))*SR)
            x[k:k+len(chirp)] += chirp*.12
        save("water", i, filtered(x, 350, 5500), ["original procedural droplets"], peak=.30)
    save("door", 0, filtered(pitch(recordings["creak"],1.35),170,6000), ["creak"], peak=.30)
    save("door", 1, filtered(pitch(recordings["creak"],1.12),170,6000), ["creak"], peak=.30)
    fire = filtered(recordings["fire"][SR*4:], 190, 6800)
    save("fire", 0, circular_excerpt(fire,23), ["fire"], loop=True, peak=.22)
    # Quiet air pressure with very slow variation, no identifiable modern appliance.
    n = SR*41
    noise = RNG.normal(0,1,n)
    room = filtered(noise,45,470)
    t = np.arange(n)/SR
    room *= .75+.12*np.sin(t*.43)+.08*np.sin(t*.19)
    save("room", 0, circular_excerpt(room,40), ["original filtered air synthesis"], loop=True, peak=.12)
    (DOC / "source-manifest.json").write_text(json.dumps(MANIFEST,indent=2)+"\n", encoding="utf-8")

    # Audition montage only: the game schedules these samples from actual actions.
    demo = np.zeros((SR*45,2),np.float32)
    def place(group, index, at, level=1., pan=0.):
        x = BANK[group][index % len(BANK[group])]
        at = round(at*SR)
        count = min(len(x), len(demo)-at)
        if count<=0: return
        demo[at:at+count,0] += x[:count]*level*math.cos((pan+1)*np.pi/4)
        demo[at:at+count,1] += x[:count]*level*math.sin((pan+1)*np.pi/4)
    for at in (0,40): place("room",0,at,.30)
    for at in (0,23): place("fire",0,at,.11,-.45)
    place("creak",0,2,.35,.6)
    for i in range(12): place("step",i,4+i*.53,.3,-.7+i*.11)
    place("door",0,9,.35,-.4)
    for i in range(9): place("hammer",i,11+i*.66,.5,-.38)
    place("scrape",0,14,.45,.45)
    place("scrape",1,16,.45,.45)
    place("crate",2,18,.6,.15)
    place("fiber",1,19,.6,-.45)
    place("water",0,20,.5,.4)
    for i in range(12):
        place("giant",i,23+i*.78,.66,-.8+i*.135)
        if i%2==0: place("creak",i,23.16+i*.78,.52,-.8+i*.135)
    for i in range(9): place("step",i,35+i*.48,.25,.5-i*.1)
    place("crate",3,40,.45,-.4)
    place("creak",3,42,.25,.6)
    demo[:SR] *= np.linspace(0,1,SR)[:,None]
    demo[-SR*2:] *= np.linspace(1,0,SR*2)[:,None]
    demo *= min(1., .79/np.max(abs(demo)))
    wav = CACHE / "soundscape-audition.wav"
    sf.write(wav,demo,SR,subtype="PCM_24")
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),"-v","error","-y","-i",str(wav),"-c:a","libmp3lame","-b:a","256k",str(DOC/"sous-le-plancher-ambiance.mp3")],check=True)
    preview, rate = sf.read(DOC/"sous-le-plancher-ambiance.mp3")
    assert len(preview)/rate == 45 and np.max(abs(preview)) < .95
    report = {"preview_duration_seconds": len(preview)/rate, "preview_channels": preview.shape[1],
              "preview_peak_dbfs": round(float(20*np.log10(np.max(abs(preview)))),2),
              "runtime_assets": len(MANIFEST["files"]), "families": len(BANK)}
    (DOC/"audio-analysis.json").write_text(json.dumps(report,indent=2)+"\n")
    for name, info in MANIFEST["files"].items():
        x,sr=sf.read(OUT/name)
        assert sr==SR and np.isfinite(x).all() and np.max(abs(x))<.8
        if info["loop"]: assert abs(x[0]-x[-1])<.02, name
    print(f"{len(MANIFEST['files'])} assets, {len(BANK)} families, audition 45 seconds; peak and loop checks passed.")


if __name__ == "__main__": main()
