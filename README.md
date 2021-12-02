# MouseBrainRegions

## A tool to explore, visualize and export allen brain atlas region data

This is just a quick tool that allows you to inspect allen institute brain region data and export any combination of regions as .stl files to use in programs like blender for creating nice figures.

![top: all brain regions shown inside a hemisphere, bottom: selected regions and their created mesh](/githubReadmeFiles/figure.png)
Entire brain, select brain regions, and created mesh

## Setup

* You need to downlaoad the allen Region data. Download **"annotation" (P56_Mouse_annotation.zip)** from [Allen Mouse Brain Atlas API](http://help.brain-map.org/display/mousebrain/API) and put the annotation.raw inside into the allenData folder.

* [On the same site](http://help.brain-map.org/display/mousebrain/API) you can find a .xml file to look up the region ID numbers under **"Download structure expression values for the sagittal Pdyn SectionDataSet"**.

## Configuration

* Create a file regions.txt within the myRegions folder and fill it with arbitrary names for- and the specific ID numbers of your regions of interest. A regions.txt for showing regions A, B and C with their looked up IDs of 1001, 1002, and 1003 might look like this:

```
regionA, 1001
regionB, 1002
regionC, 1003
```

* Once run you will see a maximum intensity projection of your regions of interest in bright tones with all other regions colored in dark blue tones. These colors can be changed in the code to fit your preferences.

* Use `showAllRegions = true` to show all regions with random colors instead of reserving a brighter color pallette for only the regions within your regions.txt

* Please be aware that this program requires a large amount of memory. Rendering only one hemisphere with `hemisphere = true` already runs at \~27GB of memory. Use `hemisphere = false` for the entire brain. (This parameter does not affect the created/exported mesh, which will always contain your regions of interest in both hemispheres.)

## Usage

* Use `X, Y, Z` or `Shift + X, Y, Z` to move the 3D cursor and update the region ID found at its new position. Use `Ctrl` to move with higher speed.

* Press `E` to create and export a mesh of all current regions used in your regions.txt as a .stl file. You can find the created file in the exports folder.

* You can afterwards toggle to a on location preview of the created mesh by pressing `M`

* If you have set `showAllRegions = true` your export will cover the entire brain regardless of the content of your regions.txt file.

## Please Note

* There are small parts of the volume data that cannot be found in the lookup .xml file but should be part of structures noted there. For now anything missing can be checked by moving the 3D cursor over its position.