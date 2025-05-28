This requires a UNIX operating system (For starters, an Ubuntu Linux will do).
If you are on Windows, you can also use WSL (Windows Subsystem for Linux).
I don't explain here how to install it, but you can follow the official
[Microsoft guide](https://learn.microsoft.com/en-us/windows/wsl/install).

1. You will need a local LPJmL model installation. You can clone from the
    [official LPJmL repository](https://github.com/PIK-LPJmL/LPJmL) or from
    [my fork](https://github.com/lbm364dl/LPJmL) (which has some custom config
    for our needs). You can run the following commands to get the model project
    in your home folder, in a folder called LPJmL:
    ```bash
    cd
    git clone https://github.com/lbm364dl/LPJmL
    cd LPJmL
    ```
    Before installing the model, you might need some operating system
    dependencies. For that, run the following command to install them (at
    least these were the ones I needed):
    ```
    sudo apt-get install libjson-c-dev libnetcdf-dev libudunits2-dev
    ```
    From inside the model's folder (you should already be if you followed
    previous commands), you now need to run these commands in order to install
    the model:
    ```bash
    ./configure.sh -noerror
    make all
    ```

2. You will also need the inputs for the model. For now the basic inputs
    can be downloaded from
    [here](https://saco.csic.es/s/nrJ3JGPZyZeQMW8?path=%2FData).
    You have to download the `LPJmL5-real-inputs` folder (you should get a
    `LPJmL5-real-inputs.zip` file download) and add it as a subfolder called
    `inputs` inside the `LPJmL` model folder you got in previous step. After
    downloading, you can do this from the terminal. First make sure you have
    `unzip` installed:
    ```bash
    sudo apt-get install unzip
    ```
    You can now use this command if you are on Linux:
    ```bash
    unzip ~/Downloads/LPJmL5-real-inputs.zip -d ~/LPJmL/ && mv LPJmL5-real-inputs inputs
    ```
    If you are on WSL, you can also get the zip downloaded on Windows directly
    to Linux (note the place we get the file from in the command, change
    username to your user in Windows):
    ```bash
    unzip /mnt/c/Users/username/Downloads/LPJmL5-real-inputs.zip -d ~/LPJmL/ && mv LPJmL5-real-inputs inputs
    ```
    In the previous command, if you don't know your Windows username you can
    find it by using the command
    ```bash
    powershell.exe '$env:UserName'
    ```

3. The model is best run concurrently, i.e., using more than one core
    of your CPU. You can still run only on one core by setting the number of
    cores, but by default the code will need anyway a program called `mpirun`
    to work. You can install everything with the command:
    ```bash
    sudo apt-get install openmpi-bin libopenmpi-dev
    ```

4. Install R. There are ways to do this in a terminal. The cleanest way for
    me is to use [`rig`](https://github.com/r-lib/rig), an R version manager,
    which allows an easy installation of new versions and also switching
    between them if needed. It can be installed with these commands (copied
    from the previous link):
    ```
    `which sudo` curl -L https://rig.r-pkg.org/deb/rig.gpg -o /etc/apt/trusted.gpg.d/rig.gpg
    `which sudo` sh -c 'echo "deb http://rig.r-pkg.org/deb rig main" > /etc/apt/sources.list.d/rig.list'
    `which sudo` apt update
    `which sudo` apt install r-rig
    ```
    Now installing the latest R version is as easy as this:
    ```
    rig add release
    ```
    If you realized this tool is extremely useful, you can learn more from
    their page (previous link).

5. The previous steps were preparations for the actual raw `C` language model.
    The `R` package `lpjmlkit` allows running the model a bit easier from `R`,
    but internally it runs the model you downloaded and installed before. For
    running the helper scripts found here, you can first get all the
    dependencies easily by using `renv`. First make sure to install some
    dependencies for `terra` R package:
    ```bash
    sudo apt-get install gdal-bin libgdal-dev
    ```
    Now, you can open your R session in this folder with the command
    ```bash
    R
    ```
    You can now just do `renv::restore()` and you should be ready. If you
    don't know about using `renv` you can check
    [my guide](https://eduaguilera.github.io/WHEP/articles/workflow-intro.html#virtual-environments-with-renv).


6. The code to run the model using the `lpjmlkit` package and get an idea of
    how to configure it further to your needs is found in `lpjmlkit.R`. It
    takes as default config the one found in the LPJmL model folder in
    `lpjml_config.cjson`, which already includes things like our own input
    files paths (if you cloned my fork instead of the official one). This
    default config can be overwritten, and examples can be seen in
    `lpjmlkit.R`. From the R session, you can run by doing
    ```
    source("lpjmlkit.R")
    ```
    If you are on WSL and you want to use Rstudio, you can't easily use the
    Rstudio Desktop installed on your Windows. Instead, you should install
    another one in WSL itself:
    ```bash
    curl -o rstudio.deb https://download1.rstudio.org/electron/jammy/amd64/rstudio-2025.05.0-496-amd64.deb
    sudo dpkg -i rstudio.deb
    sudo apt-get -f install
    ```
    You can open it from the terminal with the command:
    ```bash
    rstudio
    ```
    After doing this once, you should probably find a shorcut on your Windows
    if you search apps. The name should be something like
    `Rstudio (Ubuntu-24.04)`, as opposed to the usual `Rstudio` (if you also
    had it installed on Windows). From here on, you are probably safe to just
    open that, since Rstudio's terminal will be default also be the WSL
    terminal there.

7. The outputs of the model can also be customized. I haven't done this yet, but
    you will get the default output results in a folder called `simulation` inside
    the `LPJmL` folder. We can then read and play with these NetCDF outputs (see
    `read_output.R`).

There is still a lot to experiment with. If you want to try other config tweaks,
I suggest going through the files `lpjml_config.cjson` and `input.cjson`, and
all those in the `par` folder. All of them are in the `LPJmL` model folder.

You can also read more about the `lpjmlkit` package itself in their two
vignettes, which you can access writing in R:
```r
vignette("lpjml-runner")
vignette("lpjml-data")
```
