#List of available goals: ##
##
help : ## Prints this help.
	@fgrep "##" $(MAKEFILE_LIST) | grep -v fgrep | sed "s/:.*##/:/" | sed -r "s/^##?//"
test : ## Tests if Alpenglow is installed.
	python test/test.py
all : test movielens amazon 30M_lastfm ## Runs all experiments. Takes weeks to finish.
movielens : mlens_100k mlens_10m mlens_1m ## Runs experiments on MovieLens 100k, 1M and 10M datasets.
amazon : amazon_Books amazon_Electronics amazon_CDs_and_Vinyl amazon_Movies_and_TV ## Runs experiments on Amazon Books, Electronics, CDs_and_Vinyl and Movies_and_TV datasets.
30M_lastfm : 30M_lastfm_artist 30M_lastfm_track  ## Runs experiments on 30M Last.fm dataset.
##
#DATASET-VARIANT-MODEL : ## Runs MODEL experiment on VARIANT variant of DATASET dataset.
#DATASET-VARIANT : ## Runs each model on VARIANT variant of DATASET dataset. See available values below.
#DATASET : ## Runs each model on both variant of DATASET dataset. See available values below.
#MODEL : ## Runs MODEL on both variants of each dataset. See available values below.
#download-DATASET : ## Downloads and preprocesses DATASET dataset. See available values below.
##
#Available MODELs: ## AsymmetricFactorExperiment NearestNeighborExperiment PopularityTimeframeExperiment TransitionProbabilityExperiment BatchFactorExperiment FactorExperiment PopularityExperiment SvdppExperiment
#Available DATASETs: ## 30M_lastfm_artist 30M_lastfm_track amazon_Books amazon_Electronics amazon_CDs_and_Vinyl amazon_Movies_and_TV mlens_100k mlens_10m mlens_1m
#Available VARIANTS: ## sameshuf (samples having the same timestamp are shuffled), fullshuf (samples are shuffled)
##
##Each experiment creates a time-DCG plot. To generate a common plot for different models, use the common_plot script.

datasets = 30M_lastfm/artist 30M_lastfm/track amazon/Books amazon/Electronics amazon/CDs_and_Vinyl amazon/Movies_and_TV mlens_100k mlens_10m mlens_1m
variants = sameshuf fullshuf
models = AsymmetricFactorExperiment NearestNeighborExperiment PopularityTimeframeExperiment TransitionProbabilityExperiment BatchFactorExperiment FactorExperiment PopularityExperiment SvdppExperiment

dataset_names = $(subst /,_,$(datasets))
.PHONY : test all movielens amazon 30M_lastfm $(dataset_names) $(variants) $(models) $(foreach dataset_name, $(dataset_names), $(foreach variant, $(variants), $(dataset_name)-$(variant)))

$(foreach dataset_name, $(dataset_names), \
  $(foreach variant, $(variants), \
    $(eval $(dataset_name) $(variant) : $(dataset_name)-$(variant)) \
  ) \
)
$(foreach dataset_name, $(dataset_names), \
  $(foreach variant, $(variants), \
    $(foreach model, $(models), \
      $(eval $(dataset_name)-$(variant) $(model) : $(dataset_name)-$(variant)-$(model)) \
    ) \
  ) \
)

define EXPERIMENT_RULE =
results/$(dataset)/scrobbles-$(variant)-first-5_item_filter-recoded/$(model)/%/output : data/$(dataset)/baseline_uniformed/scrobbles-$(variant)-first-5_item_filter-recoded
	python scripts/experiment.py json/$(subst /,_,$(dataset))-$(variant)-$(model).json
endef

$(foreach dataset, $(datasets), \
  $(foreach variant, $(variants), \
    $(foreach model, $(models), \
      $(eval $(EXPERIMENT_RULE)) \
    ) \
  ) \
)


