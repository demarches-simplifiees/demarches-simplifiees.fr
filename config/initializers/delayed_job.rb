# frozen_string_literal: true

# Set max_run_time at the highest job duration we want,
# then at job level we'll decrease this value to a lower value
# except for ExportJob.
Delayed::Worker.max_run_time = 16.hours # same as Export::MAX_DUREE_GENERATION but we can't yet use this constant here
