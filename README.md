You will need a local LPJmL model installation. You can clone from the
[official LPJmL repository](https://github.com/PIK-LPJmL/LPJmL) or from
[my fork](https://github.com/lbm364dl/LPJmL) (which has some custom config
for our needs).

You will also need the inputs for the model. For now the basic inputs
can be downloaded from [here](https://saco.csic.es/s/nrJ3JGPZyZeQMW8?path=%2FData).
You have to download the `LPJmL5-real-inputs` folder and add it as a subfolder called
`inputs` inside the `LPJmL` model folder you got from Github.

You can get all the dependencies of this code easily by using `renv`. When
you open your R session in this folder, you can just do `renv::restore()` and
you're ready. If you don't know about using `renv` you can check
[my guide](https://eduaguilera.github.io/WHEP/articles/workflow-intro.html#virtual-environments-with-renv).

The code to run the model using the `lpjmlkit` package and get an idea of how
to configure it further to your needs is found in `lpjmlkit.R`. It takes as a
default the config found in the LPJmL model folder in `lpjml_config.cjson`,
which already includes things like our own input files paths (if you cloned my
fork instead of the official one). This default config can be overwritten, and
examples can be seen in `lpjmlkit.R`.

The outputs of the model can also be customized. I haven't done this yet, but
you will get the default output results in a folder called `simulation` inside
the `LPJmL` folder. We can then read and play with these NetCDF outputs (see
`read_output.R`).