#********************* DOWNLOAD DATASETS *******************************
#TODO: use local makefiles for datasets
.PHONY : download-30M_lastfm_artist
download-30M_lastfm_artist : data/30M_lastfm/artist/baseline_uniformed/orig_online_id 
data/30M_lastfm/artist/baseline_uniformed/orig_online_id : data/30M_lastfm/track/baseline_uniformed/orig_online_id data/30M_lastfm/entities/tracks.idomaar
	mkdir -p data/30M_lastfm/artist/baseline_uniformed
	cd data/30M_lastfm && \
	  cut -f"2,5" --output-delimiter=" " entities/tracks.idomaar | sed -r 's/ [^0-9]*([0-9]+)\}.*$$/ \1/' > track2artist && \
	  awk 'NR==FNR{map[$$1]=$$2;next} ($$3 in map){print $$1 " " $$2 " " map[$$3] " " $$4 " " $$5 " " $$6}' track2artist track/baseline_uniformed/orig_online_id > artist/baseline_uniformed/orig_online_id
.PHONY: download-30M_lastfm_track
download-30M_lastfm_track : data/30M_lastfm/track/baseline_uniformed/orig_online_id 
data/30M_lastfm/track/baseline_uniformed/orig_online_id : data/30M_lastfm/relations/events.idomaar
	mkdir -p data/30M_lastfm/track/baseline_uniformed
	cd data/30M_lastfm && \
	  cut -f"2,3,5" --output-delimiter=" " relations/events.idomaar | sed -r 's/[^0-9]*"id":([0-9]+)[^0-9]*( |$$)/ \1/g' | awk -F" " '{print $$2 " " $$3 " " $$4 " " $$1 " 1 x"}' | sort -n -S 30% -k1 > track/baseline_uniformed/orig_online_id
data/30M_lastfm/relations/events.idomaar data/30M_lastfm/entities/tracks.idomaar :
	mkdir -p data/30M_lastfm/
	cd data/30M_lastfm && \
	  wget -O ThirtyMusic.tar.gz -N https://polimi365-my.sharepoint.com/:u:/g/personal/10322330_polimi_it/Efbx_LL9CJNHq1625JuHe4UBQnGbRg1FHjLKU1EgmRhXwA?download=1 && \
	  echo "8589f5d102b82b23b8a37e722df5fbba  ThirtyMusic.tar.gz" > md5sum && \
	  md5sum -c md5sum  && \
	  tar -xzf ThirtyMusic.tar.gz
#  then
#    :
#  else
#    echo "Please download ThirtyMusic.tar.gz from"
#    echo "https://polimi365-my.sharepoint.com/:u:/g/personal/10322330_polimi_it/Efbx_LL9CJNHq1625JuHe4UBQnGbRg1FHjLKU1EgmRhXwA?e=4xKcOs"
#    echo "and put it into $(pwd) then rerun this script."
#    exit -1
#  fi
amazon_names = Books CDs_and_Vinyl Electronics Movies_and_TV
define AMAZON_DOWNLOAD =
#fields: user, item, score, timestamp
data/amazon/$(name)/ratings_$(name).csv :
	mkdir -p data/amazon/$(name)/
	cd data/amazon/$(name) && \
	  wget http://snap.stanford.edu/data/amazon/productGraph/categoryFiles/ratings_$(name).csv 

#fields: user, item, score, timestamp
.PHONY : download-amazon_$(name)
download-amazon_$(name) : data/amazon/$(name)/baseline_uniformed/orig_online_id 
data/amazon/$(name)/baseline_uniformed/orig_online_id : data/amazon/$(name)/ratings_$(name).csv
	mkdir -p data/amazon/$(name)/baseline_uniformed
	cd data/amazon/$(name) && \
	  nl -v0 -w1 -s"," ratings_$(name).csv | sort -n -t"," -k"5" | awk -F"," '{id=$$$$1;old_user=$$$$2;if(not (old_user in Users)){Users[old_user]=length(Users)}old_item=$$$$3;if(not (old_item in Items)){Items[old_item]=length(Items)}time=$$$$5;print time " " Users[old_user] " " Items[old_item] " " id " 1 x"}' > baseline_uniformed/orig_online_id
