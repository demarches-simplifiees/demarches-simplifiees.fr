# Write the given objects to the standard output – except if Rake is configured
# to be quiet.
#
# This is useful when running tests (when Rake is configured to be quiet),
# to avoid spamming the output with extra informations.
def rake_puts(*args)
  if Rake.verbose
    puts(*args)
  end
end
