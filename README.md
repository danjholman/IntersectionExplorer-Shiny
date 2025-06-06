# IntersectionExplorer

**Author:** Daniel Holman (daniel.holman@sheffield.ac.uk)  
**Created:** June 2025  
**License:** MIT

---

##Acknowledgement
The starting point for this app was the code in the following paper for the interactive plot (Bell et al. 2024): https://doi.org/10.1016/j.socscimed.2024.116955
The code provided with this paper can also be used to generate the pred2 file which the app uses to generate the plots.


## Live Demo

You can try the app online here:  
[IntersectionExplorer on shinyapps.io](https://danielholman.shinyapps.io/app_v5/)

## Overview

IntersectionExplorer is an R/Shiny application that displays predicted SF-12 Physical Component Summary (PCS) scores over age, stratified by intersectional categories (generation, ethnicity, sex, NS-SEC).

Users can toggle which strata to include via four panels (“Generation,” “Ethnicity,” “Sex,” “NS-SEC”). When no strata are selected, faint gray lines appear for every intersection.

When filters are active, the selected intersection lines are overlaid in color.

## Features

- **Fixed axes.** The x-axis (age) and y-axis (PCS score) remain constant for easy comparison.
- **Faint background.** If no filters are selected, you see all intersections as light gray lines.
- **Dynamic filtering.** Four panels allow “All/None” toggles for generation, ethnicity, sex, and NS-SEC.
- **Tooltip.** Hovering over a colored line shows “Generation,” “Intersection,” and “Age.”
- **Custom upload.** Upload your own CSV with the same structure to replace the default data.
- **Minimal dependencies.** Only uses Shiny, ggplot2, plotly, dplyr, and haven.

## Potential Future Features

- Allow users to upload their own data files
- Let users “favorite” particular intersections so they’re always visible
- Add a statistics panel to summarize selected strata
- Show raw intersection counts on hover
- Extent to cross-sectional and other types of models

## Instructions
To be added - see above - use the code here to generate your own pred2 file: https://doi.org/10.1016/j.socscimed.2024.116955

## Contributing
Feel free to open issues or pull requests if you find bugs or want to add features (e.g. improved color palettes, performance optimizations, etc.).

If you adapt this code, please keep the header block at the top of app.R to maintain attribution.


---
