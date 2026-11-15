# Offline Map Storage for BenMajed Cockpit Launcher

## 1. Zero-Internet Offline Navigation Architecture
The launcher uses a high-performance offline raster/vector tile engine via `flutter_map` targeting `/sdcard/CarLauncher/maps/`.

### Directory Structure on Head Unit:
```
/sdcard/CarLauncher/maps/
  ├── {z}/
  │   ├── {x}/
  │   │   ├── {y}.png
```

## 2. Supported Regions & Tile Download
To load offline maps of the UAE (Ajman, Sharjah, Dubai, Abu Dhabi, UAQ, RAK, Fujairah):
1. Download OpenStreetMap or CartoDB Dark Matter offline tiles for zoom levels 10 to 16 using tools like MOBAC (Mobile Atlas Creator) or TileMill.
2. Connect your head-unit to USB or insert a FAT32/exFAT USB flash drive.
3. Place the extracted tile tree into `/sdcard/CarLauncher/maps/`.
4. The launcher automatically detects the folder and switches to 100% offline rendering without mobile data or Wi-Fi hotspot.