endef
$(foreach name, $(amazon_names), \
  $(eval $(AMAZON_DOWNLOAD)) \
)

define MOVIELENS_DOWNLOAD =
	$(eval datasetdir = $1)
        $(eval orig_name = $2)
	mkdir -p data/$(datasetdir)/baseline_uniformed/
	cd data/$(datasetdir)/ && \
	  wget http://files.grouplens.org/datasets/movielens/$(orig_name).zip && \
	  wget http://files.grouplens.org/datasets/movielens/$(orig_name).zip.md5 && \
	  md5sum -c $(orig_name).zip.md5 && \
	  unzip $(orig_name).zip
endef

data/mlens_100k/ml-100k/u.data :
	$(call MOVIELENS_DOWNLOAD,mlens_100k,ml-100k)
.PHONY : download-mlens_100k
download-mlens_100k : data/mlens_100k/baseline_uniformed/orig_online_id
data/mlens_100k/baseline_uniformed/orig_online_id : data/mlens_100k/ml-100k/u.data
	cd data/mlens_100k/ && \
	  nl -v0 -w1 ml-100k/u.data | sort -S 30% -n -k"5" | awk '{print $$5 " " $$2 " " $$3 " " $$1 " 1 x"}' > baseline_uniformed/orig_online_id
#fields: user id | item id | rating | timestamp (tab separated)

.PHONY : download-mlens_1m
download-mlens_1m : data/mlens_1m/baseline_uniformed/orig_online_id
data/mlens_1m/ml-1m/ratings.dat :
	$(call MOVIELENS_DOWNLOAD,mlens_1m,ml-1m)
data/mlens_1m/baseline_uniformed/orig_online_id : data/mlens_1m/ml-1m/ratings.dat
	cd data/mlens_1m/ && \
	  nl -v0 -w1 -s"::" ml-1m/ratings.dat | sort -S 30% -n -t":" -k"9" | awk -F"::" '{print $$5 " " $$2 " " $$3 " " $$1 " 1 x"}' > baseline_uniformed/orig_online_id

.PHONY : download-mlens_10m
download-mlens_10m : data/mlens_10m/baseline_uniformed/orig_online_id
data/mlens_10m/ml-10M100K/ratings.dat :
	$(call MOVIELENS_DOWNLOAD,mlens_10m,ml-10m)
data/mlens_10m/baseline_uniformed/orig_online_id : data/mlens_10m/ml-10M100K/ratings.dat
	cd data/mlens_10m/ && \
	  nl -v0 -w1 -s"::" ml-10M100K/ratings.dat | sort -S 30% -n -t":" -k"9" | awk -F"::" '{print $$5 " " $$2 " " $$3 " " $$1 " 1 x"}' > baseline_uniformed/orig_online_id

#******************************** PREPROCESS DATASETS **************************
.PRECIOUS: %/scrobbles %-sameshuf %-fullshuf %-first %-5_item_filter %-recoded
%/scrobbles : %/orig_online_id
	cut -d" " -f"1,2,3,4,5" $^ > $@ #removing eval field

random_key = 234235234
%-fullshuf : %
	python scripts/dataset_generator_scripts/shuf.py $^ $@ complete_online $(random_key)
%-sameshuf : %
	python scripts/dataset_generator_scripts/shuf.py $^ $@ same_timestamp $(random_key)
%-first : %
	python scripts/dataset_generator_scripts/first.py $^ $@
%-5_item_filter : %
	python scripts/dataset_generator_scripts/n_filter.py $^ $@ 5 item
%-10_item_filter : %
	python scripts/dataset_generator_scripts/n_filter.py $^ $@ 10 item
%-recoded : %
	mkdir -p `dirname $@`/doc/recode_maps
	python scripts/dataset_generator_scripts/recode.py $^ $@ `dirname $@`/doc/recode_maps/scrobbles-recoded-user_table `dirname $@`/doc/recode_maps/scrobbles-recoded-item_table

