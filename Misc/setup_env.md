# Setting Up Environment

This document presents steps for setting up an R environment with conda. Please note that Rstudio is not supporting Anaconda anymore. As a result, on RCE, in order to have the most updated R version with a fairly isolated environment, I would suggest using R interactive session instead of Rstudio. You can read more [here](https://community.rstudio.com/t/how-do-i-update-the-version-of-rstudio-in-anaconda/39799
). 


## RCE

Here are the steps for setting up your environment on RCE:

- Step 1: Request for a powershell terminal.

Using nomachine:
  - Select Applications tab
  - Select RCE Powered Applications
  - Select Anaconda Shell (Python 3.6) 5.2.0
  - Select required number of cores and RAM
 
This will open a terminal. 

- Step 2: Make sure that conda is installed. Run:

```S
which conda
```
If conda is installed, the command should return a pass. For example:

```S
/nfs/tools/lib/anaconda/3-5.2.0/bin/conda
```

- Step 3: Under your user account, create `.conda` folder. For example, my account name is `nak443` and my `.conda` folder is located in the following path:

```S
nfs/home/N/nak443/shared_space/ci3_nak443/.conda
```

- Step 4: Under the `.conda` folder, create `pkgs` and `envs` folders.
- Step 5: Export the path of these folders. In my case, it will be:

```S
export CONDA_PKGS_DIRS=/nfs/home/N/nak443/shared_space/ci3_nak443/.conda/pkgs
export CONDA_ENVS_PATH=/nfs/home/N/nak443/shared_space/ci3_nak443/.conda/envs
```

- Step 6: Create a recipe for environment. For example this is r_env_1.yaml file content. You can put the library version infront of the library name and make the environment more customized.

```S
name: r_env_1
channels:
  - conda-forge
dependencies:
  - r-base=4.1
  - r-tidyverse
  - r-devtools
  - r-xgboost
  - r-superlearner
  - r-earth
  - r-ranger
  - r-gam
  - r-kernsmooth
  - r-gnm
  - r-polycor
  - r-wcorr
  - r-rlang
  - r-glue
  - r-logger
  - r-cli
```

- Step 7: Create your environment. 

```S
conda env create -n r_env_1 -f r_env_1.yaml
```

- Step 7: Activate your environment.

```S
conda activate r_env_1
```

- Step 8: Start and R session.

```S
R
```

- Step 9: Install other packages. For example, I want to install CausalGPS from Github and develop version.

```r
library(devtools)
try(detach("package:CausalGPS", unload = TRUE), silent = TRUE) # if already you have the package, detach and unload it, to have a new install. 
install_github("fasrc/CausalGPS", ref="develop")
library(CausalGPS)
```

If some dependencies are not found, you can install it here, too. 

- Step 9: Now you can run your scripts. For example:

```r
source('profile_causalgps_1.R')

```

- Done!
