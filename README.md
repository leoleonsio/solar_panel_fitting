# Solar panel fitting

## Code
### main.sql
Before running, first run the other sql files to define the functions.

Main workflow:
- loads the data sample to the database
- does necessary preprocessing
- creates a sample (of a sample) solution in table `solution3d_sample`.

### generate_grid.sql
Generates a rectangular grid for the extent of some geometry. 
It is used to generate a grid for the currently processed roof surface.
The grid is meant to simulate solar panels.

#### Parameters:
- bound_polygon: geometry

The grid is generated for the extent of this geometry, to cover it entirely.
- x_step: float

Size of the x-dimension of the grid cell (solar panel width).
- y_step: float

Size of the y-dimension of the grid cell (solar panel height).
- srid: integer default 28992

SRID of the Coordinate Reference System

### panel_simulation.sql
Panel simulation runs for a single roof surface.
It generates a 2D grid of panels for the roof surface extent using the `generate_grid` function.
Then it iteratively transforms the grid (rotate, translate) and in each iteration it counts how many roof panels were fitted.
The configuration with the biggest number of panels is selected in the end as the best solution.

#### Parameters:
- roof_surface: geometry

Geometry of the surface for which the simulation is run.
- x_size: float

Width of the solar panel in meters.
- y_size: float

Height of the solar panel in meters.
- margin: float

Margin from the roof edge in meters. 
This means that none of the panels in the resulting configuration will ever be closer to the edge of the rooftop than this value.

### to3d.sql
Elevates the vertices of a given 2D geometry to the plane of the other given 3D geometry.
Used to transform the final solution to 3D, since the simulation is run in 2D.
#### Parameters:
- panels: geometry

A grid of panels that will be elevated from 2D to 3D.
- roof_surface: geometry

The reference plane to which the panels will be elevated.


## Data
`roofs.csv` is a subset of 3D roofsurface data for a selected area.


## Limitations
PostGIS is not really well suited for processing 3D geometries.
This solution for solar panel fitting has a slight error in the method.
It conducts the simulation in 2D for a given size of the panels and then 
projects the solution to 3D afterwards, 
which means that the panel size is slightly distorted if the roof surface is not completely flat.
A similar functionality could be implemented in C++ with better results and performance.
