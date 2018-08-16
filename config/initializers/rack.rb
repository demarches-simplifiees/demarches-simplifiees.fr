# Number of maximum multipart chunks
# which is equal to the maximum of types de champ in one procedure
# original limit eq 128
Rack::Utils.multipart_part_limit = 256
