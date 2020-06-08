This is a command line tool for reproducing baseline experiments on public datasets using [Alpenglow](https://github.com/rpalovics/Alpenglow).

Usage
-----

Use `make` to download and preprocess datasets and run experiments. To get the list of available make targets, run `make help`.

Use the `common_plot` shell script to create a common cumulative DCG plot of the result of multiple models. The script will download data and run experiments as necessary. Run the script without parameters to get usage description.

The scripts assume that you have an existing [Alpenglow](https://github.com/rpalovics/Alpenglow) installation. To test availability of Alpenglow, run `make test`.

Available datasets:
* [MovieLens](https://grouplens.org/datasets/movielens/) 100k, 1M, 10M
* [Amazon review data](http://jmcauley.ucsd.edu/data/amazon/) Books, Movies\_and\_TV, CDs\_and\_Vinyl, Electronics
* [30M Last.fm](http://recsys.deib.polimi.it/30music-dataset/), where items can be tracks or artists.

All datasets are sorted in time, filtered for the first user-item interaction for each user-item pair, filtered for items that have a frequency of at least five. The datasets are available in two variants.
* In the _sameshuf_ variant the interactions having identical timestamps are ordered randomly.
* In the _fullshuf_ variant the complete list of the samples is shuffled, but the timestamps are kept in order. This way we generated a stationary time series.

Available models:
* [AsymmetricFactorExperiment](https://alpenglow.readthedocs.io/en/latest/alpenglow.experiments.html#module-alpenglow.experiments.AsymmetricFactorExperiment)
* [NearestNeighborExperiment](https://alpenglow.readthedocs.io/en/latest/alpenglow.experiments.html#module-alpenglow.experiments.NearestNeighborExperiment)
* [PopularityTimeframeExperiment](https://alpenglow.readthedocs.io/en/latest/alpenglow.experiments.html#module-alpenglow.experiments.PopularityTimeframeExperiment)
* [TransitionProbabilityExperiment](https://alpenglow.readthedocs.io/en/latest/alpenglow.experiments.html#module-alpenglow.experiments.TransitionProbabilityExperiment)
* [BatchFactorExperiment](https://alpenglow.readthedocs.io/en/latest/alpenglow.experiments.html#module-alpenglow.experiments.BatchFactorExperiment)
* [FactorExperiment](https://alpenglow.readthedocs.io/en/latest/alpenglow.experiments.html#module-alpenglow.experiments.FactorExperiment)
* [PopularityExperiment](https://alpenglow.readthedocs.io/en/latest/alpenglow.experiments.html#module-alpenglow.experiments.PopularityExperiment)
* [SvdppExperiment](https://alpenglow.readthedocs.io/en/latest/alpenglow.experiments.html#module-alpenglow.experiments.SvdppExperiment)

Note that experiments may take a while to run (days or weeks for some models). Use the mlens\_100k dataset for fast experimenting.

