# DEPRECATED

# dor-scripts

From Peter on 2019-09-18:

These scripts were copied from the legacy pre-assembly codebase, which is now on https://github.com/sul-dlss/lyberservices-scripts/ 
Most of the scripts were old, possibly didn't work and were removed from the new location, but the ones that still exist should work and that is the only place they are being maintained.  

per Ben on 2019-04-01:

"I think these concerns were pulled out of the pre-assembly legacy code. this is the core of a remediation framework, so let’s not kill the repo yet because it’s useful for Peter, but my guess is if we ask this question again next year it can go bye bye".

on dor-services-prod, log is datestamped Feb 26 2018.  On dor-services-stage, it's 2017.

So ... not sure we want to fuss with this one??

Note:
- no tests

### The Devel/ Folder

Note: This folder was moved from `sul-dlss/pre-assembly`. Devel/ contained a collection of one off scripts. It was convenient to do this for the infrastructure team, because we are clearning `sul-dlss/pre-assembly` to turn it into a web application.
The scripts will need some additional configuration. For example, the `devel/` folder require's the `boot.rb` and the configuration that comes with that. Also require's the dor mounts.
