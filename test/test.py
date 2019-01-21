from alpenglow.experiments import PopularityExperiment
from alpenglow.evaluation import DcgScore
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

data = pd.read_csv("test/alpenglow_sample_dataset_1000")

experiment = PopularityExperiment(
    top_k=100,
    seed=254938879
)

rankings = experiment.run(data, verbose=False)
rankings['dcg'] = DcgScore(rankings)
day = 86400
averages = rankings['dcg'].groupby((rankings['time']-rankings['time'].min())//day).mean()
plt.plot(averages)
plt.savefig('test/plot.pdf')
