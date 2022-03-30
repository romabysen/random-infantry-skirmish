from datetime import datetime
import shutil
import glob
import os
import subprocess
import json
import time
import sys
import re
from PIL import Image
from utils import buildPreview

ADDON_BUILDER = 'c:\\Program Files (x86)\\Steam\\steamapps\\common\\Arma 3 Tools\\AddonBuilder\\AddonBuilder.exe'
PUBLISHER = "c:\\Users\\KaKa\\source\\repos\\A3MissionPublisher\\A3MissionPublisher\\bin\\x64\\Release\\net6.0\\A3MissionPublisher.exe"

risPath = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
missionsPath = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "RIS-Build.%s"))
includePath = os.path.join(os.path.dirname(__file__), "include.txt")
resultsPath = os.path.join(os.path.dirname(__file__), "..", "..", "RIS-Addons")
dataPath = os.path.join(os.path.dirname(__file__), "data")
workshopDataPath = os.path.join(resultsPath, "workshopItem.json")
descriptionPath = os.path.join(dataPath, "info", "description.txt")
changelogPath = os.path.join(dataPath, "info", "changelog.txt")
idsPath = os.path.join(os.path.dirname(__file__), 'ids.json')
previewsPath = os.path.join(dataPath, "images")
logoOverlayPath = os.path.join(dataPath, "info", "logo-overlay.png")
previewTempPath = os.path.abspath(os.path.join(resultsPath, "preview.png"))

ids = {}

if os.path.exists(idsPath):
  with open(idsPath, 'r') as f:
    ids = json.load(f)

logoOverlay = Image.open(logoOverlayPath)

for variant in glob.glob(os.path.join(risPath, ".templates", "*.sqm")):
  island = os.path.splitext(os.path.basename(variant))[0]
  missionPath = missionsPath % island
  resultPath = os.path.abspath(os.path.join(resultsPath, "RIS-Build.%s.pbo" % island))
  previewPath = os.path.join(previewsPath, "%s.jpg" % island)
  missionTitle = "Random Skirmish - %s" % island
  uploadPreview = False

  if (island != "isladuala3"):
    continue

  if os.path.exists(missionPath):
    shutil.rmtree(missionPath)

  shutil.copytree(risPath, missionPath, ignore=shutil.ignore_patterns('.*', 'mission.sqm'))
  shutil.copyfile(variant, os.path.join(missionPath, 'mission.sqm'))

  with open(os.path.join(missionPath, 'mission.sqm'), 'r') as f:
    data = f.read()
    missionTitle = re.search("briefingName=\"([^\"]*)\"", data)[1]

  with open(os.path.join(missionPath, 'variables.sqf'), 'r') as f:
    variablesSqf = f.read()

  if os.path.exists(previewPath):
    title = missionTitle.split(' - ')[1]

    previewImage = buildPreview(Image.open(previewPath), logoOverlay, title)
    previewImage.save(previewTempPath)

    uploadPreview = True
    sys.exit(1)

  with open(os.path.join(missionPath, 'config.cpp'), 'w') as f:
    f.write("""class cfgMods
{
	author="";
	timepacked="%s";
};
""" % str(round(time.time())))
  
  with open(os.path.join(missionPath, 'variables.sqf'), 'w') as f:
    variablesSqf = f.write(variablesSqf.replace(
      'RSTF_DEBUG = true;',
      'RSTF_DEBUG = false;'
    ))

    subprocess.check_call(
      [ADDON_BUILDER, missionPath, resultsPath, "-include=%s" % includePath],
      stdout=subprocess.DEVNULL
    )

  with open(workshopDataPath, 'w') as f:
    json.dump({
      "id": ids[island] if island in ids else 0,
	    "tags": ["multiplayer","singleplayer","infantry","coop","vehicles","scenario","dependency","air","altis" if island == 'Altis' else 'othermap',"tag review"],
      "title": missionTitle,
      "descriptionFile": descriptionPath,
      "previewImageFile": previewTempPath if uploadPreview else None,
      "changelogFile": changelogPath,
      "contentFile": resultPath
    }, f, indent = 2)

  output = subprocess.check_output(
    [PUBLISHER, workshopDataPath]
  ).decode('utf-8').strip()

  print(output)

  match = re.search("ID = ([0-9]+)", output)

  if match:
    newId = int(match[1])
    ids[island] = newId

    with open(idsPath, "w") as f:
      json.dump(ids, f, indent=2)

  sys.exit(1)


