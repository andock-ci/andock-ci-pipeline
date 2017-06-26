# andock-ci pipline

**andock-ci-pipeline (acp)** manage your build process and deploy to docksal environments on remote hosts,
* build your docksal project and commit the builded artifact to a differnt or the same repository
* Creates public accessable docksal project services based on feature branche
* Runs tests inside these project services. Use the full power of docksal tools to run your tests
* Updates project services after rebuild the project


## Installation

### 1. Install andock-ci server
To install andock-ci server on your server run: (Port 80 and port 443 must be availabel)
```
    curl -fsSL https://raw.githubusercontent.com/andock-ci/server/master/install-server | sh
```

### 2. Install andock-ci pipeline
You can either install andock-ci pipeline on ci server or use andock-ci docker image to manage it localy 

#### Install andock-ci pipeline on your ci server

```
    curl -fsSL https://raw.githubusercontent.com/andock-ci/pipeline/master/install-pipeline | sh
```

After installation you will be asked for the andock-ci domain name or ip address. Please enter the host  


## 3. Configure your project

To configure your project place the following configuration file under .andock-ci/andock-ci.yml:

Overview: (Please check out http://github.com/andock-ci/drupal-8-demo)
```
## PROJECT CONFIGURATION
domain: "demo.dev.andock-ci.io"
project_name: "drupal-8-demo"

## GIT CONFIGURATION
git_source_repository_path: ...git #the git path of the current project.  
git_target_repository_path: ...git #the git path of the target repository. 


## HOOOKS
hook_build_tasks: "{{project_path}}/.andock-ci/hooks/build_tasks.yml"
hook_init_tasks: "{{project_path}}/.andock-ci/hooks/init_tasks.yml"
hook_update_tasks: "{{project_path}}/.andock-ci/hooks/update_tasks.yml"
hook_test_tasks: "{{project_path}}/.andock-ci/hooks/test_tasks.yml"
```

#### Configuration details:
##### Base configuration:
###### domain:
    The base domain for this project. A docksal instance will listen at feature_branch.domain.
    For example if your domain is dev.mydomain.com and your feature branch is 1121_add_stuff than the domain of the project is:
    
    1121_add_stuff.dev.mydomain.com
###### project_name:
    The name of the current project. The name must be unique on andock-ci-server. 

##### Git configuration:
###### git_source_repository_path:
    the git path of the current project.

###### git_target_repository_path:
    the git path of the target project. This can be the same project as the source repository

#### Hooks:
Hooks are used to configure the build and deploy process.<br>
Here you can run composer npm or any tool you want to build or setup your environment. 


##### .andock-ci/hooks/build_tasks.yml:
Tasks will run after "acp build"
```
- name: composer install
  command: composer install
  args:
    chdir: "{{ checkout_path }}"
```

##### .andock-ci/hooks/init_tasks.yml:
Tasks will run while andock-ci creates a new instance. (acp fin init) 
```
- name: drush sql-create
  command: "drush sql-create -y"
  args:
    chdir: "{{ docroot_path }}"
  when: !instance_exists_before

- name: drush si
  command: "drush si minimal -y"
  args:
    chdir: "{{ docroot_path }}"
  when: !instance_exists_before
```

##### .andock-ci/hooks/update_tasks.yml:
Tasks will run after acp fin update 
```
- name: drush cr
  command: "drush cr"
  args:
    chdir: "{{ docroot_path }}"
```

##### .andock-ci/hooks/test_tasks.yml:
Tasks will run after acp fin test 
```
tbd
```