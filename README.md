# andock-ci-pipeline (acp) - docksal remote control
* Use ansible to remote control docksal.
* Easy to use command line tool.
* Each branch one environment.
* git workflow.
* Extendable init, update, tests workflow with ansible hooks.
* drush support including drush sql-sync without extra ssh container.
* Can used on CI server or directly inside your docksal cli container. 
* Get full control of your remote docksal 
## Scenario 1:
### Develop local - deploy to remote docksal (no CI needed.)

#### Install andock-ci docksal bridge on your local computer. Thin wrapper script which will install andock-ci inside your docksal container.
  
```
    curl -fsSL https://raw.githubusercontent.com/andock-ci/pipeline/master/install-pipeline-docksal | sh
```
#### Install andock-ci server (Only ubuntu 16.10 is tested right now.)
```
    # Run acp connect inside your docksal project. andock-ci will be installed in your cli container.
    acp connect
    # Follow instructions.
    acp server:install
```
#### Configure your docksal project.
```
    acp config:generate
```
#### Init remote docksal.
```
    acp fin init
```
## Done.