# andock-ci pipline

**andock-ci-pipeline (acp)** is a Shell script which runs inside any ci server:
* Clone (If the project isnt' already cloned) and build any kind of project. 
* Push the result in a target git repository  
* Creates public accessable docksal project services based on feature branche
* Runs tests in these project services
* Updates project services after rebuild the project


## Install andock-ci fin server on a seperate dev server. (docksal virtual host porx will run on port 80) 

```
    curl -fsSL https://raw.githubusercontent.com/andock-ci/pipeline/master/install-server | sh
```

## Install andock-ci pipeline (acp) on your ci (build) server in one line

```
    curl -fsSL https://raw.githubusercontent.com/andock-ci/pipeline/master/install-pipeline | sh
```

## Configure andock-ci pipeline ansible hosts (/etc/ansible/hosts)


Build Server:
```
        [andock-ci-build-server]
        localhost   ansible_connection=local
```

Docksal Server:
```
        [andock-ci-fin-server]
        localhost   ansible_connection=local

```
