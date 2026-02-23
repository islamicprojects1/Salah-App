# Android notification sounds

1. Put your .mp3 files in assets/sounds/
2. Run from project root: powershell -ExecutionPolicy Bypass -File copy_sounds_to_raw.ps1

Or copy manually (lowercase, no spaces):

From assets/sounds/          ->  Save as (in res/raw/)
----------------------------------------
fagrsoon.mp3                 ->  fagrsoon.mp3   (approaching Fajr)
zohrsoon.mp3                 ->  zohrsoon.mp3   (approaching Dhuhr)
asrsoon.mp3                  ->  asrsoon.mp3    (approaching Asr)
maghribsoon.mp3              ->  maghribsoon.mp3 (approaching Maghrib)
eshaasoon.mp3                ->  eshaasoon.mp3  (approaching Isha)
Takbir 1.mp3                 ->  takbir_1.mp3   (takbeer at prayer time)
athan.mp3                    ->  athan.mp3      (full adhan - optional)
