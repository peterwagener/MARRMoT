# MARRMoT
Modular Assessment of Rainfall-Runoff Models Toolbox - Matlab code for 47 conceptual hydrologic models.

<p align="center">
<img src="Figures/logo.jpg" alt="MARRMoT logo" width="200"/>
</p>
MARRMoT is a novel rainfall-runoff model comparison framework that allows objective comparison between different conceptual hydrological model structures.
The framework provides Matlab code for 47 unique model structures, standardized parameter ranges across all model structures and robust numerical implementation of each model.
The framework is provided with extensive documentation, a User Manual and several workflow scripts that give examples of how to use the framework.
MARRMoT is based around individual flux functions and aggregated model functions, allowing a wide range of possible applications.

If you have any questions about using or running the code, or are willing to contribute, please contact l.trotter[-at-] unimelb.edu.au or wouter.knoben[-at-]usask.ca

## MARRMoT v2
The MARRMoT master branch has been updated to version 2.1.1.
Main changes in MARRMoT v2 compared to v1 include code refactoring to rely on object-oriented programming and speed-ups in the model solving routines.
The paper describing these changes was peer reviewed and published in Geoscientific Model Development ([Trotter et al., 2022](https://doi.org/10.5194/gmd-15-6359-2022))

The last release of MARRMoT v1 is version 1.4 and can be found as a release here: [dx.doi.org/10.5281/zenodo.6460624](dx.doi.org/10.5281/zenodo.6460624)

### Changes since peer-review:
Since MARRMoT v2.1 was peer reviewed, the following minor changes to the code were implemented and included in the release of v2.1.1
- Edits to _my_cmaes_ to fix typos and improve clarity of outputs to screen
- Typos fixed in models _m_13_ and _m_28_
- Edits to _MARRMoT_model_ class to make model objects loadable
- Addition of new objective functions _of_MARE_ and _of_PCMARE_
- Updates to this _REAMDE_ file

## Getting Started
These instructions will help you install a copy of MARRMoT and run a few example cases. This process should be  straightforward and MARRMoT can (given some knowledge of Github and Matlab) be up and running in a matter of minutes.

### Requirements
MARRMoT has been developed on MATLAB version 9.11.0.1873467 (R2021b) and tested with Octave 6.4.0. To run in MATLAB, the Optimization Toolbox is required, while Octave requires the `optim` package.

Note that the function `circshift()` that is used by routing routines has markedly different behaviour in Matlab 2016b and higher compared to previous versions. Routing results will be unreliable in Matlab 2016a and below but will **_not_** generate any warnings or error messages. User discretion is advised.

### Install
To obtain the MARRMoT source code:
- `EITHER:` Download a copy of the files from this repository and extract the files in an appropriate directory;
- `OR:` (Optionally fork and) clone this repository onto your own machine.

Then:
- Open Matlab;
- Add the `MARRMoT` folder  and its subfolders `Functions`, `Models` and `User Manual` to the Matlab path (see image below; open the context menu by right-clicking the main MARRMoT folder inside the Matlab explorer window);

<p align="center">
<img src="Figures/matlab_path.jpg" alt="Example of adding files to Matlab path" width="250"/>
</p>

### Try an example application
With MARRMoT installed and Matlab open:
- Navigate Matlab's current folder to `./MARRMoT/User Manual`;
- Open the script `workflow_example_1.m`;
- Run the script by pressing F5 or clicking the `Run` button;
- Repeat with `workflow_example_2.m` and `workflow_example_3.m` (`workflow_example_4.m` shows a calibration example and takes a bit longer).

The User Manual provides further details.


## Documentation
MARRMoT's documentation includes:

- **New paper**: object-oriented implementation, changes from MARRMoT v1 to v2 ([Trotter et al., 2022](https://doi.org/10.5194/gmd-15-6359-2022))
- **Original paper**: rationale behind MARRMoT development, best practices used during development, summary of included model structures and an example application of all structures to simulate streamflow in a single catchment ([Knoben et al., 2019](https://doi.org/10.5194/gmd-12-2463-2019)).
- **User manual**: description on how to use MARRMoT v2.- and how to contribute to it.
- **User manual appendices**: detailed model descriptions (A), flux equations (B) and unit hydrographs (C)

User manual and appendices are found in this repository in `./MARRMoT/User manual`.

## Model structure summary
MARRMoT model structures are based on a wide variety of different models.
However, do to the standardised format of this framework, MARRMoT models resemble, but are not the same as the models they are based on.
In addition to a range of unnamed models, the following models provided inspiration for MARRMoT:

- FLEX-Topo
- IHACRES
- GR4J
- TOPMODEL
- SIMHYD
- VIC
- LASCAM
- TCM
- TANK
- XINANJIANG
- HYMOD
- SACRAMENTO
- MODHYDROLOG
- HBV-96
- MCRM
- SMAR
- NAM
- HYCYMODEL
- GSM-SOCONT
- ECHO
- PRMS
- CLASSIC
- IHM19

## License
MARRMoT is licensed under the GNU GPL v3 license - see the LICENSE file for details.

## DOIs of previous releases
- v2.1: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6484372.svg)](https://doi.org/10.5281/zenodo.6484372)
- v2.0: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6483914.svg)](https://doi.org/10.5281/zenodo.6483914)
- v1.4: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6460624.svg)](https://doi.org/10.5281/zenodo.6460624)
- v1.3: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3552961.svg)](https://doi.org/10.5281/zenodo.3552961)
- v1.2: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3235664.svg)](https://doi.org/10.5281/zenodo.3235664)
- v1.1: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.2677728.svg)](https://doi.org/10.5281/zenodo.2677728)
- v1.0: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.2482542.svg)](https://doi.org/10.5281/zenodo.2482542)

## Acknowledgements
MARRMoT could not have been made without the effort that many hydrologists have put into development of their models. Their effors are gratefully acknowledged. Special thanks are extended to:
- Philip Kraft for finding a bug in the flux smoothing code during peer review;
- Sebastian Gnann for suggesting various quality of life fixes;
- Clara Brandes for finding and suggesting a fix for a bug in the water balance calculations and implementing m47;
- Koen Jansen for suggesting various improvements and correcting parameter descriptions;
- Mustafa Kemal Türkeri for making workflow_example_4 operational in Octave; and for performing extensive testing of MARRMoT in Matlab and Octave;
- Thomas Wöhling for suggesting various additional efficiency metrics and a possible implementation for warmup periods;
- Hidde Drost for suggesting a way to clarify MARRMoT install instructions in this readme;
- Dongdong Kong for finding a few typos in the code foe m13 and m28.
