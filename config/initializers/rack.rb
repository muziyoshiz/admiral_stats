# Change multipart limit from 128 (default) to unlimited
# http://stackoverflow.com/questions/27773368/rails-4-2-internal-server-error-with-maximum-file-multiparts-in-content-reached
Rack::Utils.multipart_part_limit = 0
