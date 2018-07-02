# Setup instructions

<a name="install"></a>
## 1. Installation

[System requirements](/system-requirements.md)
#### Add acp container to your .docksal/docksal.yml. 
(Should be done through docksal add on.) 
```
 # ACP
 acp:
   image: andockci/acp:dev-latest
   ```

#### Install wrapper. 
(Right now it is a slim wrapper script which calls acp inside the acp container. Later this should be a docksal add on.)
```
    curl -fsSL https://raw.githubusercontent.com/andock/pipeline/master/install-pipeline-docksal | sh
```
#### Server setup 
[See documentation](/install-server.md)
#### Project configuration.
```
acp config:generate
```
#### Init remote docksal.
```
acp fin init
```
## Congratulation your are done!.

3. [Configuring your docksal project to use andock](/project-setup.md)