#******************************* auto-generated rules ****************************
30M_lastfm_artist-sameshuf-AsymmetricFactorExperiment : results/30M_lastfm/artist/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.15/output
30M_lastfm_artist-sameshuf-NearestNeighborExperiment : results/30M_lastfm/artist/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
30M_lastfm_artist-sameshuf-PopularityTimeframeExperiment : results/30M_lastfm/artist/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_604800/output
30M_lastfm_artist-sameshuf-TransitionProbabilityExperiment : results/30M_lastfm/artist/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
30M_lastfm_artist-sameshuf-BatchFactorExperiment : results/30M_lastfm/artist/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.01-negative_rate_30-number_of_iterations_30-period_length_604800/output
30M_lastfm_artist-sameshuf-FactorExperiment : results/30M_lastfm/artist/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.15/output
30M_lastfm_artist-sameshuf-PopularityExperiment : results/30M_lastfm/artist/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
30M_lastfm_artist-sameshuf-SvdppExperiment : results/30M_lastfm/artist/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
30M_lastfm_artist-fullshuf-AsymmetricFactorExperiment : results/30M_lastfm/artist/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/negative_rate/experiments/experiment-negative_rate_300/output
30M_lastfm_artist-fullshuf-NearestNeighborExperiment : results/30M_lastfm/artist/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
30M_lastfm_artist-fullshuf-PopularityTimeframeExperiment : results/30M_lastfm/artist/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
30M_lastfm_artist-fullshuf-TransitionProbabilityExperiment : results/30M_lastfm/artist/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
30M_lastfm_artist-fullshuf-BatchFactorExperiment : results/30M_lastfm/artist/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.03-negative_rate_30-number_of_iterations_30-period_length_604800/output
30M_lastfm_artist-fullshuf-FactorExperiment : results/30M_lastfm/artist/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
30M_lastfm_artist-fullshuf-PopularityExperiment : results/30M_lastfm/artist/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
30M_lastfm_artist-fullshuf-SvdppExperiment : results/30M_lastfm/artist/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/negative_rate-norm_type/experiments/experiment-negative_rate_300-norm_type_constant/output
30M_lastfm_track-sameshuf-AsymmetricFactorExperiment : results/30M_lastfm/track/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
30M_lastfm_track-sameshuf-NearestNeighborExperiment : results/30M_lastfm/track/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
30M_lastfm_track-sameshuf-PopularityTimeframeExperiment : results/30M_lastfm/track/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_604800/output
30M_lastfm_track-sameshuf-TransitionProbabilityExperiment : results/30M_lastfm/track/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
30M_lastfm_track-sameshuf-BatchFactorExperiment : results/30M_lastfm/track/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.01-negative_rate_30-number_of_iterations_30-period_length_604800/output
30M_lastfm_track-sameshuf-FactorExperiment : results/30M_lastfm/track/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
30M_lastfm_track-sameshuf-PopularityExperiment : results/30M_lastfm/track/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
30M_lastfm_track-sameshuf-SvdppExperiment : results/30M_lastfm/track/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
30M_lastfm_track-fullshuf-AsymmetricFactorExperiment : results/30M_lastfm/track/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
30M_lastfm_track-fullshuf-NearestNeighborExperiment : results/30M_lastfm/track/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
30M_lastfm_track-fullshuf-PopularityTimeframeExperiment : results/30M_lastfm/track/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
30M_lastfm_track-fullshuf-TransitionProbabilityExperiment : results/30M_lastfm/track/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
30M_lastfm_track-fullshuf-BatchFactorExperiment : results/30M_lastfm/track/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.03-negative_rate_30-number_of_iterations_30-period_length_604800/output
30M_lastfm_track-fullshuf-FactorExperiment : results/30M_lastfm/track/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
30M_lastfm_track-fullshuf-PopularityExperiment : results/30M_lastfm/track/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
30M_lastfm_track-fullshuf-SvdppExperiment : results/30M_lastfm/track/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate-norm_type/experiments/experiment-learning_rate_0.2-norm_type_constant/output
amazon_Books-sameshuf-AsymmetricFactorExperiment : results/amazon/Books/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/negative_rate/experiments/experiment-negative_rate_300/output
amazon_Books-sameshuf-NearestNeighborExperiment : results/amazon/Books/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
amazon_Books-sameshuf-PopularityTimeframeExperiment : results/amazon/Books/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_86400/output
amazon_Books-sameshuf-TransitionProbabilityExperiment : results/amazon/Books/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
amazon_Books-sameshuf-BatchFactorExperiment : results/amazon/Books/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length-period_mode/experiments/experiment-learning_rate_0.03-negative_rate_30-number_of_iterations_10-period_length_100000-period_mode_samplenum/output
amazon_Books-sameshuf-FactorExperiment : results/amazon/Books/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Books-sameshuf-PopularityExperiment : results/amazon/Books/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
amazon_Books-sameshuf-SvdppExperiment : results/amazon/Books/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Books-fullshuf-AsymmetricFactorExperiment : results/amazon/Books/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/negative_rate/experiments/experiment-negative_rate_300/output
amazon_Books-fullshuf-NearestNeighborExperiment : results/amazon/Books/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
amazon_Books-fullshuf-PopularityTimeframeExperiment : results/amazon/Books/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
amazon_Books-fullshuf-TransitionProbabilityExperiment : results/amazon/Books/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
amazon_Books-fullshuf-BatchFactorExperiment : results/amazon/Books/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length-period_mode/experiments/experiment-learning_rate_0.03-negative_rate_30-number_of_iterations_10-period_length_100000-period_mode_samplenum/output
amazon_Books-fullshuf-FactorExperiment : results/amazon/Books/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Books-fullshuf-PopularityExperiment : results/amazon/Books/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
amazon_Books-fullshuf-SvdppExperiment : results/amazon/Books/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate-norm_type/experiments/experiment-learning_rate_0.3-norm_type_constant/output
amazon_Electronics-sameshuf-AsymmetricFactorExperiment : results/amazon/Electronics/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.15/output
amazon_Electronics-sameshuf-NearestNeighborExperiment : results/amazon/Electronics/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
amazon_Electronics-sameshuf-PopularityTimeframeExperiment : results/amazon/Electronics/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_604800/output
amazon_Electronics-sameshuf-TransitionProbabilityExperiment : results/amazon/Electronics/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
amazon_Electronics-sameshuf-BatchFactorExperiment : results/amazon/Electronics/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length-period_mode/experiments/experiment-learning_rate_0.08-negative_rate_30-number_of_iterations_30-period_length_100000-period_mode_samplenum/output
amazon_Electronics-sameshuf-FactorExperiment : results/amazon/Electronics/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Electronics-sameshuf-PopularityExperiment : results/amazon/Electronics/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
amazon_Electronics-sameshuf-SvdppExperiment : results/amazon/Electronics/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Electronics-fullshuf-AsymmetricFactorExperiment : results/amazon/Electronics/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.15/output
amazon_Electronics-fullshuf-NearestNeighborExperiment : results/amazon/Electronics/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
amazon_Electronics-fullshuf-PopularityTimeframeExperiment : results/amazon/Electronics/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
amazon_Electronics-fullshuf-TransitionProbabilityExperiment : results/amazon/Electronics/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
amazon_Electronics-fullshuf-BatchFactorExperiment : results/amazon/Electronics/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length-period_mode/experiments/experiment-learning_rate_0.08-negative_rate_30-number_of_iterations_30-period_length_100000-period_mode_samplenum/output
amazon_Electronics-fullshuf-FactorExperiment : results/amazon/Electronics/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Electronics-fullshuf-PopularityExperiment : results/amazon/Electronics/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
amazon_Electronics-fullshuf-SvdppExperiment : results/amazon/Electronics/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate-norm_type/experiments/experiment-learning_rate_0.3-norm_type_constant/output
amazon_CDs_and_Vinyl-sameshuf-AsymmetricFactorExperiment : results/amazon/CDs_and_Vinyl/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_CDs_and_Vinyl-sameshuf-NearestNeighborExperiment : results/amazon/CDs_and_Vinyl/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
amazon_CDs_and_Vinyl-sameshuf-PopularityTimeframeExperiment : results/amazon/CDs_and_Vinyl/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_604800/output
amazon_CDs_and_Vinyl-sameshuf-TransitionProbabilityExperiment : results/amazon/CDs_and_Vinyl/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
amazon_CDs_and_Vinyl-sameshuf-BatchFactorExperiment : results/amazon/CDs_and_Vinyl/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length-period_mode/experiments/experiment-learning_rate_0.03-negative_rate_30-number_of_iterations_30-period_length_100000-period_mode_samplenum/output
amazon_CDs_and_Vinyl-sameshuf-FactorExperiment : results/amazon/CDs_and_Vinyl/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.4/output
amazon_CDs_and_Vinyl-sameshuf-PopularityExperiment : results/amazon/CDs_and_Vinyl/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
amazon_CDs_and_Vinyl-sameshuf-SvdppExperiment : results/amazon/CDs_and_Vinyl/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_CDs_and_Vinyl-fullshuf-AsymmetricFactorExperiment : results/amazon/CDs_and_Vinyl/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_CDs_and_Vinyl-fullshuf-NearestNeighborExperiment : results/amazon/CDs_and_Vinyl/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
amazon_CDs_and_Vinyl-fullshuf-PopularityTimeframeExperiment : results/amazon/CDs_and_Vinyl/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
amazon_CDs_and_Vinyl-fullshuf-TransitionProbabilityExperiment : results/amazon/CDs_and_Vinyl/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
amazon_CDs_and_Vinyl-fullshuf-BatchFactorExperiment : results/amazon/CDs_and_Vinyl/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length-period_mode/experiments/experiment-learning_rate_0.08-negative_rate_30-number_of_iterations_30-period_length_100000-period_mode_samplenum/output
amazon_CDs_and_Vinyl-fullshuf-FactorExperiment : results/amazon/CDs_and_Vinyl/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.4/output
amazon_CDs_and_Vinyl-fullshuf-PopularityExperiment : results/amazon/CDs_and_Vinyl/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
amazon_CDs_and_Vinyl-fullshuf-SvdppExperiment : results/amazon/CDs_and_Vinyl/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate-norm_type/experiments/experiment-learning_rate_0.3-norm_type_constant/output
amazon_Movies_and_TV-sameshuf-AsymmetricFactorExperiment : results/amazon/Movies_and_TV/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.15/output
amazon_Movies_and_TV-sameshuf-NearestNeighborExperiment : results/amazon/Movies_and_TV/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
amazon_Movies_and_TV-sameshuf-PopularityTimeframeExperiment : results/amazon/Movies_and_TV/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_604800/output
amazon_Movies_and_TV-sameshuf-TransitionProbabilityExperiment : results/amazon/Movies_and_TV/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
amazon_Movies_and_TV-sameshuf-BatchFactorExperiment : results/amazon/Movies_and_TV/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length-period_mode/experiments/experiment-learning_rate_0.03-negative_rate_30-number_of_iterations_10-period_length_100000-period_mode_samplenum/output
amazon_Movies_and_TV-sameshuf-FactorExperiment : results/amazon/Movies_and_TV/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Movies_and_TV-sameshuf-PopularityExperiment : results/amazon/Movies_and_TV/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
amazon_Movies_and_TV-sameshuf-SvdppExperiment : results/amazon/Movies_and_TV/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Movies_and_TV-fullshuf-AsymmetricFactorExperiment : results/amazon/Movies_and_TV/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
amazon_Movies_and_TV-fullshuf-NearestNeighborExperiment : results/amazon/Movies_and_TV/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
amazon_Movies_and_TV-fullshuf-PopularityTimeframeExperiment : results/amazon/Movies_and_TV/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
amazon_Movies_and_TV-fullshuf-TransitionProbabilityExperiment : results/amazon/Movies_and_TV/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
amazon_Movies_and_TV-fullshuf-BatchFactorExperiment : results/amazon/Movies_and_TV/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length-period_mode/experiments/experiment-learning_rate_0.08-negative_rate_30-number_of_iterations_30-period_length_100000-period_mode_samplenum/output
amazon_Movies_and_TV-fullshuf-FactorExperiment : results/amazon/Movies_and_TV/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
amazon_Movies_and_TV-fullshuf-PopularityExperiment : results/amazon/Movies_and_TV/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
amazon_Movies_and_TV-fullshuf-SvdppExperiment : results/amazon/Movies_and_TV/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate-norm_type/experiments/experiment-learning_rate_0.3-norm_type_constant/output
mlens_100k-sameshuf-AsymmetricFactorExperiment : results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
mlens_100k-sameshuf-NearestNeighborExperiment : results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
mlens_100k-sameshuf-PopularityTimeframeExperiment : results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
mlens_100k-sameshuf-TransitionProbabilityExperiment : results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
mlens_100k-sameshuf-BatchFactorExperiment : results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.01-negative_rate_30-number_of_iterations_10-period_length_604800/output
mlens_100k-sameshuf-FactorExperiment : results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
mlens_100k-sameshuf-PopularityExperiment : results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
mlens_100k-sameshuf-SvdppExperiment : results/mlens_100k/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.3/output
mlens_100k-fullshuf-AsymmetricFactorExperiment : results/mlens_100k/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
mlens_100k-fullshuf-NearestNeighborExperiment : results/mlens_100k/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
mlens_100k-fullshuf-PopularityTimeframeExperiment : results/mlens_100k/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
mlens_100k-fullshuf-TransitionProbabilityExperiment : results/mlens_100k/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
mlens_100k-fullshuf-BatchFactorExperiment : results/mlens_100k/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.03-negative_rate_30-number_of_iterations_30-period_length_604800/output
mlens_100k-fullshuf-FactorExperiment : results/mlens_100k/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
mlens_100k-fullshuf-PopularityExperiment : results/mlens_100k/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
mlens_100k-fullshuf-SvdppExperiment : results/mlens_100k/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate-norm_type/experiments/experiment-learning_rate_0.2-norm_type_constant/output
mlens_1m-sameshuf-AsymmetricFactorExperiment : results/mlens_1m/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.1/output
mlens_1m-sameshuf-NearestNeighborExperiment : results/mlens_1m/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
mlens_1m-sameshuf-PopularityTimeframeExperiment : results/mlens_1m/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
mlens_1m-sameshuf-TransitionProbabilityExperiment : results/mlens_1m/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
mlens_1m-sameshuf-BatchFactorExperiment : results/mlens_1m/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.01-negative_rate_30-number_of_iterations_3-period_length_604800/output
mlens_1m-sameshuf-FactorExperiment : results/mlens_1m/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
mlens_1m-sameshuf-PopularityExperiment : results/mlens_1m/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
mlens_1m-sameshuf-SvdppExperiment : results/mlens_1m/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.15/output
mlens_1m-fullshuf-AsymmetricFactorExperiment : results/mlens_1m/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/gamma/experiments/experiment-gamma_0.99/output
mlens_1m-fullshuf-NearestNeighborExperiment : results/mlens_1m/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/gamma-gamma_threshold/experiments/experiment-gamma_0.09-gamma_threshold_0.001/output
mlens_1m-fullshuf-PopularityTimeframeExperiment : results/mlens_1m/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
mlens_1m-fullshuf-TransitionProbabilityExperiment : results/mlens_1m/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
mlens_1m-fullshuf-BatchFactorExperiment : results/mlens_1m/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.01-negative_rate_30-number_of_iterations_30-period_length_604800/output
mlens_1m-fullshuf-FactorExperiment : results/mlens_1m/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.15/output
mlens_1m-fullshuf-PopularityExperiment : results/mlens_1m/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
mlens_1m-fullshuf-SvdppExperiment : results/mlens_1m/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate-norm_type/experiments/experiment-learning_rate_0.1-norm_type_constant/output
mlens_10m-sameshuf-AsymmetricFactorExperiment : results/mlens_10m/scrobbles-sameshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/learning_rate/experiments/experiment-learning_rate_0.07/output
mlens_10m-sameshuf-NearestNeighborExperiment : results/mlens_10m/scrobbles-sameshuf-first-5_item_filter-recoded/NearestNeighborExperiment/compute_similarity_period-gamma-gamma_threshold/experiments/experiment-compute_similarity_period_604800-gamma_0.09-gamma_threshold_0.001/output
mlens_10m-sameshuf-PopularityTimeframeExperiment : results/mlens_10m/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_604800/output
mlens_10m-sameshuf-TransitionProbabilityExperiment : results/mlens_10m/scrobbles-sameshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/experiments/experiment/output
mlens_10m-sameshuf-BatchFactorExperiment : results/mlens_10m/scrobbles-sameshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.01-negative_rate_30-number_of_iterations_3-period_length_604800/output
mlens_10m-sameshuf-FactorExperiment : results/mlens_10m/scrobbles-sameshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.2/output
mlens_10m-sameshuf-PopularityExperiment : results/mlens_10m/scrobbles-sameshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
mlens_10m-sameshuf-SvdppExperiment : results/mlens_10m/scrobbles-sameshuf-first-5_item_filter-recoded/SvdppExperiment/learning_rate/experiments/experiment-learning_rate_0.1/output
mlens_10m-fullshuf-AsymmetricFactorExperiment : results/mlens_10m/scrobbles-fullshuf-first-5_item_filter-recoded/AsymmetricFactorExperiment/gamma/experiments/experiment-gamma_0.99/output
mlens_10m-fullshuf-NearestNeighborExperiment : results/mlens_10m/scrobbles-fullshuf-first-5_item_filter-recoded/NearestNeighborExperiment/compute_similarity_period-gamma-gamma_threshold/experiments/experiment-compute_similarity_period_604800-gamma_0.09-gamma_threshold_0.001/output
mlens_10m-fullshuf-PopularityTimeframeExperiment : results/mlens_10m/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityTimeframeExperiment/tau/experiments/experiment-tau_25920000/output
mlens_10m-fullshuf-TransitionProbabilityExperiment : results/mlens_10m/scrobbles-fullshuf-first-5_item_filter-recoded/TransitionProbabilityExperiment/mode/experiments/experiment-mode_symmetric/output
mlens_10m-fullshuf-BatchFactorExperiment : results/mlens_10m/scrobbles-fullshuf-first-5_item_filter-recoded/BatchFactorExperiment/learning_rate-negative_rate-number_of_iterations-period_length/experiments/experiment-learning_rate_0.01-negative_rate_30-number_of_iterations_10-period_length_604800/output
mlens_10m-fullshuf-FactorExperiment : results/mlens_10m/scrobbles-fullshuf-first-5_item_filter-recoded/FactorExperiment/learning_rate/experiments/experiment-learning_rate_0.1/output
mlens_10m-fullshuf-PopularityExperiment : results/mlens_10m/scrobbles-fullshuf-first-5_item_filter-recoded/PopularityExperiment/experiments/experiment/output
mlens_10m-fullshuf-SvdppExperiment : results/mlens_10m/scrobbles-fullshuf-first-5_item_filter-recoded/SvdppExperiment/negative_rate-norm_type/experiments/experiment-negative_rate_30-norm_type_constant/output
