This requires a UNIX operating system (For starters, an Ubuntu Linux will do).

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
    From inside its folder (you should already be if you followed previous
    commands), you now need to run these commands in order to install the model:
    ```bash
    ./configure.sh -noerror
    make all
    ```

2. You will also need the inputs for the model. For now the basic inputs
    can be downloaded from
    [here](https://saco.csic.es/s/nrJ3JGPZyZeQMW8?path=%2FData).
    You have to download the `LPJmL5-real-inputs` folder (you should get a
    `LPJmL5-real-inputs.zip` file download) and add it as a subfolder called
    `inputs` inside the `LPJmL` model folder you got in previous step. You can
    use the command:
    ```bash
    unzip ~/Downloads/LPJmL5-real-inputs.zip -d ~/LPJmL/ && mv LPJmL5-real-inputs inputs
    ```

3. The model is best run concurrently, i.e., using more than one core
    of your CPU. You can still run only on one core by setting the number of
    cores, but by default the code will need anyway a program called `mpirun`
    to work. You can install everything with the command:
    ```bash
    sudo apt-get install openmpi-bin libopenmpi-dev
    ```

4. The previous steps were preparations for the actual raw `C` language model.
    The `R` package `lpjmlkit` allows running the model a bit easier from `R`,
    but internally it runs the model you downloaded and installed before. For
    running the helper scripts found here, you can first get all the
    dependencies easily by using `renv`. When you open your R session in this
    folder, you can just do `renv::restore()` and you should be ready. If you
    don't know about using `renv` you can check
    [my guide](https://eduaguilera.github.io/WHEP/articles/workflow-intro.html#virtual-environments-with-renv).


5. The code to run the model using the `lpjmlkit` package and get an idea of how
    to configure it further to your needs is found in `lpjmlkit.R`. It takes as
    default config the one found in the LPJmL model folder in `lpjml_config.cjson`,
    which already includes things like our own input files paths (if you cloned my
    fork instead of the official one). This default config can be overwritten, and
    examples can be seen in `lpjmlkit.R`.

6. The outputs of the model can also be customized. I haven't done this yet, but
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
