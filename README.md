# MATLAB R2022a program for the Brownian model of the interaction between a microtubule and a protein with a linker region, such as the NDC80 complex

## Overview

These files allow for:

- Running a set of simulations for the model and determining the protein detachment times.
- Automatically analyzing the detachment time distribution (i.e., visualizing it and determining all of the quartile values).
- Calculating the most significant intramolecular angles at each time step and creating angle vs. time plots.
- Calculating the fraction of protein sites attached to the microtubule at each time step and creating an attachment state vs. time plot.
- Visualizing the protein movements in a video.

The simulation process can be started by running either `NDC80.m` or `RunNDC80.m`. 
`NDC80.m` allows for a seamless creation of plots and videos after the simulation process is finished, while `RunNDC80.m` makes it possible to perform simulations for different external force values in a single run.

---

## How to use the programs

### I. Add the files to the MATLAB path

Add the files in the folder to the MATLAB path.

### II. `Parameters.m`

- The `Parameters.m` function contains all of the model's parameter values, except for the external force value.
- To change a parameter value, make a corresponding edit to the parameter section of the file (lines 24 to 98).

> **Note:** After the initial run, the simulation conditions can be easily reproduced by running `NDC80.m` and choosing the "load a parameter file" option in the dialogue window.

---

## III. Start the simulation process

There are two ways to start the simulation process: running `NDC80.m` or `RunNDC80.m`.

### IIIa. `NDC80.m`

1. **Set the external force value**  
   - Define the desired value in `pN` on **line 19**.  
   - The sign of the force value determines the direction:  
     - Positive (+): force towards the plus end of the microtubule.  
     - Negative (-): force towards the minus end of the microtubule.

2. **Start the program**  
   - A folder will be created for simulation results (`Results <force value>`).  
   - If the folder already exists, you will be given three options:  
     - Overwrite the folder.  
     - Create a new folder with a different name.  
     - Stop the simulation.

3. **Parameter selection**  
   - Choose to use the parameters in `Parameters.m` or load a previously saved parameter file (`Technical0.mat`).

4. **Simulation execution**  
   - A wait bar will display the number of completed runs.

5. **Post-simulation analysis**  
   - The detachment time distribution is analyzed and plotted.  
   - Results are saved in `"Technical0.mat"` and a text file for easy viewing.

6. **Optional additional analysis**  
   - After the detachment time distribution is analyzed, the program prompts:  
     `"Would you like to continue analysis?"`  
   - If confirmed, the program generates:  
     - Angle vs. time plots.  
     - Attachment state vs. time plots.  
     - Protein movement videos.  

> **Note:** These visualizations can also be created separately by running the corresponding functions.

---

### IIIb. `RunNDC80.m`

1. **Set multiple force values**  
   - Enter desired force values as an array in **line 35**.  

2. **Start the program**  
   - A text file (`"! General Results.txt"`) will store summary results for all force values.  

3. **Simulation execution**  
   - The program runs through each force value sequentially.  
   - A folder is created for each force value's results.

4. **Post-simulation analysis**  
   - The detachment time distribution is analyzed for each force value.  
   - Results are saved in individual folders and in the general results file.

5. **Program completion**  
   - Stops after processing all force values.  
   - Additional plots and movies can be created separately.

---

## IV. `Survival.m`

- Analyzes the detachment time distribution from simulation results.
- Usually runs automatically in `NDC80.m` and `RunNDC80.m`.
- If needed, it can be run manually to analyze existing results:
  1. Ensure all MATLAB Data files are in the same directory.
  2. Run `Survival.m`, select the directory, and choose `"Technical0.mat"`.
  3. The function calculates quartiles, plots data, and saves results.

---

## V. Additional visualization functions

### `AngleGraphs.m`
- Calculates the most significant intramolecular angles at each time step.
- Generates **angle vs. time** plots.

### `AttachmentGraphs.m`
- Calculates the fraction of protein sites attached to the microtubule.
- Generates **attachment state vs. time** plots.

### `Movies.m`
- Creates **videos** visualizing protein movements during simulations.

### Running visualization functions
1. Ensure MATLAB Data files are in the same directory.
2. Run the desired function (`AngleGraphs.m`, `AttachmentGraphs.m`, or `Movies.m`).
3. Select `"Technical0.mat"` when prompted.
4. Choose simulations for visualization.
5. Generated plots/videos are saved in the same directory.

> **Note:** `Movies.m` requires additional time to generate videos.  
> Do not close, resize, or minimize the figure window while it records.

---

## Output files

### General results
- `"! General Results.txt"` – Summary of detachment times for all force values.

### Simulation-specific results
All of these files are saved in separate folders created by the program:

- `"Parameters.txt"` – Parameter values used in the simulation.
- `"Technical0.mat"` – System parameters and general results (MATLAB Data format).
- `"Technical<N>.mat"` – Simulation step data (`<N>` is the simulation number).
- `"Survival.png"` – Survival function plot.
- `"Times.png"` – Detachment time vs. simulation number plot.
- `"Angles <N>.png"` – Angle vs. time plot (`<N>` is the simulation number).
- `"Attachments <N>.png"` – Attachment state vs. time plot.
- `"Dynamics <N>.avi"` – Video of protein movements.

---
